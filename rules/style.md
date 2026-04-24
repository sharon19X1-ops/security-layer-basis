# Style Rules

Applies to: all Go, TypeScript, and protobuf files in this project.

## Go
- Follow `gofmt` formatting — run `make lint` before every commit
- Package names: lowercase, single word, no underscores (e.g. `attackmapper`, `tenantconfig`)
- File names: `snake_case.go`
- Exported names: `PascalCase`; unexported: `camelCase`
- Error variables: prefix `Err` (e.g. `ErrTenantNotFound`)
- Constants: `UPPER_SNAKE_CASE` for true constants; `PascalCase` for typed consts in iota blocks
- Comments: every exported type, function, and constant must have a GoDoc comment
- Max function length: 60 lines. Extract helpers if longer.
- No naked returns in functions longer than 5 lines

## TypeScript (hook agents)
- `"strict": true` in tsconfig — no exceptions
- No `any` in event schema types — use generated protobuf types only
- File names: `camelCase.ts` (modules) or `PascalCase.ts` (classes)
- Interfaces: prefix `I` only when disambiguating from a concrete class; otherwise no prefix
- Async: always `async/await` — no raw Promise chains
- Log via structured logger — no `console.log` in production code paths

## Protobuf
- File names: `snake_case.proto`
- Message names: `PascalCase`
- Field names: `snake_case`
- Enum names: `UPPER_SNAKE_CASE`
- Reserve field numbers and names when removing fields — never reuse a number
- Add a comment on every message explaining its purpose and which layer produces/consumes it

## Markdown (architecture docs)
- Architecture docs are living specs — keep them in sync with code changes
- When adding a new rule class, update: `ARCHITECTURE_V6.md` ATT&CK table + `rules/` doc index
- Tables: align columns using spaces for readability
- ASCII diagrams: preserve box-drawing characters exactly — they are part of the spec

## Commit messages
- Format: `type(scope): message`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `security`
- Scope examples: `psa-adapter`, `siem-formatter`, `attack-mapper`, `integration-bus`, `hook-vscode`, `policy`, `api`
- Body: explain *why*, not *what* (the diff shows what)
- No secrets, credentials, or tenant IDs in commit messages
