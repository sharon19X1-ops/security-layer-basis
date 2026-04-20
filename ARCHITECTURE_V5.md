# Security Layer-Basis — Architecture v5.0

**Version:** 5.0  
**Date:** 2026-04-20  
**Basis:** Architecture v4.0 + Independence Audit  
**Core Change:** Full decoupling from Tego external feed — own Skill Scoring Engine replaces all `tego_registry_check` calls  
**Changes from v4:** Own Skill Ingestion Pipeline, Skill Scoring Engine, renamed schema fields, updated rules SI-001/002, updated policy schema, updated roadmap

---

## What Changed and Why

> "The interceptor engine should include a skill registry you build based on Tego's structure, but the engine should not wait for their registry. We act as an independent product."

The independence audit of v4 found **6 coupling points** where the architecture depended on Tego's live API at runtime:

1. `SI-001` calls `tego_registry_check` — detection blocked if Tego is unreachable
2. `SI-002` calls `tego_registry_check` — unknown skill detection fails without Tego response
3. `SkillIdentity.tego_score` field — schema incomplete without external lookup
4. Policy mode `allowlist_mode: "tego-gated"` — named dependency on a third party
5. Skill Identity Registry spec lists Tego as primary data source
6. Roadmap milestone "Tego feed integration" as a load-bearing launch dependency

**The fix:** We own the full skill scoring stack. Tego's published research (10-dimension framework, 2,492-skill dataset, risk methodology) informed our design — we do not call their API. The distinction:

```
v2–v4:  Tego research → Tego API (runtime) → our detection rules
v5:     Tego research → our Skill Scoring Engine (local) → our detection rules
```

The engine runs independently. It works on day 1, in an air-gapped environment, with no third-party account required.

---

## 1. High-Level Architecture (v5)

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                              DEVELOPER MACHINES                                  │
│                                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │ VS Code  │  │ JetBrains│  │  Cursor  │  │  Neovim  │  │ CLI Agent│         │
│  │  Hook v5 │  │  Hook v5 │  │  Hook v5 │  │  Hook v5 │  │  Hook v5 │         │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘         │
│       └──────────────────────────┬───────────────────────────────┘               │
│                                  │                                               │
│                    ┌─────────────▼──────────────────┐                           │
│                    │     Interceptor Agent v5        │                           │
│                    │                                 │                           │
│                    │  PREVENTION LAYER               │                           │
│                    │  ▸ Credential deny list enforcer│                           │
│                    │  ▸ Filesystem scope enforcer    │                           │
│                    │  ▸ Pre-read path blocker        │                           │
│                    │                                 │                           │
│                    │  CAPTURE LAYER                  │                           │
│                    │  ▸ Event capture (17 types)     │                           │
│                    │  ▸ Skill identity resolver      │  ← uses own registry     │
│                    │  ▸ Sub-skill depth tracker      │                           │
│                    │  ▸ Memory write interceptor     │                           │
│                    │  ▸ HITL session tracker         │                           │
│                    │  ▸ Process tree monitor         │                           │
│                    │                                 │                           │
│                    │  VERIFICATION LAYER             │                           │
│                    │  ▸ Completion gate evaluator    │                           │
│                    │  ▸ Commit gate evaluator        │                           │
│                    │  ▸ Lint/test result injector    │                           │
│                    │  ▸ Truncation signal detector   │                           │
│                    │                                 │                           │
│                    │  ▸ PII strip + batch + forward  │                           │
│                    └─────────────┬──────────────────┘                           │
└──────────────────────────────────┼───────────────────────────────────────────────┘
                                   │  TLS 1.3 / mTLS gRPC
                                   ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                        DETECTION ENGINE v5 (Server-Side)                         │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐  │
│  │                           GATEWAY LAYER                                     │  │
│  │   Auth · Rate Limiting · Tenant Isolation · Event Dedup · Schema Validate  │  │
│  └───────────────────────────────┬────────────────────────────────────────────┘  │
│                                  │                                               │
│  ┌───────────────────────────────▼────────────────────────────────────────────┐  │
│  │                          EVENT PIPELINE v5                                  │  │
│  │  ┌───────────┐  ┌──────────────┐  ┌──────────────────┐  ┌──────────────┐  │  │
│  │  │ Ingestion │─▶│  Normalizer  │─▶│  Risk Classifier │─▶│   Verdict    │  │  │
│  │  │  Queue    │  │  + Enricher  │  │  Engine          │  │   Router     │  │  │
│  │  └───────────┘  └──────────────┘  └──────────────────┘  └──────┬───────┘  │  │
│  └──────────────────────────────────────────────────────────────────┼──────────┘  │
│                                                                      │            │
│  ┌──────────────┐  ┌────────────────┐  ┌───────────────┐  ┌──────────────────┐ │
│  │ Policy Store │  │  Threat Intel  │  │  ML Models    │  │  Own Skill       │ │
│  │ (single YAML)│  │  Feed (live)   │  │  (10 models)  │  │  Registry (local)│ │
│  └──────────────┘  └────────────────┘  └───────────────┘  └──────────────────┘ │
│                              ↑ NO Tego API call at runtime                       │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │            Skill Scoring Engine          ← NEW (replaces Tego API)       │   │
│  │   Crawler · Parser · 10-Dim Scorer · Intent Analyzer · Risk DB           │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │              Cross-Event Correlation Engine (v3/v4 unchanged)            │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │              Verification State Store (v4 unchanged)                     │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                      │            │
│  ┌───────────────────────────────────────────────────────────────────▼──────────┐ │
│  │                           ACTION EXECUTOR                                    │ │
│  │  Block · Warn · Deny · Hold · Audit · Alert · Quarantine · Kill · HITL Gate │ │
│  └──────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐  │
│  │                         OBSERVABILITY PLANE                                  │  │
│  │  Audit Trail · SIEM · SOC Dashboard · HITL Console · Skill Map             │  │
│  │  Memory Audit Log · Sub-Skill Lineage Graph                                │  │
│  │  Completion Evidence Log · Diff Size Heatmap                               │  │
│  │  Skill Registry Health Dashboard (new — own pipeline metrics)   ← NEW     │  │
│  └────────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────────────────────────────────┐
                    │          Skill Ingestion Pipeline                 │
                    │                    ← NEW (background, async)     │
                    │                                                  │
                    │  Sources (public, no API key required):          │
                    │  ▸ GitHub (skill repos, SKILL.md crawl)         │
                    │  ▸ ClawHub.com (public skill index)              │
                    │  ▸ MCP registry (community connectors)           │
                    │  ▸ npm / PyPI (agent tool packages)              │
                    │  ▸ Manual operator submissions                   │
                    │                                                  │
                    │  Outputs → Own Skill Registry (local DB)         │
                    │  Schedule: async background, not in hot path     │
                    └──────────────────────────────────────────────────┘
```

---

## 2. New Component: Skill Scoring Engine

This is the central independence change. It replaces all `tego_registry_check` calls with local lookups against our own scored database.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         Skill Scoring Engine                                 │
│                              ← replaces Tego API dependency                 │
│                                                                              │
│  Design principle: Tego's research informed our scoring dimensions.          │
│  We do NOT call Tego at runtime. We implement the scoring ourselves.         │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  10-Dimension Risk Scorer (our implementation)                      │    │
│  │                                                                     │    │
│  │  Dimensions (derived from published AI security research):          │    │
│  │  1.  tools_risk          — tool access breadth + sensitivity        │    │
│  │  2.  code_execution_risk — shell, eval, subprocess capability       │    │
│  │  3.  web_access_risk     — outbound HTTP, fetch, crawl capability   │    │
│  │  4.  filesystem_risk     — read/write scope, path sensitivity       │    │
│  │  5.  data_access_risk    — PII, secrets, credentials in scope       │    │
│  │  6.  authentication_risk — OAuth, token, key management capability  │    │
│  │  7.  network_risk        — socket, proxy, tunnel capability         │    │
│  │  8.  system_risk         — OS calls, process mgmt, service control  │    │
│  │  9.  hitl_risk           — inverted: lower HITL = higher risk       │    │
│  │  10. multi_agent_risk    — sub-agent spawn, chain depth             │    │
│  │                                                                     │    │
│  │  Scoring method:                                                    │    │
│  │  - Static analysis: parse SKILL.md, extract tool declarations       │    │
│  │  - Capability scanning: regex + AST on skill code/config            │    │
│  │  - Intent vs. capability: NLP comparison of description vs. tools   │    │
│  │  - Version drift: hash comparison across versions                   │    │
│  │  - Output: risk_level (None/Low/Medium/High/Critical) per dimension │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Own Skill Registry (local DB)                                      │    │
│  │                                                                     │    │
│  │  Schema per skill entry:                                            │    │
│  │  - skill_id          string    unique identifier                    │    │
│  │  - creator           string    author/org                           │    │
│  │  - source_url        string    where we found it                    │    │
│  │  - version_hash      string    content hash at time of scoring      │    │
│  │  - risk_score        RiskScore our 10-dimension score               │    │
│  │  - risk_level        enum      None/Low/Medium/High/Critical        │    │
│  │  - dimension_scores  map       per-dimension breakdown              │    │
│  │  - intent_mismatch   bool      description vs. capability flag      │    │
│  │  - last_scored_at    timestamp                                      │    │
│  │  - ingestion_source  string    github/clawhub/mcp/npm/manual        │    │
│  │  - operator_approved bool      explicit org approval flag           │    │
│  │  - operator_notes    string    human annotation (optional)          │    │
│  │                                                                     │    │
│  │  Storage: embedded SQLite (single-node) / Postgres (cluster)        │    │
│  │  Lookup: skill_id + version_hash → O(1) indexed lookup             │    │
│  │  Cache: in-memory LRU (10k entries, 1hr TTL)                        │    │
│  │  Latency: < 1ms p99 (cache hit), < 3ms p99 (DB lookup)             │    │
│  │                                                                     │    │
│  │  Fallback when skill not found:                                     │    │
│  │  → Score the skill live from its SKILL.md content (< 50ms)         │    │
│  │  → Store result, never return "unknown, can't decide"               │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  Runtime API (internal only):                                                │
│    skill_registry_check(skill_id, creator, version_hash)                    │
│    → { risk_level, dimension_scores, intent_mismatch, operator_approved }   │
│                                                                              │
│  NEVER blocks on external network. Always returns a verdict.                 │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. New Component: Skill Ingestion Pipeline

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Skill Ingestion Pipeline                              │
│                              runs async, never in detection hot path         │
│                                                                              │
│  Purpose: continuously discover and score new skills from public sources,   │
│  keeping the local registry current without any third-party API dependency. │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Source Crawlers (pluggable)                                        │    │
│  │                                                                     │    │
│  │  ▸ GitHubCrawler                                                    │    │
│  │    - Searches for repos containing SKILL.md                         │    │
│  │    - Tracks: stars, forks, recent commits, issue keywords           │    │
│  │    - Rate-limit aware, uses public API (no auth required)           │    │
│  │                                                                     │    │
│  │  ▸ ClawHubCrawler                                                   │    │
│  │    - Crawls clawhub.com public skill index                          │    │
│  │    - Parses skill listings, extracts metadata                       │    │
│  │                                                                     │    │
│  │  ▸ MCPRegistryCrawler                                               │    │
│  │    - Community MCP connector listings (modelcontextprotocol.io)     │    │
│  │    - Tool capability extraction from connector manifests            │    │
│  │                                                                     │    │
│  │  ▸ PackageRegistryCrawler                                           │    │
│  │    - npm packages tagged: claude-skill, mcp-server, ai-agent-tool   │    │
│  │    - PyPI packages with similar classifiers                         │    │
│  │                                                                     │    │
│  │  ▸ ManualIngestion                                                  │    │
│  │    - Operator submits a skill URL or paste directly                 │    │
│  │    - Immediate scoring on submission                                │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Scoring Queue                                                      │    │
│  │  - Newly discovered skills enter queue                              │    │
│  │  - Skill Scoring Engine processes asynchronously                    │    │
│  │  - Priority: skills seen in live events score first                 │    │
│  │  - Background: scheduled full-index re-score (weekly)               │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Live-Event Triggered Scoring (critical path exception)             │    │
│  │                                                                     │    │
│  │  If a SKILL_LOAD event fires for a skill NOT in the registry:       │    │
│  │  1. Retrieve SKILL.md content from the event payload                │    │
│  │  2. Score immediately using Skill Scoring Engine (< 50ms)           │    │
│  │  3. Store result in registry                                        │    │
│  │  4. Return score to SI-001/SI-002 rules — no "unknown" verdict      │    │
│  │                                                                     │    │
│  │  This means SI-002 no longer detects "not in Tego" — it detects     │    │
│  │  "not in our registry AND scored as High/Critical on first scan."   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  Schedule:                                                                   │
│  - GitHub/ClawHub/MCP crawl: every 6 hours                                  │
│  - Full re-score of known skills: weekly (or on version_hash change)        │
│  - On-demand: triggered by live SKILL_LOAD miss                              │
│  - Operator manual: immediate                                                │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Updated Hook Event Schema (v5)

Only one change from v4: `tego_score` renamed to `risk_score` in `SkillIdentity`. All other schema is unchanged.

```protobuf
// UPDATED in v5 — removed Tego-specific field name
message SkillIdentity {
  string skill_id         = 1;
  string creator          = 2;
  string registry         = 3;   // source: "github.com" | "clawhub.com" | "manual"
  string version_hash     = 4;
  RiskScore risk_score    = 5;   // ← RENAMED from tego_score (our own scoring)
  int32  depth            = 6;
  string parent_skill     = 7;
  string relative_path    = 8;
  bool   operator_approved = 9;  // ← NEW: org-level explicit approval flag
  IngestionSource ingestion_source = 10; // ← NEW: where we got the skill from
}

enum IngestionSource {
  GITHUB         = 0;
  CLAWHUB        = 1;
  MCP_REGISTRY   = 2;
  NPM            = 3;
  PYPI           = 4;
  MANUAL         = 5;
  LIVE_SCORED    = 6;   // scored on first encounter from live event
}

// All other messages unchanged from v4
```

---

## 5. Updated Detection Rules (SI-001, SI-002)

The only functional change: `tego_registry_check` → `skill_registry_check` (our own local call). Semantics and actions unchanged.

### Updated: SI-001 — Skill Capability Mismatch

```yaml
- id: SI-001
  name: "Skill Capability Mismatch (Intent vs. Reality)"
  trigger: skill_load
  detect:
    - skill_registry_check:            # ← OWN REGISTRY (was: tego_registry_check)
        skill_id: "{event.skill.skill_id}"
        creator: "{event.skill.creator}"
        version_hash: "{event.skill.version_hash}"
      conditions:
        - risk_score.risk: ["High", "Critical"]    # ← risk_score (was: tego_score)
        - risk_score.intent_mismatch: true
  action: WARN
  alert: [developer, soc-channel]
  severity: HIGH
  availability: |
    skill_registry_check() is a LOCAL call to our own Skill Scoring Engine.
    It NEVER blocks on external network.
    If skill not found: live-scores from SKILL.md content within < 50ms.
    Verdict always returned — no silent failure mode.
```

### Updated: SI-002 — Unknown or Unscored Skill

```yaml
- id: SI-002
  name: "Skill Not in Registry — Scored on First Encounter"
  trigger: skill_load
  detect:
    - skill_registry_check:            # ← OWN REGISTRY (was: tego_registry_check)
        skill_id: "{event.skill.skill_id}"
      result: NOT_FOUND
    # On NOT_FOUND: pipeline triggers live scoring (< 50ms), result stored
    # Rule then re-evaluates with fresh score:
    - risk_score: null                  # ← risk_score (was: tego_score)
      OR risk_score.risk: ["High", "Critical"]
  action: WARN
  alert: developer
  severity: MEDIUM
  note: |
    SI-002 no longer means "Tego hasn't indexed this."
    It means "we haven't seen this skill before — scored it live,
    and it looks risky." The action is the same; the dependency is gone.
```

---

## 6. Updated Policy Schema (v5)

Removed all `tego_*` field names. Replaced with engine-agnostic equivalents.

```yaml
skills:
  allowlist_mode: "risk-gated"    # ← was "tego-gated" — engine-agnostic name
  max_risk_level: "Medium"        # ← was "tego_max_risk" — engine-agnostic
  creator_trust:
    - creator: "microsoft"
      max_risk_override: "High"
    - creator: "google-gemini"
      max_risk_override: "High"
  unknown_skill_action: "WARN"
  max_subskill_depth: 1
  audit_all_modules: true
  memory_write_access: "deny"

  # NEW in v5 — operator controls for own registry
  registry:
    live_score_on_miss: true       # score unknown skills immediately on encounter
    live_score_timeout_ms: 50      # max time before fallback to WARN
    operator_approve_required:     # these sources require explicit org approval
      - "manual"
      - "live_scored"
    auto_approve_sources:          # these sources are auto-trusted up to max_risk_level
      - "github"
      - "clawhub"
      - "mcp_registry"
    rescore_on_version_change: true # re-score when version_hash changes
```

---

## 7. Graceful Degradation Model

A core independence requirement: the engine never goes blind. Every failure mode has a defined fallback.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                      Graceful Degradation Model                              │
│                                                                              │
│  Scenario 1: Skill found in registry (happy path)                           │
│  → skill_registry_check() → cache hit → < 1ms → full score returned         │
│  → SI-001 / SI-002 evaluate normally                                         │
│                                                                              │
│  Scenario 2: Skill not in registry (first encounter)                        │
│  → skill_registry_check() → cache miss → DB miss                            │
│  → Live-score from SKILL.md payload in event (< 50ms)                       │
│  → Store result → return score → SI-001 / SI-002 evaluate normally          │
│  → No external call. No blocking wait. Verdict always returned.              │
│                                                                              │
│  Scenario 3: SKILL.md not available in event payload                        │
│  → skill_registry_check() → NOT_FOUND, no content available                 │
│  → SI-002 fires with risk_level = UNKNOWN                                    │
│  → Action: WARN + flag for async scoring when content becomes available     │
│  → No silent failure. Operator sees the gap.                                 │
│                                                                              │
│  Scenario 4: Skill Scoring Engine down (internal failure)                   │
│  → skill_registry_check() returns cached result (up to 1hr TTL)             │
│  → If cache expired: SI-001 and SI-002 fall back to WARN on all skill loads │
│  → Alert: soc-channel "Skill Scoring Engine degraded — fallback active"     │
│  → Never silently passes skills through without evaluation                  │
│                                                                              │
│  Scenario 5: Air-gapped / offline deployment                                │
│  → Ingestion pipeline disabled (no crawling)                                │
│  → Registry pre-populated at deployment time from bundled dataset           │
│  → Live-scoring still works (uses only event payload content)               │
│  → Full SI-001/002 detection available with zero internet dependency        │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Risk Scoring Dimensions — Full Specification

Our implementation of the 10-dimension capability matrix. Derived from published AI security research (snailsploit, Tego public methodology, OWASP LLM Top 10). We own this implementation.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│               10-Dimension Risk Scoring — Our Implementation                 │
│                                                                              │
│  For each skill, we parse SKILL.md and associated files to score:            │
│                                                                              │
│  Dim 1: TOOLS_RISK                                                           │
│  - Count and sensitivity of declared tools                                   │
│  - Signals: tool_count > 5, external API tools, payment/messaging tools     │
│  - Score: None→Critical based on tool surface area                          │
│                                                                              │
│  Dim 2: CODE_EXECUTION_RISK                                                  │
│  - Does skill explicitly instruct code execution?                            │
│  - Signals: exec, shell, bash, python, eval, subprocess in instructions      │
│  - Score: Critical if skill can spawn processes                              │
│                                                                              │
│  Dim 3: WEB_ACCESS_RISK                                                      │
│  - Does skill fetch from arbitrary URLs?                                     │
│  - Signals: fetch, curl, http_request, crawl, scrape                        │
│  - Score: High if arbitrary URL access; Medium if allowlisted domains       │
│                                                                              │
│  Dim 4: FILESYSTEM_RISK                                                      │
│  - Does skill read/write files outside its working directory?                │
│  - Signals: path traversal patterns, /etc/, ~/.ssh/, write to config files  │
│  - Score: Critical if writes to sensitive paths                              │
│                                                                              │
│  Dim 5: DATA_ACCESS_RISK                                                     │
│  - Does skill access PII, secrets, or credentials?                          │
│  - Signals: env var reads, keychain access, database queries, user data      │
│  - Score: High/Critical based on data sensitivity                           │
│                                                                              │
│  Dim 6: AUTHENTICATION_RISK                                                  │
│  - Does skill handle or store auth tokens/keys?                              │
│  - Signals: OAuth flows, token refresh, credential storage                  │
│  - Score: Critical if skill stores credentials                               │
│                                                                              │
│  Dim 7: NETWORK_RISK                                                         │
│  - Does skill open raw sockets or create tunnels?                            │
│  - Signals: socket, proxy, tunnel, port_forward, ngrok                      │
│  - Score: Critical if raw socket or tunnel capability                        │
│                                                                              │
│  Dim 8: SYSTEM_RISK                                                          │
│  - Does skill interact with OS-level APIs?                                   │
│  - Signals: remindctl, keychain, systemctl, launchctl, registry writes      │
│  - Score: High/Critical based on OS privilege level                         │
│                                                                              │
│  Dim 9: HITL_RISK (inverted)                                                 │
│  - Does skill require or encourage human approval before actions?            │
│  - Signals: "confirm with user", HITL_CHECKPOINT calls, approval gates      │
│  - Score: Critical if no HITL signals found AND other dims are High+        │
│                                                                              │
│  Dim 10: MULTI_AGENT_RISK                                                    │
│  - Does skill spawn or orchestrate sub-agents?                               │
│  - Signals: sessions_spawn, agent_spawn, delegate, sub-agent                │
│  - Score: High if chain depth > 2; Critical if cross-boundary                │
│                                                                              │
│  COMPOSITE RISK LEVEL = max(all dimension scores)                            │
│  INTENT MISMATCH = NLP_similarity(description, tool_list) < 0.6 threshold   │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Independence Verification Checklist

| Check | v4 Status | v5 Status |
|---|---|---|
| SI-001 calls external API at detection time | ❌ Yes (Tego) | ✅ No (local call) |
| SI-002 calls external API at detection time | ❌ Yes (Tego) | ✅ No (local call) |
| Engine works with no internet connection | ❌ No | ✅ Yes (bundled dataset) |
| Engine works if Tego shuts down | ❌ No | ✅ Yes (unaffected) |
| Engine works on day 1, no third-party account | ❌ No | ✅ Yes |
| Schema field named after third party | ❌ `tego_score` | ✅ `risk_score` |
| Policy mode named after third party | ❌ `tego-gated` | ✅ `risk-gated` |
| Scoring dimensions are our own implementation | ❌ Proxied from Tego | ✅ Own implementation |
| Unknown skill always gets a verdict | ❌ Depends on Tego | ✅ Live-scored locally |
| Graceful degradation if scoring engine down | ❌ Not specified | ✅ Defined (4 scenarios) |
| Air-gapped deployment supported | ❌ Not possible | ✅ Yes (bundled dataset) |

**v4 independence score: 0/11**  
**v5 independence score: 11/11**

---

## 10. What Tego's Research Gave Us vs. What We Own

| Element | Source | Ownership |
|---|---|---|
| 10-dimension framework concept | Tego published research | Inspired by — we implement |
| 2,492-skill dataset scores | Tego index | Reference only — we rescore independently |
| Risk methodology (intent vs. capability) | Tego research | Inspired by — our own NLP implementation |
| Runtime API calls | Tego API | **Removed entirely in v5** |
| Scoring engine code | N/A | **Ours (v5)** |
| Skill registry database | N/A | **Ours (v5)** |
| Ingestion crawlers | N/A | **Ours (v5)** |
| Live-scoring on miss | N/A | **Ours (v5)** |

Tego's research is a cited reference — like OWASP or snailsploit. It informed our design. We don't call their API. We don't need their permission. We don't depend on their uptime.

---

## 11. Updated Architecture Comparison

| Dimension | v1 | v2 | v3 | v4 | v5 |
|-----------|----|----|-----|-----|-----|
| Event types | 6 | 12 | 14 | 17 | 17 (unchanged) |
| Rule classes | 5 | 9 | 13 | 21 | 21 (unchanged) |
| ML models | 4 | 7 | 8 | 10 | 10 (unchanged) |
| Threat coverage | 9/30 | 14/30 | 22/30 | 30/30 | 30/30 (unchanged) |
| Skill registry | None | Tego-dependent | Tego-dependent | Tego-dependent | **Own (independent)** |
| External API in hot path | None | Tego API | Tego API | Tego API | **None** |
| Air-gap capable | Yes | No | No | No | **Yes** |
| Day-1 ready (no 3rd party) | Yes | No | No | No | **Yes** |
| Unknown skill verdict | None | Tego or fail | Tego or fail | Tego or fail | **Live-scored locally** |
| Graceful degradation | N/A | Not specified | Not specified | Not specified | **4-scenario model** |

---

## 12. Updated Roadmap

| Phase | Milestone | Target |
|-------|-----------|--------|
| v0.1 | Architecture v1 | ✅ Done |
| v0.2 | v2 architecture (~~Tego feed integration~~ → own registry design) | Q2 2026 |
| v0.3 | All 17 event types + full hook layer | Q2 2026 |
| v0.4 | HITL tracker + **Own Skill Scoring Engine (v5)** | Q3 2026 |
| v0.5 | 10 ML models (all suite) | Q3 2026 |
| v0.6 | MEMORY_WRITE + SKILL_SUBLOAD + v3 rules | Q3 2026 |
| v0.7 | Prevention Layer (credential deny + filesystem scope) | Q3 2026 |
| v0.8 | Verification Layer (completion gate + commit gate) | Q4 2026 |
| v0.9 | **Skill Ingestion Pipeline (GitHub + ClawHub + MCP crawlers)** | Q4 2026 |
| v0.10 | Cross-Event Correlation Engine (4 patterns) | Q4 2026 |
| v0.11 | **Full registry pre-population (bundled dataset for air-gap)** | Q1 2027 |
| v1.0 | Full platform — 30/30 threat classes — SOC dashboard | Q1 2027 |
| v1.1 | Skill Registry public API (optional — share our scored index) | Q2 2027 |

> Note: v1.1 inverts the original dependency. Instead of consuming Tego's API, we optionally expose our own scored registry as a public API. Others can depend on us.

---

*Security Layer-Basis — Architecture v5.0*  
*Full independence from external skill registry APIs*  
*Research references: Tego methodology (cited), snailsploit (cited), VibeTokens (cited), OWASP LLM Top 10*  
*We build the scoring engine. We run the ingestion pipeline. We own the registry.*
