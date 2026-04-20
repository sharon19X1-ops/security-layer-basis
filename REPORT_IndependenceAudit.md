# Independence Audit Report: Skill Registry Dependency on Tego

**Report Date:** 2026-04-20  
**Scope:** ARCHITECTURE_V2.md → V4.md  
**Issue:** Tego external feed dependency embedded in security-critical path  
**Conclusion:** Architecture is NOT independent — 6 specific coupling points identified  
**Resolution:** Full independence design in ARCHITECTURE_V5.md

---

## The Problem Statement

> "The interceptor engine should include a skill registry you build based on Tego's structure, but the engine should not wait for their registry. We act as an independent product."

This is both a **security principle** and a **product principle**:

- **Security:** A detection engine that depends on a third-party API to make blocking decisions has an availability-coupled threat window. If Tego is down → SI-001 and SI-002 can't fire → skill identity checking silently fails.
- **Product:** An independent security product cannot have a core capability gated on a third-party commercial service's uptime, pricing, or API policy changes.

---

## Coupling Points Found (v2–v4)

### Coupling 1: SI-001 calls `tego_registry_check` directly

```yaml
# ARCHITECTURE_V2.md / V3.md / V4.md — SI-001
detect:
  - tego_registry_check:          # ← HARD EXTERNAL DEPENDENCY
      skill_id: "{event.skill.skill_id}"
      creator: "{event.skill.creator}"
      version_hash: "{event.skill.version_hash}"
    conditions:
      - tego_score.risk: ["High", "Critical"]
      - tego_score.dimension_mismatch: true
```

**Risk:** Rule SI-001 cannot fire without a live Tego API response. Any Tego outage, rate limit, or API key expiry silently disables mismatch detection.

---

### Coupling 2: SI-002 calls `tego_registry_check` for unknown skill detection

```yaml
# ARCHITECTURE_V2.md / V3.md / V4.md — SI-002
detect:
  - tego_registry_check:          # ← HARD EXTERNAL DEPENDENCY
      skill_id: "{event.skill.skill_id}"
    result: NOT_FOUND
  - skill.tego_score: null
```

**Risk:** "Unknown skill" detection depends entirely on whether Tego has the skill in its index. A newly published skill — or a locally-created malicious skill — that Tego hasn't indexed yet would score as `NOT_FOUND`... which is exactly what SI-002 is meant to catch. But the rule itself requires Tego to definitively say `NOT_FOUND`. Without the connection, no verdict is possible.

---

### Coupling 3: SkillIdentity message carries `tego_score` as a required field

```protobuf
message SkillIdentity {
  string skill_id       = 1;
  string creator        = 2;
  string registry       = 3;
  string version_hash   = 4;
  RiskScore tego_score  = 5;   // ← EXTERNAL DEPENDENCY IN SCHEMA
  int32  depth          = 6;
  string parent_skill   = 7;
  string relative_path  = 8;
}
```

**Risk:** `tego_score` being in the core event schema means every `SKILL_LOAD` event is incomplete without a Tego lookup. Downstream enrichers and rules are designed expecting this field to be populated.

---

### Coupling 4: Policy field `allowlist_mode: "tego-gated"` as a named mode

```yaml
# policy.yaml
skills:
  allowlist_mode: "tego-gated"   # ← NAMED DEPENDENCY ON THIRD PARTY
  tego_max_risk: "Medium"
```

**Risk:** The primary recommended policy mode is named after and operationally dependent on a specific third-party service. If Tego changes its API, pricing, or shuts down, the policy itself becomes invalid.

---

### Coupling 5: Skill Identity Registry spec describes Tego as the primary data source

```
Data sources:
┌─────────────────────────────────────────────────────┐
│  Tego Index API (live feed of scored skills)    │    │  ← PRIMARY SOURCE
│  - 2,492+ skills with risk scores               │    │
│  - 10-dimension capability matrix per skill     │    │
│  - Intent vs. capability mismatch flags         │    │
└─────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────┐
│  Internal approved skill allowlist              │    │  ← SECONDARY
└─────────────────────────────────────────────────┘
Update frequency: hourly (Tego feed)
```

**Risk:** Internal allowlist is secondary. Tego feed is primary. This inverts the correct dependency order for an independent product.

---

### Coupling 6: Roadmap milestone "v0.2 — Tego feed integration" is load-bearing

```
| v0.2 | v2 architecture + Tego feed integration | Q2 2026 |
```

**Risk:** A roadmap milestone that makes a core capability (skill identity scoring) dependent on a third-party integration being live creates a single point of failure in the product launch path.

---

## What Independence Actually Means

An independent skill registry means:

1. **We own the scoring engine** — the 10-dimension capability matrix is our implementation, not a proxy to Tego's API
2. **We own the data** — we crawl, parse, and ingest skill definitions ourselves from public sources (GitHub, ClawHub, MCP registries)
3. **We own the update cadence** — our registry refreshes on our schedule, from our ingestion pipeline
4. **Tego is a reference dataset, not a dependency** — we used Tego's published research to design our scoring dimensions; we don't call their API at runtime
5. **Graceful degradation** — if any external enrichment fails, the engine falls back to local scoring, never goes blind

---

## Impact on Current Rules

| Rule | Current Coupling | Independence Fix |
|---|---|---|
| SI-001 | `tego_registry_check` → external call | Own `skill_registry_check` → local DB lookup |
| SI-002 | `tego_registry_check` → external call | Own `skill_registry_check` → local DB lookup |
| SI-003 | No coupling | No change needed |
| SI-004 | No coupling | No change needed |
| SI-005 | No coupling | No change needed |
| `SkillIdentity.tego_score` | External field | Rename to `risk_score`, populated by own engine |
| `allowlist_mode: tego-gated` | Named dependency | Rename to `risk-gated`, engine-agnostic |
| Skill Registry component | Tego as primary source | Own crawler + scorer as primary source |
| Roadmap v0.2 | Tego integration milestone | Replace with own registry ingestion pipeline |

---

*Independence Audit by: Genspark Claw*  
*Baseline: ARCHITECTURE_V4.md (2026-04-20)*
