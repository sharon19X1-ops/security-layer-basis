# /check-hitl

**Slash command** — sanity-check the HITL-001 wiring end-to-end.

## Why this exists

HITL-001 is the highest-priority rule in MVP. A regression that silently disables it (e.g., a field rename, a refactor that drops `hitl_present` enrichment, a routing change) is the worst-case MVP failure mode.

This command runs an end-to-end check that HITL-001 is actually firing.

## Usage

```
/check-hitl
```

## What it does

1. Builds the engine + injects 3 synthetic events:
   - **Event A:** SHELL_EXEC, `hitl_present=true`, `session_age_sec=10` → expect ALLOW
   - **Event B:** SHELL_EXEC, `hitl_present=false`, `session_age_sec=600` → expect WARN (HITL-001 fires)
   - **Event C:** MCP_CONNECT, `hitl_present=false`, `session_age_sec=600` → expect WARN (HITL-001 fires)

2. Verifies:
   - Verdicts match expected
   - Rule ID `HITL-001` recorded on B and C
   - ATT&CK mapping `T1078` returned
   - Audit log entry created
   - SOC dashboard alert generated (in dev mode)

3. Verifies HITL-001 cannot be disabled:
   - Tries to load a policy with `HITL-001.disabled: true` → must reject
   - Tries to remove HITL-001 from `policy.yaml.rules` → must reject

## Pass criteria

```
✅ HITL-001 wiring OK
   Event A (hitl_present=true)         → ALLOW       ✓
   Event B (autonomous shell)          → WARN        ✓ (rule HITL-001, T1078)
   Event C (autonomous mcp_connect)    → WARN        ✓ (rule HITL-001, T1078)
   Disable attempt rejected            → ✓
   Removal attempt rejected            → ✓
```

## Failure escalation

Any failure here is a **release blocker**. Page the on-call security engineer.

## Run command

```bash
go run cmd/check-hitl/main.go
```

## When to run

- Before every release
- After any change to `internal/rules/hitl/`
- After any change to `internal/enrichment/` (where `hitl_present` is computed)
- After any change to the policy loader
