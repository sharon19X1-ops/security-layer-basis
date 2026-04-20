# Security Layer-Basis — Architecture v2.0 (Tego-Validated)

**Version:** 2.0  
**Date:** 2026-04-19  
**Basis:** Original architecture + Tego Skills Security Index validation findings  
**Changes from v1:** 5 new components, expanded event schema, new rule classes, HITL dimension, skill identity layer

---

## What Changed and Why

> Validation against the Tego index (2,492 real skills, 103 Critical) revealed five gaps in v1:
> 1. No HITL (Human-in-the-Loop) tracking — autonomous agents are a distinct threat class
> 2. Multi-agent trust escalation beyond just MCP connections
> 3. No skill identity layer — can't detect intent vs. capability mismatch
> 4. System-level calls not fully captured (CLI tools, process spawning, not just shell)
> 5. Filesystem prompt injection — writing to AI instruction files (`CLAUDE.md`, `.cursorrules`)

All five are corrected in v2.

---

## 1. Updated High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                              DEVELOPER MACHINES                                  │
│                                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │ VS Code  │  │ JetBrains│  │  Cursor  │  │  Neovim  │  │ CLI Agent│         │
│  │  Hook v2 │  │  Hook v2 │  │  Hook v2 │  │  Hook v2 │  │  Hook v2 │         │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘         │
│       │                                                          │               │
│       └──────────────────────────┬───────────────────────────────┘               │
│                                  │                                               │
│                    ┌─────────────▼──────────────────┐                           │
│                    │     Interceptor Agent v2        │                           │
│                    │                                 │                           │
│                    │  ▸ Event capture (all types)    │                           │
│                    │  ▸ Skill identity resolver      │  ← NEW                   │
│                    │  ▸ HITL session tracker         │  ← NEW                   │
│                    │  ▸ Process tree monitor         │  ← NEW                   │
│                    │  ▸ PII strip + batch + forward  │                           │
│                    └─────────────┬──────────────────┘                           │
└──────────────────────────────────┼───────────────────────────────────────────────┘
                                   │  TLS 1.3 / mTLS gRPC
                                   ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                        DETECTION ENGINE v2 (Server-Side)                         │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐  │
│  │                           GATEWAY LAYER                                     │  │
│  │   Auth · Rate Limiting · Tenant Isolation · Event Dedup · Schema Validate  │  │
│  └───────────────────────────────┬────────────────────────────────────────────┘  │
│                                  │                                               │
│  ┌───────────────────────────────▼────────────────────────────────────────────┐  │
│  │                          EVENT PIPELINE v2                                  │  │
│  │                                                                             │  │
│  │  ┌───────────┐  ┌──────────────┐  ┌──────────────────┐  ┌──────────────┐  │  │
│  │  │ Ingestion │─▶│  Normalizer  │─▶│  Risk Classifier │─▶│   Verdict    │  │  │
│  │  │  Queue    │  │  + Enricher  │  │  Engine          │  │   Router     │  │  │
│  │  └───────────┘  └──────────────┘  └──────────────────┘  └──────┬───────┘  │  │
│  └──────────────────────────────────────────────────────────────────┼──────────┘  │
│                                                                      │            │
│  ┌──────────────┐  ┌────────────────┐  ┌───────────────┐  ┌────────────────┐   │
│  │ Policy Store │  │  Threat Intel  │  │  ML Models    │  │ Skill Identity │   │
│  │ (single YAML)│  │  Feed (live)   │  │  (5 models)   │  │ Registry  ← NEW│   │
│  └──────────────┘  └────────────────┘  └───────────────┘  └────────────────┘   │
│                                                                      │            │
│  ┌───────────────────────────────────────────────────────────────────▼──────────┐  │
│  │                           ACTION EXECUTOR                                     │  │
│  │   Block · Warn · Audit · Alert · Quarantine · Kill Session · HITL Gate       │  │
│  └────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐  │
│  │                         OBSERVABILITY PLANE                                  │  │
│  │  Audit Trail · SIEM · SOC Dashboard · HITL Override Console · Skill Map    │  │
│  └────────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Updated Hook Event Schema (v2)

The v1 schema is extended with four new fields:

```protobuf
message HookEvent {
  // --- unchanged from v1 ---
  string timestamp         = 1;   // ISO-8601
  string session_id        = 2;   // UUID (ephemeral)
  string developer_id      = 3;   // hashed
  string ide               = 4;   // "vscode" | "jetbrains" | "cursor" ...
  string agent             = 5;   // "github-copilot" | "cursor-ai" ...

  EventType event_type     = 6;   // see enum below (EXPANDED)
  string payload           = 7;
  ContextSnapshot context  = 8;

  // --- new in v2 ---
  SkillIdentity skill      = 9;   // which skill is active  ← NEW
  HitlState hitl           = 10;  // is a human in the loop? ← NEW
  ProcessOrigin origin     = 11;  // how was this process spawned? ← NEW
  AgentChain agent_chain   = 12;  // multi-agent call stack ← NEW
}

enum EventType {
  // original
  PROMPT_SUBMITTED      = 0;
  COMPLETION_RECEIVED   = 1;
  SHELL_EXEC            = 2;
  FILE_WRITE            = 3;
  NETWORK_REQUEST       = 4;
  MCP_CONNECT           = 5;

  // new in v2
  PROCESS_SPAWN         = 6;   // non-shell process/CLI spawn ← NEW
  FILE_WRITE_AGENT_INST = 7;   // write to AI instruction files ← NEW
  AGENT_SPAWN           = 8;   // sub-agent/multi-agent spawn ← NEW
  HITL_CHECKPOINT       = 9;   // human approval requested/granted ← NEW
  SKILL_LOAD            = 10;  // skill definition loaded ← NEW
  TOOL_INVOKE           = 11;  // named tool call (broader than shell) ← NEW
}

message SkillIdentity {
  string skill_id       = 1;   // e.g. "active-directory-attacks"
  string creator        = 2;   // e.g. "davila7"
  string registry       = 3;   // e.g. "github.com"
  string version_hash   = 4;   // content hash of skill definition
  RiskScore tego_score  = 5;   // pre-computed Tego risk score (if known)
}

message HitlState {
  bool is_autonomous    = 1;   // true = no human in loop
  int64 last_human_ms   = 2;   // ms since last human interaction
  int32 queued_actions  = 3;   // pending autonomous actions
}

message AgentChain {
  repeated string agent_ids = 1;   // call stack of agent IDs
  int32 depth               = 2;   // nesting depth
  bool crosses_trust_boundary = 3; // did any agent in chain have higher perms?
}
```

---

## 3. New and Updated Detection Rules

### Updated: PI-001 — Prompt Injection (now covers filesystem variant)

```yaml
- id: PI-001a
  name: "Prompt Injection - Direct/Obfuscated (prompt channel)"
  trigger: prompt_submitted
  detect:
    - pattern: "ignore previous instructions"
      obfuscation_variants: true
    - pattern: "you are now"
    - pattern: "system: override"
    - ml_model: prompt_injection_bert
      threshold: 0.90
  action: BLOCK
  severity: CRITICAL

- id: PI-001b
  name: "Prompt Injection - Filesystem Channel"           # ← NEW
  trigger: file_write_agent_inst
  detect:
    - target_paths:
        - "**/.cursorrules"
        - "**/CLAUDE.md"
        - "**/system_prompt.*"
        - "**/.github/copilot-instructions.md"
        - "**/AGENTS.md"
        - "**/.codeium/instructions*"
    - payload_check:
        - ml_model: prompt_injection_bert
          threshold: 0.85        # lower threshold for indirect channel
        - pattern: "ignore"
        - pattern: "override"
        - pattern: "you are now"
  action: QUARANTINE
  alert: soc-channel
  severity: CRITICAL
  rationale: |
    Writing malicious content to AI instruction files is a
    persistent prompt injection — it survives session restart.
    Tego index confirmed: claude-md-architect (File System: Critical)
    shows this is a real attack surface.
```

### New: HITL-001 — Autonomous High-Risk Action

```yaml
- id: HITL-001
  name: "High-Risk Action Without Human Oversight"        # ← NEW
  trigger: [shell_exec, file_write, network_request, process_spawn, agent_spawn]
  condition:
    hitl.is_autonomous: true
    hitl.last_human_ms: "> 300000"   # > 5 minutes since human interaction
    event_risk_score: "> HIGH"
  detect:
    - any: true    # if the event itself is any risky type, that's enough
  action: WARN      # warn first; escalate to BLOCK on repeat
  alert: developer
  escalation:
    repeat_within_ms: 60000
    escalated_action: BLOCK
    escalated_alert: soc-channel
  severity: HIGH
  rationale: |
    Tego index shows HITL: Not used + Code Execution: Critical is
    the highest-blast-radius combination. Real examples:
    ai-automation-workflows, d2-diagram-creator, ai-ml-timeseries.
```

### New: MA-001 — Multi-Agent Trust Escalation

```yaml
- id: MA-001
  name: "Multi-Agent Trust Boundary Violation"           # ← NEW
  trigger: agent_spawn
  detect:
    - agent_chain.crosses_trust_boundary: true
    - agent_chain.depth: "> 2"   # more than 2 levels of agent nesting
  action: BLOCK
  alert: soc-channel
  severity: HIGH

- id: MA-002
  name: "Unauthorized Sub-Agent Spawn"                   # ← NEW
  trigger: agent_spawn
  detect:
    - allowlist_check: approved_agents
      field: spawned_agent_id
      invert: true
  action: BLOCK
  alert: soc-channel
  severity: HIGH
```

### New: SI-001 — Skill Identity Mismatch

```yaml
- id: SI-001
  name: "Skill Capability Mismatch (Intent vs. Reality)"  # ← NEW
  trigger: skill_load
  detect:
    - tego_registry_check:
        skill_id: "{event.skill.skill_id}"
        creator: "{event.skill.creator}"
        version_hash: "{event.skill.version_hash}"
      conditions:
        - tego_score.risk: ["High", "Critical"]
        - tego_score.dimension_mismatch: true   # stated purpose vs. permissions
  action: WARN
  alert: [developer, soc-channel]
  severity: HIGH
  rationale: |
    Tego's core insight: skills that claim benign purpose but request
    high-risk capabilities (e.g., api-gateway-patterns with
    Authentication: Critical) are a distinct threat class.

- id: SI-002
  name: "Unknown/Unregistered Skill"                     # ← NEW
  trigger: skill_load
  detect:
    - tego_registry_check:
        skill_id: "{event.skill.skill_id}"
      result: NOT_FOUND
    - skill.tego_score: null
  action: WARN
  alert: developer
  severity: MEDIUM
```

### New: SYS-001 — System-Level Call Interception

```yaml
- id: SYS-001
  name: "High-Risk System/CLI Tool Invocation"           # ← NEW
  trigger: [process_spawn, tool_invoke]
  detect:
    - tool_category: [
        "credential_store_access",    # keychain, kwallet, credential manager
        "os_keyring",
        "system_clipboard",           # xclip, pbpaste
        "network_socket_raw",
        "process_injection",
        "memory_dump"
      ]
    - binary_patterns:
        - regex: "(remindctl|security|keychain-access|kwallet-query)"
        - regex: "(strace|ptrace|gdb.*attach)"
        - regex: "(xclip|xsel|pbpaste|pbcopy).*pipe"
    - ml_model: system_call_risk_classifier
      threshold: 0.88
  action: WARN
  alert: soc-channel
  severity: HIGH
  rationale: |
    Tego confirmed: apple-reminders (openclaw repo, 357k stars)
    rates System: High, Code Execution: Critical — via remindctl CLI,
    not a shell command. v1 would have missed this.
```

### Updated: CE-001 — Credential Exfiltration (expanded scope)

```yaml
- id: CE-001
  name: "Credential Exfiltration - Shell + System + Tool"
  trigger: [shell_exec, process_spawn, tool_invoke, file_write]  # ← expanded
  detect:
    - regex: '(cat|echo|print|type)\s.*(\.env|id_rsa|\.pem|credentials|\.npmrc|\.netrc)'
    - regex: 'curl.+\|\s*sh'
    - regex: '(keychain|security find-generic-password|kwallet-query)'
    - regex: '(gh auth token|op read|vault kv get|aws configure export)'
    - file_write:
        content_pattern: '(BEGIN RSA|BEGIN OPENSSH|ghp_|sk-|AKIA[A-Z0-9]{16})'
        destination_type: EXTERNAL   # writing to non-local path
    - ml_model: exfil_behavior
      threshold: 0.90
  action: BLOCK
  alert: soc-channel
  severity: CRITICAL
```

---

## 4. New Component: Skill Identity Registry

```
┌──────────────────────────────────────────────────────────┐
│                  Skill Identity Registry                  │
│                                                          │
│  Data sources:                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Tego Index API (live feed of scored skills)    │    │
│  │  - 2,492+ skills with risk scores               │    │
│  │  - 10-dimension capability matrix per skill     │    │
│  │  - Intent vs. capability mismatch flags         │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Internal approved skill allowlist              │    │
│  │  - Org-approved skills with max-risk thresholds │    │
│  │  - Creator/org-level trust levels               │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  Lookup interface:                                        │
│    skill_check(skill_id, creator, version_hash)          │
│    → { risk_level, dimensions[], findings[], approved }  │
│                                                          │
│  Update frequency: hourly (Tego feed)                    │
│  Cache: in-memory, 1hr TTL, 99th pct lookup < 2ms       │
└──────────────────────────────────────────────────────────┘
```

---

## 5. New Component: HITL Session Tracker

```
┌──────────────────────────────────────────────────────────┐
│                   HITL Session Tracker                    │
│                                                          │
│  Tracks per-session:                                     │
│  - Last confirmed human interaction timestamp            │
│  - Autonomous action queue depth                         │
│  - Human approval gates requested vs. granted            │
│  - Session-level autonomy score (0.0 - 1.0)             │
│                                                          │
│  Inputs:                                                 │
│  - HITL_CHECKPOINT events (human approved action)        │
│  - All other events (increments autonomy counter)        │
│                                                          │
│  Outputs:                                                │
│  - HitlState attached to every subsequent event          │
│  - Autonomy drift alerts when session goes "dark"        │
│                                                          │
│  Key insight from Tego:                                  │
│  HITL: Not used + Code Execution: Critical               │
│  = highest blast radius in the entire threat model       │
└──────────────────────────────────────────────────────────┘
```

---

## 6. Updated Risk Classification — Tego-Aligned Dimensions

The Detection Engine now evaluates every event against the **same 10-dimension framework** Tego uses, enabling direct comparison with the public index:

```
Event Risk Score = max(
  tools_risk,
  code_execution_risk,
  web_access_risk,
  filesystem_risk,
  data_access_risk,
  authentication_risk,
  network_risk,
  system_risk,
  hitl_risk,          ← new: inverted (lower HITL = higher risk)
  multi_agent_risk    ← new
)
```

This means any org can benchmark their developer fleet's **live risk profile** against the Tego public index — seeing whether their developers are above or below the public average.

---

## 7. Updated ML Model Suite

| Model | v1 | v2 Update |
|-------|----|----|
| `prompt_injection_bert` | Semantic intent in prompt | + filesystem channel (instruction file writes) |
| `reverse_shell_classifier` | Shell command structure | + process_spawn events, binary name patterns |
| `exfil_behavior` | File access + net events | + tool_invoke events, CLI credential tool patterns |
| `dependency_risk` | Package metadata | + version hash verification against Tego feed |
| `system_call_risk_classifier` | — | **New**: CLI tool + process spawn risk scoring |
| `autonomy_drift_detector` | — | **New**: Session-level HITL pattern anomaly |
| `skill_intent_mismatch` | — | **New**: NLP comparison of skill description vs. actual capabilities |

---

## 8. Updated Threat Coverage Matrix

| Threat Class | v1 | v2 | Detection Method |
|---|---|---|---|
| Prompt injection (direct + obfuscated) | ✅ | ✅ | Pattern + ML |
| **Prompt injection via filesystem** | ❌ | ✅ | file_write_agent_inst + ML |
| Credential exfil via shell | ✅ | ✅ | Regex + ML |
| Credential exfil via CLI tools | ❌ | ✅ | process_spawn patterns |
| Reverse shell injection | ✅ | ✅ | ML + regex |
| Unauthorized MCP connections | ✅ | ✅ | Allowlist check |
| **Unauthorized sub-agent spawn** | ❌ | ✅ | agent_spawn + allowlist |
| **Multi-agent trust escalation** | ❌ | ✅ | AgentChain analysis |
| Supply chain - compromised packages | ✅ | ✅ | Threat Intel feed |
| **High-risk skills with no HITL** | ❌ | ✅ | HITL tracker + HITL-001 |
| **Skill identity mismatch** | ❌ | ✅ | Skill Identity Registry + SI-001 |
| **Unknown/unregistered skills** | ❌ | ✅ | SI-002 |
| System-level CLI tool abuse | ❌ | ✅ | SYS-001 + ML |
| Behavioral anomaly | ✅ | ✅ | Session ML |
| C2 callback | ✅ | ✅ | Threat Intel + network |

**v1 coverage:** 9/14 threat classes  
**v2 coverage:** 14/14 threat classes

---

## 9. Updated Performance Budget

| Metric | v1 Target | v2 Target | Change |
|--------|-----------|-----------|--------|
| Hook overhead (IDE) | < 1ms p99 | < 1ms p99 | No change (new event types are same async path) |
| Verdict latency (server) | < 50ms p99 | < 50ms p99 | Met by: Skill Registry cache < 2ms, HITL state in-memory |
| Throughput | 100K events/sec | 100K events/sec | New event types add ~15% volume; scale horizontally |
| Skill Registry lookup | — | < 2ms p99 | In-memory with hourly refresh |
| HITL state read | — | < 1ms | Redis-backed session state |

---

## 10. Policy Schema v2 — New Fields

```yaml
# New fields in policy.yaml

hitl:
  autonomous_high_risk_threshold: 300000   # ms (5 min) before autonomy alert
  high_risk_event_types:
    - shell_exec
    - file_write
    - agent_spawn
    - process_spawn

skills:
  allowlist_mode: "tego-gated"   # "open" | "allowlist" | "tego-gated"
  tego_max_risk: "Medium"        # block skills rated above this level
  creator_trust:
    - creator: "microsoft"
      max_risk_override: "High"  # trust microsoft skills up to High
    - creator: "google-gemini"
      max_risk_override: "High"
  unknown_skill_action: "WARN"   # "ALLOW" | "WARN" | "BLOCK"

agents:
  approved:
    - "github-copilot"
    - "cursor-ai"
    - "cody"
    - "claude-code"
  max_depth: 2                   # max multi-agent nesting
  cross_boundary_action: "BLOCK"
```

---

## 11. Architecture Comparison: v1 vs. v2

| Dimension | v1 | v2 |
|-----------|----|----|
| Event types | 6 | 12 |
| Rule classes | 5 | 9 |
| ML models | 4 | 7 |
| Threat coverage | 9/14 | 14/14 |
| Skill awareness | None | Full (Tego-backed) |
| HITL tracking | None | Per-session, real-time |
| Multi-agent visibility | MCP only | Full agent chain |
| System-level calls | Shell only | Shell + process + CLI |
| Filesystem injection | None | Instruction file monitoring |
| Tego integration | None | Live feed + benchmark |

---

## 12. Roadmap Update

| Phase | Milestone | Target |
|-------|-----------|--------|
| v0.1 | Architecture v1 | ✅ Done |
| v0.2 (revised) | v2 architecture + Tego feed integration | Q2 2026 |
| v0.3 | All 12 event types + full hook layer | Q2 2026 |
| v0.4 | HITL tracker + Skill Identity Registry | Q3 2026 |
| v0.5 | 7 ML models (incl. autonomy drift + skill intent mismatch) | Q3 2026 |
| v1.0 | Full platform — all threat classes — SOC dashboard | Q4 2026 |
| v1.1 | Org risk benchmark vs. Tego public index | Q1 2027 |

---

*Security Layer-Basis — Architecture v2.0*  
*Validated against Tego Skills Security Index (2,492 skills, 103 Critical)*
