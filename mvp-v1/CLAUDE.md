# Security Layer-Basis — MVP v1 — CLAUDE.md
> Loaded at session start. MVP sub-project of `security-layer-basis/`. Defines scope, tech stack, commands, conventions, and what is intentionally deferred.

---

## Project Overview

**Security Layer-Basis MVP v1** is the smallest deployable subset of the full v6 architecture — engineered to ship fast and stop the highest-confirmed-impact attacks on day one, while maintaining every security rule from the parent project.

- **Parent project:** `../` (security-layer-basis/, currently at v6.0)
- **Status:** MVP — Q3 2026 target launch
- **Scope:** VS Code + Claude Code CLI hooks · 8 event types · 7 rules · 3 ML models · ConnectWise PSA + webhook
- **Posture:** DETECT → BLOCK (MVP) → PREVENT → VERIFY (v1.1 fast-follow)
- **Priority:** HITL Gate (HITL-001) · Skill Identity Scan (SI-001/SI-002) — both in Tier 1

**Threat coverage:** 6/30 high-priority classes (vs. 30/30 in v6). Schema forward-compatible — every v6 capability slots in without breaking changes.

---

## Architecture Summary (MVP)

| Layer | Components |
|-------|-----------|
| **Hook Agent** | VS Code extension + Claude Code CLI shim — captures 8 event types |
| **Capture** | PROMPT_SUBMITTED · COMPLETION_RECEIVED · SHELL_EXEC · FILE_WRITE · NETWORK_REQUEST · MCP_CONNECT · SKILL_LOAD · HITL_CHECKPOINT |
| **Gateway Layer** | mTLS auth · rate limiting · tenant isolation · event dedup |
| **Event Pipeline** | NATS queue → Normalizer+Enricher → Rule Evaluator (7 rules) → Verdict Router |
| **Skill Registry** | Own SQLite registry (no Tego dependency) — daily ingestion from GitHub/ClawHub/MCP |
| **ML** | 3 ONNX models: reverse_shell_classifier · prompt_injection_bert · skill_intent_mismatch |
| **Action Executor** | ALLOW · WARN · BLOCK · KILL_SESSION |
| **Integration Bus** | ConnectWise PSA adapter + Webhook Engine (HMAC-SHA256) |
| **Tenant Config Store** | Encrypted at rest (Postgres + Vault) — same security model as v6 |
| **Observability** | Audit trail (immutable) + SOC dashboard + alert feed |

**Out of MVP:** Prevention layer (full pre-read), Verification layer, memory tracking, sub-skill depth, cross-event correlation, SIEM, REST API, RMM scripts. All listed in MVParchitecture_v1.md §12 upgrade path.

---

## Tech Stack

### Hook Agent (IDE side)
- **Language:** TypeScript (VS Code extension), Node.js (Claude Code CLI shim)
- **Transport:** gRPC over TLS 1.3 / mTLS to detection engine
- **Event schema:** Protocol Buffers (protobuf) — see MVParchitecture_v1.md §2
- **Install:** One-liner curl install (per-developer-machine, no admin required in MVP)

### Detection Engine (server side)
- **Language:** Go (gateway, event pipeline, integration bus) · Python (ML inference)
- **Event queue:** NATS (MVP) → Kafka (v1.0)
- **Database:** SQLite (skill registry MVP) → PostgreSQL (tenant config + audit log)
- **Secrets:** HashiCorp Vault (PSA credentials encryption) — required from day one
- **ML runtime:** ONNX Runtime (3 models, local inference only)
- **API:** Internal-only in MVP (REST API v1 in v1.3)

### Policy
- **Format:** Single YAML file (`policy.yaml`)
- **Scope:** Per-tenant config in Tenant Config Store

### Integration Targets (MVP)
- **PSA:** ConnectWise Manage REST API (only)
- **Webhook:** Outbound HMAC-SHA256 signed (universal — Rewst, Zapier, Slack, custom)
- **SIEM:** None in MVP (webhook covers alert delivery)

---

## Key Commands

```bash
# Run all tests
make test

# Run linter
make lint

# Build hook agent (VS Code extension)
npm run build --prefix hook/vscode

# Build CLI shim (claude-code / codex)
npm run build --prefix hook/cli

# Build detection engine (Go)
go build ./...

# Run detection engine locally
go run cmd/engine/main.go --config config/local.yaml

# Generate protobuf bindings (8 event types — MVP subset)
make proto

# Validate policy.yaml against MVP schema
go run cmd/policy-validator/main.go --file policy.yaml --mvp

# Run integration bus in dry-run mode (no PSA tickets created)
go run cmd/integration-bus/main.go --dry-run

# Skill registry — refresh from public sources
go run cmd/skill-ingester/main.go --sources github,clawhub,mcp

# Run full pre-commit check
make pre-commit

# Slash commands
/validate-policy        # Validates policy.yaml against MVP schema
/run-tests              # Runs full test suite
/check-hitl             # Sanity check HITL-001 wiring
```

---

## Project Structure

```
security-layer-basis/
├── (parent project files)
└── mvp-v1/                          # ← this sub-project
    ├── MVParchitecture_v1.md        # Canonical MVP architecture
    ├── CLAUDE.md                    # ← this file
    ├── mcp.json                     # MCP integration configs (MVP-scoped)
    ├── settings.json                # Permissions, model, hooks
    ├── policy.yaml                  # Sample MVP policy
    ├── rules/
    │   ├── security.md
    │   ├── style.md
    │   └── testing.md
    ├── commands/
    │   ├── validate-policy.md
    │   ├── run-tests.md
    │   └── check-hitl.md
    ├── skills/
    │   └── skill-scorer.md
    ├── agents/
    │   ├── security-reviewer.md
    │   └── policy-validator.md
    └── hooks/
        ├── pre-tool-use/
        │   └── secrets-scan.sh
        └── post-tool-use/
            └── run-tests.sh
```

---

## Coding Conventions (MVP)

All conventions from the parent project apply. MVP-specific notes:

### Go (engine, integration bus)
- Standard layout (`cmd/`, `internal/`, `pkg/`)
- Error wrapping: `fmt.Errorf("context: %w", err)`
- Context propagation: all functions accept `context.Context`
- No global mutable state in hot path
- All credentials via Vault — never hardcoded, never logged
- MVP code stays minimal — resist adding v6 features prematurely

### TypeScript (hook agents)
- Strict mode on
- No `any` types in event schema (use generated protobuf types)
- Hook capture must be zero-latency — async queue, never block IDE
- All hook errors caught and logged locally — never crash the IDE

### Protocol Buffers
- All event messages versioned (field numbers stable across MVP → v6)
- New fields always optional, never remove existing field numbers
- MVP uses field numbers 1–12 of HookEvent — fields 13+ reserved for v1.1+
- Generate via `make proto` — never hand-edit generated files

### YAML (policy)
- `policy.yaml` is single source of truth
- All MVP rule classes have ATT&CK mapping
- Integration routing matches severity enum exactly
- New rules require: rule ID, name, severity, ATT&CK mapping, test fixture

### General — MVP Discipline
- **Don't add v6 features speculatively.** If a v1.1 fast-follow capability isn't ready, do not stub it in.
- **Maintain the schema, not the runtime.** It's fine for protobuf field 12 (SkillIdentity) to exist while only depth=0 is enforced — v1.1 will turn on the deeper checks without schema breakage.
- **No silent feature flags.** Every feature flag has a default, a documented owner, and a removal target.

---

## MVP Architecture Key Decisions

| Decision | Rationale |
|----------|-----------|
| HITL Gate (HITL-001) at WARN, not BLOCK | First 30 days of MVP traffic tunes the 5-min threshold. Escalate after baseline. |
| SI-002 (Unknown Skill) at WARN, not BLOCK | Most "unknown" skills will be legitimate internal tools. Operator review path required first. |
| ConnectWise PSA only (no Autotask in MVP) | ~40% of MSP market. Validates PSA adapter pattern before fanning out. |
| Webhook covers SIEM in MVP | Lowest-friction universal alert path. Native SIEM connectors in v1.3. |
| Own SQLite skill registry from day one | No Tego dependency, ever. Independence audit findings non-negotiable. |
| ONNX local inference, no external ML API | Same constraint as v6 — never relaxed in MVP. |
| mTLS hook → engine (no plain TLS option) | No security downgrade path. MVP must be production-grade transport. |
| Vault for tenant credentials (no DB plaintext) | Same as v6. MVP doesn't shortcut secret handling. |
| 8 event types out of 17 | Covers HITL + skill + credential + reverse-shell signals. Other 9 are v1.1+. |
| 3 ML models (not 10) | Trained on real data only. Don't ship undertrained models that produce false positives. |

---

## What's Different From the Parent Project (v6)

This is a sub-project, not a fork. It coexists with the v6 architecture in the parent directory. The parent project is the **target end-state**; this MVP is the **first shippable increment**.

| Aspect | Parent (v6) | This MVP (v1) |
|--------|-------------|---------------|
| Posture | PREVENT → VERIFY → DETECT → BLOCK → INTEGRATE → DISTRIBUTE | DETECT → BLOCK (+ minimal integrate) |
| Threats | 30/30 | 6/30 (highest-priority) |
| Rules | 21 | 7 |
| ML Models | 10 | 3 |
| Event Types | 17 | 8 |
| IDEs | 7 (VS Code, JetBrains, Cursor, Neovim, Emacs, Zed, CLI) | 2 (VS Code, Claude Code CLI) |
| PSAs | 4 | 1 (ConnectWise) |
| SIEMs | 4 native | 0 (webhook only) |
| RMMs | 5 | 0 (manual install) |
| API | REST v1 (read+write+MSSP) | None (internal only) |
| Verdicts | 9 | 4 |

---

## Security Constraints — All Inherited From Parent

These are non-negotiable in MVP. See `rules/security.md`:

1. **No secrets in code, logs, or git history**
2. **All credentials encrypted at rest (Vault)**
3. **mTLS between hook and engine**
4. **TLS 1.3 only for external delivery**
5. **HMAC-SHA256 on all webhooks**
6. **No external API in ML hot path**
7. **Tenant isolation enforced at DB layer**
8. **No PII in transit (developer IDs hashed)**

---

## Current Milestone

**MVP v1.0 target: Q3 2026**
- VS Code extension (TypeScript) — feature-complete
- Claude Code CLI shim (Node.js) — feature-complete
- Detection engine v1 (Go) — 7 rules, 3 ML models, NATS queue
- ConnectWise PSA adapter (Go)
- Webhook Engine (Go)
- Tenant Config Store (Postgres + Vault)
- SOC Dashboard (web app — minimal alert feed + audit search)

**Success criteria for v1.0 → v1.1:**
- 30 days of production traffic from at least 3 design partners
- HITL-001 baseline: false-positive rate < 5% before escalating to BLOCK
- SI-002 baseline: < 10 unknown skills/dev/week before tightening
- Zero CRITICAL escapes (no missed RS-001, CE-001, SI-001:Critical events)

See full roadmap in `MVParchitecture_v1.md` §13.
