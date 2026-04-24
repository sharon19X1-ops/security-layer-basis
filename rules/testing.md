# Testing Rules

Applies to: all test files in this project.

## Requirements

- Every new rule class requires a test event fixture in `testdata/fixtures/{rule_id}.json`
- Every new PSA adapter function requires a unit test with a mock PSA API server
- Every new SIEM formatter requires a unit test that validates the exact output format against the SIEM spec
- Every new ATT&CK mapping entry must be covered by a test in `internal/attack_mapper/`
- The Integration Bus delivery path requires an integration test per channel (PSA, SIEM, Webhook)
- Policy changes require a test proving the routing table produces the correct channel set per severity

## Test structure (Go)

```
internal/
├── attack_mapper/
│   ├── mapper.go
│   └── mapper_test.go          # table-driven tests for all 21 rules
├── integration_bus/
│   ├── bus.go
│   └── bus_test.go             # routing logic + delivery guarantee tests
├── psa/
│   ├── connectwise/
│   │   ├── adapter.go
│   │   └── adapter_test.go     # mock CW API, assert ticket fields
│   └── autotask/
│       ├── adapter.go
│       └── adapter_test.go
├── siem/
│   ├── cef/
│   │   ├── formatter.go
│   │   └── formatter_test.go   # assert CEF string format byte-for-byte
│   ├── ecs/
│   │   ├── formatter.go
│   │   └── formatter_test.go   # assert JSON fields against ECS spec
│   └── sentinel/
│       ├── formatter.go
│       └── formatter_test.go
└── webhook/
    ├── engine.go
    └── engine_test.go          # HMAC signing, retry logic, DLQ
```

## Naming
- Test functions: `TestComponentName_Scenario_ExpectedOutcome`
- Example: `TestConnectWiseAdapter_CriticalEvent_CreatesTicketWithCorrectPriority`
- Table-driven tests: `cases := []struct{ name, input, expected }` pattern

## Coverage gates
- Minimum 80% line coverage on all `internal/` packages
- 100% coverage required on: `attack_mapper`, `siem/cef`, `siem/ecs`, `webhook/engine` (HMAC signing path)
- CI blocks merge if coverage drops below gate

## Integration tests
- Tag with `//go:build integration` — excluded from default `go test ./...`
- Run with `make test-integration` (requires live test PSA/SIEM sandbox credentials)
- Never run integration tests against production endpoints — use sandbox env vars

## Fixtures
- `testdata/fixtures/{rule_id}.json` — one per rule class, representing a realistic event
- `testdata/fixtures/tenant_config_sample.yaml` — non-sensitive sample tenant config
- `testdata/mock_psa_responses/` — saved API response payloads for mock servers
- No real credentials, tenant IDs, or PII in fixture files

## Pre-commit
- `make pre-commit` must pass before any commit: runs `go vet ./... && golangci-lint run && go test ./...`
- This is enforced by the pre-commit hook in `hooks/pre-tool-use/`
