# Security Rules

Applies to: all code, config, and tooling in this project.

## Hard rules — never violate

1. **No secrets in code.** No API keys, passwords, tokens, or private keys hardcoded in any source file. Use environment variables or Vault references exclusively.
2. **No secrets in git history.** If a secret is accidentally committed, rotate it immediately before doing anything else. Use `git filter-branch` or `BFG Repo Cleaner` to purge it from history.
3. **No secrets in logs.** Never log credential fields, even at DEBUG level. Tenant config credentials are marked `encrypted` — never pass them to `log.Printf` or any logging call.
4. **No plain HTTP for external delivery.** All webhook deliveries, PSA API calls, and SIEM ingest calls must use TLS 1.3. Reject non-HTTPS URLs at config validation time.
5. **Credentials stored encrypted at rest.** All PSA and SIEM credentials in the Tenant Config Store must be encrypted via Vault. Never write them to Postgres in plaintext.
6. **HMAC on all webhooks.** Every outbound webhook delivery must carry an `X-SLB-Signature` header. Receivers must verify it before processing.
7. **mTLS between hook and engine.** The hook → detection engine gRPC transport must use mutual TLS. Client certificate must be org-token-derived.
8. **No external API in ML hot path.** All 10 ML models run local inference (ONNX Runtime). No model inference request may leave the detection engine server.

## Credential handling patterns

```go
// ✅ CORRECT — read from Vault at startup, never log
creds, err := vault.GetTenantCredentials(ctx, tenantID)
if err != nil {
    return fmt.Errorf("get tenant credentials: %w", err)
}
client.SetAuth(creds.PublicKey, creds.PrivateKey) // passed to client, never logged

// ❌ WRONG — never do this
log.Printf("using credentials: %s / %s", creds.PublicKey, creds.PrivateKey)
```

## Secrets scanning
- The pre-tool-use hook `hooks/pre-tool-use/secrets-scan.sh` runs on every `Bash` command and `Write` operation
- It blocks execution if it detects patterns matching: API keys, private keys, AWS secrets, common secret patterns
- This scan cannot be disabled without modifying `settings.json` (which requires a team review)

## Tenant isolation
- Every query to the event store must be scoped by `tenant_id` — no cross-tenant data access
- The Tenant Config Store enforces row-level security: API keys can only read their own tenant's row
- MSSP scope allows reading child tenant data — but only for tenants listed in `parent_tenant` relationship
- Integration Bus routes events only to the webhook/PSA/SIEM configured for that event's tenant

## Dependency security
- `go.sum` must be committed — verify checksums on all dependency updates
- No dependency updates without reviewing the changelog for security notices
- Supply chain rule SI-001/SI-002 applies to our own build toolchain too — pin versions in Makefile
- Run `govulncheck ./...` before every release

## Vulnerability disclosure
- Security issues in this codebase: report to `security@securitylayerbasis.io` — do NOT open public GitHub issues
- CVE-severity mapping: CVSS ≥ 9.0 → patch and release within 24h; ≥ 7.0 → within 7 days; < 7.0 → next release cycle

## Code review security checklist
Before approving any PR touching integration code:
- [ ] No secrets in diff
- [ ] Credential fields not logged
- [ ] New endpoints: auth enforced, scope checked
- [ ] New webhook delivery: HMAC signing present
- [ ] New PSA adapter: credentials read from Vault, not config struct
- [ ] New SIEM formatter: no PII added beyond what architecture specifies
- [ ] Tenant isolation: all DB queries scoped by `tenant_id`
- [ ] TLS enforced on all new external connections
