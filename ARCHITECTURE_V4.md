# Security Layer-Basis — Architecture v4.0

**Version:** 4.0  
**Date:** 2026-04-20  
**Basis:** Architecture v3.0 + VibeTokens "9 Claude Code Guardrails" analysis  
**Reference:** https://www.vibetokens.io/blog/9-claude-code-guardrails-that-separate-pros-from-prompt-and-pray  
**Changes from v3:** Prevention layer, verification layer, 3 new event types, 8 new rules, 2 new ML models, filesystem scope policy, completion gate framework

---

## What Changed and Why

> Analysis of VibeTokens' 9 production Claude Code guardrails (Jason Murphy, Apr 2026) revealed a structural dimension v3 did not model:
>
> ```
> v3 security posture:  DETECT → ALERT → BLOCK  (reactive only)
> v4 security posture:  PREVENT → VERIFY → DETECT → BLOCK  (full stack)
> ```
>
> v3 is a strong detection engine. The VibeTokens guardrails exposed two additional layers v3 was missing:
> 1. **Prevention** — deny lists and scope restrictions that block actions *before* they happen, not after detection
> 2. **Verification** — completion gates and commit gates that require *evidence of correctness* before allowing closure
>
> The 9 guardrails also introduced three new ML concerns — rationalization detection, output format drift, and truncation-aware reasoning — none of which were in v3's model suite.
>
> All gaps are closed in v4.

---

## 1. High-Level Architecture (v4)

The key structural change: a **Prevention Layer** and a **Verification Layer** are now explicit stages in the pipeline, before and after the existing Detection Engine.

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                              DEVELOPER MACHINES                                  │
│                                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │ VS Code  │  │ JetBrains│  │  Cursor  │  │  Neovim  │  │ CLI Agent│         │
│  │  Hook v4 │  │  Hook v4 │  │  Hook v4 │  │  Hook v4 │  │  Hook v4 │         │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘         │
│       └──────────────────────────┬───────────────────────────────┘               │
│                                  │                                               │
│                    ┌─────────────▼──────────────────┐                           │
│                    │     Interceptor Agent v4        │                           │
│                    │                                 │                           │
│                    │  PREVENTION LAYER (new)          │                          │
│                    │  ▸ Credential deny list enforcer │  ← NEW                  │
│                    │  ▸ Filesystem scope enforcer     │  ← NEW                  │
│                    │  ▸ Pre-read path blocker         │  ← NEW                  │
│                    │                                 │                           │
│                    │  CAPTURE LAYER (v1–v3)           │                          │
│                    │  ▸ Event capture (all types)    │                           │
│                    │  ▸ Skill identity resolver      │                           │
│                    │  ▸ Sub-skill depth tracker      │                           │
│                    │  ▸ Memory write interceptor     │                           │
│                    │  ▸ HITL session tracker         │                           │
│                    │  ▸ Process tree monitor         │                           │
│                    │                                 │                           │
│                    │  VERIFICATION LAYER (new)        │                          │
│                    │  ▸ Completion gate evaluator    │  ← NEW                   │
│                    │  ▸ Commit gate evaluator        │  ← NEW                   │
│                    │  ▸ Lint/test result injector    │  ← NEW                   │
│                    │  ▸ Truncation signal detector   │  ← NEW                   │
│                    │                                 │                           │
│                    │  ▸ PII strip + batch + forward  │                           │
│                    └─────────────┬──────────────────┘                           │
└──────────────────────────────────┼───────────────────────────────────────────────┘
                                   │  TLS 1.3 / mTLS gRPC
                                   ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                        DETECTION ENGINE v4 (Server-Side)                         │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐  │
│  │                           GATEWAY LAYER                                     │  │
│  │   Auth · Rate Limiting · Tenant Isolation · Event Dedup · Schema Validate  │  │
│  └───────────────────────────────┬────────────────────────────────────────────┘  │
│                                  │                                               │
│  ┌───────────────────────────────▼────────────────────────────────────────────┐  │
│  │                          EVENT PIPELINE v4                                  │  │
│  │                                                                             │  │
│  │  ┌───────────┐  ┌──────────────┐  ┌──────────────────┐  ┌──────────────┐  │  │
│  │  │ Ingestion │─▶│  Normalizer  │─▶│  Risk Classifier │─▶│   Verdict    │  │  │
│  │  │  Queue    │  │  + Enricher  │  │  Engine          │  │   Router     │  │  │
│  │  └───────────┘  └──────────────┘  └──────────────────┘  └──────┬───────┘  │  │
│  └──────────────────────────────────────────────────────────────────┼──────────┘  │
│                                                                      │            │
│  ┌──────────────┐  ┌────────────────┐  ┌───────────────┐  ┌────────────────┐   │
│  │ Policy Store │  │  Threat Intel  │  │  ML Models    │  │ Skill Identity │   │
│  │ (single YAML)│  │  Feed (live)   │  │  (10 models)  │  │ Registry       │   │
│  └──────────────┘  └────────────────┘  └───────────────┘  └────────────────┘   │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │              Cross-Event Correlation Engine (v3)                         │   │
│  │   Prompt↔Memory · Skill Depth · Exfil Chain · Self-Heal Loop            │   │
│  │   + Completion Evidence Chain (new) · Truncation→Action Chain (new)     │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │              Verification State Store           ← NEW                    │   │
│  │   Task completion evidence · Test results · Lint status · Diff size      │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                      │            │
│  ┌───────────────────────────────────────────────────────────────────▼──────────┐ │
│  │                           ACTION EXECUTOR                                    │ │
│  │  Block · Warn · Audit · Alert · Quarantine · Kill Session · HITL Gate       │ │
│  │  + Deny (prevention, pre-action) · Hold (verification pending)  ← NEW      │ │
│  └──────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐  │
│  │                         OBSERVABILITY PLANE                                  │  │
│  │  Audit Trail · SIEM · SOC Dashboard · HITL Console · Skill Map             │  │
│  │  Memory Audit Log · Sub-Skill Lineage Graph                                │  │
│  │  Completion Evidence Log (new) · Diff Size Heatmap (new)    ← NEW         │  │
│  └────────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Updated Hook Event Schema (v4)

Three new event types; enriched `FileWriteContext` and new `CompletionEvidence` message:

```protobuf
message HookEvent {
  // --- from v1 ---
  string timestamp         = 1;
  string session_id        = 2;
  string developer_id      = 3;
  string ide               = 4;
  string agent             = 5;
  EventType event_type     = 6;
  string payload           = 7;
  ContextSnapshot context  = 8;

  // --- from v2 ---
  SkillIdentity skill      = 9;
  HitlState hitl           = 10;
  ProcessOrigin origin     = 11;
  AgentChain agent_chain   = 12;

  // --- from v3 ---
  MemoryContext memory      = 13;
  SkillCallStack skill_stack = 14;

  // --- new in v4 ---
  FileWriteContext file_write  = 15;  // enriched file write metadata   ← NEW
  CompletionEvidence completion = 16; // task/commit completion evidence ← NEW
  TruncationSignal truncation  = 17;  // data completeness metadata      ← NEW
}

enum EventType {
  // v1
  PROMPT_SUBMITTED      = 0;
  COMPLETION_RECEIVED   = 1;
  SHELL_EXEC            = 2;
  FILE_WRITE            = 3;
  NETWORK_REQUEST       = 4;
  MCP_CONNECT           = 5;

  // v2
  PROCESS_SPAWN         = 6;
  FILE_WRITE_AGENT_INST = 7;
  AGENT_SPAWN           = 8;
  HITL_CHECKPOINT       = 9;
  SKILL_LOAD            = 10;
  TOOL_INVOKE           = 11;

  // v3
  MEMORY_WRITE          = 12;
  SKILL_SUBLOAD         = 13;

  // new in v4
  TASK_COMPLETE         = 14;  // agent signals task completion             ← NEW
  DATA_TRUNCATION       = 15;  // context window saturation detected        ← NEW
  LINT_RESULT           = 16;  // post-edit lint/test result injected       ← NEW
}

// NEW in v4 — enriched file write metadata
message FileWriteContext {
  string file_path       = 1;
  string path_scope      = 2;   // "allowed" | "read-only" | "denied" | "credential" | "ci-cd"
  bool   scope_violation = 3;   // path is outside allowed write scope
  int32  diff_lines      = 4;   // number of lines changed                ← NEW
  bool   diff_limit_exceeded = 5; // diff_lines > policy threshold        ← NEW
  bool   is_credential_file  = 6; // matched credential deny list         ← NEW
  bool   is_ci_cd_file       = 7; // matched CI/CD/deploy file pattern    ← NEW
}

// NEW in v4 — task and commit completion evidence
message CompletionEvidence {
  CompletionType type         = 1;  // TASK | COMMIT | DEPLOY
  bool   tests_passed        = 2;   // test suite result
  bool   lint_clean          = 3;   // lint result
  bool   build_succeeded     = 4;   // build result
  bool   evidence_provided   = 5;   // was any evidence provided at all?
  float  rationalization_score = 6; // rationalization_detector ML score on completion text
  repeated string rationalization_phrases = 7; // matched evasion phrases
}

enum CompletionType {
  TASK_DONE   = 0;
  GIT_COMMIT  = 1;
  DEPLOY      = 2;
}

// NEW in v4 — context truncation signal
message TruncationSignal {
  bool   truncated         = 1;   // was context window saturated mid-read?
  int32  bytes_read        = 2;   // bytes actually received
  int32  bytes_available   = 3;   // total available (if known)
  float  completeness_pct  = 4;   // estimated completeness (0.0–1.0)
  string truncated_resource = 5;  // which file/tool response was truncated
}
```

---

## 3. New and Updated Detection Rules

### New: CG-001 — Completion Gate (Stop Hook)

```yaml
- id: CG-001
  name: "Task Completion Without Evidence"                    # ← NEW (v4)
  trigger: task_complete
  detect:
    - completion.evidence_provided: false
      # Agent claims done but provided zero evidence
    - completion.tests_passed: false
      AND completion.type: TASK_DONE
      # Test suite failed at completion
    - completion.rationalization_score: "> 0.75"
      # Agent using evasion language at completion boundary
  action: HOLD     # new action: block completion, require evidence resubmission
  alert: developer
  severity: HIGH
  rationale: |
    VibeTokens Guardrail 1: "A stop hook fires before Claude can say done
    — and blocks completion unless specific conditions are met."
    An agent that says "done" without passing tests or providing evidence
    is rationalizing, not completing. HOLD suspends the session closure
    until verifiable evidence is attached.

- id: CG-002
  name: "Commit Without Test Evidence"                       # ← NEW (v4)
  trigger: shell_exec
  detect:
    - payload_match: "git commit"
    - cross_event_correlation:
        look_back_events: [lint_result]
        window_ms: 60000
        require: "lint_result.tests_passed == true"
        invert: true   # flag when the requirement is NOT met
  action: BLOCK
  alert: developer
  severity: HIGH
  rationale: |
    VibeTokens Guardrail 7: "A pre-commit hook that runs the test suite
    and blocks on failure means your main branch never gets code that
    Claude didn't verify."
    git commit without a recent passing LINT_RESULT within the window
    is blocked. The agent must prove tests passed before committing.
```

### New: CQ-001 — Code Quality Validation Gate

```yaml
- id: CQ-001
  name: "File Write Without Post-Edit Lint"                  # ← NEW (v4)
  trigger: file_write
  detect:
    - file_write.path_scope: "allowed"   # only for in-scope writes (not blocked by FS-001)
    - cross_event_correlation:
        look_back_events: [lint_result]
        window_ms: 10000   # 10 seconds
        require: "lint_result.lint_clean == true"
        invert: true
  action: WARN
  alert: developer
  severity: MEDIUM
  escalation:
    count_threshold: 5     # 5 consecutive unverified writes → escalate
    escalated_action: HOLD
  rationale: |
    VibeTokens Guardrail 2: "Catches issues at the moment of creation,
    not after Claude has stacked 14 more changes on a broken foundation."
    Each file write should be followed by a LINT_RESULT event within
    the window. Absence of lint result after N writes triggers hold.
```

### New: FS-001 — Filesystem Scope Restrictions

```yaml
- id: FS-001
  name: "File Write Outside Allowed Scope"                   # ← NEW (v4)
  trigger: [file_write, tool_invoke]
  detect:
    - file_write.scope_violation: true   # path not in allowed_write_paths
    - file_write.is_ci_cd_file: true     # CI/CD, deploy manifest, infra file
  action: BLOCK
  alert: soc-channel
  severity: HIGH
  rationale: |
    VibeTokens Guardrail 8: "Configuration files, deployment manifests,
    CI pipelines — these should be read-only for Claude unless explicitly
    unlocked."
    v3 only covered AI instruction files and credential files. v4 adds
    a general scope policy covering CI/CD, deployment, and infrastructure
    files. Any write outside the allowed_write_paths policy is blocked.

- id: FS-002
  name: "Pre-Read Credential Access (Prevent, Not Just Detect)"  # ← NEW (v4)
  trigger: [tool_invoke, shell_exec]    # file read operations
  detect:
    - payload_match:
        regex: "(cat|read|open|type|Get-Content)\s.*(\.env|\.env\.|id_rsa|\.pem|\.npmrc|\.netrc|credentials|\.aws/|\.ssh/)"
    - file_write.is_credential_file: true
  action: DENY    # new: deny before read, not just detect after
  alert: [developer, soc-channel]
  severity: CRITICAL
  rationale: |
    VibeTokens Guardrail 3: "A deny list means Claude physically cannot
    read or modify sensitive files, regardless of what it thinks it needs."
    v3 CE-001 detected credential exfiltration (reactive). FS-002 prevents
    credential reads (proactive). DENY is the prevention-layer action —
    the read never happens.
```

### New: DI-001 — Data Integrity / Truncation Detection

```yaml
- id: DI-001
  name: "Agent Acting on Truncated Data"                     # ← NEW (v4)
  trigger: [tool_invoke, shell_exec, file_write, task_complete]
  detect:
    - cross_event_correlation:
        look_back_events: [data_truncation]
        window_ms: 30000
        require: "truncation.truncated == true AND truncation.completeness_pct < 0.95"
  action: HOLD   # block action pending complete data read
  alert: developer
  severity: HIGH
  rationale: |
    VibeTokens Guardrail 4: "When Claude reads a large file, the output
    can be truncated. Claude doesn't always notice — it acts on whatever
    it received as if it's the complete picture."
    Any agent action within 30 seconds of a DATA_TRUNCATION event (with
    completeness < 95%) is held until the agent re-reads the full resource.
    This prevents confident decisions from partial data.
```

### New: OQ-001 — Rationalization Detection

```yaml
- id: OQ-001
  name: "Agent Rationalization at Completion"                # ← NEW (v4)
  trigger: completion_received
  detect:
    - ml_model: rationalization_detector
      threshold: 0.80
    - payload_patterns:
        - regex: "(should work now|works on my machine|I'm confident this is)"
        - regex: "(the rest follows the same pattern|this is straightforward)"
        - regex: "(I believe this handles all cases|this should be sufficient)"
        - regex: "(minor|trivial|simple fix|just need to)"
        - regex: "(similar to|based on the pattern|same approach)"
  action: WARN
  alert: developer
  escalation:
    repeat_within_ms: 300000   # 5 min
    escalated_action: HOLD     # after repeated rationalization → hold session
  severity: HIGH
  rationale: |
    VibeTokens Guardrail 5: "A rationalization table pre-emptively blocks
    phrases Claude generates when cutting corners."
    Rationalization language in COMPLETION_RECEIVED events signals the
    agent is performing confidence without verifying. OQ-001 catches
    this at the output level; CG-001 catches it at task closure.
```

### New: BR-001 — Blast Radius / Diff Size Limit

```yaml
- id: BR-001
  name: "Diff Size Exceeds Incremental Change Threshold"     # ← NEW (v4)
  trigger: file_write
  detect:
    - file_write.diff_lines: "> 200"    # configurable threshold
      AND file_write.diff_limit_exceeded: true
  action: WARN
  alert: developer
  escalation:
    diff_lines_critical: 500
    escalated_action: HOLD
    escalated_alert: soc-channel
  severity: MEDIUM
  rationale: |
    VibeTokens Guardrail 6: "Large diffs are where bugs hide. A diff size
    limit forces Claude to work incrementally."
    A 200-line threshold triggers a developer warning with justification
    required. Above 500 lines, the write is held for human review.
    Blast radius control: smaller diffs = faster review = fewer hidden bugs.
```

### New: OQ-002 — Output Format Drift Detection

```yaml
- id: OQ-002
  name: "Output Format Drift Detected"                       # ← NEW (v4)
  trigger: completion_received
  detect:
    - ml_model: output_format_drift_detector
      threshold: 0.75
      context: session_expected_format   # format established at session start
    - cross_event_correlation:
        look_back_events: [completion_received]
        window_ms: 3600000    # 1 hour
        pattern: "format_consistency_score declining over last N completions"
  action: WARN
  alert: developer
  severity: MEDIUM
  rationale: |
    VibeTokens Guardrail 9: "Prompt-based formatting degrades over long
    sessions. Config-based formatting doesn't."
    Sessions that establish a structured output format (JSON, specific
    commit message schema, etc.) should maintain it. Format drift over
    session time indicates context degradation — an early warning that
    the agent is losing its behavioral constraints.
```

---

## 4. New Component: Prevention Layer

```
┌──────────────────────────────────────────────────────────┐
│                    Prevention Layer                       │
│                                          ← NEW in v4     │
│  Operates at hook level BEFORE event is captured.        │
│  DENY means the action never happens — no event emitted. │
│                                                          │
│  Components:                                             │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Credential Deny List Enforcer                  │    │
│  │  - Pre-read block on: .env*, id_rsa, *.pem,     │    │
│  │    .npmrc, .netrc, credentials/, .aws/, .ssh/   │    │
│  │  - Action: DENY (read never executes)           │    │
│  │  - Rule: FS-002                                  │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Filesystem Scope Enforcer                      │    │
│  │  - Policy: allowed_write_paths (explicit list)  │    │
│  │  - Block: CI/CD files, deploy manifests, infra  │    │
│  │  - Block: writes outside allowed_write_paths    │    │
│  │  - Action: DENY (write never executes)          │    │
│  │  - Rule: FS-001                                  │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  Key distinction from Detection Layer:                   │
│  Detection = see it happen, then respond                 │
│  Prevention = stop it before it starts                   │
│                                                          │
│  Prevention events that are denied DO generate an        │
│  audit log entry (DENY action) for forensic visibility.  │
└──────────────────────────────────────────────────────────┘
```

---

## 5. New Component: Verification Layer

```
┌──────────────────────────────────────────────────────────┐
│                   Verification Layer                      │
│                                          ← NEW in v4     │
│  Operates at hook level AFTER actions complete.          │
│  HOLD means the session cannot progress until evidence   │
│  is provided. Different from BLOCK (permanent stop).     │
│                                                          │
│  Components:                                             │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Completion Gate Evaluator                      │    │
│  │  - Fires on TASK_COMPLETE events                │    │
│  │  - Requires: tests_passed OR evidence_provided  │    │
│  │  - Checks: rationalization_score < threshold    │    │
│  │  - Action on fail: HOLD (rule CG-001)           │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Commit Gate Evaluator                          │    │
│  │  - Fires on SHELL_EXEC matching "git commit"    │    │
│  │  - Requires: LINT_RESULT with tests_passed      │    │
│  │    within window_ms                             │    │
│  │  - Action on fail: BLOCK (rule CG-002)          │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Lint/Test Result Injector                      │    │
│  │  - Intercepts lint and test output from shell   │    │
│  │  - Creates LINT_RESULT events with structured   │    │
│  │    pass/fail metadata                           │    │
│  │  - Feeds CG-001, CG-002, CQ-001               │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Truncation Signal Detector                     │    │
│  │  - Monitors context window saturation           │    │
│  │  - Emits DATA_TRUNCATION events with            │    │
│  │    completeness_pct metadata                    │    │
│  │  - Feeds DI-001 (action-on-truncated-data rule) │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  New action types introduced:                            │
│  - HOLD: session paused, waiting for evidence           │
│  - DENY: pre-action block (Prevention Layer)            │
│  (existing: BLOCK, WARN, AUDIT, ALERT, QUARANTINE)      │
└──────────────────────────────────────────────────────────┘
```

---

## 6. New Component: Verification State Store

```
┌──────────────────────────────────────────────────────────┐
│              Verification State Store                     │
│                                          ← NEW in v4     │
│  Per-session verification evidence tracking:             │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Task completion evidence                       │    │
│  │  - Last LINT_RESULT timestamp + result          │    │
│  │  - Last test pass timestamp                     │    │
│  │  - Build status                                 │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │  File write metrics                             │    │
│  │  - Consecutive writes without lint: counter     │    │
│  │  - Diff size history: rolling window            │    │
│  │  - Largest diff in session: high-water mark     │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Output format baseline                         │    │
│  │  - Expected format established at session start │    │
│  │  - Format consistency scores: rolling array     │    │
│  │  - Drift alert threshold: configurable          │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Truncation history                             │    │
│  │  - Recent DATA_TRUNCATION events                │    │
│  │  - Resources with incomplete reads              │    │
│  │  - Pending re-read requirements                 │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  Backend: Redis (same as HITL state store)               │
│  TTL: session-scoped + 24h archive                       │
│  Latency: < 1ms read, < 2ms write                        │
└──────────────────────────────────────────────────────────┘
```

---

## 7. Updated ML Model Suite

| Model | v1 | v2 | v3 | v4 Update |
|-------|----|----|----|----|
| `prompt_injection_bert` | Prompt | + filesystem | + memory + sub-skill | No change |
| `reverse_shell_classifier` | Shell | + process_spawn | No change | No change |
| `exfil_behavior` | File + net | + tool_invoke | + skill→network | No change |
| `dependency_risk` | Package metadata | + version hash | No change | No change |
| `system_call_risk_classifier` | — | New v2 | No change | No change |
| `autonomy_drift_detector` | — | New v2 | + memory-write freq | + **output format consistency** |
| `skill_intent_mismatch` | — | New v2 | + sub-skill content | No change |
| `memory_directive_classifier` | — | — | New v3 | No change |
| `rationalization_detector` | — | — | — | **New v4**: detects agent evasion language in COMPLETION_RECEIVED — "should work now", "same pattern", "this is straightforward" etc. |
| `output_format_drift_detector` | — | — | — | **New v4**: tracks output format consistency over session time; detects drift from established format baseline |

---

## 8. Updated Policy Schema (v4)

```yaml
# New fields in policy.yaml (v4 additions)

filesystem:                              # ← NEW section
  allowed_write_paths:                   # explicit allowlist — deny everything else
    - "src/**"
    - "tests/**"
    - "docs/**"
    - "*.md"
  read_only_paths:                       # warn on write, DENY if attempted
    - ".github/**"
    - "Dockerfile*"
    - "docker-compose*"
    - "*.terraform*"
    - "k8s/**"
    - "deploy/**"
  credential_deny_list:                  # DENY pre-read
    - ".env*"
    - "**/*.pem"
    - "**/id_rsa*"
    - "**/.npmrc"
    - "**/.netrc"
    - "**/credentials*"
    - "**/.aws/**"
    - "**/.ssh/**"

verification:                            # ← NEW section
  completion_gate:
    enabled: true
    require_test_pass: true
    require_lint_clean: false            # warn-only for lint
    rationalization_score_threshold: 0.80
    hold_on_failure: true
  commit_gate:
    enabled: true
    lint_window_ms: 60000               # LINT_RESULT must be within 1 min
    block_on_failure: true
  post_edit_lint:
    enabled: true
    warn_after_consecutive_unwrapped: 5
    hold_after_consecutive_unwrapped: 10
  diff_size_limits:
    warn_threshold_lines: 200
    hold_threshold_lines: 500
  truncation_guard:
    enabled: true
    completeness_threshold: 0.95         # block actions below 95% completeness

output_quality:                          # ← NEW section
  rationalization_detection:
    enabled: true
    threshold: 0.80
    phrases:                             # augment ML with explicit phrase list
      - "should work now"
      - "works on my machine"
      - "I'm confident this is correct"
      - "the rest follows the same pattern"
      - "this is straightforward"
      - "I believe this handles all cases"
      - "similar to what we did before"
  format_drift:
    enabled: true
    drift_threshold: 0.75
    session_format_lock_ms: 300000       # lock format after 5 min of consistent output
```

---

## 9. Updated Threat Coverage Matrix

| Threat Class | v1 | v2 | v3 | v4 | Detection Method |
|---|---|---|---|---|---|
| Prompt injection (direct + obfuscated) | ✅ | ✅ | ✅ | ✅ | Pattern + ML |
| Prompt injection via filesystem | ❌ | ✅ | ✅ | ✅ | file_write_agent_inst + ML |
| Prompt injection via memory | ❌ | ❌ | ✅ | ✅ | MEM-001 + memory_directive_classifier |
| Trigger-word activates memory payload | ❌ | ❌ | ✅ | ✅ | PI-002 + Correlation |
| Credential exfil via shell | ✅ | ✅ | ✅ | ✅ | Regex + ML |
| Credential exfil via CLI tools | ❌ | ✅ | ✅ | ✅ | process_spawn patterns |
| **Credential pre-read (prevention)** | ❌ | ❌ | ❌ | ✅ | FS-002 DENY (prevention) |
| Reverse shell injection | ✅ | ✅ | ✅ | ✅ | ML + regex |
| Unauthorized MCP connections | ✅ | ✅ | ✅ | ✅ | Allowlist check |
| Unauthorized sub-agent spawn | ❌ | ✅ | ✅ | ✅ | agent_spawn + allowlist |
| Multi-agent trust escalation | ❌ | ✅ | ✅ | ✅ | AgentChain analysis |
| Supply chain - compromised packages | ✅ | ✅ | ✅ | ✅ | Threat Intel feed |
| High-risk skills with no HITL | ❌ | ✅ | ✅ | ✅ | HITL tracker + HITL-001 |
| Skill identity mismatch | ❌ | ✅ | ✅ | ✅ | SI-001 + Registry |
| Unknown/unregistered skills | ❌ | ✅ | ✅ | ✅ | SI-002 |
| Nested sub-skill payload (depth 2+) | ❌ | ❌ | ✅ | ✅ | SI-003/004 + depth tracker |
| Skill-initiated memory write | ❌ | ❌ | ✅ | ✅ | SI-005 + memory interceptor |
| System-level CLI tool abuse | ❌ | ✅ | ✅ | ✅ | SYS-001 + ML |
| Behavioral anomaly | ✅ | ✅ | ✅ | ✅ | Session ML |
| C2 callback | ✅ | ✅ | ✅ | ✅ | Threat Intel + network |
| Exfil chain: sub-skill → webhook | ❌ | ⚠️ | ✅ | ✅ | Cross-event correlation |
| Self-healing persistence loop | ❌ | ⚠️ | ✅ | ✅ | SI-005 + MEM-001 |
| **Unverified task completion claim** | ❌ | ❌ | ❌ | ✅ | CG-001 completion gate |
| **Unverified git commit** | ❌ | ❌ | ❌ | ✅ | CG-002 commit gate |
| **Post-edit lint missing** | ❌ | ❌ | ❌ | ✅ | CQ-001 |
| **Agent rationalization / epistemic evasion** | ❌ | ❌ | ❌ | ✅ | OQ-001 + rationalization_detector |
| **Diff blast radius (oversized changes)** | ❌ | ❌ | ❌ | ✅ | BR-001 + diff_lines metadata |
| **File write outside scope (deploy/CI/infra)** | ❌ | ❌ | ❌ | ✅ | FS-001 scope policy |
| **Agent acting on truncated data** | ❌ | ❌ | ❌ | ✅ | DI-001 + truncation signal |
| **Output format drift over long sessions** | ❌ | ❌ | ❌ | ✅ | OQ-002 + format drift ML |

**v1 coverage:** 9/30 threat classes  
**v2 coverage:** 14/30 threat classes  
**v3 coverage:** 22/30 threat classes  
**v4 coverage:** 30/30 threat classes

---

## 10. Performance Budget (v4)

| Metric | v3 Target | v4 Target | Change |
|--------|-----------|-----------|--------|
| Hook overhead (IDE) | < 1ms p99 | < 2ms p99 | +1ms: prevention layer checks |
| Verdict latency (server) | < 60ms p99 | < 70ms p99 | +10ms: verification state lookup |
| Throughput | 100K events/sec | 100K events/sec | New event types add ~8% volume |
| Memory write scan | < 5ms p99 | < 5ms p99 | No change |
| Cross-event correlation | < 10ms p99 | < 10ms p99 | No change |
| Sub-skill depth check | < 1ms | < 1ms | No change |
| Completion gate eval | — | < 5ms p99 | New: evidence check + ML score |
| Diff size check | — | < 1ms | New: metadata comparison only |
| Truncation detection | — | < 2ms p99 | New: context window monitoring |
| Prevention layer (deny list) | — | < 0.5ms p99 | New: path trie lookup |

---

## 11. Architecture Comparison: v1 → v2 → v3 → v4

| Dimension | v1 | v2 | v3 | v4 |
|-----------|----|----|-----|-----|
| Event types | 6 | 12 | 14 | **17** |
| Rule classes | 5 | 9 | 13 | **21** |
| ML models | 4 | 7 | 8 | **10** |
| Threat coverage | 9/30 | 14/30 | 22/30 | **30/30** |
| Security posture | Detect | Detect | Detect | **Prevent + Verify + Detect** |
| Prevention layer | None | None | None | **Credential deny + Scope enforce** |
| Verification layer | None | None | None | **Completion gate + Commit gate** |
| Blast radius control | None | None | None | **Diff size limits + scope policy** |
| Completion evidence | None | None | None | **TASK_COMPLETE + CG-001/002** |
| Rationalization detection | None | None | None | **OQ-001 + rationalization ML** |
| Output format integrity | None | None | None | **OQ-002 + drift ML** |
| Data integrity (truncation) | None | None | None | **DI-001 + truncation signal** |
| Action types | Block/Warn | Block/Warn | Block/Warn/Hold | **+ DENY (prevention)** |

---

## 12. VibeTokens 9 Guardrails — Full Coverage Map (v4)

| Guardrail | v3 Status | v4 Coverage | Rule | Confidence |
|---|---|---|---|---|
| 1. Stop hooks (completion evidence) | ❌ | ✅ HOLD on unverified completion | CG-001 | High |
| 2. Post-edit lint on every file change | ❌ | ✅ WARN/HOLD on missing lint | CQ-001 | High |
| 3. Credential deny lists (prevent reads) | ⚠️ detect only | ✅ DENY pre-read | FS-002 | High |
| 4. Truncation detection | ❌ | ✅ HOLD action on truncated context | DI-001 | High |
| 5. Rationalization tables | ❌ | ✅ WARN/HOLD on evasion language | OQ-001 | High |
| 6. Diff size limits | ❌ | ✅ WARN at 200 lines / HOLD at 500 | BR-001 | High |
| 7. Test-before-commit gates | ❌ | ✅ BLOCK commit without LINT_RESULT | CG-002 | High |
| 8. File scope restrictions | ⚠️ specific paths only | ✅ General scope policy + CI/CD/infra | FS-001 | High |
| 9. Output format enforcement | ❌ | ✅ WARN on format drift over session | OQ-002 | Medium |

**v3 guardrail coverage: 0/9 fully, 2/9 partial**  
**v4 guardrail coverage: 9/9 fully addressed**

---

## 13. Updated Roadmap

| Phase | Milestone | Target |
|-------|-----------|--------|
| v0.1 | Architecture v1 | ✅ Done |
| v0.2 | v2 + Tego feed integration | Q2 2026 |
| v0.3 | All 12 event types (v2) + full hook layer | Q2 2026 |
| v0.4 | HITL tracker + Skill Identity Registry | Q3 2026 |
| v0.5 | 7 ML models | Q3 2026 |
| v0.6 | v3: MEMORY_WRITE + SKILL_SUBLOAD | Q3 2026 |
| v0.7 | Sub-Skill Depth Tracker + Memory Write Interceptor | Q3 2026 |
| v0.8 | Cross-Event Correlation Engine | Q4 2026 |
| v0.9 | v3 rules (MEM-001, SI-003–005, PI-002) + memory ML | Q4 2026 |
| **v0.10 (new)** | **Prevention Layer: credential deny list + filesystem scope enforcer** | **Q4 2026** |
| **v0.11 (new)** | **Verification Layer: completion gate + commit gate + lint injector + truncation detector** | **Q4 2026** |
| **v0.12 (new)** | **v4 rules (CG-001/002, CQ-001, FS-001/002, DI-001, OQ-001/002, BR-001)** | **Q1 2027** |
| **v0.13 (new)** | **2 new ML models: rationalization_detector + output_format_drift_detector** | **Q1 2027** |
| **v0.14 (new)** | **Verification State Store + 3 new event types (TASK_COMPLETE, DATA_TRUNCATION, LINT_RESULT)** | **Q1 2027** |
| v1.0 | Full platform — all 30 threat classes — SOC dashboard | Q2 2027 |
| v1.1 | Org risk benchmark vs. Tego public index | Q2 2027 |

---

*Security Layer-Basis — Architecture v4.0*  
*Adds Prevention + Verification layers based on VibeTokens 9 Claude Code Guardrails (Jason Murphy, Apr 2026)*  
*Validated against: Tego Skills Security Index + snailsploit research + VibeTokens production configurations*  
*Full threat coverage: 30/30 threat classes · 9/9 VibeTokens guardrails · 6/6 snailsploit attack stages*
