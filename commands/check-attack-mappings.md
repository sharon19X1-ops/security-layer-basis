# /check-attack-mappings

**Description:** Verify that all 21 SLB rule classes have valid ATT&CK technique mappings, and that the mapping table in `ARCHITECTURE_V6.md` matches the authoritative `internal/attack_mapper/mappings.go`.

## What it does

1. Reads rule IDs from the rule registry (`internal/rules/registry.go`)
2. Reads ATT&CK mappings from `internal/attack_mapper/mappings.go`
3. Reads mapping table from `ARCHITECTURE_V6.md` section 5
4. Reports:
   - ✅ Rules with valid ATT&CK technique IDs
   - ❌ Rules missing ATT&CK mapping (must be fixed before merge)
   - ⚠️  Rules where code mapping differs from architecture doc (doc must be updated)
5. Validates technique IDs against MITRE ATT&CK Navigator format (`Txxxx` or `Txxxx.xxx`)

## Shell execution

```bash
go test ./internal/attack_mapper/... -v -run TestMappingCompleteness
```

Or run the dedicated check:
```bash
go run cmd/attack-mapper-check/main.go --rules-registry internal/rules/registry.go --mappings internal/attack_mapper/mappings.go
```

## When to use
- When adding a new rule class (must add mapping before PR is approved)
- After updating MITRE ATT&CK version reference
- Before any v-dot release

## Expected output (pass)
```
ATT&CK Mapping Coverage: 21/21 rules mapped ✅

PI-001a → T1566 ✅
PI-001b → T1195.001 ✅
PI-002  → T1547 ✅
CE-001  → T1552.001 ✅
...
BR-001  → T1490 ✅

Architecture doc sync: ✅ All 21 entries match mappings.go
```

## Expected output (fail — new rule added without mapping)
```
ATT&CK Mapping Coverage: 21/22 rules mapped ❌

MISSING: XX-003 — no ATT&CK technique ID assigned
Action required: add mapping to internal/attack_mapper/mappings.go and ARCHITECTURE_V6.md section 5
```
