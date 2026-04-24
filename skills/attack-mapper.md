# Skill: ATT&CK Mapper

**Trigger:** Auto-loaded when working on `internal/attack_mapper/`, MITRE ATT&CK, technique IDs, ATT&CK mappings, or adding new rule classes.

---

## Context

The ATT&CK Mapper appends MITRE ATT&CK technique IDs to every verdict before it reaches the Integration Bus. This enables SIEM dashboards to correlate SLB events with enterprise threat frameworks, and is required by all SIEM formatters.

## Current mapping table (21 rules → ATT&CK)

| SLB Rule | MITRE ATT&CK Technique |
|----------|----------------------|
| PI-001a | T1566 — Phishing (adapted: LLM prompt injection) |
| PI-001b | T1195.001 — Supply Chain: SW Dependencies |
| PI-002 | T1547 — Boot/Logon Autostart (memory-resident payload) |
| CE-001 | T1552.001 — Unsecured Credentials: Files |
| FS-002 | T1552.001 — Unsecured Credentials (prevention) |
| RS-001 | T1059 — Command and Scripting Interpreter |
| HITL-001 | T1078 — Valid Accounts (autonomous misuse) |
| MA-001 | T1574 — Hijack Execution Flow |
| MA-002 | T1053 — Scheduled Task / unauthorized spawn |
| SI-001 | T1195.001 — Supply Chain: SW Dependencies |
| SI-002 | T1195.001 — Supply Chain: SW Dependencies |
| SI-003/004 | T1195.002 — Supply Chain: Software (nested payload) |
| SI-005 | T1547 — Persistence via memory write |
| SYS-001 | T1059.004 — Unix Shell / T1059.001 PowerShell |
| MEM-001 | T1547.009 — Shortcut Modification (memory directive) |
| CG-001/002 | T1036 — Masquerading (unverified completion claim) |
| DI-001 | T1480 — Execution Guardrails (evading detection) |
| OQ-001 | T1036 — Masquerading (rationalization as completion) |
| FS-001 | T1083 — File and Directory Discovery (scope violation) |
| BR-001 | T1490 — Inhibit System Recovery (blast radius) |

> Note: These mappings are adapted from base ATT&CK techniques to LLM/AI agent threat context. Custom sub-technique "T1xxx.AI" additions proposed to MITRE ATT&CK for LLM agents.

## Mapper interface

```go
type ATTACKMapper interface {
    GetTechnique(ruleID string) (ATTACKTechnique, bool)
    GetAllMappings() map[string]ATTACKTechnique
}

type ATTACKTechnique struct {
    ID          string   // e.g. "T1566"
    SubID       string   // e.g. "T1195.001" (empty if no subtechnique)
    Name        string   // e.g. "Phishing"
    Framework   string   // always "MITRE ATT&CK"
    Version     string   // ATT&CK version pinned (e.g. "v14")
    Notes       string   // LLM/AI agent adaptation note
}
```

## Adding a new rule class (mandatory steps)

1. Add rule ID to `internal/rules/registry.go`
2. Add ATT&CK mapping to `internal/attack_mapper/mappings.go`
3. Run `/check-attack-mappings` to verify coverage
4. Update mapping table in `ARCHITECTURE_V6.md` section 5
5. Add test fixture in `testdata/fixtures/{rule_id}.json`
6. Policy validator will fail CI if a rule exists without a mapping

## If no ATT&CK technique fits

1. Document the rationale in a comment in `mappings.go`
2. Use the closest base technique and add a note explaining the adaptation
3. If genuinely novel: use placeholder `T0000` temporarily and open a GitHub issue to track the proposed new technique
4. Do NOT leave a rule without any mapping at all — the SIEM formatter will error

## Testing

```go
func TestMappingCompleteness(t *testing.T) {
    registry := rules.LoadRegistry()
    mapper := attackmapper.New()
    for _, rule := range registry.AllRules() {
        technique, ok := mapper.GetTechnique(rule.ID)
        assert.True(t, ok, "Rule %s has no ATT&CK mapping", rule.ID)
        assert.NotEmpty(t, technique.ID, "ATT&CK technique ID empty for rule %s", rule.ID)
    }
}
```

This test must pass with 100% rule coverage. CI blocks merge if it fails.
