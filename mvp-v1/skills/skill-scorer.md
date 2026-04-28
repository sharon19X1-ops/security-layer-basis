# Skill Scorer Skill

**Type:** Auto-triggered context skill  
**Triggered when:** working on `internal/skills/`, `cmd/skill-ingester/`, or rules SI-001/SI-002  
**Purpose:** Provides the 10-dimension scoring schema and MVP scoring rules so contributors don't reinvent or drift the model.

---

## The 10 Capability Dimensions (same as v6)

The MVP skill registry uses the same 10-dimension matrix as the parent v6 architecture. **Schema-forward — do not simplify.**

| Dimension | What it measures |
|-----------|-----------------|
| `code_execution` | Shell/script/interpreter execution capability |
| `authentication` | Credential handling, token use |
| `web_access` | Unscoped web browsing, crawling |
| `file_system` | Read/write/delete on local FS |
| `data_access` | Sensitive data reads (credentials, PII) |
| `network` | Outbound connections, socket access |
| `system` | OS-level calls, process spawning |
| `hitl` | Whether the skill expects/enforces human checkpoints |
| `multi_agent` | Whether the skill spawns sub-agents |
| `tools` | External tool invocation risk |

Each dimension scored: **Pass · Low · Medium · High · Critical**.

## Overall risk score derivation

```
overall = max(dimension scores)

with the following modifiers:
- If code_execution = Critical AND hitl = "Not used"     → bump to Critical (highest blast radius)
- If authentication = Critical AND network = High         → bump to Critical (exfil chain)
- If multi_agent = High AND hitl = "Not used"             → bump to Critical (transitive trust)
```

These modifiers come from Tego index validation findings (parent `VALIDATION_REPORT.md`). The MVP must replicate them.

## MVP scoring policy (enforced by SI-001)

| Overall score | Action |
|--------------|--------|
| `Critical` | BLOCK |
| `High` | BLOCK |
| `Medium` | ALLOW + audit |
| `Low` | ALLOW |
| `Pass` | ALLOW |
| (not in registry) | WARN (SI-002) |

## Skill identity hashing

`version_hash`: SHA-256 of skill content at load time. Computed by hook at SKILL_LOAD event.

Used to detect:
- Skill content drift (skill ID matches but hash doesn't → registered version was tampered)
- Cache/lookup keying

## MVP ingestion sources

The skill registry ingests from:
1. **GitHub** — search for `SKILL.md`, `.cursorrules`, `AGENTS.md`, `CLAUDE.md` patterns in public repos
2. **ClawHub** — published skill index
3. **MCP server manifests** — public registries of MCP servers

Daily ingestion job (`cmd/skill-ingester/main.go`). Manually curated seed of 100 highest-star skills at MVP launch.

## Independence guarantee

**No runtime call to Tego or any external skill API.** Same as v6.

If the skill registry is unavailable when SI-001/SI-002 evaluates:
- Emit `WARN`, never `ALLOW`
- Log degraded mode
- Continue serving other rules

This is mandatory — the v5 Independence Audit specifically called out the failure mode where third-party API outage silently disables skill identity checking. MVP must inherit the fix.

## Reference: how to add a new skill manually

```bash
# Add a curated skill via CLI
go run cmd/skill-ingester/main.go add \
  --skill-id "my-org/internal-helper" \
  --creator "my-org" \
  --registry "local" \
  --version-hash "$(sha256sum path/to/SKILL.md | cut -d' ' -f1)" \
  --score-code-execution "Low" \
  --score-authentication "Pass" \
  ...
```

This adds the skill with explicit dimension scores. Useful for internal tools that should never be flagged as "unknown".

## Common pitfalls

- **Don't store full skill content in the registry.** Store hash + dimension scores + metadata only. Source content stays at the source.
- **Don't rate based on stated description alone.** The `skill_intent_mismatch` ML model exists because skills lie about what they do. Cross-check description against actual capabilities.
- **Don't auto-promote risk scores.** A skill that scored Medium last week should stay Medium until manually re-scored or re-ingested.
