# Security Layer-Basis — MVP v1

**Sub-project of:** [`security-layer-basis/`](../) (currently at v6.0)  
**Status:** MVP — Q3 2026 target launch  
**Posture:** DETECT → BLOCK (MVP) → PREVENT → VERIFY (v1.1 fast-follow)  
**Threat coverage:** 6/30 highest-priority classes (forward-compatible to v6's 30/30)

---

## What This Is

The smallest deployable subset of the full v6 architecture — engineered to ship fast and stop the highest-confirmed-impact attacks on day one, while maintaining every security rule from the parent project.

> *"Ship the smallest thing that stops the real attacks. Add everything else once you have real traffic."*

## What's In

| Area | MVP scope |
|------|-----------|
| Hook agent | VS Code + Claude Code CLI (~80% of AI coding agent usage) |
| Event types | 8 of 17 (HITL, skill, credential, reverse-shell signals) |
| Rule classes | 7 of 21 (HITL-001, SI-001, SI-002, CE-001, RS-001, MCP-001, FS-002) |
| ML models | 3 of 10 (reverse_shell, prompt_injection_bert, skill_intent_mismatch) |
| Verdicts | ALLOW · WARN · BLOCK · KILL_SESSION |
| PSA | ConnectWise (only) |
| Webhook | HMAC-SHA256, retry, DLQ — universal alert delivery |
| SIEM | None (webhook covers MVP needs) |
| Skill registry | Own SQLite — no Tego dependency |
| Multi-tenancy | Yes — from day one |
| Transport | mTLS gRPC (no downgrade path) |

## Priority Guards (Highest)

1. **HITL-001** — autonomous AI agents acting with no human checkpoint
2. **SI-001 / SI-002** — skill identity scan against own registry
3. **CE-001 / RS-001** — credential exfil + reverse shell (CRITICAL)

## What's Out (v1.1+ Fast-Follow)

- Prevention layer (full pre-read deny)
- Verification layer (completion gates, commit gates, truncation guard)
- Memory write interception
- Sub-skill depth tracking
- Cross-event correlation engine
- SIEM native connectors (Sentinel, Splunk, Elastic)
- Other PSA adapters (Autotask, HaloPSA, Syncro)
- REST API v1
- RMM deployment scripts
- Other IDE hooks (JetBrains, Cursor, Neovim)

All listed in [`MVParchitecture_v1.md`](./MVParchitecture_v1.md) §12 upgrade path.

## Documents

| File | Purpose |
|------|---------|
| [`MVParchitecture_v1.md`](./MVParchitecture_v1.md) | Canonical MVP architecture |
| [`CLAUDE.md`](./CLAUDE.md) | Session context: scope, tech stack, commands, conventions |
| [`mcp.json`](./mcp.json) | MCP server configs (MVP-scoped) |
| [`settings.json`](./settings.json) | Permissions, model, hooks |
| [`policy.yaml`](./policy.yaml) | Sample MVP policy (reference implementation) |
| `rules/` | Modular coding/style/security rules |
| `commands/` | Custom slash commands |
| `skills/` | Auto-triggered context skills |
| `agents/` | Specialized sub-agents |
| `hooks/` | Pre/post tool-use scripts |

## Key Slash Commands

```
/validate-policy        Validate policy.yaml against MVP schema
/run-tests              Run the test suite
/check-hitl             Sanity-check HITL-001 wiring (release-blocker check)
```

## Security Constraints (Inherited From Parent)

All non-negotiable in MVP:

1. No secrets in code, logs, or git history
2. All credentials encrypted at rest (Vault)
3. mTLS between hook and engine
4. TLS 1.3 only for external delivery
5. HMAC-SHA256 on all webhooks
6. No external API in ML hot path
7. Tenant isolation enforced at DB layer
8. No PII in transit (developer IDs hashed)
9. HITL-001 cannot be silently disabled
10. Skill registry calls fall back to WARN, never ALLOW

See [`rules/security.md`](./rules/security.md).

## Roadmap

| Milestone | What | Target |
|-----------|------|--------|
| **MVP v1.0** | This sub-project shipped | **Q3 2026** |
| v1.1 | Prevention + Verification + 4 more ML + Autotask PSA | Q4 2026 |
| v1.2 | All 17 event types + all 21 rules + JetBrains/Cursor hooks | Q1 2027 |
| v1.3 | SIEM native + REST API v1 + RMM scripts | Q2 2027 |
| v1.4 (= full v6) | Remaining PSAs + ATT&CK dashboard + ConnectWise Invent cert | Q3 2027 |

## Success Criteria (MVP → v1.1)

- 30 days of production traffic from ≥ 3 design partners
- HITL-001 false-positive rate < 5% before escalating to BLOCK
- SI-002 baseline: < 10 unknown skills/dev/week
- Zero CRITICAL escapes (no missed RS-001, CE-001, SI-001:Critical events)

---

*Sub-project of: security-layer-basis/*  
*Architecture by Sharon · Designed by Genspark Claw*  
*Last updated: 2026-04-28*
