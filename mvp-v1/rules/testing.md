# Testing Rules — MVP v1

## Required coverage

| Component | Minimum |
|-----------|---------|
| Rule evaluator (7 rules) | 100% — every rule has a fixture |
| ML model loaders (3 models) | Smoke tests + ONNX runtime sanity |
| ConnectWise PSA adapter | Unit tests + recorded API integration tests |
| Webhook engine (HMAC, retry, DLQ) | Unit tests + integration tests with test receiver |
| Skill registry (SQLite) | CRUD + risk-score query tests |
| Tenant isolation | Cross-tenant query attempts must fail |
| HITL-001 logic | Threshold transitions, hitl_present states |

## Rule test fixtures

Every rule in `policy.yaml` references a fixture under `tests/fixtures/`:

- `hitl-001-autonomous-shell.json` — shell exec after 5+ min without HITL
- `si-001-critical-skill.json` — skill load with risk_score=Critical
- `si-002-unknown-skill.json` — skill load with NOT_FOUND result
- `ce-001-env-exfil.json` — `cat .env | curl ...`
- `rs-001-reverse-shell.json` — `bash -i >& /dev/tcp/...`
- `mcp-001-unauth-server.json` — mcp_connect to non-allowlisted server
- `fs-002-env-write.json` — file_write to `.env`

Each fixture: input HookEvent + expected VerdictResponse + expected ATT&CK mapping.

## Integration tests

- ConnectWise PSA: ticket creation, dedup, auto-close — against ConnectWise sandbox
- Webhook delivery: HMAC verify, retry on 5xx, DLQ on permanent failure
- mTLS: hook ↔ engine handshake with valid + revoked + expired certificates
- Vault: tenant credential read/write/rotation

## Performance tests

| Metric | Target | Test |
|--------|--------|------|
| Verdict latency p99 | < 50ms | Load test with realistic event mix |
| Hook overhead p99 | < 1ms | Microbench in VS Code extension |
| Throughput | 10K events/sec | Sustained load test |
| Integration Bus delivery | < 100ms | End-to-end PSA + webhook timing |

## Forward-compatibility tests

Critical for MVP: nothing here may break v1.1 / v6 schema.

- Protobuf: golden-file tests against v6 schema — MVP messages must parse with v6 schema
- Policy YAML: v1 policy must validate against v6 schema (deferred fields ignored, not rejected)
- Tenant config: encrypted credential format must survive v1 → v1.1 migration

## Test commands

```bash
# Full suite
make test

# Just rules
go test ./internal/rules/...

# Just integration bus
go test ./internal/integration_bus/...

# Just performance
make perf-test

# Forward-compat
make compat-test
```
