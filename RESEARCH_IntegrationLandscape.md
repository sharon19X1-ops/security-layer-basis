# Integration Landscape Research Report
## How to Turn Security Layer-Basis into a Platform That Plugs Into Any MSP/MSSP/SMB Stack

**Date:** 2026-04-20  
**Scope:** Current SMB/MSP/MSSP security tool ecosystem — integration patterns, API models, partner programs, technical standards  
**Purpose:** Define the integration architecture for Security Layer-Basis to become a native citizen in any existing IT security stack

---

## Part 1 — The Market We're Entering

### 1.1 The Stack Every MSP/SMB Runs

Before we talk integration, we need to know what we're integrating *into*. The SMB/MSP stack in 2026 has five functional layers:

```
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 5: BUSINESS OPERATIONS                                   │
│  PSA (Professional Services Automation)                         │
│  ConnectWise PSA · Autotask (Datto) · HaloPSA · Syncro         │
│  → Ticketing, billing, client management, SLA tracking         │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 4: DEVICE MANAGEMENT                                     │
│  RMM (Remote Monitoring & Management)                           │
│  NinjaOne · N-able · Kaseya VSA · Datto RMM · ConnectWise RMM  │
│  → Endpoint monitoring, patching, remote access, scripting     │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 3: SECURITY DETECTION                                    │
│  EDR / MDR / XDR                                                │
│  SentinelOne · CrowdStrike · Huntress · Defender for Business  │
│  → Endpoint threat detection, managed SOC, incident response   │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 2: SECURITY VISIBILITY                                   │
│  SIEM / Log Management                                          │
│  Microsoft Sentinel · Splunk · Elastic · Huntress SIEM         │
│  → Log correlation, threat intel, compliance reporting         │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 1: IDENTITY & ACCESS                                     │
│  IAM / ITDR                                                     │
│  Azure AD / Entra · Okta · Google Workspace · Duo              │
│  → User identity, MFA, access control, identity threat         │
└─────────────────────────────────────────────────────────────────┘
```

**Where Security Layer-Basis fits:** We are a new Layer 3+ capability — AI coding agent threat interception — that doesn't exist in any current layer. Our integration challenge: attach to all five layers *simultaneously* so we become a natural part of the existing workflow rather than a new silo.

---

### 1.2 The #1 Market Signal: Integration IS the Product

From Acronis MSP Integration Trends 2025 report (Feb 2026):

> **Security integration adoption grew 123% year-over-year — fastest growing category.**  
> XDR and MDR integrations grew 162%. General-purpose automation (Zapier) grew 146%.

Key insight: **MSPs manage 20+ tools on average. They are not buying more tools — they are buying better integration.** The differentiator in 2026 is not "does your tool detect threats" but "does your tool speak my stack's language."

Implication for us: **Integration is not a feature we add later. It is the go-to-market.**

---

## Part 2 — How "All-Around Players" Actually Integrate

Researched integration patterns from: Huntress, Guardz, SentinelOne, CrowdStrike, Acronis, NinjaOne, N-able, ConnectWise, Autotask, Microsoft Sentinel, Splunk.

### 2.1 The 5 Integration Patterns Every Security Vendor Uses

**Pattern 1: Alert-to-Ticket (PSA Integration)**
> The most common, most expected integration. Security event → PSA ticket, automatically.

How it works:
- Security vendor detects a threat
- Calls ConnectWise/Autotask/HaloPSA REST API
- Creates a service ticket with: severity, description, affected device, recommended remediation
- Optionally: updates ticket status when threat is resolved, closes ticket
- MSP never leaves their PSA — security events appear as tickets they already know how to handle

Examples: Huntress → ConnectWise/Autotask. Guardz → ConnectWise. SaaS Alerts → ConnectWise.  
Technical mechanism: PSA REST API + API key/secret pair issued by MSP admin.

**Pattern 2: Agent Deploy via RMM (RMM Integration)**
> Security vendor provides a deployment script. MSP pushes it via their RMM to all managed endpoints in one click.

How it works:
- Security vendor provides a PowerShell/Bash script with their agent embedded
- MSP uploads script to their RMM (NinjaOne, Datto RMM, N-able, Kaseya)
- RMM deploys to all endpoints under management
- No per-endpoint manual install — scales across 1,000 endpoints instantly
- Status reported back: "Huntress agent installed on 847/847 endpoints"

Examples: Huntress provides deployment scripts for Datto RMM, NinjaOne, Syncro, Kaseya, N-able.  
Technical mechanism: Platform-specific deployment script + RMM webhook/callback for status.

**Pattern 3: Event Forwarding to SIEM (SIEM Integration)**
> Security events pushed to the customer's SIEM for correlation, compliance, and long-term retention.

How it works:
- Three transport options (in order of prevalence):
  1. **REST API pull** — SIEM polls vendor API for new events (Microsoft Sentinel, Elastic model)
  2. **Syslog/CEF push** — vendor forwards events as CEF-formatted syslog to SIEM collector
  3. **Webhook push** — vendor POSTs structured JSON to SIEM webhook endpoint on event
- Event format standards: **CEF** (Common Event Format, ArcSight) or **LEEF** (Log Event Extended Format, IBM QRadar) or vendor-native JSON
- Most SIEMs (Sentinel, Splunk, Elastic, QRadar) have pre-built connectors that map vendor event fields to their schema

Examples: CrowdStrike → Splunk (official app). SentinelOne → Microsoft Sentinel connector. Huntress → any SIEM via syslog/CEF.  
Technical mechanism: REST API + OAuth2 or API key; or syslog/UDP/TLS to collector agent.

**Pattern 4: Bidirectional Platform API (Deep Integration)**
> Full programmatic access — not just event push, but query, configure, and act on the security platform from external tools.

How it works:
- Vendor publishes a documented REST API
- Partners build their own integrations using the API
- Used by: automation platforms (Rewst, Zapier), SOAR playbooks, custom MSP dashboards
- Auth: OAuth2 / API key
- Rate limits, versioning, sandbox environments

Examples: CrowdStrike Falcon API (extensive marketplace). Huntress REST API (used by Rewst for automation). N-able Developer Portal (AI-powered, launched Feb 2025).  
Technical mechanism: Full OpenAPI spec, sandbox, webhook subscriptions, REST CRUD.

**Pattern 5: Marketplace Listing + Partner Certification**
> Vendor is listed in the platform's official marketplace/app store, certified, and promoted.

How it works:
- **ConnectWise Invent Program**: Security review + certification → listed on ConnectWise Marketplace → ConnectWise promotes to 30,000 MSP partners. Tier 1 integration support. Requires passing independent security review.
- **N-able Technology Alliance Program (TAP)**: API access, dev tools, documentation, use cases, product training. Listed on N-able partner directory.
- **Kaseya Marketplace**: Listed, supported, co-marketed.
- **NinjaOne Integrations**: API-based, listed in their integrations directory.
- Marketplace listing = distribution. MSPs trust vetted marketplace tools far more than cold outreach.

Examples: Guardz → ConnectWise Invent (certified Jul 2024). EasyDMARC → ConnectWise Invent (Mar 2026). Huntress → NinjaOne, Datto, Syncro, Kaseya all listed.

---

### 2.2 The PSA Integration Deep Dive (Most Critical)

ConnectWise PSA is the most common MSP PSA (~40% market share). Integration works like this:

```
Security Event (our engine)
        │
        ▼
POST https://api.connectwise.com/v4_6_release/apis/3.0/service/tickets
Headers:
  Authorization: Basic {base64(companyId+publicKey:privateKey)}
  Content-Type: application/json

Body:
{
  "summary": "[AI Security] Prompt injection blocked — Dev: alice@acme.com",
  "board": { "id": 1 },
  "company": { "id": 250 },
  "status": { "id": 1 },
  "priority": { "id": 3 },
  "severity": "High",
  "initialDescription": "...",
  "customFields": [
    { "id": 1, "value": "PI-001" },          // rule ID
    { "id": 2, "value": "BLOCK" },            // action taken
    { "id": 3, "value": "alice@acme.com" }    // developer
  ]
}
```

**Autotask PSA** works similarly via their REST API.  
**HaloPSA** — REST API, ticket creation endpoint.  
**Syncro** — REST API, same pattern.

All PSAs support: ticket creation, ticket update, ticket closure, priority/severity mapping, custom fields, company/contact association.

---

### 2.3 The SIEM Integration Deep Dive

The three SIEM giants and how they receive security events:

**Microsoft Sentinel:**
- Preferred: REST API to Log Analytics workspace (custom log ingestion endpoint)
- Also: CEF via AMA (Azure Monitor Agent) as syslog forwarder
- Data Connector API: vendors apply to be listed as an official Sentinel data connector
- Format: JSON + Log Analytics schema

**Splunk:**
- Preferred: HTTP Event Collector (HEC) — REST endpoint accepting JSON events
- Also: Splunk Add-on (TA) published to Splunkbase
- Format: Splunk CIM (Common Information Model) normalized fields

**Elastic/OpenSearch:**
- Preferred: Elastic integration package (published to Elastic Package Registry)
- REST API to Elasticsearch ingest endpoint
- Format: ECS (Elastic Common Schema)

**QRadar:**
- LEEF format via syslog
- DSM (Device Support Module) for custom log parsing

---

### 2.4 How RMM Deployment Works in Practice

For a security vendor to deploy via RMM:

**NinjaOne:** Script library → PowerShell/Bash → deploy to device groups  
**N-able N-sight/N-central:** Automation Manager → device policy → script deploy  
**Datto RMM:** Component Library → ComStore → deploy component  
**Kaseya VSA:** Agent Procedure → script → deploy on schedule or trigger  

Our hook agent (the IDE interceptor) is not an endpoint agent — it's a developer workstation tool. This changes the deployment vector:
- RMM deploys to managed workstations (which includes developer machines)
- Our hook installs as: VS Code extension + NinjaOne/Datto deployment script for the gateway component
- This is the **developer workstation → RMM** integration path, not the server/endpoint path

---

## Part 3 — What "Offering Your API for Integration" Actually Means

Studied: CrowdStrike Falcon API, Huntress API (via Rewst docs), N-able Developer Portal, ConnectWise Invent API model.

### 3.1 The Vendor API Maturity Ladder

```
Level 1: Webhook out         → POST events to customer-configured URL
Level 2: REST API (read)     → GET events, alerts, verdicts via API key
Level 3: REST API (full)     → GET + POST (configure, manage, act)
Level 4: OAuth2 + scopes     → Delegated access, partner apps, user-level auth
Level 5: Partner program     → SDK, sandbox, certification, marketplace listing
```

**Where new security vendors start:** Level 1 + 2  
**Where Huntress/Guardz are:** Level 3 + 4  
**Where CrowdStrike is:** Level 5 (full marketplace, 300+ partner apps)

Our target starting position: **Level 2 + 3** — sufficient for PSA and SIEM integrations from day 1. Level 4 + 5 as we scale.

---

### 3.2 What PSA Partners Need From Our API

From ConnectWise Invent program requirements and Guardz/Huntress integration docs:

| Requirement | Why They Need It |
|---|---|
| Company/tenant identifier per event | Map our events to the right PSA client |
| Severity levels (Critical/High/Medium/Low) | Drive PSA ticket priority automatically |
| Human-readable description | Fills ticket body without manual writing |
| Rule/policy ID + name | Compliance reference in ticket |
| Developer identifier (user@domain) | Associates ticket with the right resource |
| Device/workstation identifier | Maps to PSA configuration item |
| Timestamp (ISO-8601) | SLA clock starts at event time, not ticket creation |
| Recommended action / remediation step | Saves MSP from researching the fix |
| Dedup key | Prevents duplicate tickets for the same ongoing event |
| Resolution webhook | Auto-closes ticket when threat is resolved |

---

### 3.3 What SIEM Partners Need From Our API

| Requirement | Why They Need It |
|---|---|
| Normalized event schema | Maps to CEF / ECS / Splunk CIM without custom parsing |
| Event category (injection / exfil / skill / memory / completion) | SIEM correlation rules need typed categories |
| MITRE ATT&CK mapping | Every SIEM dashboard uses ATT&CK framework |
| Source/destination (developer machine, target endpoint) | Network topology in SIEM |
| Confidence score (ML model output) | SIEM uses this for alert severity weighting |
| Session/correlation ID | Links multiple events from the same attack chain |
| Raw payload hash (not content) | Forensic evidence without leaking actual code |

---

### 3.4 What RMM Partners Need From Our API

| Requirement | Why They Need It |
|---|---|
| Deployment script (PS1 + Shell) | One-click deploy via RMM automation |
| Agent health status endpoint | RMM monitors if our hook is running on each endpoint |
| Agent version + update mechanism | RMM manages updates like it manages all other agents |
| Policy sync endpoint | MSP sets policy in their RMM, we pull it |
| Per-device status (active/inactive/blocked) | RMM dashboard shows security posture per device |

---

## Part 4 — The Partner Program Landscape

### 4.1 Certified Programs We Need to Enter (Priority Order)

| Program | Platform | Members | Why Critical |
|---|---|---|---|
| **ConnectWise Invent** | ConnectWise PSA/RMM | 30,000+ MSPs | Largest MSP PSA ecosystem. Certification = trust + distribution |
| **N-able TAP** | N-able N-central/N-sight | Large MSP base | Developer portal launched Feb 2025, actively onboarding ISVs |
| **Kaseya Marketplace** | Kaseya VSA + Autotask | Large MSP + PSA base | Combined Kaseya+Autotask ecosystem post-acquisition |
| **NinjaOne Integrations** | NinjaOne RMM | Fast-growing MSP segment | Listed integrations get exposure to growing NinjaOne user base |
| **Datto Marketplace** | Datto RMM + Autotask | Mid-market MSP segment | Deployment scripts via Datto ComStore |
| **Microsoft MISA** | Sentinel + Defender | Enterprise + SMB via CSP | Microsoft Intelligent Security Association — co-sell with Microsoft |

### 4.2 What Certification Requires (ConnectWise Invent as model)

From Guardz's experience (Jul 2024) and ConnectWise Invent docs:
1. Pass independent security review of your integration
2. Work with ConnectWise API team on integration roadmap
3. Build to ConnectWise API spec (REST, auth model, field mapping)
4. Submit for certification review
5. Receive Tier 1 support from ConnectWise for the integration
6. Listed on ConnectWise Marketplace with "Certified" badge

Timeline: 3–6 months from API build to certified listing.

---

## Part 5 — The Technical Integration Standards We Must Implement

### 5.1 Event Format: CEF (Common Event Format)

The de-facto standard for security event forwarding. Used by ArcSight, accepted by Sentinel, Splunk, QRadar, Elastic.

```
CEF:0|SecurityLayerBasis|DetectionEngine|5.0|PI-001a|Prompt Injection Detected|8|
  src=192.168.1.42
  suser=alice@acme.com
  dvc=DEVLAPTOP-A14
  act=BLOCK
  reason=prompt_injection_bert score 0.97
  cs1=VS Code
  cs1Label=IDE
  cs2=PI-001a
  cs2Label=RuleID
  cs3=CRITICAL
  cs3Label=Severity
  msg=Direct prompt injection in user prompt. Score: 0.97. Action: BLOCK.
  rt=1745158800000
```

### 5.2 Event Format: ECS (Elastic Common Schema)

Required for Elastic/OpenSearch integration.

```json
{
  "@timestamp": "2026-04-20T15:30:00.000Z",
  "event.kind": "alert",
  "event.category": ["intrusion_detection"],
  "event.type": ["denied"],
  "event.action": "block",
  "event.severity": 9,
  "rule.id": "PI-001a",
  "rule.name": "Prompt Injection Detected",
  "source.user.email": "alice@acme.com",
  "host.hostname": "DEVLAPTOP-A14",
  "process.name": "VS Code",
  "threat.technique.id": ["T1055"],
  "threat.technique.name": ["Prompt Injection"],
  "labels.tenant_id": "acme-corp",
  "labels.action": "BLOCK",
  "labels.ml_score": 0.97
}
```

### 5.3 MITRE ATT&CK Mapping (Required by all SIEMs)

Our threat classes map to ATT&CK for Enterprise + new LLM-specific techniques:

| Our Rule | ATT&CK Technique | ATT&CK ID |
|---|---|---|
| PI-001a (Prompt Injection) | Phishing / Spearphishing | T1566 (adapted) |
| PI-001b (Filesystem Injection) | Supply Chain Compromise | T1195 |
| PI-002 (Memory Payload) | Persistence: Boot/Logon Autostart | T1547 |
| CE-001 (Credential Exfil) | Credentials from Files | T1552.001 |
| RS-001 (Reverse Shell) | Command and Scripting Interpreter | T1059 |
| MA-001 (Multi-Agent) | Hijack Execution Flow | T1574 |
| SI-001/002 (Skill Identity) | Supply Chain Compromise: SW Dependencies | T1195.001 |
| MEM-001 (Memory Poisoning) | Pre-OS Boot: Firmware | T1542 (adapted) |

### 5.4 Authentication Standards

| Integration Type | Auth Method |
|---|---|
| PSA (ConnectWise, Autotask) | API Key + Secret (Base64 encoded) |
| SIEM (Sentinel, Splunk) | OAuth2 Client Credentials / API Token |
| RMM Agent Health | API Key per tenant |
| Partner App (deep integration) | OAuth2 Authorization Code + scopes |
| Webhook delivery | HMAC-SHA256 signature header |

---

## Part 6 — The Integration Go-To-Market Pattern (How Successful Vendors Do It)

### How Huntress Built Their Integration Ecosystem

Huntress is the closest analog to us in the MSP market — security-first, MSP-focused, no enterprise bloat.

Their integration build order:
1. **ConnectWise PSA** first (alert-to-ticket) — biggest MSP PSA, immediate credibility
2. **Autotask PSA** second — second largest PSA
3. **RMM deployment scripts** — Datto RMM, NinjaOne, N-able, Syncro, Kaseya
4. **HaloPSA, Syncro PSA** — long tail PSAs
5. **SIEM** — syslog/CEF forwarding added later
6. **REST API** — opened for Rewst/automation platforms
7. **Google Workspace + M365 ITDR** — identity layer added last

**Lesson: PSA first. RMM second. SIEM third. API fourth. Marketplace last.**  
Every step increases distribution without increasing support complexity until you're ready.

### How Guardz Did It

1. ConnectWise Invent certification (Jul 2024) — led with the highest-trust path
2. Autotask PSA integration — same week
3. One-way ticket sync (alerts → tickets, not bidirectional — simpler to build, less support burden)
4. MSP admin configures: company mapping, ticket board, severity-to-priority mapping, template

**Lesson: One-way integration is fine to start. Bidirectional is a feature, not a requirement.**

---

## Part 7 — Key Findings for Security Layer-Basis Integration Architecture

### Finding 1: We Are Not a New Category to the Market
MSSPs and MSPs already buy "security tools" — they know the pattern. Our differentiation is not "security" but "AI agent security." We must speak their language (PSA tickets, SIEM events, RMM deployment) while explaining a new threat category simply.

### Finding 2: PSA Integration Is the Single Most Important First Step
MSPs live in their PSA. A security tool that doesn't create PSA tickets is invisible to them. ConnectWise PSA integration + Autotask PSA integration covers ~70% of the market. This must be integration #1.

### Finding 3: RMM Deployment Script Removes the Biggest Friction
The hardest part of rolling out a new agent tool across 500 developer machines is deployment. An RMM-deployable script that MSPs can push via their existing NinjaOne/Datto/N-able makes our hook installation a 1-click operation instead of a 500-machine project.

### Finding 4: SIEM Integration Unlocks the Enterprise and Compliance Segment
SMBs with compliance requirements (SOC 2, HIPAA, ISO 27001) are already running Sentinel or Splunk. Being able to forward our events as CEF or via REST API makes us a compliance data source — a mandatory integration, not an optional one.

### Finding 5: Webhook Outbound Is the Universal Adapter
Every tool (Zapier, Make, Rewst, Tines, custom SOAR) accepts webhooks. A configurable outbound webhook per event type is the lowest-effort, highest-compatibility integration we can build. It's the 80% solution before we build native connectors.

### Finding 6: ConnectWise Invent Certification Is the Distribution Unlock
30,000 MSPs use ConnectWise tools. Being "certified" on their marketplace is not a vanity metric — it's a distribution channel that costs 3–6 months of engineering time but delivers access to the largest single pool of MSP buyers. Guardz, EasyDMARC, and dozens of others have used this path.

### Finding 7: The Integration Pattern Is Standardized — We Don't Need to Invent It
The PSA integration pattern (API key → create ticket on alert → close ticket on resolve → custom fields for context) is literally the same across every security vendor. We implement the same pattern. The only thing that's new is our event category (AI agent threats vs. endpoint threats).

### Finding 8: MITRE ATT&CK Mapping Is Non-Negotiable for SIEM Acceptance
Every enterprise SIEM dashboard, compliance report, and SOC workflow is built around ATT&CK. Without ATT&CK mappings on our events, SIEM teams cannot ingest us into their dashboards. This is a 2-day implementation effort that unlocks the entire SIEM market.

---

## Part 8 — Proposed Integration Roadmap for Security Layer-Basis

| Phase | Integration | Technical Build | Distribution |
|---|---|---|---|
| **Phase 1** (Launch) | Webhook outbound (configurable URL + HMAC) | 1 week | Universal — any tool with a webhook receiver |
| **Phase 1** (Launch) | ConnectWise PSA — alert-to-ticket | 2 weeks | ~40% of MSP market |
| **Phase 1** (Launch) | Autotask PSA — alert-to-ticket | 1 week | ~25% of MSP market |
| **Phase 2** (Q3 2026) | RMM deployment scripts (NinjaOne, Datto, N-able, Kaseya) | 1 week each | Full MSP deployment coverage |
| **Phase 2** (Q3 2026) | SIEM: CEF/syslog forwarding (works with all SIEMs) | 1 week | Sentinel, Splunk, Elastic, QRadar |
| **Phase 2** (Q3 2026) | Microsoft Sentinel REST API connector | 2 weeks | Enterprise + CSP channel |
| **Phase 3** (Q4 2026) | ConnectWise Invent certification | 3–6 months | 30,000+ MSPs via marketplace |
| **Phase 3** (Q4 2026) | N-able TAP partnership | 2 months | N-able MSP ecosystem |
| **Phase 3** (Q4 2026) | REST API v1 (read + webhook config) | 4 weeks | Rewst, Zapier, custom builds |
| **Phase 4** (Q1 2027) | OAuth2 + partner scopes | 4 weeks | Platform-grade integrations |
| **Phase 4** (Q1 2027) | Splunk Add-on (TA) on Splunkbase | 3 weeks | Splunk enterprise market |
| **Phase 4** (Q1 2027) | Kaseya + NinjaOne marketplace listing | 2 months | Additional MSP segments |
| **Phase 5** (2027) | Microsoft MISA membership | 6+ months | Microsoft co-sell channel |

---

## Part 9 — What This Means for ARCHITECTURE_V6.md

The research defines six new architectural components we need to add:

| Component | Purpose |
|---|---|
| **Integration Bus** | Core outbound event router — PSA, SIEM, webhook, all go through here |
| **PSA Adapter Layer** | Pluggable adapters per PSA (ConnectWise, Autotask, HaloPSA, Syncro) |
| **SIEM Formatter** | CEF / ECS / Splunk CIM event formatter per SIEM target |
| **ATT&CK Mapper** | Maps our rule IDs to MITRE ATT&CK technique IDs per event |
| **Tenant Config Store** | Per-tenant: PSA credentials, SIEM endpoint, webhook URLs, company mapping |
| **REST API v1** | Public API for partners, SOAR playbooks, automation tools |

These six components transform Security Layer-Basis from a detection engine into an **integration-first security platform** — one that MSPs can plug in and immediately see value in the tools they already use.

---

*Research conducted: 2026-04-20*  
*Sources: Acronis MSP Integration Trends 2025, ConnectWise Invent Program docs, Guardz integration case study, Huntress integration ecosystem, N-able Developer Portal launch, NinjaOne integrations directory, Microsoft Sentinel connector docs, Splunk HEC documentation, MITRE ATT&CK framework*  
*Next step: Implement findings in ARCHITECTURE_V6.md*
