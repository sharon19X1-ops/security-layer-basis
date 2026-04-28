# Policy Validator (MVP v1)

**Type:** Specialized sub-agent  
**Triggered by:** changes to `policy.yaml`, manual `/validate-policy` invocations  
**Auto-invoke on:** any write to `policy.yaml` (via `hooks/post-tool-use/run-tests.sh`)

---

## Role

Validates `policy.yaml` against the MVP v1 schema before changes are committed or deployed.

## Validation checks

### Structural
- [ ] `version: "1.0-mvp"` and `schema: "slb.mvp.v1"` present
- [ ] All required top-level keys present: `rules`, `ml_models`, `mcp_servers`, `skills`, `hitl`, `integrations`
- [ ] No unknown top-level keys

### Rules
- [ ] Exactly 7 rules in MVP (no more, no fewer — v1.1+ rules go in the `_deferred_to_v1_1` block, not in `rules:`)
- [ ] All MVP rule IDs present: HITL-001, SI-001, SI-002, CE-001, RS-001, MCP-001, FS-002
- [ ] Each rule has: `id`, `name`, `priority`, `trigger`, `detect`, `action`, `severity`, `att&ck`, `fixture`
- [ ] `action` ∈ {ALLOW, WARN, BLOCK, KILL_SESSION}
- [ ] `severity` ∈ {CRITICAL, HIGH, MEDIUM, LOW}
- [ ] `priority` ∈ {1, 2, 3}
- [ ] `trigger` references only the 8 MVP event types
- [ ] `att&ck` is a valid MITRE ATT&CK technique ID
- [ ] `fixture` path exists under `tests/fixtures/`

### ML models
- [ ] Exactly 3 models: `reverse_shell_classifier`, `prompt_injection_bert`, `skill_intent_mismatch`
- [ ] Each has `file`, `runtime: onnx`, `threshold`
- [ ] `prompt_injection_bert.used_by` is `[]` (advisory mode in MVP)

### HITL config
- [ ] `autonomous_threshold_sec` ≥ 60 (sanity check — anything lower will false-positive)
- [ ] `action_on_threshold` ∈ {WARN, BLOCK}
- [ ] In MVP default policy: `action_on_threshold == "WARN"` (escalate only after 30-day baseline)

### Integrations
- [ ] `psa.provider == "connectwise"` (only PSA in MVP)
- [ ] `psa.ticket_on_severity` includes both `CRITICAL` and `HIGH`
- [ ] `webhooks.require_tls == true`
- [ ] `webhooks.require_hmac_verification == true`
- [ ] Routing: `CRITICAL` and `HIGH` both route to `psa` and `webhook`

### Forward-compatibility
- [ ] Policy validates against v6 schema (deferred fields tolerated, not rejected)
- [ ] No deprecated v1 → v6 field renames

## Output format

```
✅ Policy valid (MVP v1 schema)
   Rules: 7/7
   ML models: 3/3
   ATT&CK mappings: 7/7
   Integrations: psa=connectwise, webhook enabled
   Forward-compat: OK

OR

❌ Policy invalid
   Errors:
     - rules[3].att&ck: missing
     - rules[5].action: "DENY" not in MVP verdict set
     - hitl.autonomous_threshold_sec: 30 < minimum 60
   Warnings:
     - integrations.routing.MEDIUM: no targets configured
```

## Exit codes

- `0` — valid
- `1` — invalid (errors present)
- `2` — warnings only (advisory; blocks deploy in strict mode)
