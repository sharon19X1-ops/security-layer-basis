# Security Rules — MVP v1

**Inherits from:** `../rules/security.md` (parent project)  
**Scope:** All code, config, and tooling in `mvp-v1/`

The MVP does NOT relax any security rule from the parent. Every constraint below is enforced from day one.

## Hard rules — never violate

1. **No secrets in code.** No API keys, passwords, tokens, or private keys hardcoded. Use environment variables or Vault references exclusively.
2. **No secrets in git history.** If a secret is accidentally committed, rotate it immediately, then purge from history.
3. **No secrets in logs.** Never log credential fields, even at DEBUG. Tenant config credentials marked `encrypted` — never pass to `log.Printf` or any logger.
4. **No plain HTTP for external delivery.** All webhook deliveries and PSA API calls must use TLS 1.3. Reject non-HTTPS URLs at config validation time.
5. **Credentials encrypted at rest.** All PSA credentials in Tenant Config Store encrypted via Vault. Never written to Postgres in plaintext. **Vault is required from MVP day one — no shortcut.**
6. **HMAC on all webhooks.** Every outbound webhook delivery carries `X-SLB-Signature` (HMAC-SHA256). Receivers verify before processing.
7. **mTLS between hook and engine.** The hook → detection engine gRPC transport uses mutual TLS. Client certificate is org-token-derived. **No plain TLS option in MVP.**
8. **No external API in ML hot path.** All 3 MVP ML models run local inference (ONNX Runtime). No model inference request leaves the detection engine server.
9. **No PII in transit.** Developer IDs hashed at hook. Payload de-identified before forwarding. Same as v6.
10. **Tenant isolation at DB layer.** Every query scoped by `tenant_id`. Row-level security enforced.

## MVP-specific security discipline

### Skill registry independence
The MVP **never** depends on Tego or any external skill API at runtime. The own SQLite skill registry is populated by an ingestion pipeline and queried locally. If the registry is unavailable:
- SI-001 emits **WARN** (not ALLOW) — never silently blind
- SI-002 emits **WARN** (not ALLOW) — never silently blind
- This prevents the failure mode the v5 Independence Audit identified

### HITL gate cannot be silently disabled
The HITL-001 rule is in Tier 1 and the highest priority in MVP. It cannot be disabled per-tenant in MVP — only the threshold (`autonomous_threshold_sec`) and the action (WARN | BLOCK) are tunable. **Disabling HITL-001 entirely requires a code change, not a config change.**

### MVP doesn't ship undertrained models
`prompt_injection_bert` is loaded in MVP but used in advisory mode only — no blocking rule fires on it alone. Reason: false-positive BLOCK on legitimate prompts is a worse failure than detecting later. The blocking rule (PI-001a) ships in v1.1 after corpus tuning.

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
- Pre-tool-use hook `hooks/pre-tool-use/secrets-scan.sh` runs on every `Bash` and `Write` operation
- Blocks execution if it detects: API keys, private keys, AWS secrets, ConnectWise public/private key patterns, common secret patterns
- Cannot be disabled without a `settings.json` change (which requires team review)

## Tenant isolation (MVP)
- Every query to event store scoped by `tenant_id`
- Tenant Config Store enforces row-level security: API keys read only their own tenant's row
- Integration Bus routes events only to webhook/PSA configured for that event's tenant
- MSSP scope **deferred to v1.1** — MVP is single-tenant per operator login

## Dependency security
- `go.sum` must be committed
- No dependency updates without reviewing changelog for security notices
- SI-001/SI-002 supply chain rule applies to our own build toolchain — pin Makefile versions
- Run `govulncheck ./...` before every release

## Code review security checklist (MVP)
Before approving any PR:
- [ ] No secrets in diff
- [ ] Credential fields not logged
- [ ] New endpoints: auth enforced, scope checked
- [ ] New webhook delivery: HMAC signing present
- [ ] PSA adapter: credentials read from Vault, not config struct
- [ ] Tenant isolation: all DB queries scoped by `tenant_id`
- [ ] TLS enforced on all new external connections
- [ ] HITL-001 cannot be silently disabled by the change
- [ ] Skill registry calls fall back to WARN, not ALLOW, on failure
- [ ] Forward-compatibility: new protobuf fields use field numbers reserved for MVP (1–12) or v1.1+ (13+)

## Vulnerability disclosure
- Security issues: report to `security@securitylayerbasis.io` — do NOT open public GitHub issues
- CVSS ≥ 9.0 → patch + release within 24h; ≥ 7.0 → 7 days; < 7.0 → next cycle
