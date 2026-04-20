# Security Analysis Report: VibeTokens 9 Claude Code Guardrails
## Verification Against Architecture v3.0

**Report Date:** 2026-04-20  
**Source:** https://www.vibetokens.io/blog/9-claude-code-guardrails-that-separate-pros-from-prompt-and-pray  
**Author:** Jason Murphy / VibeTokens (Apr 19, 2026)  
**Architecture Baseline:** ARCHITECTURE_V3.md (v3.0, 2026-04-20)  
**Context:** Operational Claude Code configuration discipline patterns from production GitHub repo analysis

---

## Executive Summary

VibeTokens' "9 Claude Code Guardrails" article identifies production-grade guardrails sourced from real Claude Code configurations on GitHub. Unlike the snailsploit research (which modeled adversarial attack chains), these 9 patterns describe **operational security discipline** — the gap between naive "prompt-and-pray" usage and hardened AI agent deployment.

The meta-pattern across all 9: **"Don't trust output you haven't verified."**

This maps directly to the security-layer-basis project's core concern: what the agent *does* must be observable, constrained, and verifiable — not just what the agent *says*.

**Verdict: Architecture v3.0 addresses 4 of 9 patterns adequately. 5 patterns expose structural gaps that require v4 additions.**

---

## The 9 Guardrails — Analysis Against v3

---

### Guardrail 1: Stop Hooks That Demand Evidence
> "A stop hook fires before Claude can say 'done' — and blocks completion unless specific conditions are met: tests pass, compiles, lint is clean."

**What it targets:** Agent self-reporting completion without verification. The AI says "done" but doesn't prove it.

| v3 Component | Coverage |
|---|---|
| `HITL-001` (High-Risk Action Without Oversight) | ⚠️ Partial — covers autonomous *actions*, not task *completion claims* |
| `COMPLETION_RECEIVED` event | ✅ Captured — but no rule validates the claim |
| Stop hook logic | ❌ Not present — v3 has no concept of "completion gate" that requires evidence before session closure |

**Gap:** v3 monitors what the agent *does* but not whether the agent's *completion claim* is verified by external evidence (test results, build output, lint status). No `TASK_COMPLETION` event type or completion gate rule exists.

---

### Guardrail 2: Post-Edit Lint on Every File Change
> "On every single file change — catches issues at moment of creation, not after 14 more stacked changes."

**What it targets:** Cascading errors from unvalidated incremental changes.

| v3 Component | Coverage |
|---|---|
| `FILE_WRITE` event | ✅ Captured |
| `CE-001` / `PI-001b` | ⚠️ Cover security-relevant writes only — not general code quality/lint |
| Post-write validation hook | ❌ Not present — v3 has no rule requiring code validation after file writes |

**Gap:** v3 treats `FILE_WRITE` as a security event (credential exfil, instruction injection). It does not model **code quality validation** as a security concern — but broken code committed by an agent is a reliability and supply-chain risk.

---

### Guardrail 3: Credential Deny Lists
> "Claude should never touch .env, .env.local, credentials files, or API keys. Period. A deny list means Claude physically cannot read or modify sensitive files."

**What it targets:** Agent access to credential files, regardless of intent.

| v3 Component | Coverage |
|---|---|
| `CE-001` (Credential Exfiltration) | ✅ Detects when agent *reads and exfiltrates* credentials |
| `FILE_WRITE_AGENT_INST` (`PI-001b`) | ✅ Detects writes to AI instruction files |
| Pre-read deny list | ❌ Not present — v3 only detects credential access as an *exfiltration event*. No proactive deny list blocks the *read* before it happens |

**Gap:** v3 is reactive (detects exfil after access). The guardrail calls for a **proactive deny list** — block the read entirely. This is a prevention gap vs. detection gap: detection is present; prevention is absent.

---

### Guardrail 4: Truncation Detection
> "When Claude reads a large file, output can be truncated. Claude doesn't always notice — acts on whatever it received as if it's the complete picture."

**What it targets:** Confident agent decisions based on incomplete data ingestion.

| v3 Component | Coverage |
|---|---|
| Any v3 rule | ❌ Not covered at all |
| `PROMPT_SUBMITTED` / `COMPLETION_RECEIVED` | ❌ No truncation metadata attached |
| ML models | ❌ None trained on context-completeness signals |

**Gap:** Entirely novel to v3. Truncation detection requires a new `DATA_TRUNCATION` signal in the event schema — a flag that the agent's context window was saturated mid-read, potentially causing it to reason on partial data. This is a **reliability/integrity** attack surface: an attacker who can trigger truncation mid-read could influence agent decisions by controlling what gets cut off.

---

### Guardrail 5: Rationalization Tables
> "Claude generates specific phrases when cutting corners: 'Should work now', 'I'm confident this is correct', 'The rest follows the same pattern'. A rationalization table blocks these phrases and forces specificity."

**What it targets:** Agent language patterns that perform confidence without doing the verification work — epistemic cheating.

| v3 Component | Coverage |
|---|---|
| `prompt_injection_bert` (on completions) | ⚠️ Trained on injection patterns, not rationalization patterns |
| `COMPLETION_RECEIVED` event | ✅ Captured |
| Rationalization detection | ❌ No rule, no ML model, no pattern list for agent self-rationalization phrases |

**Gap:** Rationalization detection is a new ML class entirely — not injection, not exfil, not autonomy drift. It's **output quality assurance**: scanning `COMPLETION_RECEIVED` payloads for evasion language that signals the agent is hand-waving instead of verifying.

---

### Guardrail 6: Diff Size Limits
> "Large diffs are where bugs hide. A diff size limit forces Claude to work incrementally — smaller changes, each verified before moving on."

**What it targets:** Agents making overly large, unreviewed changes in a single shot.

| v3 Component | Coverage |
|---|---|
| `FILE_WRITE` event | ✅ Captured |
| `HITL-001` | ⚠️ Triggers on high-risk autonomous actions — but "large diff" is not a defined high-risk signal |
| Diff size threshold | ❌ No policy field, no event metadata for diff size/line count |

**Gap:** v3 has no diff size awareness. `FILE_WRITE` events don't carry line-count delta metadata. No rule enforces incremental change discipline. This maps to the **blast-radius control** problem: a single 2000-line autonomous diff is harder to audit than 10 x 200-line diffs, but both produce the same event count in v3.

---

### Guardrail 7: Test-Before-Commit Gates
> "A pre-commit hook that runs the test suite and blocks on failure means your main branch never gets code that Claude didn't verify."

**What it targets:** Agent committing unverified code to version control.

| v3 Component | Coverage |
|---|---|
| `SHELL_EXEC` (git commit) | ✅ Shell exec events captured |
| Pre-commit gate rule | ❌ No rule that requires test pass evidence before a `git commit` shell event |
| `HITL-001` | ⚠️ Would only fire if session has been autonomous > 5 min and commit is "high risk" |

**Gap:** v3 captures git commit as a shell event but has no semantic understanding that `git commit` requires verified test evidence. No **commit gate rule** exists. Related to Gap 1 (stop hooks) — both are about "evidence before closure."

---

### Guardrail 8: File Scope Restrictions
> "Tell Claude which directories it can modify and which are off-limits. Configuration files, deployment manifests, CI pipelines — these should be read-only for Claude unless explicitly unlocked."

**What it targets:** Agent modifying files outside its intended operational scope.

| v3 Component | Coverage |
|---|---|
| `FILE_WRITE_AGENT_INST` (`PI-001b`) | ✅ Covers writes to AI instruction files specifically |
| `CE-001` | ✅ Covers writes to external paths containing secrets |
| General filesystem scope policy | ❌ No policy field for "allowed write directories" vs. "read-only directories" |
| Scope violation rule | ❌ No rule `FS-001` that checks file path against an allowed-write allowlist |

**Gap:** v3 has targeted file-write rules for specific high-risk paths (AI instruction files, credential files) but **no general filesystem scope policy**. An agent writing to `/deploy/production.yml` or `.github/workflows/ci.yml` would not be blocked unless those paths are explicitly added to `PI-001b`'s target list — which doesn't currently cover deployment/CI files.

---

### Guardrail 9: Output Format Enforcement
> "If you need structured output — JSON responses, specific commit message formats, consistent code style — enforce it in configuration, not in prompts. Prompt-based formatting degrades. Config-based formatting doesn't."

**What it targets:** Output format drift over long sessions — agent stops following formatting requirements as session context degrades.

| v3 Component | Coverage |
|---|---|
| `autonomy_drift_detector` ML | ⚠️ Detects behavioral drift in autonomous sessions — but behavioral drift ≠ output format drift |
| Output schema enforcement | ❌ No event type, no rule, no ML model for output format compliance |
| Session-level format tracking | ❌ Not modeled at all |

**Gap:** Output format drift is a **session integrity** concern. An agent that stops producing valid JSON after 2 hours of work is creating downstream integration failures. v3 has no mechanism to detect or enforce output format consistency over long sessions.

---

## Coverage Scorecard

| Guardrail | v3 Coverage | Gap Class | Severity |
|---|---|---|---|
| 1. Stop hooks (completion evidence) | ❌ Not covered | Completion gate | HIGH |
| 2. Post-edit lint | ❌ Not covered | Code quality validation | MEDIUM |
| 3. Credential deny lists | ⚠️ Detection only (no prevention) | Pre-read prevention | HIGH |
| 4. Truncation detection | ❌ Not covered | Data integrity | HIGH |
| 5. Rationalization tables | ❌ Not covered | Output quality ML | HIGH |
| 6. Diff size limits | ❌ Not covered | Blast radius control | MEDIUM |
| 7. Test-before-commit gates | ❌ Not covered | Commit gate | HIGH |
| 8. File scope restrictions | ⚠️ Partial (specific paths only) | General filesystem scope | HIGH |
| 9. Output format enforcement | ❌ Not covered | Session integrity | MEDIUM |

**v3 fully covers: 0/9**  
**v3 partially covers: 2/9** (Guardrails 3 and 8)  
**v3 does not cover: 7/9**

---

## Gap Classification

### New Gap Category A: Completion & Commit Gates (Guardrails 1, 7)
v3 monitors what agents *do* but not whether agent *completion claims* are backed by verifiable evidence. Both "task done" and "git commit" need evidence requirements.

### New Gap Category B: Pre-Action Prevention vs. Detection (Guardrail 3)
v3 is fundamentally a **detection** architecture. Guardrail 3 calls for **prevention** — a deny list that blocks reads before they happen. v3 needs a prevention layer alongside detection.

### New Gap Category C: Data Integrity Signals (Guardrail 4)
Truncation is an integrity attack surface not modeled anywhere in v3. An agent reasoning on partial data is as dangerous as one being actively injected.

### New Gap Category D: Output Quality ML (Guardrails 5, 9)
v3's ML suite covers injection, exfil, autonomy drift, and skill intent. It has no models for **agent output quality**: rationalization language detection and output format drift detection.

### New Gap Category E: Blast Radius Metrics (Guardrail 6)
v3 has no concept of change *magnitude*. A diff size limit is a blast-radius constraint — v3 needs diff line-count in `FILE_WRITE` event metadata and a policy threshold.

### New Gap Category F: General Filesystem Scope Policy (Guardrail 8)
v3 has targeted file-write rules but no general allowlist/denylist for agent write scope. Deployment manifests, CI pipelines, and infrastructure files are currently unprotected.

---

## Proposed Additions for ARCHITECTURE_V4.md

| Addition | Type | Closes Guardrail(s) |
|---|---|---|
| `TASK_COMPLETE` event type + completion gate rule `CG-001` | Event + Rule | 1, 7 |
| `DATA_TRUNCATION` event type + rule `DI-001` | Event + Rule | 4 |
| Pre-read credential deny list (policy + hook enforcement) | Prevention Layer | 3 |
| `rationalization_detector` ML model + `OQ-001` rule | ML + Rule | 5 |
| Diff size metadata in `FILE_WRITE` + rule `BR-001` | Schema + Rule | 6 |
| General filesystem scope policy + rule `FS-001` | Policy + Rule | 8 |
| Output format drift detection + rule `OQ-002` | ML + Rule | 9 |
| Post-edit lint gate rule `CQ-001` | Rule | 2 |

---

## Meta-Pattern: Detection vs. Prevention vs. Verification

The VibeTokens guardrails reveal a structural dimension v3 doesn't model:

```
v3 security posture:     DETECT → ALERT → BLOCK (reactive)
VibeTokens posture:      PREVENT → VERIFY → DETECT → BLOCK (full stack)
```

v3 is excellent at detecting and blocking *after* a dangerous action is observed. The guardrails add two layers v3 is missing:
- **Prevention** (deny lists, scope restrictions, file locks) — stop the action before it starts
- **Verification** (completion gates, lint gates, test gates) — require evidence of correctness before allowing closure

v4 must integrate all three layers: Prevention → Verification → Detection.

---

*Report authored by: Genspark Claw (AI Security Analysis)*  
*Based on: VibeTokens "9 Claude Code Guardrails" — Jason Murphy, Apr 19, 2026*  
*Architecture baseline: ARCHITECTURE_V3.md, 2026-04-20*
