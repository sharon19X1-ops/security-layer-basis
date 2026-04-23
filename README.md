# Security Layer-Basis

**Universal AI Coding Agent Security Interception Platform**  
One detection engine. One policy. Every IDE. Every agent. Every stack.

---

## What This Is

Security Layer-Basis is an architecture for a transparent, zero-impact security enforcement layer across all AI-assisted developer workflows.

Every IDE (VS Code, JetBrains, Cursor, Neovim, CLI) connects through a thin hook layer to a centralized detection engine. Security teams write one policy — it applies everywhere. In v6, that detection engine becomes a native citizen in any MSP/MSSP/SMB stack: every security event flows automatically into the PSA, SIEM, and automation tools the team already uses.

The architecture has evolved through six versions, each validated against real-world research and production deployment patterns.

---

## Architecture Versions

| Version | Basis | Key Addition | Threat Coverage |
|---------|-------|--------------|-----------------|
| [v1](./ARCHITECTURE.md) | Original design | Hook layer, 6 event types, 5 rule classes | 9/30 |
| [v2](./ARCHITECTURE_V2.md) | Tego Skills Index validation | HITL tracking, Skill Identity Registry, multi-agent visibility | 14/30 |
| [v3](./ARCHITECTURE_V3.md) | snailsploit Memory Injection research | Sub-skill depth tracking, memory write interception, cross-event correlation | 22/30 |
| [v4](./ARCHITECTURE_V4.md) | VibeTokens 9 Guardrails | Prevention layer, verification layer, completion gates, rationalization detection | 30/30 |
| [v5](./ARCHITECTURE_V5.md) | Independence Audit | Own Skill Scoring Engine, own registry, no external API in hot path, air-gap capable | 30/30 |
| **[v6](./ARCHITECTURE_V6.md)** ← _current_ | Integration Landscape Research | Integration Bus, PSA adapters, SIEM formatters, ATT&CK mapper, REST API v1, RMM deployment | **30/30 + full stack integration** |

---

## Validation Reports

| Report | Source | Finding |
|--------|--------|---------|
| [Tego Index Validation](./VALIDATION_REPORT.md) | Tego Skills Security Index (2,492 skills, 103 Critical) | 5 gaps in v1 → all closed in v2 |
| [Memory Injection / Nested Skills](./REPORT_MemoryInjectionNestedSkills.md) | [snailsploit.com research](https://snailsploit.com/ai-security/prompt-injection/memory-injection-nested-skills/) — Kai Aizen, Feb 2026 | v3 covers 50% of attack chain → v3 closes 6/6 stages |
| [9 Claude Code Guardrails](./REPORT_VibeTokens9Guardrails.md) | [VibeTokens](https://www.vibetokens.io/blog/9-claude-code-guardrails-that-separate-pros-from-prompt-and-pray) — Jason Murphy, Apr 2026 | v3 covers 0/9 guardrails fully → v4 closes all 9 |
| [Independence Audit](./REPORT_IndependenceAudit.md) | Internal design review | v4 depends on external skill registry → v5 closes all 3 external dependencies |

---

## Security Posture — v1 → v6

```
v1–v3 posture:  DETECT → ALERT → BLOCK
v4 posture:     PREVENT → VERIFY → DETECT → BLOCK
v5 posture:     PREVENT → VERIFY → DETECT → BLOCK  (own registry, independent)
v6 posture:     PREVENT → VERIFY → DETECT → BLOCK → INTEGRATE → DISTRIBUTE
```

---

## v6 Architecture Overview

Six new components added in v6 — the detection and prevention engine is unchanged:

| Component | Description |
|-----------|-------------|
| **Integration Bus** | Central outbound router — every verdict flows here before external delivery |
| **PSA Adapter Layer** | Pluggable adapters for ConnectWise, Autotask, HaloPSA, Syncro |
| **SIEM Formatter** | CEF, ECS (Elastic), Splunk CIM, Sentinel REST output per SIEM target |
| **ATT&CK Mapper** | Maps every rule to MITRE ATT&CK technique IDs |
| **Tenant Config Store** | Per-org PSA credentials, SIEM endpoints, webhook URLs — encrypted at rest |
| **REST API v1** | Public API for SOAR, automation platforms, MSSP dashboards, partner apps |

Plus:
- **RMM Deployment Layer** — push Hook v6 to developer workstations via NinjaOne, Datto RMM, N-able, Kaseya VSA, or ConnectWise RMM
- **Webhook Engine** — configurable outbound webhooks with HMAC-SHA256 signing, retry, dead-letter queue
- **Partner Program readiness** — ConnectWise Invent + N-able TAP certification paths in progress

---

## Three Layers (v4–v6, all retained)

**Prevention Layer**
- Credential deny list enforcer — blocks reads of `.env`, `id_rsa`, `.pem`, etc. before they happen
- Filesystem scope enforcer — CI/CD, deploy manifests, infra files are read-only

**Verification Layer**
- Completion gate — agent cannot claim "done" without test/lint evidence
- Commit gate — `git commit` blocked without passing test suite
- Truncation guard — actions blocked when context window was saturated mid-read
- Rationalization detector — catches agent evasion language ("should work now", "same pattern")

**Detection Layer** (v1–v3, fully retained)
- 21 rule classes across prompt injection, credential exfil, skill identity, memory poisoning, multi-agent trust, sub-skill depth, output quality, blast radius, and more
- 10 ML models
- Cross-event correlation engine (4 patterns)

---

## Threat Coverage Matrix

| Category | Threat Classes | Status |
|----------|---------------|--------|
| Prompt Injection | Direct, obfuscated, filesystem, memory, trigger-word activation | ✅ All covered |
| Credential Security | Shell exfil, CLI exfil, pre-read prevention | ✅ All covered |
| Skill Security | Identity mismatch, unknown skills, nested sub-skills, scope violations | ✅ All covered |
| Memory Security | Memory instruction content, skill-to-memory isolation, self-healing loops | ✅ All covered |
| Agent Behavior | Rationalization, completion claims, format drift, truncation-aware reasoning | ✅ All covered |
| Multi-Agent | Trust escalation, unauthorized spawns, cross-boundary violations | ✅ All covered |
| Operational | Diff blast radius, commit gates, file scope, post-edit lint | ✅ All covered |
| Persistence | Self-healing memory worm, C2 callback, supply chain | ✅ All covered |

**Total: 30/30 threat classes covered**

---

## Event Schema (v6)

17 event types across four generations, plus integration delivery metadata (v6):

```
v1: PROMPT_SUBMITTED · COMPLETION_RECEIVED · SHELL_EXEC · FILE_WRITE · NETWORK_REQUEST · MCP_CONNECT
v2: PROCESS_SPAWN · FILE_WRITE_AGENT_INST · AGENT_SPAWN · HITL_CHECKPOINT · SKILL_LOAD · TOOL_INVOKE
v3: MEMORY_WRITE · SKILL_SUBLOAD
v4: TASK_COMPLETE · DATA_TRUNCATION · LINT_RESULT
v6: + IntegrationDelivery metadata (PSA ticket ID / SIEM event ID / webhook delivery status)
```

---

## Rule Classes (v6)

21 rules across 9 categories — unchanged from v5:

| ID | Name | Severity |
|----|------|----------|
| PI-001a/b | Prompt Injection (direct + filesystem) | CRITICAL |
| PI-002 | Prompt activates memory-resident payload | CRITICAL |
| CE-001 | Credential exfiltration | CRITICAL |
| HITL-001 | High-risk action without human oversight | HIGH |
| MA-001/002 | Multi-agent trust escalation / unauthorized spawn | HIGH |
| SI-001–005 | Skill identity, unknown skills, sub-skill depth, memory isolation | CRITICAL/HIGH |
| SYS-001 | System-level CLI tool abuse | HIGH |
| MEM-001 | Memory entry contains skill-loading directive | CRITICAL |
| CG-001/002 | Completion gate / commit gate | HIGH |
| CQ-001 | Post-edit lint missing | MEDIUM |
| FS-001/002 | Filesystem scope / credential pre-read deny | CRITICAL/HIGH |
| DI-001 | Agent acting on truncated data | HIGH |
| OQ-001/002 | Rationalization detection / output format drift | HIGH/MEDIUM |
| BR-001 | Diff size blast radius | MEDIUM |

---

## ML Model Suite

| Model | Purpose |
|-------|---------|
| `prompt_injection_bert` | Injection detection across prompt, filesystem, memory, sub-skill channels |
| `reverse_shell_classifier` | Shell + process spawn risk |
| `exfil_behavior` | File + network + skill→webhook exfil chains |
| `dependency_risk` | Package + version hash supply chain |
| `system_call_risk_classifier` | CLI tool + process spawn risk |
| `autonomy_drift_detector` | Session-level HITL + memory-write pattern anomaly |
| `skill_intent_mismatch` | Skill description vs. actual capabilities (NLP) |
| `memory_directive_classifier` | Skill-loading directives in memory entries |
| `rationalization_detector` | Agent evasion language at completion boundaries |
| `output_format_drift_detector` | Format consistency over long sessions |

---

## Integration (v6)

Security Layer-Basis is a native citizen in any MSP/MSSP/SMB stack:

| Layer | Supported Platforms |
|-------|---------------------|
| **PSA** (ticketing) | ConnectWise PSA · Autotask · HaloPSA · Syncro |
| **SIEM** (visibility) | Microsoft Sentinel · Splunk · Elastic · QRadar |
| **SIEM formats** | CEF · ECS (Elastic) · Splunk CIM · Sentinel REST |
| **RMM** (deployment) | NinjaOne · Datto RMM · N-able · Kaseya VSA · ConnectWise RMM |
| **Automation** | Webhook (HMAC-signed) · Rewst · Zapier · Tines · Make · n8n |
| **API** | REST API v1 (read + write + MSSP multi-tenant scopes) |
| **Partner programs** | ConnectWise Invent · N-able TAP · Microsoft MISA (roadmap) |
| **ATT&CK** | All 21 rules mapped to MITRE ATT&CK technique IDs |

Every security event is automatically enriched with MITRE ATT&CK technique IDs and routed to the right channel — PSA ticket, SIEM event, webhook — without leaving the tools the MSP already uses.

### Integration Bus Routing (default, configurable per tenant)

| Verdict Severity | PSA Ticket | SIEM Event | Webhook | Alert |
|-----------------|:----------:|:----------:|:-------:|:-----:|
| CRITICAL        | ✅ | ✅ | ✅ | ✅ |
| HIGH            | ✅ | ✅ | ✅ | — |
| MEDIUM          | — | ✅ | ✅ | — |
| LOW / AUDIT     | — | ✅ | — | — |
| HOLD            | ✅ | — | — | — |
| DENY            | — | ✅ | — | — |

### MSP Go-Live Checklist

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

DAY 2 — Tuning
□ Review first 24h of events in SLB dashboard
□ Approve any legitimate skills flagged by SI-002
□ Adjust severity routing in policy.yaml if needed

WEEK 1 — Automation (optional)
□ Register webhook endpoint (Rewst / Zapier)
□ Create automation: CRITICAL event → notify on-call via Teams/Slack
□ Create automation: resolved event → close PSA ticket + add resolution note
```

---

## Architecture Comparison: v1 → v6

| Dimension | v1 | v2 | v3 | v4 | v5 | v6 |
|-----------|----|----|----|----|----|----|
| Event types | 6 | 12 | 14 | 17 | 17 | 17 + delivery metadata |
| Rule classes | 5 | 9 | 13 | 21 | 21 | 21 (unchanged) |
| ML models | 4 | 7 | 8 | 10 | 10 | 10 (unchanged) |
| Threat coverage | 9/30 | 14/30 | 22/30 | 30/30 | 30/30 | 30/30 (unchanged) |
| Security posture | Detect | Detect | Detect | P+V+D | P+V+D | P+V+D+**Integrate** |
| PSA integration | — | — | — | — | — | ✅ 4 PSAs |
| SIEM integration | — | — | — | — | — | ✅ 4 formats |
| ATT&CK mapping | — | — | — | — | — | ✅ 21 rules mapped |
| Webhook engine | — | — | — | — | — | ✅ HMAC-signed, retry, DLQ |
| REST API | — | — | — | — | — | ✅ v1 (read+write+MSSP) |
| RMM deployment | — | — | — | — | — | ✅ 5 RMMs |
| Partner programs | — | — | — | — | — | ✅ CW Invent + N-able TAP path |
| Multi-tenant MSSP | — | Console | Console | Console | Console | ✅ API + console + policy broadcast |

---

## Roadmap

| Phase | Milestone | Target |
|-------|-----------|--------|
| v0.1–v0.5 | Architecture v1–v5 (detection, prevention, verification, independence) | ✅ Designed |
| **v0.6** | **Integration Bus + Webhook Engine + Tenant Config Store** | Q1 2027 |
| **v0.7** | **PSA Adapter Layer: ConnectWise + Autotask** | Q1 2027 |
| **v0.8** | **SIEM Formatter: CEF + Sentinel REST + Splunk HEC + ECS** | Q1 2027 |
| **v0.9** | **ATT&CK Mapper (21 rules mapped)** | Q1 2027 |
| **v0.10** | **REST API v1 (read + write + MSSP scopes)** | Q2 2027 |
| **v0.11** | **RMM Deployment Scripts (NinjaOne, Datto, N-able, Kaseya)** | Q2 2027 |
| v1.0 | Full platform launch — detection + integration — 30/30 threats | Q2 2027 |
| v1.1 | ConnectWise Invent certification + N-able TAP listing | Q3 2027 |
| v1.2 | HaloPSA + Syncro adapters + PSA long-tail | Q3 2027 |
| v1.3 | OAuth2 + partner app scopes + sandbox environment | Q4 2027 |
| v1.4 | Splunk TA (Splunkbase) + Elastic package registry | Q4 2027 |
| v1.5 | Microsoft MISA application + Azure Marketplace listing | Q1 2028 |
| v2.0 | Own Skill Registry public API — expose scored index to ecosystem | Q1 2028 |

---

## Document Index

| Document | Description |
|----------|-------------|
| [`ARCHITECTURE.md`](./ARCHITECTURE.md) | v1 — original hook layer design |
| [`ARCHITECTURE_V2.md`](./ARCHITECTURE_V2.md) | v2 — HITL tracking, Skill Identity Registry |
| [`ARCHITECTURE_V3.md`](./ARCHITECTURE_V3.md) | v3 — memory injection coverage, sub-skill depth |
| [`ARCHITECTURE_V4.md`](./ARCHITECTURE_V4.md) | v4 — prevention + verification layers |
| [`ARCHITECTURE_V5.md`](./ARCHITECTURE_V5.md) | v5 — own registry, air-gap capable |
| [`ARCHITECTURE_V6.md`](./ARCHITECTURE_V6.md) | **v6 — integration-first platform (current)** |
| [`THREAT_MODEL.md`](./THREAT_MODEL.md) | Threat class definitions and trust boundaries |
| [`SMB_ARCHITECTURE.md`](./SMB_ARCHITECTURE.md) | SMB edition: user flows, MSSP/SI/Admin modes (v2.0) |
| [`VALIDATION_REPORT.md`](./VALIDATION_REPORT.md) | Tego Skills Index validation: 5 gaps in v1 → closed in v2 |
| [`REPORT_MemoryInjectionNestedSkills.md`](./REPORT_MemoryInjectionNestedSkills.md) | snailsploit Memory Injection research → v3 coverage |
| [`REPORT_VibeTokens9Guardrails.md`](./REPORT_VibeTokens9Guardrails.md) | 9 Claude Code Guardrails → v4 coverage |
| [`REPORT_IndependenceAudit.md`](./REPORT_IndependenceAudit.md) | Independence audit → v5 coverage |
| [`RESEARCH_IntegrationLandscape.md`](./RESEARCH_IntegrationLandscape.md) | Integration landscape research (basis for v6) |

---

## Research References

- [Tego Skills Security Index](https://tego.dev) — 2,492 skills, 103 Critical, 10-dimension capability matrix
- [Memory Injection Through Nested Skills](https://snailsploit.com/ai-security/prompt-injection/memory-injection-nested-skills/) — Kai Aizen, Feb 2026
- [Self-Replicating Memory Worm](https://snailsploit.com/ai-security/self-replicating-memory-worm/) — Kai Aizen
- [9 Claude Code Guardrails](https://www.vibetokens.io/blog/9-claude-code-guardrails-that-separate-pros-from-prompt-and-pray) — Jason Murphy / VibeTokens, Apr 2026
- AATMF (Adversarial AI Threat Modeling Framework) — accepted into OWASP GenAI Security Project 2026
- OWASP LLM Top 10: LLM01 (Prompt Injection), LLM05 (Supply Chain), LLM07 (Insecure Plugin Design)

---

*Architecture by Sharon · AI Analysis by Genspark Claw*  
*Last updated: 2026-04-23*
