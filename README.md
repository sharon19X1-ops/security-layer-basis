# Security Layer-Basis

**Universal AI Coding Agent Security Interception Platform**  
One detection engine. One policy. Every IDE. Every agent.

---

## What This Is

Security Layer-Basis is an architecture project for a transparent, zero-impact security enforcement layer across all AI-assisted developer workflows.

Every IDE (VS Code, JetBrains, Cursor, Neovim, CLI) connects through a thin hook layer to a centralized detection engine. Security teams write one policy. It applies everywhere.

The architecture has evolved through four versions, each validated against real-world research and production deployment patterns.

---

## Architecture Versions

| Version | Basis | Key Addition | Threat Coverage |
|---------|-------|--------------|-----------------|
| [v1](./ARCHITECTURE.md) | Original design | Hook layer, 6 event types, 5 rule classes | 9/30 |
| [v2](./ARCHITECTURE_V2.md) | Tego Skills Index validation | HITL tracking, Skill Identity Registry, multi-agent visibility | 14/30 |
| [v3](./ARCHITECTURE_V3.md) | snailsploit Memory Injection research | Sub-skill depth tracking, memory write interception, cross-event correlation | 22/30 |
| [v4](./ARCHITECTURE_V4.md) | VibeTokens 9 Guardrails | Prevention layer, verification layer, completion gates, rationalization detection | **30/30** |

---

## Validation Reports

| Report | Source | Finding |
|--------|--------|---------|
| [Tego Index Validation](./VALIDATION_REPORT.md) | Tego Skills Security Index (2,492 skills, 103 Critical) | 5 gaps in v1 → all closed in v2 |
| [Memory Injection / Nested Skills](./REPORT_MemoryInjectionNestedSkills.md) | [snailsploit.com research](https://snailsploit.com/ai-security/prompt-injection/memory-injection-nested-skills/) — Kai Aizen, Feb 2026 | v3 covers 50% of attack chain → v3 closes 6/6 stages |
| [9 Claude Code Guardrails](./REPORT_VibeTokens9Guardrails.md) | [VibeTokens](https://www.vibetokens.io/blog/9-claude-code-guardrails-that-separate-pros-from-prompt-and-pray) — Jason Murphy, Apr 2026 | v3 covers 0/9 guardrails fully → v4 closes all 9 |

---

## v4 Architecture — Security Posture

```
v1–v3 posture:  DETECT → ALERT → BLOCK
v4 posture:     PREVENT → VERIFY → DETECT → BLOCK
```

### Three Layers

**Prevention Layer** (new in v4)
- Credential deny list enforcer — blocks reads of `.env`, `id_rsa`, `.pem`, etc. before they happen
- Filesystem scope enforcer — CI/CD, deploy manifests, infra files are read-only

**Verification Layer** (new in v4)
- Completion gate — agent cannot claim "done" without test/lint evidence
- Commit gate — `git commit` blocked without passing test suite
- Truncation guard — actions blocked when context window was saturated mid-read
- Rationalization detector — catches agent evasion language ("should work now", "same pattern")

**Detection Layer** (v1–v3, fully retained)
- 21 rule classes across prompt injection, credential exfil, skill identity, memory poisoning, multi-agent trust, sub-skill depth, output quality, blast radius, and more
- 10 ML models
- Cross-event correlation engine (4 patterns)

---

## Threat Coverage Matrix (v4)

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

## Event Schema (v4)

17 event types across four generations:

```
v1: PROMPT_SUBMITTED · COMPLETION_RECEIVED · SHELL_EXEC · FILE_WRITE · NETWORK_REQUEST · MCP_CONNECT
v2: PROCESS_SPAWN · FILE_WRITE_AGENT_INST · AGENT_SPAWN · HITL_CHECKPOINT · SKILL_LOAD · TOOL_INVOKE
v3: MEMORY_WRITE · SKILL_SUBLOAD
v4: TASK_COMPLETE · DATA_TRUNCATION · LINT_RESULT
```

---

## Rule Classes (v4)

21 rules across 9 categories:

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

## ML Model Suite (v4)

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

## Additional Documents

- [`THREAT_MODEL.md`](./THREAT_MODEL.md) — Threat class definitions and trust boundaries
- [`SMB_ARCHITECTURE.md`](./SMB_ARCHITECTURE.md) — SMB edition: user flows, MSSP/SI/Admin modes

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
*Last updated: 2026-04-20*
