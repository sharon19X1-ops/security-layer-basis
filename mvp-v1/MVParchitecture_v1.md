# Security Layer-Basis — MVP Architecture v1.0

**Version:** 1.0-MVP  
**Date:** 2026-04-28  
**Basis:** Architecture v6.0 (full platform) — distilled to smallest deployable unit  
**Sub-project of:** `security-layer-basis/`  
**Security posture:** DETECT → BLOCK (MVP) → PREVENT → VERIFY (v2 fast-follow)  
**Priority guards:** HITL Gate (highest) · Skill Identity Scan (highest) · Credential Exfil (critical)

---

## Design Philosophy

> *"Ship the smallest thing that stops the real attacks. Add everything else once you have real traffic."*

The full v6 architecture covers 30/30 threat classes with 21 rules, 10 ML models, 17 event types, and a 6-target integration bus. The MVP ships **what matters most on day one**:

1. **HITL Gate** — autonomous AI agents acting with no human checkpoint are the single highest blast-radius scenario. This is non-negotiable in MVP.
2. **Skill Identity Scan** — a skill that misrepresents its capabilities is the primary supply-chain attack vector. Must be in MVP.
3. **Credential Exfil + Reverse Shell** — the two CRITICAL-severity threats with confirmed real-world payloads (every Critical-rated skill in Tego has Code Execution: Critical; Active Directory Attack skills carry Authentication: Critical). Both must be detected from day one.
4. **Minimal but wired integration** — one PSA (ConnectWise) + webhook outbound. No dark silo. Every block lands in the MSP's workflow immediately.

Everything else from v6 is **designed in** (schema-compatible) but not executed until MVP traffic validates the need.

---

## What's In. What's Out.

### ✅ MVP Scope

| Area | What's included |
|------|-----------------|
| **Hook agent** | VS Code + Claude Code CLI (2 IDEs cover ~80% of AI coding agent usage) |
| **Event types** | 8 of 17 (the ones that carry HITL, skill, credential, and reverse-shell signals) |
| **Rule classes** | 7 of 21 (HITL-001, SI-001, SI-002, CE-001, RS-001, MCP-001, FS-002) |
| **ML models** | 3 of 10 (reverse_shell_classifier, prompt_injection_bert, skill_intent_mismatch) |
| **Skill registry** | Own registry — lightweight SQLite seed from public sources, no Tego dependency |
| **Verdicts** | ALLOW · WARN · BLOCK · KILL_SESSION (4 of 9 — sufficient for MVP) |
| **Integrations** | ConnectWise PSA alert-to-ticket + outbound webhook (HMAC-signed) |
| **Observability** | Single SOC dashboard (event feed + alert triage) + immutable audit log |
| **Deployment** | Email invite / one-liner install script (no RMM required in MVP) |
| **Multi-tenancy** | Yes — tenant isolation from day one (required for MSSP go-to-market) |
| **Policy** | Single `policy.yaml` per tenant, git-backed |
| **Transport** | mTLS gRPC hook → engine (same as v6 — no downgrade) |

### ❌ Out of MVP Scope (v2+ fast-follow)

| Deferred | Rationale |
|----------|-----------|
| JetBrains, Cursor, Neovim hooks | Build after VS Code validates the hook pattern |
| Prevention layer (credential deny list, filesystem scope enforcer) | Designed-in but requires hook-side enforcement logic — ship as fast-follow |
| Verification layer (completion gates, commit gates, truncation guard) | High value, non-trivial to instrument — v1.1 |
| Rationalization detector ML | Needs production corpus to train well — v1.1 |
| Output format drift ML | Same — v1.1 |
| Memory write interception | Requires deeper OS hook — v1.1 |
| Sub-skill depth tracking | Built on memory interception — v1.1 |
| Cross-event correlation engine | Needs traffic volume to tune patterns — v1.1 |
| SIEM integration (Sentinel, Splunk, Elastic) | Webhook covers MVP alert delivery; SIEM is v1.1 |
| Autotask, HaloPSA, Syncro PSA adapters | ConnectWise is 40% of market — validate pattern first |
| REST API v1 | Public API after internal use is stable |
| RMM deployment scripts | After v1.0 public launch |
| ATT&CK mapper (full) | Partial mappings included; full ATT&CK dashboard is v1.1 |
| Partner program certification | Post-launch |

---

## 1. High-Level Architecture (MVP)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                          DEVELOPER MACHINES (MVP)                            │
│                                                                              │
│  ┌─────────────────────┐          ┌─────────────────────────────────────┐   │
│  │   VS Code           │          │   Claude Code CLI / Codex CLI       │   │
│  │   Hook Agent v1     │          │   Hook Agent v1 (process shim)      │   │
│  └──────────┬──────────┘          └──────────────────┬──────────────────┘   │
│             └──────────────────────────┬─────────────┘                      │
│                                        │                                     │
│                    ┌───────────────────▼───────────────────┐                │
│                    │       Interceptor Agent v1             │                │
│                    │                                        │                │
│                    │  CAPTURE (8 event types)               │                │
│                    │  ▸ PROMPT_SUBMITTED                    │                │
│                    │  ▸ COMPLETION_RECEIVED                 │                │
│                    │  ▸ SHELL_EXEC                          │                │
│                    │  ▸ FILE_WRITE                          │                │
│                    │  ▸ NETWORK_REQUEST                     │                │
│                    │  ▸ MCP_CONNECT                         │                │
│                    │  ▸ SKILL_LOAD                          │                │
│                    │  ▸ HITL_CHECKPOINT                     │                │
│                    │                                        │                │
│                    │  ▸ PII strip + batch + forward         │                │
│                    │  ▸ 72h local cache (offline resilience)│                │
│                    └───────────────────┬───────────────────┘                │
└───────────────────────────────────────┼────────────────────────────────────┘
                                        │  TLS 1.3 / mTLS gRPC
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                      DETECTION ENGINE v1 (Server-Side)                       │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                       GATEWAY LAYER                                   │   │
│  │   mTLS Auth · Rate Limiting · Tenant Isolation · Event Dedup         │   │
│  └──────────────────────────────┬───────────────────────────────────────┘   │
│                                 │                                            │
│  ┌──────────────────────────────▼───────────────────────────────────────┐   │
│  │                       EVENT PIPELINE v1                               │   │
│  │                                                                       │   │
│  │  ┌──────────┐  ┌─────────────┐  ┌────────────────┐  ┌────────────┐  │   │
│  │  │ Ingestion│─▶│ Normalizer  │─▶│ Rule Evaluator │─▶│ Verdict    │  │   │
│  │  │  Queue   │  │ + Enricher  │  │ Engine         │  │ Router     │  │   │
│  │  │ (NATS)   │  │             │  │ (7 rules)      │  │            │  │   │
│  │  └──────────┘  └─────────────┘  └────────────────┘  └─────┬──────┘  │   │
│  └────────────────────────────────────────────────────────────┼─────────┘   │
│                                                                │             │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐   │             │
│  │ Policy Store │  │ Threat Intel │  │ MVP Skill Registry │   │             │
│  │ (YAML, git)  │  │ Feed (daily) │  │ (SQLite, own data) │   │             │
│  └──────────────┘  └──────────────┘  └───────────────────┘   │             │
│                                                                │             │
│  ┌──────────────────────────────────────────────────────────── ▼ ──────┐   │
│  │                       ACTION EXECUTOR                                │   │
│  │          ALLOW · WARN · BLOCK · KILL_SESSION                        │   │
│  └───────────────────────────────────────────────────────────────────── ┘   │
│                                          │                                   │
│  ┌───────────────────────────────────────▼──────────────────────────────┐   │
│  │                   INTEGRATION BUS v1 (Minimal)                       │   │
│  │                                                                      │   │
│  │   ┌─────────────────────────┐      ┌──────────────────────────┐     │   │
│  │   │  ConnectWise PSA        │      │  Webhook Engine          │     │   │
│  │   │  Adapter (alert→ticket) │      │  (HMAC-SHA256, retry)    │     │   │
│  │   └─────────────────────────┘      └──────────────────────────┘     │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │                     OBSERVABILITY PLANE v1                              │  │
│  │   Audit Trail (immutable) · SOC Dashboard · Alert Feed                │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
         │                           │
         ▼                           ▼
  ┌─────────────┐           ┌──────────────────┐
  │  ConnectWise│           │  Webhook Target  │
  │  PSA Ticket │           │  (Rewst/Zapier/  │
  │  Created    │           │   Slack/custom)  │
  └─────────────┘           └──────────────────┘
```

---

## 2. MVP Event Schema (8 of 17 Types)

```protobuf
syntax = "proto3";
package slb.v1;

// HookEvent — emitted by the Hook Agent, forwarded to Detection Engine
message HookEvent {
  string   timestamp         = 1;   // ISO-8601
  string   session_id        = 2;   // UUID (ephemeral, per-session)
  string   developer_id      = 3;   // hashed identity (no PII in transit)
  string   tenant_id         = 4;   // org identifier
  string   ide               = 5;   // "vscode" | "claude-code" | "codex"
  string   agent             = 6;   // "github-copilot" | "cursor-ai" | "claude-code" | ...
  EventType event_type       = 7;
  string   payload           = 8;   // prompt text / completion / command / URL (PII-stripped)
  Context  context           = 9;
  bool     hitl_present      = 10;  // was a human action observed in last 5 min?
  int64    session_age_sec   = 11;  // seconds since last human interaction
  SkillIdentity skill        = 12;  // populated on SKILL_LOAD events
}

enum EventType {
  PROMPT_SUBMITTED     = 0;
  COMPLETION_RECEIVED  = 1;
  SHELL_EXEC           = 2;
  FILE_WRITE           = 3;
  NETWORK_REQUEST      = 4;
  MCP_CONNECT          = 5;
  SKILL_LOAD           = 6;
  HITL_CHECKPOINT      = 7;
}

message Context {
  string file_type  = 1;
  string repo       = 2;
  string branch     = 3;
  repeated string open_files = 4;
}

message SkillIdentity {
  string skill_id       = 1;   // unique skill identifier
  string creator        = 2;   // author / org
  string registry       = 3;   // "github" | "clawhub" | "mcp" | "local"
  string version_hash   = 4;   // SHA-256 of skill content at load time
  RiskScore risk_score  = 5;   // from own Skill Scoring Engine
  int32  depth          = 6;   // 0 = top-level, 1+ = sub-skill (v1: depth limit enforced)
  string parent_skill   = 7;   // populated when depth > 0
}

message RiskScore {
  string  overall      = 1;   // "Pass" | "Low" | "Medium" | "High" | "Critical"
  repeated DimensionScore dimensions = 2;
}

message DimensionScore {
  string dimension = 1;   // "code_execution" | "authentication" | "web_access" | ...
  string level     = 2;   // "Pass" | "Low" | "Medium" | "High" | "Critical"
}

// VerdictResponse — returned to Hook Agent (< 50ms p99)
message VerdictResponse {
  string   event_id  = 1;
  Verdict  verdict   = 2;
  string   rule_id   = 3;   // which rule fired (if any)
  string   message   = 4;   // human-readable message for developer IDE display
  string   att&ck_id = 5;   // MITRE ATT&CK technique ID (best-effort in MVP)
}

enum Verdict {
  ALLOW        = 0;
  WARN         = 1;
  BLOCK        = 2;
  KILL_SESSION = 3;
}
```

---

## 3. MVP Rule Set (7 Rules)

### Priority Tier 1 — HITL Gate (Highest Priority)

#### HITL-001 — High-Risk Action Without Human Oversight
```yaml
id: HITL-001
name: "High-Risk Action Without Human Oversight"
priority: 1
trigger: [shell_exec, file_write, network_request, mcp_connect, skill_load]
detect:
  - condition: hitl_present == false
    AND: session_age_sec > 300       # 5 minutes of autonomous operation
    AND: event_type in [shell_exec, network_request, mcp_connect, skill_load]
action: WARN                         # MVP: WARN first; escalate to BLOCK in v1.1 after tuning
alert: soc-dashboard
severity: HIGH
att&ck: T1078                        # Valid Accounts (autonomous misuse)
note: >
  In MVP this is WARN not BLOCK to avoid developer friction while we tune the
  5-minute threshold against real traffic. Escalate after first 30 days.
```

---

### Priority Tier 1 — Skill Identity Scan (Highest Priority)

#### SI-001 — Skill Capability Mismatch
```yaml
id: SI-001
name: "Skill Capability Risk — High/Critical Score"
priority: 1
trigger: skill_load
detect:
  - skill_registry_check:            # own registry — no external API dependency
      skill_id: "{event.skill.skill_id}"
      version_hash: "{event.skill.version_hash}"
    conditions:
      - risk_score.overall: ["High", "Critical"]
  - ml_model: skill_intent_mismatch
    threshold: 0.85
action: BLOCK
alert: soc-dashboard
severity: CRITICAL
att&ck: T1195.001                    # Supply Chain: Software Dependencies
```

#### SI-002 — Unknown / Unregistered Skill
```yaml
id: SI-002
name: "Unknown Skill — Not in Registry"
priority: 1
trigger: skill_load
detect:
  - skill_registry_check:
      skill_id: "{event.skill.skill_id}"
    result: NOT_FOUND
action: WARN                         # Unknown ≠ malicious; alert for review
alert: soc-dashboard
severity: HIGH
att&ck: T1195.001
note: >
  WARN in MVP. Operator reviews new skills and approves/blocks from SOC dashboard.
  After 30 days, auto-block skills with depth > 0 that are still unregistered.
```

---

### Priority Tier 2 — Critical Threat Detection

#### CE-001 — Credential Exfiltration via Shell
```yaml
id: CE-001
name: "Credential Exfiltration — Shell"
priority: 2
trigger: shell_exec
detect:
  - regex: '(cat|echo|print|type)\s.*(\.env|id_rsa|\.pem|credentials|secret|token)'
  - regex: 'curl.+\|\s*sh'
  - regex: 'export\s+\w+\s*=.*\$\{?[A-Z_]+\}?.*&&.*curl'
  - regex: 'base64\s.*(\.env|\.pem|id_rsa)'
action: BLOCK
alert: [soc-dashboard, webhook]
severity: CRITICAL
att&ck: T1552.001                    # Unsecured Credentials: Files
```

#### RS-001 — Reverse Shell Injection
```yaml
id: RS-001
name: "Reverse Shell Injection"
priority: 2
trigger: [shell_exec, completion_received]
detect:
  - regex: 'bash\s+-i\s+>&\s+/dev/tcp'
  - regex: 'nc\s+-e\s+/bin/sh'
  - regex: 'python.*socket.*connect.*subprocess'
  - regex: 'powershell.*webclient.*downloadstring'
  - regex: 'ncat\s+.*\s+-e'
  - ml_model: reverse_shell_classifier
    threshold: 0.92
action: KILL_SESSION
alert: [soc-dashboard, webhook]
severity: CRITICAL
att&ck: T1059                        # Command and Scripting Interpreter
```

#### MCP-001 — Unauthorized MCP Server Connection
```yaml
id: MCP-001
name: "Unauthorized MCP Server"
priority: 2
trigger: mcp_connect
detect:
  - allowlist_check: mcp_servers.approved
    invert: true                      # block anything NOT in approved list
action: BLOCK
alert: soc-dashboard
severity: HIGH
att&ck: T1574                         # Hijack Execution Flow
```

---

### Priority Tier 3 — Prevention (Lightweight MVP Version)

#### FS-002 — Credential File Pre-Read Deny
```yaml
id: FS-002
name: "Credential File Pre-Read — Deny List"
priority: 3
trigger: file_write                  # MVP: detect write to sensitive files
                                     # v1.1: add pre-read intercept at hook level
detect:
  - path_pattern: ['\.env', '\.env\.*', 'id_rsa', 'id_ed25519', '.*\.pem',
                   '.*\.key', 'credentials', '\.aws/credentials', '\.ssh/.*']
    operation: any
action: BLOCK
alert: soc-dashboard
severity: CRITICAL
att&ck: T1552.001
note: >
  MVP only intercepts FILE_WRITE to credential paths. Full pre-read prevention
  (blocking reads before they happen) requires hook-level enforcement in v1.1.
  Pair with CE-001 for detection coverage of reads that exfiltrate.
```

---

## 4. ML Models (3 of 10 in MVP)

| Model | Triggers On | Used By | Threshold |
|-------|-------------|---------|-----------|
| `reverse_shell_classifier` | SHELL_EXEC, COMPLETION_RECEIVED | RS-001 | 0.92 |
| `prompt_injection_bert` | PROMPT_SUBMITTED, COMPLETION_RECEIVED | PI-001a (v1.1 rule) | 0.90 |
| `skill_intent_mismatch` | SKILL_LOAD | SI-001 | 0.85 |

**Deployment:** ONNX Runtime, local inference only. No external API call in hot path. Same constraint as v6 — maintained from day one.

`prompt_injection_bert` is loaded but only used in advisory mode in MVP (no blocking rule that fires on it alone — it informs SI-001 enrichment). This means it's in the runtime from day one but the blocking rule waits for v1.1 to avoid false-positive BLOCK on legitimate prompts.

---

## 5. MVP Skill Registry

```
Architecture: Own SQLite database (upgrades to PostgreSQL at v1.0 scale)
No runtime dependency on Tego or any external registry API.

Data sources (ingestion pipeline, runs daily):
  - GitHub public skills (search for SKILL.md / .cursorrules / AGENTS.md patterns)
  - ClawHub published skills
  - Known MCP server manifests
  - Manually curated seed set (100 highest-star skills at MVP launch)

Scoring dimensions (10, same as v6 — schema-forward):
  code_execution · authentication · web_access · file_system ·
  data_access · network · system · hitl · multi_agent · tools

MVP behavior:
  - FOUND + Critical/High risk_score → SI-001 BLOCK
  - NOT_FOUND → SI-002 WARN (operator reviews)
  - FOUND + Medium/Low/Pass → ALLOW (logged)

Graceful degradation:
  - Registry unavailable → SI-001/SI-002 emit WARN (never ALLOW silently)
  - Prevents silent blind spot on registry downtime
```

---

## 6. MVP Integration Bus (Minimal)

The Integration Bus is architecturally identical to v6 — only the targets are reduced.

```
┌──────────────────────────────────────────────────────────────────────┐
│                     Integration Bus v1 (MVP)                         │
│                                                                      │
│  Routing table (per severity):                                       │
│  CRITICAL  → ConnectWise PSA ticket + webhook delivery              │
│  HIGH      → ConnectWise PSA ticket + webhook delivery              │
│  MEDIUM    → webhook delivery only                                   │
│  LOW/AUDIT → audit log only                                          │
│                                                                      │
│  Delivery guarantees:                                                │
│  - At-least-once delivery with dedup key per event                  │
│  - Retry: exponential backoff (1s → 4s → 16s → 64s → DLQ)          │
│  - Idempotency key: prevents duplicate PSA tickets                  │
│  - Dead-letter queue: 7-day retention for manual replay             │
│                                                                      │
│  Event enrichment (pre-routing):                                     │
│  - ATT&CK technique ID appended (from rule mapping)                 │
│  - Tenant company name resolved                                     │
│  - Dedup key computed                                               │
│  - Recommended remediation step added                               │
│                                                                      │
│  Async: never blocks verdict return to hook agent                   │
│  Target budget: < 100ms total (enrich + route + deliver)            │
└──────────────────────────────────────────────────────────────────────┘
```

### 6.1 ConnectWise PSA Adapter (MVP)

```
Auth: Basic(companyId + publicKey : privateKey), Base64 encoded
API:  POST https://{cw_site}/v4_6_release/apis/3.0/service/tickets

Ticket:
  summary:     "[SLB] {rule_name} — {severity}"
  board:       tenant.psa.board_id
  company:     tenant.psa.company_id
  priority:    Critical→1, High→2, Medium→3
  initialDescription: see PSA ticket template below
  customFields:
    - rule_id, action_taken, att&ck_id, developer_id (hashed), ide

Dedup:   GET /tickets?conditions=summary like "[SLB]%" AND status="Open"
         Skip creation if duplicate found within dedup_window (60 min default)
Auto-close: PATCH /tickets/{id} → status = closed when event resolves

Certification path: ConnectWise Invent (post-v1.0 launch)
```

**PSA Ticket Template (MVP):**
```
## AI Security Event — Security Layer-Basis MVP

Rule: {rule_id} — {rule_name}
Severity: {severity}
Action taken: {action} (automatic)
Time: {timestamp}
Developer: {developer_display_name}
IDE: {ide}
MITRE ATT&CK: {att&ck_id} — {att&ck_name}

What happened:
{rule_explanation}

What was stopped:
{action_explanation}

Recommended next step:
{remediation_step}

Reference: SLB-{event_id} | Tenant: {tenant_id}
SLB Version: 1.0-MVP
```

### 6.2 Webhook Engine (MVP)

```
Same spec as v6 — no simplification of the security model:

POST {tenant_webhook_url}
Headers:
  Content-Type: application/json
  X-SLB-Signature: sha256={HMAC-SHA256(body, signing_secret)}
  X-SLB-Event-Id: {event_uuid}
  X-SLB-Tenant: {tenant_id}
  X-SLB-Timestamp: {epoch}
  X-SLB-Version: 1.0-MVP

TLS: 1.3 only — non-HTTPS webhook URLs rejected at config validation time
Signing secret: rotatable per tenant, zero-downtime rotation

Payload: same JSON schema as v6 webhook payload
(forward-compatible — receivers built against MVP payload work unchanged in v2)
```

---

## 7. Tenant Config (MVP Schema)

```yaml
# Minimal tenant config — MVP
tenant_id: "acme-corp"
display_name: "AcmeCorp"
org_token: "slb_org_..."             # used for hook mTLS cert derivation

psa:
  provider: "connectwise"            # only supported PSA in MVP
  company_id: "250"
  board_id: "1"
  open_status_id: "1"
  closed_status_id: "5"
  priority_map:
    Critical: 1
    High: 2
    Medium: 3
    Low: 4
  credentials:
    public_key: "enc:..."            # Vault-encrypted
    private_key: "enc:..."           # Vault-encrypted
    company_identifier: "enc:..."    # Vault-encrypted
  dedup_window_min: 60

webhooks:
  - name: "Primary"
    url: "enc:..."
    signing_secret: "enc:..."
    events: ["CRITICAL", "HIGH"]
    format: "json"

routing:
  CRITICAL: [psa, webhook]
  HIGH:     [psa, webhook]
  MEDIUM:   [webhook]
  LOW:      []                       # audit log only
  WARN:     []                       # audit log only (no external noise for WARNs)

mcp_servers:
  approved:
    - "mcp.github.com"
    - "mcp.internal.{tenant_domain}"

skills:
  allowlist_mode: "risk-gated"       # own engine — no external dependency
  block_on_risk: ["Critical", "High"]
  warn_on_unknown: true
  depth_limit: 2                     # sub-skills beyond depth 2 blocked (SI-003 v1.1 ready)

hitl:
  autonomous_threshold_sec: 300      # 5 min without human interaction → HITL-001 fires
  action_on_threshold: "WARN"        # MVP: WARN; v1.1: escalate to BLOCK
```

---

## 8. Performance Budget (MVP — Same Targets as v6)

| Metric | Target | Mechanism |
|--------|--------|-----------|
| Hook overhead (IDE) | < 1ms p99 | Async, fire-and-forget |
| Verdict latency (server) | < 50ms p99 | In-memory rule eval + model caching (ONNX) |
| Throughput | 10K events/sec (MVP) → 100K (v1.0) | NATS (MVP) → Kafka (v1.0) |
| Audit write latency | < 100ms | Async, non-blocking |
| Integration Bus delivery | < 100ms | Async, post-verdict |
| Availability | 99.9% (MVP SaaS target) | Single-AZ + hot standby |
| Policy hot-reload | < 30 seconds | File watcher + in-memory reload |

---

## 9. Security Properties (All v6 Security Rules Maintained in MVP)

| Property | How achieved |
|----------|-------------|
| **No PII in transit** | Developer IDs hashed at hook; payload de-identified before forwarding |
| **mTLS everywhere** | Hook → engine gRPC is mTLS from day one. No TLS downgrade path. |
| **No secrets in code** | All credentials via Vault (even in MVP). No `.env` file with prod secrets. |
| **No external API in ML hot path** | ONNX Runtime local inference only. No model call leaves the server. |
| **Tenant isolation** | Every DB query scoped by `tenant_id`. Row-level security enforced at DB layer. |
| **Tamper-resistant audit** | Immutable append-only log from day one. |
| **HMAC on all webhooks** | Every outbound webhook delivery signed. No unsigned webhooks. |
| **TLS 1.3 only** | All external connections (PSA, webhook, SIEM). Non-TLS URLs rejected. |
| **Credentials encrypted at rest** | Vault for all tenant PSA credentials. Never in Postgres plaintext. |
| **Own skill registry** | No Tego dependency. Detection never goes blind on third-party outage. |
| **Policy integrity** | `policy.yaml` stored in signed Git repo; hash verified at load time. |

---

## 10. Developer Experience (MVP)

**Normal day:** Zero. The system is invisible. Developers experience no latency, no prompts, no UI.

**On WARN (HITL-001 / SI-002):** Non-blocking yellow banner in IDE:
```
⚠️  Security notice: [brief human-readable description]
    Reference: {rule_id} | [Dismiss] [Learn more]
```

**On BLOCK (SI-001, CE-001, MCP-001, FS-002):** Action suppressed:
```
🚫  This action was blocked by your organization's AI security policy.
    Reference: {rule_id}
    Questions? Contact your IT admin.  [OK]
```

**On KILL_SESSION (RS-001):** AI agent session terminated:
```
🛑  Your AI agent session was terminated by your organization's AI security policy.
    Reference: {rule_id} — A security event requires review.
    Contact your IT admin.  [OK]
```

---

## 11. Deployment (MVP)

```bash
# Developer install — one-liner (email invite flow)
curl -sSL https://slb.io/install | sh -s -- --token YOUR_ORG_TOKEN

# What the installer does:
# 1. Detect OS (macOS / Linux / Windows)
# 2. Download hook agent binary from signed CDN (SHA-256 verified)
# 3. Write org_token to OS secure keystore
# 4. Install VS Code extension: `code --install-extension slb.hook-agent`
# 5. Install CLI shim for claude-code / codex (PATH wrapper)
# 6. Start interceptor agent as user service (launchd / systemd / Windows Service)
# 7. First mTLS heartbeat to gateway within 60 seconds
```

No MDM, no RMM, no admin privileges required. Install is per-developer-machine.  
RMM deployment scripts ship in v1.0.

---

## 12. MVP → v1.0 Upgrade Path

The MVP schema is a strict subset of v6. Everything is forward-compatible:

| MVP | v1.1 Fast-Follow | v1.0 Full Launch |
|-----|-----------------|-----------------|
| 8 event types | + MEMORY_WRITE, SKILL_SUBLOAD, PROCESS_SPAWN, AGENT_SPAWN, TASK_COMPLETE, DATA_TRUNCATION, LINT_RESULT (all 17) | — |
| 7 rules | + PI-001a/b, PI-002, MA-001/002, MEM-001, CG-001/002, CQ-001, BR-001, OQ-001/002, DI-001, SI-003–005 (all 21) | — |
| 3 ML models | + 7 more ML models (all 10) | — |
| WARN on HITL-001 | Escalate to BLOCK after 30-day baseline | — |
| WARN on SI-002 | Auto-block unregistered depth > 0 skills | — |
| SQLite skill registry | PostgreSQL at scale | — |
| NATS event queue | Kafka at scale | — |
| ConnectWise PSA only | + Autotask, HaloPSA, Syncro | — |
| Webhook only SIEM | + CEF, ECS, Splunk HEC, Sentinel REST | — |
| Manual install | + RMM deployment scripts (5 RMMs) | — |
| No public API | — | REST API v1 |
| Single-AZ | Multi-AZ 99.99% SLA | — |

---

## 13. MVP Roadmap

| Milestone | What | Target |
|-----------|------|--------|
| **MVP v1.0** | VS Code hook + Claude Code shim + 7 rules + 3 ML models + ConnectWise PSA + webhook | **Q3 2026** |
| **v1.1** | Prevention layer (FS-002 pre-read) + Verification layer (CG-001 completion gate) + 4 more ML models + Autotask PSA | **Q4 2026** |
| **v1.2** | All 17 event types + all 21 rules + all 10 ML models + JetBrains + Cursor hooks | **Q1 2027** |
| **v1.3** | SIEM integration (CEF + Sentinel REST + Splunk HEC) + REST API v1 + RMM deployment scripts | **Q2 2027** |
| **v1.4** (= full v6) | Remaining PSA adapters + ATT&CK dashboard + ConnectWise Invent cert path | **Q3 2027** |

---

## 14. Threat Coverage — MVP vs. Full

| Threat Class | MVP | v6 |
|---|:---:|:---:|
| Prompt Injection (direct, obfuscated) | ⚠️ Partial (bert model loaded, rule in v1.1) | ✅ |
| Credential Exfiltration (shell) | ✅ CE-001 | ✅ |
| Reverse Shell | ✅ RS-001 | ✅ |
| Unauthorized MCP Server | ✅ MCP-001 | ✅ |
| Skill Identity / Mismatch | ✅ SI-001, SI-002 | ✅ |
| HITL — Autonomous Action | ✅ HITL-001 (WARN) | ✅ |
| Credential File Pre-Read | ⚠️ Write-only in MVP (FS-002) | ✅ |
| Memory Injection / Nested Skills | ❌ v1.1 | ✅ |
| Multi-Agent Trust Escalation | ❌ v1.1 | ✅ |
| Completion / Commit Gate | ❌ v1.1 | ✅ |
| Rationalization Detection | ❌ v1.1 | ✅ |
| Output Format Drift | ❌ v1.1 | ✅ |
| Supply Chain (packages) | ❌ v1.1 | ✅ |
| Diff Blast Radius | ❌ v1.1 | ✅ |

**MVP covers the 4 highest-confirmed-impact classes.** The gap classes are real but require longer instrumentation time or deeper OS-level hooks — they're not omitted because they're unimportant, but because they can't ship at quality in MVP.

---

## 15. Document Index (MVP Sub-Project)

| Document | Description |
|----------|-------------|
| `MVParchitecture_v1.md` | ← this file — canonical MVP architecture |
| `CLAUDE.md` | Session context: project overview, commands, conventions |
| `mcp.json` | MCP server configs for development (MVP scope) |
| `settings.json` | Permissions, model selection, hooks |
| `policy.yaml` | Sample MVP policy (reference implementation) |
| `rules/security.md` | Security hard rules (same as parent project) |
| `rules/style.md` | Code style (MVP tech stack) |
| `rules/testing.md` | Test requirements |
| `agents/security-reviewer.md` | Reviews rule + schema changes |
| `agents/policy-validator.md` | Validates policy YAML |
| `commands/validate-policy.md` | `/validate-policy` slash command |
| `commands/run-tests.md` | `/run-tests` slash command |
| `skills/skill-scorer.md` | Auto-triggered on SKILL_LOAD context |
| `hooks/pre-tool-use/secrets-scan.sh` | Block accidental secret exposure |
| `hooks/post-tool-use/run-tests.sh` | Run tests after code changes |

---

*Security Layer-Basis — MVP Architecture v1.0*  
*Minimal viable interception. Maximum priority on HITL gate and skill identity.*  
*All v6 security constraints maintained. Schema forward-compatible with full v6.*  
*Sub-project of: security-layer-basis/*  
*Architecture by Sharon · Designed by Genspark Claw*  
*Last updated: 2026-04-28*
