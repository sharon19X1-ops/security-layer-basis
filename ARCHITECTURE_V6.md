# Security Layer-Basis — Architecture v6.0

**Version:** 6.0  
**Date:** 2026-04-20  
**Basis:** Architecture v5.0 + Integration Landscape Research  
**Core Change:** Integration-first platform — Security Layer-Basis becomes a native citizen in any MSP/MSSP/SMB stack  
**Changes from v5:** Integration Bus, PSA Adapter Layer, SIEM Formatter, ATT&CK Mapper, Tenant Config Store, REST API v1, RMM Deployment Layer, Partner Program readiness, updated event schema, updated roadmap

---

## What Changed and Why

> "Research how to turn this architecture into a layer that integrates to any MSSP/SI/SMB current IT tool or security platform."

The integration landscape research found one structural truth:

> **MSPs manage 20+ tools on average. They are not buying more tools — they are buying better integration. In 2026, security integration adoption grew 123% YoY. Integration IS the go-to-market.**

v5 is a complete, independent detection engine. But it is a silo — it detects, blocks, and holds in its own world. No alerts flow into the PSA where the MSP analyst lives. No events land in the SIEM where compliance is tracked. No deployment script exists for the RMM that manages all developer machines.

v6 fixes this. The detection engine is unchanged. What changes is everything around it:

```
v5 posture:  PREVENT → VERIFY → DETECT → BLOCK  (own world)
v6 posture:  PREVENT → VERIFY → DETECT → BLOCK → INTEGRATE → DISTRIBUTE
```

Six new components added:
1. **Integration Bus** — central outbound router for all external signals
2. **PSA Adapter Layer** — pluggable adapters for ConnectWise, Autotask, HaloPSA, Syncro
3. **SIEM Formatter** — CEF, ECS, Splunk CIM, syslog output per SIEM target
4. **ATT&CK Mapper** — maps every rule to MITRE ATT&CK technique IDs
5. **Tenant Config Store** — per-org PSA credentials, SIEM endpoints, webhook URLs
6. **REST API v1** — public API for SOAR, automation platforms, partner apps

Plus:
- **RMM Deployment Layer** — hook agent deployment scripts for all major RMMs
- **Webhook Engine** — configurable outbound webhooks with HMAC signing
- **Partner Program readiness** — ConnectWise Invent, N-able TAP certification paths

---

## 1. High-Level Architecture (v6)

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                              DEVELOPER MACHINES                                  │
│                                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │ VS Code  │  │ JetBrains│  │  Cursor  │  │  Neovim  │  │ CLI Agent│         │
│  │  Hook v6 │  │  Hook v6 │  │  Hook v6 │  │  Hook v6 │  │  Hook v6 │         │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘         │
│       └──────────────────────────┬───────────────────────────────┘               │
│                                  │                                               │
│                    ┌─────────────▼──────────────────┐                           │
│                    │     Interceptor Agent v6        │                           │
│                    │                                 │                           │
│                    │  PREVENTION LAYER (v4/v5)        │                          │
│                    │  ▸ Credential deny list         │                           │
│                    │  ▸ Filesystem scope enforcer    │                           │
│                    │                                 │                           │
│                    │  CAPTURE LAYER (v1–v5)           │                          │
│                    │  ▸ Event capture (17 types)     │                           │
│                    │  ▸ Skill identity resolver      │                           │
│                    │  ▸ Sub-skill depth tracker      │                           │
│                    │  ▸ Memory write interceptor     │                           │
│                    │  ▸ HITL session tracker         │                           │
│                    │  ▸ Process tree monitor         │                           │
│                    │                                 │                           │
│                    │  VERIFICATION LAYER (v4/v5)      │                          │
│                    │  ▸ Completion gate evaluator    │                           │
│                    │  ▸ Commit gate evaluator        │                           │
│                    │  ▸ Lint/test result injector    │                           │
│                    │  ▸ Truncation signal detector   │                           │
│                    │                                 │                           │
│                    │  ▸ PII strip + batch + forward  │                           │
│                    └─────────────┬──────────────────┘                           │
└──────────────────────────────────┼───────────────────────────────────────────────┘
     ┌────────────────────────────────────────────────────────┐
     │               RMM DEPLOYMENT LAYER   ← NEW            │
     │  NinjaOne · Datto RMM · N-able · Kaseya · ConnectWise │
     │  → Push Hook v6 to developer workstations via RMM     │
     │  → Agent health reported back to RMM dashboard        │
     └────────────────────────┬───────────────────────────────┘
                              │
                              │  TLS 1.3 / mTLS gRPC
                              ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                        DETECTION ENGINE v6 (Server-Side)                         │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐  │
│  │                           GATEWAY LAYER                                     │  │
│  │   Auth · Rate Limiting · Tenant Isolation · Event Dedup · Schema Validate  │  │
│  └───────────────────────────────┬────────────────────────────────────────────┘  │
│                                  │                                               │
│  ┌───────────────────────────────▼────────────────────────────────────────────┐  │
│  │                          EVENT PIPELINE v6                                  │  │
│  │                                                                             │  │
│  │  ┌───────────┐  ┌──────────────┐  ┌────────────────┐  ┌─────────────────┐ │  │
│  │  │ Ingestion │─▶│  Normalizer  │─▶│ Risk Classifier│─▶│  Verdict Router │ │  │
│  │  │  Queue    │  │  + Enricher  │  │  Engine        │  │  + ATT&CK Map   │ │  │
│  │  └───────────┘  └──────────────┘  └────────────────┘  └────────┬────────┘ │  │
│  └───────────────────────────────────────────────────────────────────┼─────────┘  │
│                                                                       │            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐   │
│  │ Policy Store │  │ Threat Intel │  │  ML Models   │  │  Own Skill        │   │
│  │ (single YAML)│  │  Feed (live) │  │  (10 models) │  │  Registry (local) │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └───────────────────┘   │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │            Skill Scoring Engine (v5 — unchanged)                         │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │            Cross-Event Correlation Engine (v3 — unchanged)               │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │            Verification State Store (v4 — unchanged)                     │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │            ATT&CK Mapper               ← NEW (v6)                        │   │
│  │   Maps every verdict + rule ID → MITRE ATT&CK technique IDs             │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                       │            │
│  ┌────────────────────────────────────────────────────────────────────▼──────────┐ │
│  │                           ACTION EXECUTOR                                    │ │
│  │  Block · Warn · Deny · Hold · Audit · Alert · Quarantine · Kill · HITL Gate │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                          │                                       │
│  ┌───────────────────────────────────────▼──────────────────────────────────┐   │
│  │                    INTEGRATION BUS        ← NEW (v6)                     │   │
│  │                                                                           │   │
│  │   Every verdict + action flows through here before external delivery     │   │
│  │                                                                           │   │
│  │   ┌──────────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │   │
│  │   │  PSA Adapter     │  │ SIEM         │  │  Webhook Engine          │  │   │
│  │   │  Layer           │  │ Formatter    │  │                          │  │   │
│  │   │  (v6 new)        │  │ (v6 new)     │  │  (v6 new)                │  │   │
│  │   └──────────────────┘  └──────────────┘  └──────────────────────────┘  │   │
│  │                                                                           │   │
│  │   ┌──────────────────────────────────────────────────────────────────┐   │   │
│  │   │  Tenant Config Store  (v6 new)                                   │   │   │
│  │   │  Per-org: PSA creds · SIEM endpoint · webhook URLs · mappings   │   │   │
│  │   └──────────────────────────────────────────────────────────────────┘   │   │
│  └───────────────────────────────────────────────────────────────────────────┘   │
│                                          │                                       │
│  ┌───────────────────────────────────────▼──────────────────────────────────┐   │
│  │                    REST API v1          ← NEW (v6)                       │   │
│  │   Public API for SOAR · automation · partner apps · MSSP dashboards     │   │
│  └───────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐  │
│  │                         OBSERVABILITY PLANE (v6 updated)                    │  │
│  │  Audit Trail · SIEM · SOC Dashboard · HITL Console · Skill Map             │  │
│  │  Memory Audit Log · Sub-Skill Lineage Graph                                │  │
│  │  Completion Evidence Log · Diff Size Heatmap                               │  │
│  │  Integration Health Dashboard (PSA sync · SIEM delivery · webhook status) │  │
│  │  API Usage Dashboard (partner call volume, rate limit status)              │  │
│  └────────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────┘
         │                    │                    │                    │
         ▼                    ▼                    ▼                    ▼
  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │  PSA LAYER  │    │  SIEM LAYER  │    │  AUTOMATION  │    │  RMM LAYER   │
  │             │    │              │    │  LAYER       │    │              │
  │ ConnectWise │    │  MS Sentinel │    │  Rewst       │    │  NinjaOne    │
  │ Autotask    │    │  Splunk      │    │  Zapier      │    │  Datto RMM   │
  │ HaloPSA     │    │  Elastic     │    │  Tines       │    │  N-able      │
  │ Syncro      │    │  QRadar      │    │  Make        │    │  Kaseya VSA  │
  └─────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

---

## 2. New Component: Integration Bus

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                            Integration Bus                                   │
│                                              ← NEW in v6                    │
│                                                                              │
│  Central router. Every verdict from the Action Executor flows here.          │
│  Routes to one or more external channels based on Tenant Config.            │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Routing Rules (per tenant, per event severity)                     │    │
│  │                                                                     │    │
│  │  CRITICAL verdict  → PSA (ticket) + SIEM + webhook + alert         │    │
│  │  HIGH verdict      → PSA (ticket) + SIEM + webhook                 │    │
│  │  MEDIUM verdict    → SIEM + webhook                                 │    │
│  │  LOW / AUDIT       → SIEM only                                      │    │
│  │  HOLD event        → PSA (ticket flagged "awaiting evidence")       │    │
│  │  DENY event        → SIEM + audit log only                         │    │
│  │                                                                     │    │
│  │  All routes are configurable per tenant in policy.yaml             │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Delivery Guarantees                                                │    │
│  │  - At-least-once delivery with dedup key per event                  │    │
│  │  - Retry: exponential backoff (1s, 4s, 16s, 64s, give up + alert)  │    │
│  │  - Dead letter queue: failed deliveries stored for manual replay    │    │
│  │  - Idempotency key: prevents duplicate PSA tickets from retries    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Event Enrichment (added before routing)                            │    │
│  │  - ATT&CK technique ID(s) appended                                  │    │
│  │  - Tenant company name + ID resolved                                │    │
│  │  - Developer name resolved (hashed ID → display name if available) │    │
│  │  - Recommended remediation step added per rule                     │    │
│  │  - Dedup key computed (rule_id + session_id + timestamp bucket)    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  Latency budget: < 100ms total (enrich + route + deliver to PSA/SIEM)      │
│  Throughput: same as detection engine (100K events/sec capable)             │
│  Async: does not block verdict return to hook agent                         │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. New Component: PSA Adapter Layer

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         PSA Adapter Layer                                    │
│                                              ← NEW in v6                    │
│                                                                              │
│  Design: pluggable adapter per PSA. Same internal event → each adapter      │
│  transforms it into the PSA's exact API format and auth model.              │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  ConnectWisePSAAdapter                                              │    │
│  │                                                                     │    │
│  │  Auth: Basic(companyId + publicKey : privateKey), Base64 encoded    │    │
│  │  API: POST /v4_6_release/apis/3.0/service/tickets                  │    │
│  │  Ticket fields:                                                     │    │
│  │    summary    → "[SLB] {rule_name} — {severity}"                   │    │
│  │    board      → tenant config: default_board_id                    │    │
│  │    company    → tenant config: client_company_id                   │    │
│  │    status     → tenant config: open_status_id                      │    │
│  │    priority   → mapped from severity (Critical→1, High→2, Med→3)  │    │
│  │    initialDescription → full event context (see template below)   │    │
│  │    customFields:                                                    │    │
│  │      - rule_id, action_taken, developer_id, ide, att&ck_id         │    │
│  │  Dedup: GET /tickets?conditions=summary="[SLB]..."&status=Open     │    │
│  │  Resolve: PATCH /tickets/{id} → status = tenant.closed_status_id  │    │
│  │                                                                     │    │
│  │  ConnectWise Invent certification target: Q4 2026                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  AutotaskPSAAdapter                                                 │    │
│  │                                                                     │    │
│  │  Auth: API Key + Username header                                    │    │
│  │  API: POST /atservicesrest/v1.0/Tickets                            │    │
│  │  Ticket fields:                                                     │    │
│  │    title      → "[SLB] {rule_name}"                                │    │
│  │    companyID  → tenant config                                      │    │
│  │    priority   → mapped (1=Critical, 2=High, 3=Medium, 4=Low)      │    │
│  │    status     → 1 (New)                                            │    │
│  │    description → event context template                            │    │
│  │    queueID    → tenant config: default_queue_id                   │    │
│  │  Webhook: Autotask → us (optional bidirectional): ticket updates  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  HaloPSAAdapter                                                     │    │
│  │  Auth: OAuth2 Client Credentials                                    │    │
│  │  API: POST /api/Tickets                                            │    │
│  │  Same field pattern — adapter maps to HaloPSA schema              │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  SyncroPSAAdapter                                                   │    │
│  │  Auth: API Key header (X-Syncro-Api-Key)                           │    │
│  │  API: POST /api/v1/tickets                                         │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Ticket Description Template (shared across all PSA adapters)       │    │
│  │                                                                     │    │
│  │  ## AI Security Event — Security Layer-Basis                        │    │
│  │                                                                     │    │
│  │  **Rule:** {rule_id} — {rule_name}                                  │    │
│  │  **Severity:** {severity}                                           │    │
│  │  **Action taken:** {action} (automatic)                            │    │
│  │  **Time:** {timestamp}                                              │    │
│  │  **Developer:** {developer_display_name}                           │    │
│  │  **Workstation:** {device_hostname}                                 │    │
│  │  **IDE:** {ide}                                                     │    │
│  │  **MITRE ATT&CK:** {att&ck_id} — {att&ck_name}                    │    │
│  │                                                                     │    │
│  │  **What happened:**                                                 │    │
│  │  {rule_explanation}  ← human-readable, rule-specific text         │    │
│  │                                                                     │    │
│  │  **What was stopped:**                                              │    │
│  │  {action_explanation} ← "The action was blocked automatically..."  │    │
│  │                                                                     │    │
│  │  **Recommended next step:**                                         │    │
│  │  {remediation_step}  ← rule-specific, actionable instruction      │    │
│  │                                                                     │    │
│  │  Reference: SLB-{event_id} | Tenant: {tenant_id}                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. New Component: SIEM Formatter

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                           SIEM Formatter                                     │
│                                              ← NEW in v6                    │
│                                                                              │
│  Transforms internal event schema → target SIEM format.                     │
│  One internal event → multiple SIEM outputs simultaneously if configured.   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  CEF Formatter (syslog transport)                                   │    │
│  │  → Compatible with: MS Sentinel, Splunk, QRadar, ArcSight          │    │
│  │                                                                     │    │
│  │  Format:                                                            │    │
│  │  CEF:0|SecurityLayerBasis|SLB-Engine|6.0|{rule_id}|{rule_name}|{sev}│   │
│  │    src={developer_ip}                                               │    │
│  │    suser={developer_email}                                          │    │
│  │    dvc={device_hostname}                                            │    │
│  │    act={action}                                                     │    │
│  │    reason={ml_model}:{ml_score}                                     │    │
│  │    cs1={ide}          cs1Label=IDE                                  │    │
│  │    cs2={rule_id}      cs2Label=RuleID                               │    │
│  │    cs3={att&ck_id}    cs3Label=ATTACKId                             │    │
│  │    cs4={tenant_id}    cs4Label=TenantID                             │    │
│  │    msg={human_readable_description}                                 │    │
│  │    rt={epoch_ms}                                                    │    │
│  │                                                                     │    │
│  │  Transport: syslog/UDP or syslog/TLS to collector agent            │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  ECS Formatter (Elastic Common Schema)                              │    │
│  │  → Compatible with: Elastic/OpenSearch, Kibana                     │    │
│  │                                                                     │    │
│  │  JSON output:                                                       │    │
│  │  {                                                                  │    │
│  │    "@timestamp": "{ISO-8601}",                                      │    │
│  │    "event.kind": "alert",                                           │    │
│  │    "event.category": ["intrusion_detection"],                       │    │
│  │    "event.type": ["denied"|"allowed"|"info"],                      │    │
│  │    "event.action": "{action_lower}",                                │    │
│  │    "event.severity": {1-10},                                        │    │
│  │    "rule.id": "{rule_id}",                                          │    │
│  │    "rule.name": "{rule_name}",                                      │    │
│  │    "rule.category": "ai-agent-security",                            │    │
│  │    "source.user.email": "{developer_email}",                        │    │
│  │    "host.hostname": "{device_hostname}",                            │    │
│  │    "process.name": "{ide}",                                         │    │
│  │    "threat.technique.id": ["{att&ck_id}"],                          │    │
│  │    "threat.technique.name": ["{att&ck_name}"],                      │    │
│  │    "threat.framework": "MITRE ATT&CK",                              │    │
│  │    "labels.tenant_id": "{tenant_id}",                               │    │
│  │    "labels.action": "{action}",                                     │    │
│  │    "labels.ml_score": {score},                                      │    │
│  │    "labels.slb_version": "6.0"                                      │    │
│  │  }                                                                  │    │
│  │                                                                     │    │
│  │  Transport: POST to Elasticsearch ingest endpoint (API key auth)   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Splunk HEC Formatter (HTTP Event Collector)                        │    │
│  │  → Compatible with: Splunk Enterprise, Splunk Cloud                │    │
│  │                                                                     │    │
│  │  POST https://{splunk_host}:8088/services/collector                 │    │
│  │  Authorization: Splunk {hec_token}                                  │    │
│  │  {                                                                  │    │
│  │    "time": {epoch},                                                 │    │
│  │    "host": "{device_hostname}",                                     │    │
│  │    "source": "security-layer-basis",                                │    │
│  │    "sourcetype": "slb:alert",                                       │    │
│  │    "index": "security",                                             │    │
│  │    "event": { ...normalized CIM fields... }                        │    │
│  │  }                                                                  │    │
│  │                                                                     │    │
│  │  Splunk CIM fields: action, app, dest, severity, src_user, vendor  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Microsoft Sentinel REST Formatter                                  │    │
│  │  → Compatible with: Log Analytics workspace custom table           │    │
│  │                                                                     │    │
│  │  POST https://{workspace_id}.ods.opinsights.azure.com/             │    │
│  │       api/logs?api-version=2016-04-01                               │    │
│  │  Authorization: SharedKey {workspace_id}:{HMAC-SHA256 signature}   │    │
│  │  Log-Type: SLBSecurityEvents                                        │    │
│  │  {                                                                  │    │
│  │    "TimeGenerated": "{ISO-8601}",                                   │    │
│  │    "RuleId": "{rule_id}",                                           │    │
│  │    "RuleName": "{rule_name}",                                       │    │
│  │    "Severity": "{severity}",                                        │    │
│  │    "Action": "{action}",                                            │    │
│  │    "DeveloperEmail": "{developer_email}",                           │    │
│  │    "DeviceHostname": "{device_hostname}",                           │    │
│  │    "IDE": "{ide}",                                                  │    │
│  │    "MitreAttackId": "{att&ck_id}",                                  │    │
│  │    "TenantId": "{tenant_id}",                                       │    │
│  │    "MLScore": {score},                                              │    │
│  │    "Description": "{human_readable}"                                │    │
│  │  }                                                                  │    │
│  │                                                                     │    │
│  │  Sentinel Data Connector application: submit via MISA program      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. New Component: ATT&CK Mapper

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                           ATT&CK Mapper                                      │
│                                              ← NEW in v6                    │
│                                                                              │
│  Maps every Security Layer-Basis rule → MITRE ATT&CK technique(s).         │
│  Required by all enterprise SIEMs for dashboard correlation.                │
│                                                                              │
│  Rule → ATT&CK Mapping Table:                                               │
│                                                                              │
│  ┌──────────────┬───────────────────────────────────────────────────────┐   │
│  │ SLB Rule     │ MITRE ATT&CK Technique                                │   │
│  ├──────────────┼───────────────────────────────────────────────────────┤   │
│  │ PI-001a      │ T1566 Phishing (adapted: LLM prompt injection)        │   │
│  │ PI-001b      │ T1195.001 Supply Chain: SW Dependencies               │   │
│  │ PI-002       │ T1547 Boot/Logon Autostart (memory-resident payload)  │   │
│  │ CE-001       │ T1552.001 Unsecured Credentials: Files                │   │
│  │ FS-002       │ T1552.001 Unsecured Credentials (prevention)          │   │
│  │ RS-001       │ T1059 Command and Scripting Interpreter               │   │
│  │ HITL-001     │ T1078 Valid Accounts (autonomous misuse)              │   │
│  │ MA-001       │ T1574 Hijack Execution Flow                           │   │
│  │ MA-002       │ T1053 Scheduled Task / unauthorized spawn             │   │
│  │ SI-001       │ T1195.001 Supply Chain: SW Dependencies               │   │
│  │ SI-002       │ T1195.001 Supply Chain: SW Dependencies               │   │
│  │ SI-003/004   │ T1195.002 Supply Chain: Software (nested payload)     │   │
│  │ SI-005       │ T1547 Persistence via memory write                    │   │
│  │ SYS-001      │ T1059.004 Unix Shell / T1059.001 PowerShell           │   │
│  │ MEM-001      │ T1547.009 Shortcut Modification (memory directive)    │   │
│  │ CG-001/002   │ T1036 Masquerading (unverified completion claim)      │   │
│  │ DI-001       │ T1480 Execution Guardrails (evading detection)        │   │
│  │ OQ-001       │ T1036 Masquerading (rationalization as completion)    │   │
│  │ FS-001       │ T1083 File and Directory Discovery (scope violation)  │   │
│  │ BR-001       │ T1490 Inhibit System Recovery (blast radius)          │   │
│  └──────────────┴───────────────────────────────────────────────────────┘   │
│                                                                              │
│  Note: Some mappings are adapted from base ATT&CK techniques to LLM/AI     │
│  agent threat context. Custom sub-technique "T1xxx.AI" additions proposed  │
│  to MITRE ATT&CK for LLM agents (part of OWASP LLM contribution).          │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. New Component: Tenant Config Store

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         Tenant Config Store                                  │
│                                              ← NEW in v6                    │
│                                                                              │
│  Per-organization configuration for all integration targets.                │
│  Encrypted at rest. Never logged in plaintext.                              │
│                                                                              │
│  Schema per tenant:                                                          │
│                                                                              │
│  tenant_id: "acme-corp"                                                      │
│  display_name: "AcmeCorp"                                                    │
│  operator_mode: "mssp" | "si" | "admin"                                     │
│  parent_tenant: "securemsp-ltd"   # MSSP parent (if applicable)             │
│                                                                              │
│  psa:                                                                        │
│    provider: "connectwise" | "autotask" | "halopsa" | "syncro" | null       │
│    company_id: "250"              # PSA client company ID                   │
│    board_id: "1"                  # service board for tickets               │
│    open_status_id: "1"            # ticket open status ID                   │
│    closed_status_id: "5"          # ticket closed status ID                 │
│    priority_map:                  # severity → PSA priority ID              │
│      Critical: 1                                                             │
│      High: 2                                                                 │
│      Medium: 3                                                               │
│      Low: 4                                                                  │
│    credentials:                   # encrypted, never logged                 │
│      public_key: "enc:..."                                                   │
│      private_key: "enc:..."                                                  │
│      company_identifier: "enc:..."                                           │
│    auto_close_on_resolve: true                                               │
│    dedup_window_min: 60           # suppress duplicate tickets within 60min  │
│                                                                              │
│  siem:                                                                       │
│    provider: "sentinel" | "splunk" | "elastic" | "qradar" | "syslog" | null│
│    format: "cef" | "ecs" | "splunk-cim" | "leef"                           │
│    endpoint: "enc:..."            # SIEM ingest URL (encrypted)             │
│    api_key: "enc:..."             # SIEM API key (encrypted)                │
│    workspace_id: "enc:..."        # Sentinel-specific                       │
│    index: "security"              # Splunk-specific                         │
│    min_severity: "Medium"         # don't send LOW/AUDIT to SIEM           │
│                                                                              │
│  webhooks:                        # list of outbound webhook targets        │
│    - name: "Rewst Automation"                                                │
│      url: "enc:..."                                                          │
│      signing_secret: "enc:..."    # HMAC-SHA256 key                        │
│      events: ["CRITICAL", "HIGH"] # which severities to deliver            │
│      format: "json"                                                          │
│    - name: "Zapier"                                                          │
│      url: "enc:..."                                                          │
│      events: ["CRITICAL"]                                                    │
│                                                                              │
│  routing:                         # Integration Bus routing overrides       │
│    CRITICAL: [psa, siem, webhook, alert]                                    │
│    HIGH:     [psa, siem, webhook]                                            │
│    MEDIUM:   [siem, webhook]                                                 │
│    LOW:      [siem]                                                          │
│    HOLD:     [psa]                                                           │
│    DENY:     [siem]                                                          │
│                                                                              │
│  Storage: Postgres (cluster) + HashiCorp Vault for credential encryption   │
│  Access: only Integration Bus + REST API v1 (with appropriate scopes)      │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. New Component: Webhook Engine

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                            Webhook Engine                                    │
│                                              ← NEW in v6                    │
│                                                                              │
│  Outbound webhook delivery to any URL. The universal adapter.               │
│  Works with: Rewst · Zapier · Make · Tines · n8n · custom SOAR             │
│                                                                              │
│  Delivery:                                                                   │
│    POST {tenant_webhook_url}                                                 │
│    Content-Type: application/json                                            │
│    X-SLB-Signature: sha256={HMAC-SHA256(payload, signing_secret)}           │
│    X-SLB-Event-Id: {event_uuid}                                             │
│    X-SLB-Tenant: {tenant_id}                                                │
│    X-SLB-Timestamp: {epoch}                                                 │
│                                                                              │
│  Payload (JSON):                                                             │
│  {                                                                           │
│    "event_id": "uuid",                                                       │
│    "timestamp": "ISO-8601",                                                  │
│    "tenant_id": "acme-corp",                                                 │
│    "rule_id": "PI-001a",                                                     │
│    "rule_name": "Prompt Injection Detected",                                 │
│    "severity": "CRITICAL",                                                   │
│    "action": "BLOCK",                                                        │
│    "att&ck_id": "T1566",                                                     │
│    "att&ck_name": "Phishing",                                                │
│    "developer": { "id": "hashed", "email": "alice@acme.com" },              │
│    "device": { "hostname": "DEVLAPTOP-A14", "os": "macOS" },               │
│    "ide": "VS Code",                                                         │
│    "ml_score": 0.97,                                                         │
│    "description": "Human-readable event description...",                    │
│    "remediation": "Review prompt source and check for injected content."   │
│  }                                                                           │
│                                                                              │
│  Security:                                                                   │
│  - HMAC-SHA256 signature per delivery (receiver can verify)                 │
│  - Signing secret rotatable per tenant, zero-downtime rotation              │
│  - TLS 1.3 only for delivery (no plain HTTP webhooks)                       │
│                                                                              │
│  Reliability:                                                                │
│  - Retry: 5 attempts with exponential backoff                               │
│  - Timeout per attempt: 10 seconds                                          │
│  - Dead-letter queue: failed events stored 7 days for replay                │
│  - Delivery status visible in operator console                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. New Component: REST API v1

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                             REST API v1                                      │
│                                              ← NEW in v6                    │
│                                                                              │
│  Public API for: SOAR platforms · automation tools · MSSP dashboards        │
│  Partner apps · custom integrations · Rewst · Zapier · Tines                │
│                                                                              │
│  Auth: API Key (v1) → OAuth2 Client Credentials (v1.1)                     │
│  Base URL: https://api.securitylayerbasis.io/v1/                            │
│  Format: JSON (request + response)                                          │
│  Rate limiting: 1000 req/min per tenant (configurable for partners)        │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Endpoints — Read (all API key tiers)                               │    │
│  │                                                                     │    │
│  │  GET  /events                                                       │    │
│  │       List events for tenant (paginated, filterable by severity,   │    │
│  │       rule_id, date range, action, developer)                       │    │
│  │                                                                     │    │
│  │  GET  /events/{event_id}                                            │    │
│  │       Full event detail including ML scores + ATT&CK mapping       │    │
│  │                                                                     │    │
│  │  GET  /developers                                                   │    │
│  │       List active developers in tenant (hashed IDs + status)      │    │
│  │                                                                     │    │
│  │  GET  /developers/{id}/risk-summary                                 │    │
│  │       Per-developer risk profile: event counts, rule triggers,    │    │
│  │       blocked vs warned, session count                             │    │
│  │                                                                     │    │
│  │  GET  /skills                                                       │    │
│  │       List skills seen in tenant + their registry risk scores      │    │
│  │                                                                     │    │
│  │  GET  /skills/{skill_id}/score                                      │    │
│  │       Full 10-dimension risk score for a specific skill             │    │
│  │                                                                     │    │
│  │  GET  /policy                                                       │    │
│  │       Current active policy for tenant                             │    │
│  │                                                                     │    │
│  │  GET  /stats/summary                                                │    │
│  │       Tenant-level: events today/week/month, top rules, top devs  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Endpoints — Write (elevated API key or OAuth2 scope)              │    │
│  │                                                                     │    │
│  │  POST /skills/{skill_id}/approve                                    │    │
│  │       Operator approves a flagged skill for use in tenant          │    │
│  │                                                                     │    │
│  │  POST /skills/{skill_id}/block                                      │    │
│  │       Operator blocks a skill org-wide                             │    │
│  │                                                                     │    │
│  │  POST /webhooks                                                     │    │
│  │       Register a new webhook endpoint for tenant                   │    │
│  │                                                                     │    │
│  │  DELETE /webhooks/{id}                                              │    │
│  │       Remove a webhook endpoint                                    │    │
│  │                                                                     │    │
│  │  POST /events/{event_id}/resolve                                    │    │
│  │       Mark an event as resolved (closes linked PSA ticket)        │    │
│  │                                                                     │    │
│  │  POST /policy                                                       │    │
│  │       Update tenant policy (admin/MSSP scope only)                │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Endpoints — MSSP Multi-Tenant (MSSP scope only)                   │    │
│  │                                                                     │    │
│  │  GET  /tenants                                                      │    │
│  │       List all client tenants under MSSP account                  │    │
│  │                                                                     │    │
│  │  GET  /tenants/{tenant_id}/stats/summary                           │    │
│  │       Per-client risk summary for MSSP fleet dashboard            │    │
│  │                                                                     │    │
│  │  POST /tenants/{tenant_id}/policy                                   │    │
│  │       Push policy to specific client tenant                        │    │
│  │                                                                     │    │
│  │  POST /tenants/policy/broadcast                                     │    │
│  │       Push policy update to all client tenants simultaneously      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  OpenAPI 3.0 spec published at: /v1/openapi.json                           │
│  Interactive docs (Swagger UI): https://api.securitylayerbasis.io/docs     │
│  Sandbox environment: https://api-sandbox.securitylayerbasis.io/v1/        │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. New Component: RMM Deployment Layer

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                          RMM Deployment Layer                                │
│                                              ← NEW in v6                    │
│                                                                              │
│  Purpose: MSP deploys Hook v6 to all developer workstations via their       │
│  existing RMM — zero per-machine manual install.                            │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Deployment Scripts (provided per RMM platform)                     │    │
│  │                                                                     │    │
│  │  NinjaOne:                                                          │    │
│  │    Upload to Script Library → assign to device policy              │    │
│  │    PS1 (Windows) + Shell (macOS/Linux) + org_token embedded        │    │
│  │                                                                     │    │
│  │  Datto RMM:                                                         │    │
│  │    Component Library → ComStore submission                         │    │
│  │    Component zip: script + metadata + icon                         │    │
│  │                                                                     │    │
│  │  N-able N-central / N-sight:                                        │    │
│  │    Automation Manager task → deploy to device policy               │    │
│  │    TAP partner listing (N-able Technology Alliance Program)        │    │
│  │                                                                     │    │
│  │  Kaseya VSA:                                                        │    │
│  │    Agent Procedure → scheduled deployment script                   │    │
│  │    Kaseya Marketplace listing                                       │    │
│  │                                                                     │    │
│  │  ConnectWise RMM / Automate:                                        │    │
│  │    Script library → ConnectWise Invent certified deployment        │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Agent Health Reporting (RMM sees us like any managed endpoint)     │    │
│  │                                                                     │    │
│  │  Hook v6 reports to RMM:                                            │    │
│  │  - heartbeat: alive / not responding                                │    │
│  │  - version: current hook version                                    │    │
│  │  - status: active / paused / error                                  │    │
│  │  - last_event_ts: timestamp of last captured event                  │    │
│  │                                                                     │    │
│  │  RMM can:                                                           │    │
│  │  - See hook health per device in their dashboard                   │    │
│  │  - Alert if hook goes offline on a developer machine               │    │
│  │  - Trigger reinstall via RMM if health check fails                 │    │
│  │  - Report hook version across fleet (patch compliance view)        │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Deployment Script — What It Does (platform-agnostic logic)         │    │
│  │                                                                     │    │
│  │  1. Check OS: Windows / macOS / Linux                               │    │
│  │  2. Download hook agent binary from signed CDN (version pinned)    │    │
│  │  3. Verify SHA-256 checksum                                         │    │
│  │  4. Write org_token to secure system store                          │    │
│  │  5. Install as system service (Windows: service / macOS: launchd / │    │
│  │     Linux: systemd)                                                 │    │
│  │  6. VS Code extension: install via `code --install-extension`      │    │
│  │  7. JetBrains/Cursor: drop plugin JAR to plugin directory          │    │
│  │  8. Report success/failure back to RMM                             │    │
│  │  9. First heartbeat to SLB gateway within 60 seconds               │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 10. Updated Hook Event Schema (v6)

Minimal addition to v5: Integration Bus routing metadata appended to events post-verdict.

```protobuf
// ADDED in v6 — integration delivery metadata (appended post-verdict)
message IntegrationDelivery {
  repeated DeliveryRecord deliveries = 1;
}

message DeliveryRecord {
  DeliveryChannel channel   = 1;   // PSA | SIEM | WEBHOOK | API
  string          target    = 2;   // PSA adapter name / SIEM endpoint / webhook URL hash
  DeliveryStatus  status    = 3;   // PENDING | DELIVERED | FAILED | RETRYING
  string          reference = 4;   // PSA ticket ID / SIEM event ID / webhook delivery ID
  string          delivered_at = 5; // ISO-8601 timestamp
}

enum DeliveryChannel {
  PSA     = 0;
  SIEM    = 1;
  WEBHOOK = 2;
  API     = 3;
}

enum DeliveryStatus {
  PENDING   = 0;
  DELIVERED = 1;
  FAILED    = 2;
  RETRYING  = 3;
}

// All other v5 messages unchanged
```

---

## 11. Partner Program Readiness

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                      Partner Program Readiness                               │
│                                              ← NEW in v6                    │
│                                                                              │
│  TIER 1 — ConnectWise Invent Program (Priority, Q4 2026)                   │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Requirements:                                                      │    │
│  │  ✅ ConnectWisePSAAdapter built (v6)                                │    │
│  │  ✅ Security review of integration (independent audit)              │    │
│  │  ✅ API field mapping to ConnectWise spec                           │    │
│  │  ✅ Sandbox environment for CW API team testing                    │    │
│  │  → Outcome: Listed on CW Marketplace (30,000+ MSPs)               │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  TIER 1 — N-able Technology Alliance Program (Q4 2026)                     │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Requirements:                                                      │    │
│  │  ✅ N-able N-central deployment script                              │    │
│  │  ✅ N-able Developer Portal API integration                         │    │
│  │  ✅ TAP application submission                                      │    │
│  │  → Outcome: Listed on N-able TAP directory, dev tools access       │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  TIER 2 — Kaseya Marketplace (Q1 2027)                                     │
│  TIER 2 — NinjaOne Integrations (Q1 2027)                                  │
│  TIER 2 — Datto ComStore (Q1 2027)                                         │
│                                                                              │
│  TIER 3 — Microsoft MISA (Q2 2027)                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Microsoft Intelligent Security Association                         │    │
│  │  Requirements: Sentinel connector published + MISA application      │    │
│  │  → Outcome: Microsoft co-sell channel, Azure Marketplace listing   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 12. Updated Policy Schema (v6)

New section: `integrations`. All v5 fields unchanged.

```yaml
# v6 additions to policy.yaml

integrations:
  psa:
    enabled: true
    provider: "connectwise"          # connectwise | autotask | halopsa | syncro
    ticket_on_severity: ["CRITICAL", "HIGH"]
    auto_close_on_resolve: true
    dedup_window_min: 60
    include_remediation_step: true

  siem:
    enabled: true
    provider: "sentinel"             # sentinel | splunk | elastic | qradar | syslog
    format: "sentinel-rest"          # cef | ecs | splunk-cim | leef | sentinel-rest
    min_severity: "MEDIUM"           # don't forward LOW or AUDIT events
    include_att&ck_mapping: true

  webhooks:
    enabled: true
    require_tls: true                # reject non-HTTPS webhook URLs
    require_hmac_verification: true  # receiver must verify HMAC signature
    max_endpoints: 5                 # per tenant

  api:
    enabled: true
    rate_limit_per_min: 1000
    read_scopes: ["events", "developers", "skills", "policy", "stats"]
    write_scopes: ["skills.approve", "skills.block", "webhooks", "events.resolve"]
    mssp_scopes: ["tenants", "policy.broadcast"]

  routing:                           # Integration Bus routing table
    CRITICAL: ["psa", "siem", "webhook"]
    HIGH:     ["psa", "siem", "webhook"]
    MEDIUM:   ["siem", "webhook"]
    LOW:      ["siem"]
    HOLD:     ["psa"]
    DENY:     ["siem"]
```

---

## 13. Updated Architecture Comparison: v1 → v6

| Dimension | v1 | v2 | v3 | v4 | v5 | v6 |
|-----------|----|----|----|----|----|----|
| Event types | 6 | 12 | 14 | 17 | 17 | 17 + delivery metadata |
| Rule classes | 5 | 9 | 13 | 21 | 21 | 21 (unchanged) |
| ML models | 4 | 7 | 8 | 10 | 10 | 10 (unchanged) |
| Threat coverage | 9/30 | 14/30 | 22/30 | 30/30 | 30/30 | 30/30 (unchanged) |
| Security posture | Detect | Detect | Detect | P+V+D | P+V+D | P+V+D+**Integrate** |
| PSA integration | None | None | None | None | None | **4 PSAs (CW/AT/Halo/Syncro)** |
| SIEM integration | None | None | None | None | None | **4 formats (CEF/ECS/CIM/Sentinel)** |
| ATT&CK mapping | None | None | None | None | None | **21 rules mapped** |
| Webhook engine | None | None | None | None | None | **HMAC-signed, retry, DLQ** |
| REST API | None | None | None | None | None | **v1 (read+write+MSSP)** |
| RMM deployment | None | None | None | None | None | **5 RMMs (NinjaOne/Datto/N-able/Kaseya/CW)** |
| Partner programs | None | None | None | None | None | **CW Invent + N-able TAP path** |
| Tenant config | None | None | None | None | None | **Encrypted per-tenant store** |
| Multi-tenant MSSP | None | Console only | Console | Console | Console | **API + console + policy broadcast** |

---

## 14. Integration Go-Live Checklist

A practical checklist for an MSP adding Security Layer-Basis to their stack:

```
DAY 1 — Core connection (30 minutes)
□ Create SLB tenant account
□ Generate org_token
□ Run RMM deployment script on developer device group
□ Verify first events appear in SLB dashboard

DAY 1 — PSA connection (15 minutes)
□ Create API Member in ConnectWise PSA (security role + API keys)
□ Enter PSA credentials in SLB tenant config
□ Set default board + priority mapping
□ Trigger test alert → verify PSA ticket created

DAY 1 — SIEM connection (15 minutes, if applicable)
□ Generate SIEM API key / Log Analytics workspace ID
□ Enter SIEM credentials in SLB tenant config
□ Select format (CEF / Sentinel REST / Splunk HEC)
□ Send test event → verify it appears in SIEM

DAY 2 — Tuning (shadow mode optional)
□ Review first 24h of events in SLB dashboard
□ Approve any legitimate skills flagged by SI-002
□ Adjust severity routing in policy.yaml if needed

WEEK 1 — Automation (optional)
□ Register webhook endpoint (Rewst / Zapier)
□ Create automation: CRITICAL event → notify on-call via Teams/Slack
□ Create automation: resolved event → close PSA ticket + add resolution note
```

---

## 15. Updated Roadmap (v6)

| Phase | Milestone | Target |
|-------|-----------|--------|
| v0.1–v0.5 | Architecture v1–v5 (detection, prevention, verification, independence) | ✅ Designed |
| **v0.6 (new)** | **Integration Bus + Webhook Engine + Tenant Config Store** | **Q1 2027** |
| **v0.7 (new)** | **PSA Adapter Layer: ConnectWise + Autotask** | **Q1 2027** |
| **v0.8 (new)** | **SIEM Formatter: CEF + Sentinel REST + Splunk HEC + ECS** | **Q1 2027** |
| **v0.9 (new)** | **ATT&CK Mapper (21 rules mapped)** | **Q1 2027** |
| **v0.10 (new)** | **REST API v1 (read + write + MSSP scopes)** | **Q2 2027** |
| **v0.11 (new)** | **RMM Deployment Scripts (NinjaOne, Datto, N-able, Kaseya)** | **Q2 2027** |
| v1.0 | Full platform launch — detection + integration — 30/30 threats | **Q2 2027** |
| **v1.1 (new)** | **ConnectWise Invent certification + N-able TAP listing** | **Q3 2027** |
| **v1.2 (new)** | **HaloPSA + Syncro adapters + PSA long-tail** | **Q3 2027** |
| **v1.3 (new)** | **OAuth2 + partner app scopes + sandbox environment** | **Q4 2027** |
| **v1.4 (new)** | **Splunk TA (Splunkbase) + Elastic package (Elastic Package Registry)** | **Q4 2027** |
| **v1.5 (new)** | **Microsoft MISA application + Azure Marketplace listing** | **Q1 2028** |
| v2.0 | Own Skill Registry public API — expose our scored index to ecosystem | Q1 2028 |

---

*Security Layer-Basis — Architecture v6.0*  
*Integration-first: Security Layer-Basis becomes a native citizen in any MSP/MSSP/SMB stack*  
*PSA: ConnectWise · Autotask · HaloPSA · Syncro*  
*SIEM: Microsoft Sentinel · Splunk · Elastic · QRadar (CEF/ECS/CIM/Sentinel-REST)*  
*RMM: NinjaOne · Datto RMM · N-able · Kaseya VSA · ConnectWise RMM*  
*API: REST v1 · Webhook (HMAC-signed) · MSSP multi-tenant*  
*Partner programs: ConnectWise Invent · N-able TAP · Microsoft MISA*
