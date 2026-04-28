# Style Rules — MVP v1

## Go (detection engine, integration bus)

- Standard layout: `cmd/`, `internal/`, `pkg/`
- Error wrapping: `fmt.Errorf("context: %w", err)` — never discard errors
- Context propagation: every function takes `context.Context` as first arg
- No global mutable state in hot path
- All exported types: struct field comments required
- Lint: `golangci-lint run` — must pass before commit
- Format: `gofmt -w .` — no exceptions

## TypeScript (hook agents)

- Strict mode (`"strict": true` in tsconfig)
- No `any` types — especially not in event schema (use generated protobuf types)
- Hook capture: zero-latency, async queue, never block the IDE
- All hook errors caught and logged locally — never crash the IDE
- Lint: `eslint` — must pass
- Format: `prettier` — no exceptions

## Protocol Buffers

- Field numbers stable across MVP → v1.1 → v6
- New fields always optional, never remove existing field numbers
- MVP uses field numbers 1–12 of HookEvent — fields 13+ reserved for v1.1+ extensions
- Generate via `make proto` — never hand-edit generated files

## YAML (policy.yaml)

- Single source of truth — no per-rule inline config in code
- All rule classes carry an ATT&CK mapping
- Integration routing matches severity enum exactly
- Every new rule includes a test fixture path

## MVP-specific discipline

- **No premature v6 features.** Features deferred to v1.1+ stay deferred until that milestone opens.
- **Don't stub silently.** A v1.1 capability is either fully in MVP or fully not in MVP — no half-implemented placeholders that look real.
- **Comment every "designed-in but not enforced" field.** E.g., `depth_limit` in policy.yaml: schema present, enforcement deferred, comment says so.
