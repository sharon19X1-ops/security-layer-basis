# Security Layer-Basis — CLAUDE.md
> Loaded at session start. Defines project overview, tech stack, commands, coding conventions, and architecture summary.

---

## Project Overview

**Security Layer-Basis** is a universal AI coding-agent security interception platform.

- A thin hook layer runs inside every IDE (VS Code, JetBrains, Cursor, Neovim, CLI agent)
- Events flow to a centralized detection engine over TLS 1.3 / mTLS gRPC
- The engine prevents, verifies, detects, and blocks — then routes every verdict into the MSP/MSSP stack via the Integration Bus (v6)
- One policy YAML governs everything

**Current version:** 6.0 (Integration-first)  
**Security posture:** PREVENT → VERIFY → DETECT → BLOCK → INTEGRATE → DISTRIBUTE  
**Threat coverage:** 30/30 threat classes

---

## Architecture Summary (v6)

| Layer | Components |
|-------|-----------|
| **Hook Agent** | IDE plugins (VS Code, JetBrains, Cursor, Neovim, CLI) — captures 17 event types |
| **Prevention** | Credential deny list, filesystem scope enforcer |
| **Capture** | Event capture, skill identity resolver, sub-skill depth tracker, memory write interceptor, HITL session tracker, process tree monitor |
| **Verification** | Completion gate evaluator, commit gate evaluator, lint/test result injector, truncation signal detector |
| **Gateway Layer** | Auth, rate limiting, tenant isolation, event dedup, schema validation |
| **Event Pipeline** | Ingestion queue → Normalizer+Enricher → Risk Classifier → Verdict Router+ATT&CK Map |
| **Scoring & Correlation** | Skill Scoring Engine (10 ML models), Cross-Event Correlation Engine (4 patterns) |
| **Action Executor** | Block · Warn · Deny · Hold · Audit · Alert · Quarantine · Kill · HITL Gate |
| **Integration Bus** | Central outbound router: PSA Adapter Layer · SIEM Formatter · Webhook Engine |
| **Tenant Config Store** | Per-org PSA creds, SIEM endpoints, webhook URLs — encrypted at rest (Postgres + Vault) |
| **REST API v1** | Public API for SOAR · automation · MSSP dashboards · partner apps |
| **RMM Deployment Layer** | NinjaOne · Datto RMM · N-able · Kaseya VSA · ConnectWise RMM |
| **Observability Plane** | Audit trail · SOC dashboard · HITL console · integration health · API usage |

---

## Tech Stack

### Hook Agent (IDE side)
- **Language:** TypeScript (VS Code extension) / Kotlin (JetBrains plugin) / Node.js (CLI agent hook)
- **Transport:** gRPC over TLS 1.3 / mTLS to detection engine
- **Event schema:** Protocol Buffers (protobuf)
- **Install:** Via RMM deployment script (PS1/Shell) or manual

### Detection Engine (server side)
- **Language:** Go (gateway, event pipeline, integration bus) · Python (ML inference)
- **Event queue:** Apache Kafka (100K events/sec)
- **Database:** PostgreSQL (tenant config, event store, audit log)
- **Secrets:** HashiCorp Vault (credential encryption for tenant config)
- **ML runtime:** ONNX Runtime (10 models, local inference — no external API in hot path)
- **API:** REST v1 (JSON, API Key → OAuth2 Client Credentials)
- **Transport (API):** HTTPS, TLS 1.3

### Policy
- **Format:** Single YAML file (`policy.yaml`)
- **Scope:** Global defaults + per-tenant overrides via Tenant Config Store

### Integration targets
- **PSA:** ConnectWise Manage REST API · Autotask REST API · HaloPSA REST API · Syncro REST API
- **SIEM:** CEF/syslog · ECS (Elastic) · Splunk HEC · Microsoft Sentinel REST (Log Analytics)
- **RMM:** NinjaOne Script Library · Datto RMM Component Library · N-able Automation Manager · Kaseya Agent Procedure · ConnectWise Automate Script Library
- **Automation:** Webhook (HMAC-SHA256) → Rewst · Zapier · Tines · Make · n8n

---

## Key Commands

```bash
# Run all tests
make test

# Run linter
make lint

# Build hook agent (VS Code extension)
npm run build --prefix hook/vscode

# Build detection engine (Go)
go build ./...

# Run detection engine locally
go run cmd/engine/main.go --config config/local.yaml

# Generate protobuf bindings
make proto

# Run integration bus in dry-run mode
go run cmd/integration-bus/main.go --dry-run

# Validate policy.yaml
go run cmd/policy-validator/main.go --file policy.yaml

# Run ATT&CK mapper test
go test ./internal/attack_mapper/...

# Build & push Docker image (detection engine)
make docker-build && make docker-push

# Deploy to staging
make deploy-staging

# Run full test suite + lint before commit
make pre-commit
```

---

## Project Structure

```
security-layer-basis/
├── CLAUDE.md                    # ← this file
├── mcp.json                     # MCP integration configs
├── settings.json                # Permissions, model selection, hooks
├── rules/                       # Modular coding/style rules
│   ├── style.md
│   ├── testing.md
│   ├── api-design.md
│   ├── security.md
│   └── integration.md
├── commands/                    # Custom slash commands
│   ├── validate-policy.md
│   ├── run-tests.md
│   ├── check-attack-mappings.md
│   └── integration-healthcheck.md
├── skills/                      # Auto-triggered context skills
│   ├── psa-adapter.md
│   ├── siem-formatter.md
│   └── attack-mapper.md
├── agents/                      # Specialized sub-agents
│   ├── security-reviewer.md
│   ├── integration-engineer.md
│   └── policy-validator.md
├── hooks/                       # Pre/post tool-use scripts
│   ├── pre-tool-use/
│   │   ├── lint-check.sh
│   │   └── secrets-scan.sh
│   └── post-tool-use/
│       ├── run-tests.sh
│       └── format-check.sh
├── ARCHITECTURE_V6.md           # Current canonical architecture
├── ARCHITECTURE_V5.md
├── ...
├── policy.yaml                  # Detection + integration policy
└── README.md
```

---

## Coding Conventions

### Go (detection engine, integration bus, API)
- Follow standard Go project layout (`cmd/`, `internal/`, `pkg/`)
- Error wrapping: `fmt.Errorf("context: %w", err)` — never discard errors
- Context propagation: all functions must accept `context.Context` as first argument
- No global mutable state in hot path
- All PSA/SIEM credentials must be read from Vault — never hardcoded, never logged
- Struct field comments required for all exported types

### TypeScript (hook agents)
- Strict mode on (`"strict": true` in tsconfig)
- No `any` types in event schema types — use generated protobuf types
- Event capture must be zero-latency from the IDE's perspective (async queue, no blocking)
- All hook errors must be caught and logged locally — never crash the IDE

### Protocol Buffers
- All event messages versioned (field numbers stable across versions)
- New fields: always optional, never remove existing field numbers
- Generate bindings via `make proto` — never hand-edit generated files

### YAML (policy)
- `policy.yaml` is the single source of truth — no per-rule inline config in code
- All new rule classes require a corresponding ATT&CK mapping entry
- Integration routing rules must match severity enum exactly

### General
- No secrets in code, logs, or git history
- All tenant credential fields in Tenant Config Store: encrypted at rest, never logged in plaintext
- All webhook deliveries: TLS 1.3 only, HMAC-SHA256 signed
- Every new rule class must have: rule ID, name, severity, ATT&CK mapping, and test event fixture

---

## Architecture Key Decisions

| Decision | Rationale |
|----------|-----------|
| Own ML inference (no external API in hot path) | Independence audit finding — prevents single-point failure and data leakage |
| Single policy YAML | One policy, everywhere — no per-IDE or per-developer policy drift |
| Integration Bus decoupled from verdict return | Verdict → hook is synchronous; Integration Bus delivery is async — hook is never delayed by PSA/SIEM latency |
| HMAC-SHA256 on all webhooks | Receivers can verify authenticity without shared session state |
| Vault for credential encryption | Tenant PSA/SIEM credentials never touch the application DB in plaintext |
| Protobuf event schema | Stable, versioned, language-agnostic — hook and engine can evolve independently |
| At-least-once delivery + idempotency key | Guarantees no lost PSA tickets on retry, no duplicates |

---

## Current Milestone

**v0.6 target: Q1 2027**
- Integration Bus core
- Webhook Engine (HMAC-signed, retry, DLQ)
- Tenant Config Store (Postgres + Vault)

See full roadmap in `ARCHITECTURE_V6.md` section 15.
