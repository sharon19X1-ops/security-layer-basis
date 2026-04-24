# /run-tests

**Description:** Run the full test suite (unit tests + linter) and report coverage by package.

## What it does

1. `go vet ./...` — catches common Go mistakes
2. `golangci-lint run` — runs configured linters (errcheck, staticcheck, gosec, etc.)
3. `go test ./... -cover -coverprofile=coverage.out` — runs all unit tests with coverage
4. `go tool cover -func=coverage.out` — prints per-package coverage
5. Checks if any package is below the 80% coverage gate
6. Reports total pass/fail summary

## Shell execution

```bash
make test
```

Or step by step:
```bash
go vet ./...
golangci-lint run
go test ./... -cover -coverprofile=coverage.out -race
go tool cover -func=coverage.out | tail -5
```

## Run integration tests (requires sandbox credentials)

```bash
make test-integration
```

> Requires env vars: `CW_SANDBOX_*`, `SPLUNK_SANDBOX_*`, `SENTINEL_SANDBOX_*`  
> Never run against production endpoints.

## When to use
- Before any commit
- After changing any Go or TypeScript source file
- After modifying the ATT&CK mapper, SIEM formatter, or PSA adapter

## Expected output (pass)
```
ok  internal/attack_mapper       0.112s  coverage: 100.0%
ok  internal/integration_bus     0.088s  coverage: 87.3%
ok  internal/psa/connectwise     0.201s  coverage: 91.2%
ok  internal/siem/cef            0.045s  coverage: 100.0%
ok  internal/webhook             0.067s  coverage: 100.0%
...
All packages above 80% gate. ✅
```
