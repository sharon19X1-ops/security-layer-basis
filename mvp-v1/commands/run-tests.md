# /run-tests

**Slash command** — runs the MVP v1 test suite.

## Usage

```
/run-tests [scope]
```

## Scopes

| Scope | What it runs |
|-------|--------------|
| (none / `all`) | Full suite: rules + integration + perf-light + forward-compat |
| `rules` | Just the 7 rules against their fixtures |
| `integration` | ConnectWise PSA + webhook engine tests |
| `hitl` | HITL-001-specific tests (threshold transitions, hitl_present states) |
| `skill` | SI-001 / SI-002 + skill registry tests |
| `perf` | Verdict latency + throughput |
| `compat` | Forward-compatibility against v6 schema |

## Examples

```
/run-tests
/run-tests rules
/run-tests hitl
/run-tests compat
```

## What it runs (under the hood)

```bash
case ${scope:-all} in
  all)         make test ;;
  rules)       go test ./internal/rules/... ;;
  integration) go test ./internal/integration_bus/... ;;
  hitl)        go test ./internal/rules/hitl/... -run HITL ;;
  skill)       go test ./internal/skills/... ./internal/rules/si/... ;;
  perf)        make perf-test ;;
  compat)      make compat-test ;;
esac
```

## Pass criteria

- All 7 rule fixtures produce expected verdicts
- ConnectWise PSA: ticket created, dedup'd, auto-closed
- Webhook: HMAC valid, retry triggers on 5xx, DLQ on permanent failure
- mTLS handshake: valid cert OK, revoked cert rejected, expired cert rejected
- Vault: credential read/write/rotation OK
- Verdict latency p99 < 50ms
- Forward-compat: MVP messages parse cleanly with v6 schema
