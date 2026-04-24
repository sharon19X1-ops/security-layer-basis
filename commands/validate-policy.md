# /validate-policy

**Description:** Validate `policy.yaml` against the schema, check all rule IDs exist, verify routing table completeness, and confirm all enabled integrations have required config fields.

## What it does

1. Runs `go run cmd/policy-validator/main.go --file policy.yaml`
2. Checks every rule ID in `policy.yaml` exists in the rule registry
3. Checks routing table covers all severity levels: CRITICAL, HIGH, MEDIUM, LOW, HOLD, DENY
4. Checks integration section: if `psa.enabled: true`, verifies `provider` is set and `credentials` are resolvable via Vault
5. Checks ATT&CK mapping is present for every rule in the enabled rule set
6. Reports: ✅ PASS or ❌ FAIL with specific error lines

## Shell execution

```bash
go run cmd/policy-validator/main.go --file policy.yaml --verbose
```

## When to use
- After any edit to `policy.yaml`
- Before merging a PR that touches policy
- After adding a new rule class (to verify ATT&CK mapping and routing entry exist)
- After changing tenant integration config

## Expected output (pass)
```
✅ Policy validation passed
   Rules: 21/21 mapped to ATT&CK
   Routing table: 6/6 severity levels covered
   PSA: connectwise — credentials resolvable
   SIEM: sentinel — endpoint resolvable
   Webhooks: 2 endpoints configured
```
