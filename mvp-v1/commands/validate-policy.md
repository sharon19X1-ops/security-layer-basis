# /validate-policy

**Slash command** — validates `policy.yaml` against MVP v1 schema and runs policy unit tests.

## Usage

```
/validate-policy [--file path] [--strict]
```

## Arguments

| Arg | Description |
|-----|-------------|
| `--file` | Path to policy file (default: `./policy.yaml`) |
| `--strict` | Treat warnings as errors (exit 1 on any warning) |

## What it runs

```bash
go run cmd/policy-validator/main.go --file ${file:-policy.yaml} --mvp ${strict:+--strict}
```

The validator performs:

1. **Structural validation** — required keys, no unknown keys
2. **Rule validation** — all 7 MVP rules present, each with required fields
3. **Severity / action validation** — values within MVP verdict set
4. **ATT&CK mapping validation** — every rule has a valid technique ID
5. **Fixture path validation** — every fixture file exists
6. **ML model validation** — only 3 MVP models referenced
7. **Integration validation** — only ConnectWise PSA, only HMAC-signed webhooks
8. **HITL sanity** — threshold ≥ 60 sec, action ∈ {WARN, BLOCK}
9. **Forward-compatibility** — passes v6 schema validation as well

## Output

See `agents/policy-validator.md` for output format.

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Valid |
| `1` | Invalid (errors) |
| `2` | Warnings (advisory) |
