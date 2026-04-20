# Security Layer-Basis — Detailed Architecture

**Version:** 0.1-DRAFT  
**Date:** 2026-04-19  
**Classification:** Internal — Architecture Design

---

## 1. Design Philosophy

> *"The hook is invisible. The engine is everywhere. The policy is one."*

Security Layer-Basis operates on three axioms:

1. **Single Policy Source of Truth** — Security writes one policy document. No per-IDE, per-team, or per-agent copies.
2. **Thin Client, Thick Server** — IDE plugins contain zero detection logic. All intelligence lives server-side.
3. **Zero Developer Friction** — Developers experience no latency, no workflow change, no prompts. The system is architecturally invisible.

---

## 2. High-Level Architecture

```
┌───────────────────────────────────────────────────────────────────────────┐
│                          DEVELOPER MACHINES                               │
│                                                                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ VS Code  │  │ JetBrains│  │  Cursor  │  │  Neovim  │  │ Any IDE  │  │
│  │  + Hook  │  │  + Hook  │  │  + Hook  │  │  + Hook  │  │  + Hook  │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  │
│       │              │              │              │              │        │
│       └──────────────┴──────────────┴──────────────┴──────────────┘      │
│                                    │                                       │
│                          Interceptor Agent (local)                        │
│                          ┌─────────────────────┐                          │
│                          │ - Captures events    │                          │
│                          │ - Strips PII tokens  │                          │
│                          │ - Buffers + forwards │                          │
│                          └──────────┬──────────┘                          │
└─────────────────────────────────────┼─────────────────────────────────────┘
                                      │  TLS 1.3 / mTLS
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DETECTION ENGINE (Server-Side)                       │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                        GATEWAY LAYER                                  │  │
│  │   Auth · Rate Limiting · Tenant Isolation · Event Deduplication      │  │
│  └───────────────────────────┬──────────────────────────────────────────┘  │
│                              │                                              │
│  ┌───────────────────────────▼──────────────────────────────────────────┐  │
│  │                     EVENT PIPELINE (Streaming)                        │  │
│  │                                                                       │  │
│  │   ┌──────────┐   ┌─────────────┐   ┌───────────────┐   ┌─────────┐  │  │
│  │   │ Ingestion│──▶│ Normalizer  │──▶│ Rule Evaluator│──▶│ Verdict │  │  │
│  │   │  Queue   │   │             │   │  Engine       │   │ Router  │  │  │
│  │   └──────────┘   └─────────────┘   └───────────────┘   └────┬────┘  │  │
│  └──────────────────────────────────────────────────────────────┼───────┘  │
│                                                                  │          │
│  ┌───────────────┐  ┌────────────────┐  ┌───────────────────┐   │          │
│  │  Policy Store │  │ Threat Intel   │  │  ML Anomaly       │   │          │
│  │  (single file)│  │ Feed (live)    │  │  Models           │   │          │
│  └───────────────┘  └────────────────┘  └───────────────────┘   │          │
│                                                                  │          │
│  ┌────────────────────────────────────────────────────────────── ▼ ──────┐  │
│  │                        ACTION EXECUTOR                                 │  │
│  │   Block · Warn · Audit · Alert · Quarantine · Kill Session            │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                   OBSERVABILITY PLANE                                  │  │
│  │   Audit Trail · SIEM Forwarding · Dashboard · Incident Timeline       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Component Breakdown

### 3.1 — IDE Hook Layer (Client-Side)

**Responsibility:** Intercept and forward. Nothing else.

| Property | Specification |
|----------|--------------|
| Deployment | IDE extension / plugin (per supported IDE) |
| Code size | < 500 lines per integration |
| CPU overhead | < 0.1% (async, non-blocking) |
| Memory | < 10 MB resident |
| Detection logic | **None** |
| Failure mode | Fail-open with alert (developer unblocked, security team notified) |

**What the hook captures:**

```
HookEvent {
  timestamp:         ISO-8601
  session_id:        UUID (ephemeral, per-session)
  developer_id:      hashed identity (no PII in transit)
  ide:               "vscode" | "jetbrains" | "cursor" | "neovim" | ...
  agent:             "github-copilot" | "cursor-ai" | "cody" | "claude-code" | ...
  event_type:        "prompt_submitted" | "completion_received" | "shell_exec"
                   | "file_write" | "network_request" | "mcp_connect" | ...
  payload:           string (prompt/completion text, command, URL)
  context_snapshot:  {file_type, repo, branch, open_files[]}
}
```

**Supported IDE Integrations (v1):**

| IDE | Integration Method | Status |
|-----|--------------------|--------|
| VS Code | Extension API + LSP middleware | ✅ |
| JetBrains (IntelliJ/PyCharm/GoLand) | Plugin SDK + OpenAPI listener | ✅ |
| Cursor | Proxy intercept via local MITM | ✅ |
| Neovim | Lua plugin + stdio pipe hook | ✅ |
| Emacs | elisp advice wrapper | 🔜 |
| Zed | Extension API | 🔜 |
| CLI agents (Claude Code, Codex) | Process-level shim | ✅ |

---

### 3.2 — Local Interceptor Agent

**Responsibility:** Lightweight local daemon running per developer machine.

- Collects events from all IDE hooks on the machine
- Performs **no detection** — only buffering, batching, and forwarding
- Strips credential-shaped strings before transmission (defense-in-depth)
- Authenticates to the Detection Engine via mTLS client certificates
- Provides local audit cache (72-hour rolling window) for offline resilience

```
┌────────────────────────────────────┐
│       Interceptor Agent            │
│                                    │
│  ┌─────────────┐  ┌─────────────┐ │
│  │  Hook IPC   │  │  Local      │ │
│  │  Receiver   │  │  Cache DB   │ │
│  │  (Unix sock)│  │  (SQLite)   │ │
│  └──────┬──────┘  └──────┬──────┘ │
│         │                │        │
│  ┌──────▼────────────────▼──────┐ │
│  │     Event Batcher            │ │
│  │   (50ms flush / 100 events)  │ │
│  └──────────────┬───────────────┘ │
│                 │                  │
│  ┌──────────────▼───────────────┐ │
│  │   mTLS Forwarder             │ │
│  │   (gRPC streaming)           │ │
│  └──────────────────────────────┘ │
└────────────────────────────────────┘
```

---

### 3.3 — Detection Engine

**The brain. Runs entirely server-side.**

#### 3.3.1 Gateway Layer

- Validates mTLS client certificates
- Enforces per-tenant rate limits
- Deduplicates events across IDE + agent combos
- Routes to correct tenant policy context

#### 3.3.2 Event Pipeline

```
Ingestion Queue (Kafka/NATS)
        │
        ▼
Normalizer
  → Converts all IDE-specific formats to canonical EventSchema
  → Enriches with: developer identity, repo metadata, risk context
        │
        ▼
Rule Evaluator Engine
  → Loads active policy from Policy Store
  → Evaluates all applicable rules (parallel, <5ms p99)
  → Consults ML Anomaly Models for behavioral signals
  → Consults Threat Intel Feed for known-bad patterns
        │
        ▼
Verdict Router
  → Assigns: ALLOW | WARN | BLOCK | QUARANTINE | KILL_SESSION
  → Emits verdict back to Interceptor Agent (real-time)
  → Emits audit record to Observability Plane
```

#### 3.3.3 Policy Store

```yaml
# Single policy file. All IDEs. All developers. All agents.
# security/policy.yaml

version: "1.0"
tenant: "acme-corp"

rules:
  - id: PI-001
    name: "Prompt Injection - Obfuscated"
    trigger: prompt_submitted
    detect:
      - pattern: "ignore previous instructions"
        obfuscation_variants: true   # catches leet, unicode, base64 variants
      - pattern: "you are now"
      - pattern: "system: override"
    action: BLOCK
    alert: soc-channel
    severity: CRITICAL

  - id: CE-001
    name: "Credential Exfiltration - Shell"
    trigger: shell_exec
    detect:
      - regex: '(cat|echo|print)\s.*(\.env|id_rsa|\.pem|credentials)'
      - regex: 'curl.+\|\s*sh'
      - regex: 'export\s+\w+\s*=.*\$\{?[A-Z_]+\}?.*&&.*curl'
    action: BLOCK
    alert: soc-channel
    severity: CRITICAL

  - id: RS-001
    name: "Reverse Shell Injection"
    trigger: [shell_exec, completion_received]
    detect:
      - regex: 'bash\s+-i\s+>&\s+/dev/tcp'
      - regex: 'nc\s+-e\s+/bin/sh'
      - regex: 'python.*socket.*connect.*subprocess'
      - ml_model: reverse_shell_classifier
        threshold: 0.92
    action: KILL_SESSION
    alert: [soc-channel, pagerduty]
    severity: CRITICAL

  - id: MCP-001
    name: "Unauthorized MCP Server"
    trigger: mcp_connect
    detect:
      - allowlist_check: mcp_servers.approved
        invert: true              # block anything NOT in approved list
    action: BLOCK
    alert: soc-channel
    severity: HIGH

  - id: SC-001
    name: "Supply Chain - Compromised Package"
    trigger: [file_write, shell_exec]
    detect:
      - threat_intel: package_malware_feed
        fields: [package_name, package_version]
      - pattern: "npm install.*--ignore-scripts false"
    action: WARN
    alert: developer
    severity: HIGH

allowlists:
  mcp_servers:
    approved:
      - "mcp.internal.acme.com"
      - "mcp.github.com"
```

#### 3.3.4 ML Anomaly Models

| Model | Purpose | Signal |
|-------|---------|--------|
| `reverse_shell_classifier` | Multi-layer text classifier | Shell command structure + entropy |
| `prompt_injection_bert` | Fine-tuned BERT for injection | Semantic intent in prompt text |
| `exfil_behavior` | Session-level behavioral model | Sequence of file access + net events |
| `dependency_risk` | Package risk scoring | Package metadata + known-bad feed |

---

### 3.4 — Threat Intel Feed

Live-updated feed consumed by the Rule Evaluator:

- **Known malicious packages** (npm, PyPI, Maven, Go modules)
- **Known C2 / reverse shell endpoints**
- **Known prompt injection templates** (updated daily from honeypot corpus)
- **MCP server reputation database**

Update frequency: real-time for critical IOCs, hourly for full feed refresh.

---

### 3.5 — Action Executor

Maps verdicts to real-world consequences:

| Verdict | Action |
|---------|--------|
| `ALLOW` | Pass-through, audit record only |
| `WARN` | Developer sees non-blocking notice in IDE |
| `BLOCK` | Event suppressed, developer sees policy message |
| `QUARANTINE` | Session output sandboxed, security review required |
| `KILL_SESSION` | AI agent session terminated, SOC alerted immediately |

**Latency budget:** Verdict must be returned within **50ms p99** to avoid any perceptible IDE delay.

---

### 3.6 — Observability Plane

```
┌─────────────────────────────────────────────────────┐
│                 Observability Plane                  │
│                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────┐  │
│  │ Audit Trail │  │  SIEM Fwd   │  │  Dashboard │  │
│  │ (immutable) │  │ (Splunk/    │  │  (SOC ops) │  │
│  │             │  │  Sentinel)  │  │            │  │
│  └─────────────┘  └─────────────┘  └────────────┘  │
│                                                     │
│  ┌─────────────────────────────────────────────┐    │
│  │          Incident Timeline                   │    │
│  │  - Full event replay per session             │    │
│  │  - Developer attribution (hashed by default) │    │
│  │  - One-click de-anonymize (SOC only)         │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

**Audit record schema:**

```json
{
  "event_id":       "evt_01HX...",
  "timestamp":      "2026-04-19T09:18:00Z",
  "tenant":         "acme-corp",
  "developer_id":   "sha256:a3f4...",
  "ide":            "vscode",
  "agent":          "cursor-ai",
  "rule_triggered": "RS-001",
  "verdict":        "KILL_SESSION",
  "severity":       "CRITICAL",
  "payload_hash":   "sha256:...",
  "payload_preview": "[REDACTED - SOC access required]",
  "context": {
    "repo":    "acme-corp/payments-service",
    "branch":  "feat/checkout-v2",
    "file":    "src/checkout.py"
  }
}
```

---

## 4. Data Flow — End to End

```
Developer types a prompt in VS Code
          │
          ▼
VS Code Hook captures event (< 1ms)
          │ (async, non-blocking)
          ▼
Local Interceptor Agent receives event
  → strips sensitive tokens
  → batches with other events
          │ (gRPC stream, mTLS)
          ▼
Detection Engine Gateway
  → validates auth, tenant
          │
          ▼
Event Pipeline
  → normalizes
  → evaluates against policy
  → ML models score
  → Threat Intel checked
  → verdict assigned (< 50ms)
          │
          ▼
Verdict returned to Interceptor Agent
          │
     ALLOW?─────────────▶ pass-through, audit record written
          │
     BLOCK/WARN?─────────▶ hook suppresses/surfaces message in IDE
          │
     KILL_SESSION?───────▶ agent session terminated
                           SOC alerted
                           full incident record created
```

---

## 5. Deployment Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                       PRODUCTION DEPLOYMENT                       │
│                                                                  │
│   ┌──────────────────┐        ┌────────────────────────────┐    │
│   │  Developer Fleet  │        │   Detection Engine Cluster │    │
│   │                  │  mTLS  │                            │    │
│   │  Agent installed  │───────▶│  - Kubernetes (multi-AZ)  │    │
│   │  on each machine  │        │  - Auto-scaling            │    │
│   │                  │        │  - 99.99% SLA              │    │
│   └──────────────────┘        └────────────┬───────────────┘    │
│                                            │                     │
│                               ┌────────────▼───────────────┐    │
│                               │   Policy + Config Store     │    │
│                               │   (Git-backed, audited)     │    │
│                               └────────────────────────────┘    │
│                                                                  │
│                               ┌────────────────────────────┐    │
│                               │   SOC Dashboard             │    │
│                               │   + SIEM Integration        │    │
│                               └────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

**Deployment options:**
- **SaaS** — Detection Engine hosted, zero infra burden
- **Self-hosted** — Full Kubernetes manifest, air-gap friendly
- **Hybrid** — Detection Engine on-prem, policy sync via encrypted channel

---

## 6. Security Properties

| Property | How it's achieved |
|----------|------------------|
| **No PII in transit** | Developer IDs hashed at hook; payload de-identified before forwarding |
| **Tamper-resistant audit** | Immutable append-only log (WORM storage / blockchain anchored) |
| **Policy integrity** | Policy stored in signed Git repo; hash verified at load time |
| **Interceptor compromise resistance** | Interceptor runs with minimal privileges; cannot modify policy or audit trail |
| **Availability** | Engine cluster multi-AZ; fail-open keeps developers unblocked |
| **Confidentiality** | mTLS everywhere; tenant data strictly isolated at DB level |

---

## 7. What It Catches — Threat Coverage Matrix

| Threat Class | Detection Method | Verdict |
|---|---|---|
| Prompt injection (direct) | Rule pattern match | BLOCK |
| Prompt injection (obfuscated — leet/unicode/base64) | ML classifier + pattern variants | BLOCK |
| Credential exfiltration via shell | Regex rule on shell_exec events | BLOCK |
| `.env` / key file reads piped to network | Shell event correlation | BLOCK |
| Reverse shell injection | ML classifier + regex | KILL_SESSION |
| Unauthorized MCP server connections | Allowlist check on mcp_connect event | BLOCK |
| Supply chain — compromised npm/PyPI packages | Threat Intel feed lookup | WARN → BLOCK |
| Behavioral anomaly (unusual file access sequences) | Session-level ML model | QUARANTINE |
| C2 callback attempts | Threat Intel + network event | BLOCK + ALERT |

---

## 8. Performance Budget

| Metric | Target | Mechanism |
|--------|--------|-----------|
| Hook overhead (IDE) | < 1ms p99 | Async, fire-and-forget |
| Verdict latency (server) | < 50ms p99 | In-memory rule eval + model caching |
| Throughput | 100K events/sec per cluster | Kafka + horizontal scale |
| Audit write latency | < 100ms | Async, non-blocking to event pipeline |
| Availability | 99.99% | Multi-AZ, circuit breaker, fail-open |

---

## 9. Developer Experience

The developer sees **nothing** unless there is a policy violation.

- ✅ No setup required — agent is deployed via MDM/endpoint management
- ✅ No prompts, no authentication flows
- ✅ No perceptible latency
- ✅ No changes to their workflow, shortcuts, or AI agent behavior
- ⚠️ On WARN: non-blocking inline message (dismissible)
- 🚫 On BLOCK: action suppressed + short policy message
- 🛑 On KILL_SESSION: AI session ends, brief explanation shown

---

## 10. Security Team Experience

Security teams interact with:

1. **Policy file** — single YAML, version-controlled in Git, deployed via CI/CD
2. **SOC Dashboard** — real-time event feed, alert triage, incident timeline
3. **Audit Trail** — full searchable history, exportable for compliance
4. **SIEM integration** — events forwarded to Splunk, Sentinel, or Elastic

**Policy changes take effect in < 30 seconds** (policy hot-reload without engine restart).

---

## 11. Roadmap

| Phase | Milestone | Target |
|-------|-----------|--------|
| v0.1 | Architecture design (this document) | ✅ Done |
| v0.2 | VS Code + Cursor hook + Detection Engine prototype | Q2 2026 |
| v0.3 | JetBrains + CLI agent support + Policy YAML v1 | Q3 2026 |
| v0.4 | ML models (prompt injection, reverse shell) | Q3 2026 |
| v1.0 | Full IDE coverage + SIEM integrations + SOC dashboard | Q4 2026 |
| v1.1 | Behavioral anomaly detection + supply chain feed | Q1 2027 |

---

*Security Layer-Basis — Architecture v0.1-DRAFT*  
*All threat patterns, rule IDs, and ML model names are illustrative for design purposes.*
