# Security Layer-Basis — Architecture v7.0

**Version:** 7.0  
**Date:** 2026-05-16  
**Basis:** Architecture v6.0 (Integration-first platform)  
**Core Change:** GRC-first platform — Security Layer-Basis gains a compliance intelligence layer, live security posture engine, risk register, quick-action workflows, and an AI chat interface  
**Changes from v6:** Security Posture Engine, Compliance Framework Layer, Risk Register, Quick Actions Engine, AI Compliance Chat, updated Observability Plane, updated REST API v1 endpoints, updated roadmap

---

## What Changed and Why

> *"Add quick actions like Risk Assessment and SOC 2 Readiness Check, a live security posture dashboard, compliance tracking across SOC 2 / ISO 27001 / PCI-DSS / GDPR/CCPA, a risk register that updates when company data is uploaded, and a chat interface to ask security and compliance questions."

v6 is a complete detection and integration engine. It detects AI agent threats, blocks them, routes verdicts into PSA/SIEM/webhook, and exposes a REST API. But it answers only one question: **what is happening right now?**

Customers — especially MSSPs and compliance-driven enterprises — need three more questions answered:

1. **How secure are we overall?** (posture, not just events)
2. **Are we compliant?** (SOC 2, ISO 27001, PCI-DSS, GDPR/CCPA — not just ATT&CK)
3. **What should we do next?** (risk register, quick actions, AI-guided remediation)

v7 adds the GRC intelligence layer on top of v6's detection engine. The detection engine is **unchanged** — v7 consumes its output and converts it into compliance evidence, posture scores, and risk register entries.

```
v6 posture:  PREVENT → VERIFY → DETECT → BLOCK → INTEGRATE → DISTRIBUTE
v7 posture:  PREVENT → VERIFY → DETECT → BLOCK → INTEGRATE → DISTRIBUTE
                                                              ↓
                                               ASSESS → COMPLY → ADVISE
```

Five new components added:
1. **Security Posture Engine** — org-level posture score, trend over time, coverage gaps
2. **Compliance Framework Layer** — maps every v6 rule and control to SOC 2 / ISO 27001 / PCI-DSS v4 / GDPR / CCPA
3. **Risk Register** — GRC-style register updated by detection events and company data uploads
4. **Quick Actions Engine** — on-demand Risk Assessment and SOC 2 Readiness Check workflows
5. **AI Compliance Chat** — LLM-powered Q&A grounded in tenant's own posture, events, and compliance state

---

## 1. High-Level Architecture (v7)

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                              DEVELOPER MACHINES                                  │
│  [VS Code Hook v7] [JetBrains Hook v7] [Cursor] [Neovim] [CLI Agent]            │
│                          │ (unchanged from v6)                                   │
└──────────────────────────┼───────────────────────────────────────────────────────┘
                           │  TLS 1.3 / mTLS gRPC
                           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                    DETECTION ENGINE v6 (unchanged)                               │
│  Gateway → Event Pipeline → Risk Classifier → Action Executor → Integration Bus  │
│  PSA Adapter · SIEM Formatter · Webhook Engine · REST API v1 · ATT&CK Mapper    │
└──────────────────────────┬───────────────────────────────────────────────────────┘
                           │  verdict stream + audit events
                           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                    GRC INTELLIGENCE LAYER          ← NEW (v7)                   │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │                     Security Posture Engine                              │   │
│  │  Posture score · Coverage gaps · Trend tracking · Hook deployment %     │   │
│  └─────────────────────────────┬────────────────────────────────────────────┘   │
│                                │                                                 │
│  ┌─────────────────────────────▼────────────────────────────────────────────┐   │
│  │                  Compliance Framework Layer                              │   │
│  │  SOC 2 Type II · ISO 27001:2022 · PCI-DSS v4 · GDPR · CCPA             │   │
│  │  Control coverage map · Evidence store · Gap tracker · Readiness score  │   │
│  └─────────────────────────────┬────────────────────────────────────────────┘   │
│                                │                                                 │
│  ┌─────────────────────────────▼────────────────────────────────────────────┐   │
│  │                       Risk Register                                      │   │
│  │  GRC risk items · Likelihood/impact matrix · Owner assignment           │   │
│  │  Updated by: detection events + company data uploads + compliance gaps  │   │
│  └─────────────────────────────┬────────────────────────────────────────────┘   │
│                                │                                                 │
│  ┌─────────────────────────────▼────────────────────────────────────────────┐   │
│  │                    Quick Actions Engine                                  │   │
│  │  Risk Assessment · SOC 2 Readiness Check · On-demand report generation  │   │
│  └─────────────────────────────┬────────────────────────────────────────────┘   │
│                                │                                                 │
│  ┌─────────────────────────────▼────────────────────────────────────────────┐   │
│  │                    AI Compliance Chat                                    │   │
│  │  LLM-powered Q&A · Grounded in tenant posture, events, risk register    │   │
│  │  Answers: compliance gaps, remediation steps, policy questions           │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐  │
│  │              DATA INGESTION PIPELINE (Company Data Upload)   ← NEW (v7)   │  │
│  │  PDF · CSV · XLSX · JSON → Extractor → Risk Register + Compliance Layer   │  │
│  └────────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────┬───────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                 OBSERVABILITY PLANE v7 (updated)                                 │
│                                                                                  │
│  Live Security Posture Dashboard · SOC Dashboard · Compliance Tracker           │
│  Risk Register UI · Quick Action Panel · AI Chat Interface                      │
│  Audit Trail · Integration Health · API Usage · Skill Map                       │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. New Component: Security Posture Engine

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                       Security Posture Engine                                │
│                                              ← NEW in v7                    │
│                                                                              │
│  Computes a single org-level posture score (0–100) updated continuously.    │
│  Score is a weighted composite of five signal categories.                   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Score Dimensions (weighted)                                        │    │
│  │                                                                     │    │
│  │  Hook Coverage          25%   % of dev machines with hook installed │    │
│  │  Event Severity         25%   weighted event counts (30-day window) │    │
│  │  Compliance Coverage    25%   % of framework controls met           │    │
│  │  Policy Completeness    15%   % of recommended policy rules enabled │    │
│  │  Risk Register Health   10%   % of open risks with owner + plan     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Posture Bands                                                      │    │
│  │                                                                     │    │
│  │  90–100   STRONG    All hooks deployed, no open CRITICAL risks      │    │
│  │  70–89    GOOD      Minor gaps, no CRITICAL events in 30 days       │    │
│  │  50–69    FAIR      Partial hook coverage or compliance gaps        │    │
│  │  30–49    WEAK      Active CRITICAL events or major compliance gap  │    │
│  │  0–29     CRITICAL  Widespread unprotected machines or breach risk  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Inputs (live feeds)                                                │    │
│  │                                                                     │    │
│  │  From Detection Engine:                                             │    │
│  │    - Hook heartbeat per device (coverage %)                         │    │
│  │    - Verdict stream (event severity counts, 30-day rolling)        │    │
│  │    - Active CRITICAL/HIGH events with no resolution                │    │
│  │                                                                     │    │
│  │  From Compliance Framework Layer:                                   │    │
│  │    - Control coverage % per framework                              │    │
│  │    - Number of open compliance gaps                                │    │
│  │                                                                     │    │
│  │  From Policy Store:                                                 │    │
│  │    - Rules enabled / total recommended rules                       │    │
│  │                                                                     │    │
│  │  From Risk Register:                                                │    │
│  │    - Open risks with no owner (unmanaged risk count)               │    │
│  │    - Open HIGH/CRITICAL risks with no mitigation plan              │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Output                                                             │    │
│  │                                                                     │    │
│  │  posture_snapshot (written every 15 minutes):                      │    │
│  │  {                                                                  │    │
│  │    "tenant_id": "acme-corp",                                        │    │
│  │    "score": 74,                                                     │    │
│  │    "band": "GOOD",                                                  │    │
│  │    "trend": "+3 (7 days)",                                         │    │
│  │    "dimensions": {                                                  │    │
│  │      "hook_coverage":       { "score": 88, "detail": "22/25 devs" },│    │
│  │      "event_severity":      { "score": 71, "detail": "2 HIGH open"},│    │
│  │      "compliance_coverage": { "score": 62, "detail": "SOC2: 68%" },│    │
│  │      "policy_completeness": { "score": 80, "detail": "16/20 rules"},│    │
│  │      "risk_register_health":{ "score": 55, "detail": "3 unowned"  }│    │
│  │    },                                                               │    │
│  │    "top_gaps": [                                                    │    │
│  │      "3 developer machines without hook agent",                    │    │
│  │      "SOC 2 CC6.6 — partial coverage (MCP-001 not enabled)",       │    │
│  │      "2 HIGH risks in register with no assigned owner"             │    │
│  │    ],                                                               │    │
│  │    "computed_at": "2026-05-16T14:00:00Z"                           │    │
│  │  }                                                                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  History: 12 months of posture snapshots retained for trend charts.         │
│  MSSP view: posture score visible per client tenant in fleet dashboard.     │
│  Alert: score drops > 10 points in 24h → webhook + PSA ticket auto-created.│
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. New Component: Compliance Framework Layer

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                      Compliance Framework Layer                              │
│                                              ← NEW in v7                    │
│                                                                              │
│  Maps Security Layer-Basis detection controls → compliance framework         │
│  requirements. Tracks evidence, coverage, and gaps per framework.           │
│                                                                              │
│  Supported frameworks (v7):                                                 │
│    SOC 2 Type II (2017 Trust Service Criteria)                              │
│    ISO 27001:2022 (Annex A controls)                                        │
│    PCI-DSS v4.0                                                             │
│    GDPR (EU 2016/679)                                                       │
│    CCPA / CPRA (California)                                                 │
│                                                                              │
│  Control Status Values:                                                     │
│    COVERED   — SLB rule(s) fully satisfy the control requirement            │
│    PARTIAL   — SLB provides partial evidence; gap noted                     │
│    GAP       — Control not addressed by current SLB rule set               │
│    N/A       — Control not applicable to this tenant's scope               │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  3.1  SOC 2 Type II — Trust Service Criteria Mapping                        │
│                                                                              │
│  ┌────────────┬──────────────────────────────────────────┬──────────┬─────┐ │
│  │ SOC 2 CC   │ Criterion                                │ SLB Rule │ Cov │ │
│  ├────────────┼──────────────────────────────────────────┼──────────┼─────┤ │
│  │ CC6.1      │ Logical and physical access controls      │ HITL-001 │  ✅ │ │
│  │ CC6.2      │ Prior to issuing system credentials      │ FS-002   │  ✅ │ │
│  │ CC6.3      │ Role-based access restriction             │ HITL-001 │  ✅ │ │
│  │ CC6.6      │ Restrict access to authorized external   │ MCP-001  │  ⚠️ │ │
│  │            │ connections                               │ SI-001   │     │ │
│  │ CC6.7      │ Transmission of data                     │ CE-001   │  ✅ │ │
│  │ CC6.8      │ Prevent unauthorized software            │ SI-001   │  ✅ │ │
│  │            │                                          │ SI-002   │     │ │
│  │ CC7.1      │ Detect and monitor threats               │ All rules│  ✅ │ │
│  │ CC7.2      │ Monitor system components                │ HITL-001 │  ✅ │ │
│  │ CC7.3      │ Evaluate security events                 │ Audit log│  ✅ │ │
│  │ CC7.4      │ Respond to identified security incidents │ PSA/wbhk │  ✅ │ │
│  │ CC7.5      │ Recover from identified incidents        │ REST API │  ⚠️ │ │
│  │ CC8.1      │ Authorize changes to infrastructure      │ CG-001   │  ⚠️ │ │
│  │ CC9.2      │ Assess vendor and partner risk           │ SI-001-5 │  ✅ │ │
│  └────────────┴──────────────────────────────────────────┴──────────┴─────┘ │
│                                                                              │
│  ⚠️ PARTIAL = evidence generated by SLB but manual controls also required  │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  3.2  ISO 27001:2022 — Annex A Control Mapping                              │
│                                                                              │
│  ┌──────────┬────────────────────────────────────────────┬──────────┬─────┐ │
│  │ ISO Ctrl │ Control                                    │ SLB Rule │ Cov │ │
│  ├──────────┼────────────────────────────────────────────┼──────────┼─────┤ │
│  │ A.5.23   │ Information security for cloud services    │ MCP-001  │  ✅ │ │
│  │ A.5.30   │ ICT readiness for business continuity      │ Audit log│  ⚠️ │ │
│  │ A.6.3    │ Information security awareness             │ WARN UX  │  ⚠️ │ │
│  │ A.8.2    │ Privileged access rights                   │ HITL-001 │  ✅ │ │
│  │ A.8.5    │ Secure authentication                      │ HITL-001 │  ✅ │ │
│  │ A.8.8    │ Management of technical vulnerabilities    │ SI-001   │  ✅ │ │
│  │ A.8.16   │ Monitoring activities                      │ All rules│  ✅ │ │
│  │ A.8.19   │ Installation of software on oper. systems  │ SI-001-5 │  ✅ │ │
│  │ A.8.20   │ Networks security                          │ RS-001   │  ✅ │ │
│  │ A.8.22   │ Segregation of networks                    │ MCP-001  │  ✅ │ │
│  │ A.8.25   │ Secure development lifecycle               │ CG-001   │  ⚠️ │ │
│  │ A.8.28   │ Secure coding                              │ CG-001/2 │  ⚠️ │ │
│  │ A.8.29   │ Security testing in dev and acceptance     │ CG-002   │  ⚠️ │ │
│  └──────────┴────────────────────────────────────────────┴──────────┴─────┘ │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  3.3  PCI-DSS v4.0 — Requirement Mapping                                   │
│                                                                              │
│  ┌──────────────┬──────────────────────────────────────────┬────────┬─────┐ │
│  │ PCI Req      │ Requirement                              │ SLB    │ Cov │ │
│  ├──────────────┼──────────────────────────────────────────┼────────┼─────┤ │
│  │ Req 2.2      │ Develop config standards for all systems │ FS-002 │  ⚠️ │ │
│  │ Req 5.2      │ Malicious software protection            │ RS-001 │  ✅ │ │
│  │ Req 6.3      │ Security vulnerabilities identified      │ SI-001 │  ✅ │ │
│  │ Req 6.4      │ Public-facing web app protection         │ PI-001 │  ⚠️ │ │
│  │ Req 7.2      │ Least-privilege access control           │ HITL   │  ✅ │ │
│  │ Req 8.3      │ Multi-factor authentication              │ HITL   │  ⚠️ │ │
│  │ Req 10.2     │ Audit logs implemented                   │ Audit  │  ✅ │ │
│  │ Req 10.3     │ Audit logs protected from destruction    │ Immut. │  ✅ │ │
│  │ Req 10.4     │ Audit logs reviewed                      │ SOC UI │  ✅ │ │
│  │ Req 10.7     │ Failures of critical security controls   │ Health │  ✅ │ │
│  │ Req 11.5     │ Network intrusion detection              │ RS-001 │  ✅ │ │
│  │ Req 12.3     │ Targeted risk analysis                   │ QA Eng │  ✅ │ │
│  └──────────────┴──────────────────────────────────────────┴────────┴─────┘ │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  3.4  GDPR / CCPA — Article and Requirement Mapping                         │
│                                                                              │
│  ┌──────────────┬────────────────────────────────────────────┬────────────┐  │
│  │ Framework    │ Requirement                                │ SLB Cover. │  │
│  ├──────────────┼────────────────────────────────────────────┼────────────┤  │
│  │ GDPR Art.25  │ Data protection by design and by default   │ PII strip  │✅│  │
│  │ GDPR Art.32  │ Security of processing                     │ mTLS+Vault │✅│  │
│  │ GDPR Art.33  │ Notification of personal data breach       │ PSA ticket │✅│  │
│  │ GDPR Art.35  │ Data protection impact assessment          │ QA Engine  │⚠️│  │
│  │ CCPA §1798.81│ Reasonable security procedures             │ All rules  │✅│  │
│  │ CCPA §1798.82│ Notification of breach (45-day)           │ Integration│⚠️│  │
│  └──────────────┴────────────────────────────────────────────┴────────────┘  │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Evidence Store                                                             │
│                                                                              │
│  Every detection event is linked to one or more compliance controls.        │
│  Evidence records are immutable and exportable.                             │
│                                                                              │
│  evidence_record:                                                           │
│  {                                                                          │
│    "evidence_id":    "ev_abc123",                                           │
│    "event_id":       "SLB-uuid",                                            │
│    "rule_id":        "CE-001",                                              │
│    "timestamp":      "ISO-8601",                                            │
│    "action":         "BLOCK",                                               │
│    "frameworks": [                                                          │
│      { "name": "SOC2",    "control": "CC6.7", "status": "COVERED" },       │
│      { "name": "PCI-DSS", "control": "Req 10.2", "status": "COVERED" }    │
│    ],                                                                       │
│    "exportable": true                                                       │
│  }                                                                          │
│                                                                              │
│  Export formats: PDF audit report · CSV evidence table · JSON (API)         │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. New Component: Risk Register

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                            Risk Register                                     │
│                                              ← NEW in v7                    │
│                                                                              │
│  GRC-style risk register. Every risk item has a lifecycle:                  │
│  Identified → Assessed → Owner Assigned → Mitigated → Accepted / Closed     │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Risk Item Schema                                                   │    │
│  │                                                                     │    │
│  │  risk_id:          "RISK-0042"                                      │    │
│  │  title:            "Unprotected developer machines (3 of 25)"       │    │
│  │  source:           "posture_engine" | "detection_event" |           │    │
│  │                    "compliance_gap" | "data_upload" | "manual"      │    │
│  │  category:         "ai-agent" | "access" | "data" | "supply-chain" │    │
│  │                    | "compliance" | "infrastructure"                │    │
│  │  likelihood:       1–5  (1=Rare, 5=Almost Certain)                 │    │
│  │  impact:           1–5  (1=Negligible, 5=Critical)                 │    │
│  │  risk_score:       likelihood × impact  (1–25)                     │    │
│  │  risk_level:       "Low" | "Medium" | "High" | "Critical"          │    │
│  │  owner:            "alice@acme.com"   (nullable — triggers alert)  │    │
│  │  status:           "open" | "mitigating" | "accepted" | "closed"   │    │
│  │  mitigation_plan:  "Deploy hook agent to 3 remaining machines"     │    │
│  │  target_date:      "2026-06-30"                                     │    │
│  │  linked_events:    ["SLB-uuid1", "SLB-uuid2"]                      │    │
│  │  linked_controls:  ["SOC2:CC6.1", "ISO:A.8.16"]                   │    │
│  │  created_at:       "ISO-8601"                                       │    │
│  │  updated_at:       "ISO-8601"                                       │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Automatic Risk Creation — Detection Events                         │    │
│  │                                                                     │    │
│  │  Trigger: CRITICAL or HIGH verdict with no linked open risk         │    │
│  │  Action:  New risk item auto-created (source: detection_event)      │    │
│  │                                                                     │    │
│  │  Mapping:                                                           │    │
│  │  CE-001 BLOCK   → category=data,          likelihood=4, impact=5   │    │
│  │  RS-001 KILL    → category=infrastructure, likelihood=5, impact=5   │    │
│  │  HITL-001 WARN  → category=ai-agent,       likelihood=3, impact=4   │    │
│  │  SI-001 BLOCK   → category=supply-chain,   likelihood=4, impact=4   │    │
│  │  MCP-001 BLOCK  → category=access,         likelihood=3, impact=3   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Automatic Risk Creation — Compliance Gaps                          │    │
│  │                                                                     │    │
│  │  Trigger: Compliance Framework Layer identifies GAP on a control   │    │
│  │  Action:  New risk item auto-created (source: compliance_gap)       │    │
│  │                                                                     │    │
│  │  Example:                                                           │    │
│  │    SOC 2 CC6.6 GAP detected →                                       │    │
│  │    risk: "SOC 2 CC6.6 — External connection control gap"           │    │
│  │    likelihood=3, impact=4, category=compliance                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Automatic Risk Creation — Company Data Uploads                     │    │
│  │                                                                     │    │
│  │  Trigger: Operator uploads company data file (see §6)              │    │
│  │  Action:  Data Ingestion Pipeline extracts risk signals →           │    │
│  │           creates or updates risk items (source: data_upload)       │    │
│  │                                                                     │    │
│  │  Extractable signals from uploads:                                  │    │
│  │    Asset inventory → identify unprotected dev machines             │    │
│  │    Org chart → identify developers with no hook assignment         │    │
│  │    Policy docs → identify compliance scope + in/out-of-scope items │    │
│  │    Incident history → backfill prior risk items for context        │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  Dedup: risks with same category + linked_control within 7 days → merged   │
│  Alerts: unowned risk for > 48h → PSA ticket created + webhook fired        │
│  Export: CSV · PDF · JSON (REST API)                                        │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. New Component: Data Ingestion Pipeline

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                      Data Ingestion Pipeline                                 │
│                                              ← NEW in v7                    │
│                                                                              │
│  Accepts company data uploads from operators. Extracts structured signals   │
│  that update the Risk Register, Compliance Framework Layer, and Posture     │
│  Engine without manual data entry.                                          │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Supported Upload Types                                             │    │
│  │                                                                     │    │
│  │  Type              Format              Extracts                     │    │
│  │  ─────────────── ─────────────────── ──────────────────────────── │    │
│  │  Asset Inventory  CSV / XLSX / JSON   Device list, OS, owner       │    │
│  │  Org Chart        CSV / XLSX          Dev team members, roles      │    │
│  │  Security Policy  PDF / DOCX          Scope, controls claimed      │    │
│  │  Incident History CSV / XLSX          Prior incidents → risks      │    │
│  │  Vendor List      CSV / XLSX          Third-party risk signals     │    │
│  │  SOC 2 Report     PDF                 Existing control evidence    │    │
│  │  Pen Test Report  PDF                 Open findings → risk items   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Pipeline Steps                                                     │    │
│  │                                                                     │    │
│  │  1. Upload:   Operator uploads file via dashboard or REST API      │    │
│  │  2. Validate: File type + size check (max 50MB per file)           │    │
│  │  3. Extract:  Structured extractor per file type                   │    │
│  │               PDF → text + LLM extraction (Claude API, off-path)  │    │
│  │               CSV/XLSX → column mapper + row normalizer            │    │
│  │               JSON → schema validator + field mapper               │    │
│  │  4. Classify: Extracted items → risk signal type                   │    │
│  │  5. Write:    Signals → Risk Register (create/update/merge)        │    │
│  │  6. Notify:   Operator notified: "Upload processed: 12 risk items  │    │
│  │               created, 3 updated, 0 errors"                        │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  Privacy:                                                                   │
│  - Uploaded files never stored beyond processing window (deleted after 1h) │
│  - Extracted signals stored as structured records only (no raw file)       │
│  - PII in uploads (emails, names) → hashed before storage                 │
│  - PDF text never sent to external LLM API (all extraction runs locally   │
│    using embedded model; Claude API is used only for structured parsing,  │
│    not storage)                                                            │
│                                                                              │
│  Upload endpoint:  POST /v1/data-upload (REST API v1 write scope)          │
│  Status endpoint:  GET  /v1/data-upload/{job_id}                           │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. New Component: Quick Actions Engine

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Quick Actions Engine                                  │
│                                              ← NEW in v7                    │
│                                                                              │
│  On-demand workflows that produce structured reports and dashboard updates. │
│  Triggered from the dashboard, REST API, or AI Chat.                       │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Quick Action: Risk Assessment                                      │    │
│  │                                                                     │    │
│  │  Trigger:  Button in dashboard / POST /v1/actions/risk-assessment  │    │
│  │  Runtime:  < 30 seconds                                             │    │
│  │                                                                     │    │
│  │  Steps:                                                             │    │
│  │  1. Snapshot current posture score + dimensions                    │    │
│  │  2. Pull all open risk register items                              │    │
│  │  3. Pull active compliance gaps (all frameworks)                   │    │
│  │  4. Pull last 30 days of CRITICAL + HIGH detection events          │    │
│  │  5. Pull hook coverage % per device group                          │    │
│  │  6. Rank risks by score (likelihood × impact)                      │    │
│  │  7. Generate: executive summary + top 10 risks + recommended       │    │
│  │     remediations ordered by risk reduction per effort              │    │
│  │                                                                     │    │
│  │  Output:                                                            │    │
│  │    Dashboard update (risk assessment widget refreshed)             │    │
│  │    PDF report (downloadable, branded, date-stamped)                │    │
│  │    JSON response (for API consumers / SOAR playbooks)              │    │
│  │                                                                     │    │
│  │  Report sections:                                                   │    │
│  │    1. Executive Summary (posture score, trend, band)               │    │
│  │    2. Top Risks (ranked, with owner + target date if set)          │    │
│  │    3. Threat Landscape (last 30d events by rule, severity, dev)    │    │
│  │    4. Compliance Gaps Summary (per framework)                      │    │
│  │    5. Recommended Next Actions (ordered by impact)                 │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Quick Action: SOC 2 Readiness Check                                │    │
│  │                                                                     │    │
│  │  Trigger:  Button in dashboard / POST /v1/actions/soc2-readiness   │    │
│  │  Runtime:  < 60 seconds                                             │    │
│  │                                                                     │    │
│  │  Steps:                                                             │    │
│  │  1. Load SOC 2 control map from Compliance Framework Layer         │    │
│  │  2. For each TSC criterion: compute coverage status                │    │
│  │  3. Pull evidence records linked to each criterion                 │    │
│  │  4. Count: COVERED / PARTIAL / GAP / N/A per category             │    │
│  │  5. Compute readiness % = COVERED / (COVERED + PARTIAL + GAP)     │    │
│  │  6. Flag criteria with zero evidence in last 90 days              │    │
│  │  7. Generate readiness report                                      │    │
│  │                                                                     │    │
│  │  Output:                                                            │    │
│  │    Readiness score: e.g., "SOC 2 — 74% ready"                     │    │
│  │    Per-criterion status table (CC6.1 ✅ CC6.6 ⚠️ CC8.1 ⚠️ ...)    │    │
│  │    Gap list with specific recommended actions                      │    │
│  │    PDF report (auditor-ready format)                               │    │
│  │    Risk register: new items created for each GAP                  │    │
│  │                                                                     │    │
│  │  Readiness bands:                                                   │    │
│  │    90–100%   Audit-ready. Engage your auditor.                     │    │
│  │    75–89%    Nearly ready. Close remaining gaps first.             │    │
│  │    50–74%    Significant gaps. Focus on CC6 and CC7 first.        │    │
│  │    < 50%     Not ready. Run Risk Assessment first.                 │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Additional Quick Actions (v7 — at launch)                         │    │
│  │                                                                     │    │
│  │  ISO 27001 Gap Analysis    POST /v1/actions/iso27001-gap           │    │
│  │  PCI-DSS Scope Check       POST /v1/actions/pcidss-scope           │    │
│  │  GDPR Data Flow Review     POST /v1/actions/gdpr-review            │    │
│  │  Hook Coverage Audit       POST /v1/actions/coverage-audit         │    │
│  │  Policy Completeness Check POST /v1/actions/policy-check           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  Rate limit: 1 Quick Action per type per tenant per hour (prevents abuse)  │
│  All Quick Action runs logged in audit trail                               │
│  MSSP: can run Quick Actions on behalf of any client tenant                │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. New Component: AI Compliance Chat

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         AI Compliance Chat                                   │
│                                              ← NEW in v7                    │
│                                                                              │
│  LLM-powered conversational interface grounded entirely in the tenant's     │
│  own data — detection events, posture score, risk register, compliance      │
│  coverage, and policy. No hallucination of controls that do not exist.     │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Context Injected Per Query (retrieval-augmented)                   │    │
│  │                                                                     │    │
│  │  - Current posture snapshot (score, band, dimensions, top gaps)    │    │
│  │  - Last 30 days: event counts by rule, severity, top rules fired   │    │
│  │  - Open risk register items (top 20 by risk score)                 │    │
│  │  - Compliance coverage per framework (control status table)        │    │
│  │  - Active policy.yaml (rules enabled, thresholds)                  │    │
│  │  - Hook coverage % and unprotected machine count                   │    │
│  │                                                                     │    │
│  │  NOT injected:                                                      │    │
│  │    - Raw prompt/completion payloads (never stored after analysis)  │    │
│  │    - Developer PII (hashed IDs only)                               │    │
│  │    - PSA/SIEM credentials                                          │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Example Questions the Chat Can Answer                              │    │
│  │                                                                     │    │
│  │  Posture & Events:                                                  │    │
│  │   "What is our current security posture score and why?"            │    │
│  │   "What were our top 3 security incidents last month?"             │    │
│  │   "Which developer has the most blocked events this week?"         │    │
│  │   "Why did our posture score drop this week?"                      │    │
│  │                                                                     │    │
│  │  Compliance:                                                        │    │
│  │   "Are we ready for a SOC 2 Type II audit?"                        │    │
│  │   "What are our gaps for ISO 27001?"                               │    │
│  │   "Which PCI-DSS requirements are we not meeting?"                 │    │
│  │   "What evidence do we have for SOC 2 CC6.7?"                      │    │
│  │   "What do we need to fix to meet GDPR Article 32?"                │    │
│  │                                                                     │    │
│  │  Risk:                                                              │    │
│  │   "What are our top 5 open risks right now?"                       │    │
│  │   "Which risks have no owner assigned?"                            │    │
│  │   "What is the risk of deploying an unregistered skill?"           │    │
│  │                                                                     │    │
│  │  Remediation:                                                       │    │
│  │   "What should we fix first to improve our posture score?"         │    │
│  │   "What steps do I take to close the SOC 2 CC6.6 gap?"            │    │
│  │   "How do I configure the HITL-001 rule to block instead of warn?" │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Technical Spec                                                     │    │
│  │                                                                     │    │
│  │  LLM:         Claude API (claude-sonnet-4-6 — balanced speed/cost) │    │
│  │  Pattern:     RAG — context retrieved from tenant data store,      │    │
│  │               injected into system prompt per query                 │    │
│  │  Max context: 8K tokens per query (posture + risks + compliance)   │    │
│  │  Caching:     Prompt prefix cached (posture snapshot) — reduces    │    │
│  │               latency and cost on repeated queries                 │    │
│  │  Latency:     < 5s p90 for first token                            │    │
│  │  Streaming:   Yes — tokens streamed to UI as generated             │    │
│  │                                                                     │    │
│  │  Access:      Role-gated — Admin and Analyst roles only            │    │
│  │  Rate limit:  20 queries per user per hour                         │    │
│  │  Audit:       Every query + response logged (tenant audit trail)   │    │
│  │                                                                     │    │
│  │  Guardrails:                                                        │    │
│  │   - Will not make compliance certification claims                  │    │
│  │   - Will not provide remediation that contradicts policy.yaml      │    │
│  │   - Responses cite the specific data points used (source-linked)   │    │
│  │   - Off-topic queries (non-security/compliance) redirected politely│    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  Interface:                                                                 │
│    Dashboard chat panel (right sidebar) — persistent per session           │
│    REST API: POST /v1/chat (returns streamed response)                     │
│    Suggested prompts shown on first open (4 quick-start questions)         │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Updated Observability Plane (v7)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                    OBSERVABILITY PLANE v7                                    │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Live Security Posture Dashboard            ← NEW in v7             │   │
│  │                                                                      │   │
│  │  Layout:                                                             │   │
│  │  ┌──────────────┐ ┌────────────────────────┐ ┌──────────────────┐  │   │
│  │  │ Posture Score│ │ Compliance Coverage     │ │ Quick Actions    │  │   │
│  │  │              │ │ SOC2:  74%  ██████░░░░ │ │                  │  │   │
│  │  │     74       │ │ ISO27: 68%  ██████░░░░ │ │ Risk Assessment  │  │   │
│  │  │    GOOD      │ │ PCI:   81%  ████████░░ │ │ SOC2 Readiness   │  │   │
│  │  │  ↑+3 (7d)   │ │ GDPR:  91%  █████████░ │ │ ISO27001 Gap     │  │   │
│  │  └──────────────┘ └────────────────────────┘ │ Coverage Audit   │  │   │
│  │                                               └──────────────────┘  │   │
│  │  ┌──────────────────────────────────────────────────────────────┐   │   │
│  │  │ Top Gaps (live, from Posture Engine)                         │   │   │
│  │  │ ⚠️  3 developer machines without hook agent                 │   │   │
│  │  │ ⚠️  SOC 2 CC6.6 — partial (MCP-001 not enabled)            │   │   │
│  │  │ ⚠️  2 HIGH risks with no assigned owner                     │   │   │
│  │  └──────────────────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  SOC Dashboard (v6 — unchanged)                                      │   │
│  │  Live event feed · Alert triage · HITL console · Skill map          │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Compliance Tracker                         ← NEW in v7             │   │
│  │  Per-framework control status table · Evidence viewer · Gap list    │   │
│  │  Evidence export (PDF / CSV) · Audit-ready report generator         │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Risk Register UI                           ← NEW in v7             │   │
│  │  Risk table (sortable by score, owner, status) · Risk detail view   │   │
│  │  Create / update / close risk items · Link events · Export          │   │
│  │  Upload trigger (drag-and-drop company data files)                  │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  AI Compliance Chat                         ← NEW in v7             │   │
│  │  Persistent chat sidebar · Streaming responses · Source citations   │   │
│  │  Suggested prompts · Query history (session-scoped)                 │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Integration Health Dashboard (v6 — unchanged)                       │   │
│  │  PSA sync · SIEM delivery · Webhook status · API usage              │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Updated REST API v1 — New v7 Endpoints

All v6 endpoints unchanged. New endpoints added:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                     REST API v1 — v7 Additions                               │
│                                                                              │
│  Posture                                                                    │
│  GET  /v1/posture                                                           │
│       Current posture snapshot (score, band, dimensions, top gaps)          │
│                                                                              │
│  GET  /v1/posture/history?days=90                                           │
│       Posture score history (daily snapshots, up to 12 months)              │
│                                                                              │
│  Compliance                                                                 │
│  GET  /v1/compliance                                                        │
│       All frameworks — coverage % and control status summary                │
│                                                                              │
│  GET  /v1/compliance/{framework}                                            │
│       Full control status table for one framework (soc2|iso27001|pcidss|gdpr│
│       |ccpa)                                                                │
│                                                                              │
│  GET  /v1/compliance/{framework}/evidence                                   │
│       All evidence records linked to this framework's controls              │
│                                                                              │
│  GET  /v1/compliance/{framework}/report                                     │
│       Download PDF compliance report for the framework                     │
│                                                                              │
│  Risk Register                                                              │
│  GET  /v1/risks                                                             │
│       All open risk items (filterable by status, level, owner, category)   │
│                                                                              │
│  GET  /v1/risks/{risk_id}                                                   │
│       Full risk item detail                                                 │
│                                                                              │
│  POST /v1/risks                                                             │
│       Create a manual risk item                                             │
│                                                                              │
│  PATCH /v1/risks/{risk_id}                                                  │
│       Update risk item (owner, status, mitigation plan, target date)       │
│                                                                              │
│  POST /v1/risks/{risk_id}/close                                             │
│       Close a risk item (requires resolution note)                         │
│                                                                              │
│  Quick Actions                                                              │
│  POST /v1/actions/risk-assessment                                           │
│       Trigger risk assessment. Returns job_id. Poll for completion.        │
│                                                                              │
│  POST /v1/actions/soc2-readiness                                            │
│       Trigger SOC 2 readiness check. Returns job_id.                       │
│                                                                              │
│  POST /v1/actions/iso27001-gap                                              │
│  POST /v1/actions/pcidss-scope                                              │
│  POST /v1/actions/gdpr-review                                               │
│  POST /v1/actions/coverage-audit                                            │
│  POST /v1/actions/policy-check                                              │
│                                                                              │
│  GET  /v1/actions/{job_id}                                                  │
│       Poll action status (pending | running | complete | failed)           │
│                                                                              │
│  GET  /v1/actions/{job_id}/report                                           │
│       Download action output report (PDF or JSON)                          │
│                                                                              │
│  Data Upload                                                                │
│  POST /v1/data-upload                                                       │
│       Upload company data file (multipart/form-data, max 50MB)             │
│                                                                              │
│  GET  /v1/data-upload/{job_id}                                              │
│       Poll upload processing status                                         │
│                                                                              │
│  AI Chat                                                                    │
│  POST /v1/chat                                                              │
│       Send a compliance/security question. Streams response tokens.        │
│       Body: { "message": "Are we SOC 2 ready?" }                           │
│       Returns: text/event-stream (SSE)                                     │
│                                                                              │
│  GET  /v1/chat/history                                                      │
│       Retrieve chat history for current session (last 50 exchanges)        │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 10. Updated Architecture Comparison: v1 → v7

| Dimension | v5 | v6 | v7 |
|-----------|----|----|----|
| Security posture | Event feed only | Event feed + integration health | **Live posture score (0–100) + trend + gaps** |
| Compliance frameworks | None | ATT&CK only | **SOC 2 · ISO 27001 · PCI-DSS v4 · GDPR · CCPA** |
| Compliance evidence | None | None | **Auto-linked per detection event** |
| Risk register | None | None | **GRC risk items, auto-created + data-upload** |
| Quick actions | None | None | **Risk Assessment · SOC2 Readiness + 5 more** |
| AI chat | None | None | **RAG-grounded compliance Q&A (Claude API)** |
| Data ingestion | None | None | **Asset inventory, org chart, policy docs, reports** |
| Dashboard | SOC event feed | SOC + integration health | **Posture · Compliance · Risk Register · Chat** |
| Report generation | None | None | **PDF: Risk Assessment, SOC 2, ISO 27001, PCI-DSS** |
| API scope | v6 endpoints | v6 endpoints | **+ posture · compliance · risk · actions · chat** |

---

## 11. Security Properties — New in v7

| Property | How achieved |
|----------|--------------|
| **No PII in AI Chat context** | Developer IDs remain hashed; raw payloads never stored or injected into LLM |
| **No compliance claims** | Chat guardrails prevent the LLM from stating certification is achieved |
| **No external LLM on raw data** | PDF extraction uses local embedded model; only structured signals go to Claude API |
| **Uploaded files purged** | Raw upload deleted within 1 hour of processing; only extracted structured records retained |
| **Chat audit trail** | Every query and response logged immutably per tenant |
| **Quick Action rate limiting** | 1 action per type per tenant per hour prevents resource abuse |
| **Role-gated Chat and Actions** | Admin and Analyst roles only; Read-only role cannot trigger actions or chat |

---

## 12. Updated Roadmap (v7)

| Phase | Milestone | Target |
|-------|-----------|--------|
| v0.6–v0.11 | v6 milestones: Integration Bus, PSA, SIEM, ATT&CK, REST API, RMM | Q1–Q2 2027 |
| v1.0 | Full v6 platform launch | Q2 2027 |
| **v1.5 (new)** | **Security Posture Engine + Live Posture Dashboard** | **Q3 2027** |
| **v1.6 (new)** | **Compliance Framework Layer: SOC 2 + ISO 27001 mapping + evidence store** | **Q3 2027** |
| **v1.7 (new)** | **Risk Register + Data Ingestion Pipeline** | **Q4 2027** |
| **v1.8 (new)** | **Quick Actions: Risk Assessment + SOC 2 Readiness Check** | **Q4 2027** |
| **v1.9 (new)** | **AI Compliance Chat (RAG, Claude API, streaming)** | **Q1 2028** |
| **v2.0 (new)** | **PCI-DSS v4 + GDPR + CCPA compliance layers + remaining Quick Actions** | **Q1 2028** |
| v2.1 | Own Skill Registry public API | Q2 2028 |
| v2.2 | Microsoft MISA + Azure Marketplace + Splunkbase | Q2 2028 |

---

## 13. Document Index (v7 additions)

| Document | Description |
|----------|-------------|
| `ARCHITECTURE_V7.md` | ← this file — v7 canonical architecture |
| `ARCHITECTURE_V6.md` | v6 — Integration-first platform (basis for v7) |
| `ARCHITECTURE_V5.md` | v5 — Independence + full detection |
| `mvp-v1/MVParchitecture_v1.md` | MVP v1 — smallest shippable subset |
| `mvp-v1/SD suggestions for POC.md` | POC plan for customer demos |

---

*Security Layer-Basis — Architecture v7.0*  
*GRC-first: posture scoring, compliance frameworks, risk register, quick actions, AI compliance chat*  
*Basis: v6.0 (Integration-first platform) — detection engine and all integrations unchanged*  
*SOC 2 · ISO 27001 · PCI-DSS v4 · GDPR · CCPA*  
*Quick Actions: Risk Assessment · SOC 2 Readiness Check · ISO 27001 Gap · PCI-DSS Scope · GDPR Review*  
*AI Chat: RAG-grounded, Claude API, streaming, audit-logged*  
*Architecture by Sharon*  
*Last updated: 2026-05-16*
