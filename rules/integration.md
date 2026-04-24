# Integration Rules

Applies to: Integration Bus, PSA adapters, SIEM formatters, Webhook Engine, Tenant Config Store, REST API v1.

## Integration Bus

- The Integration Bus is async — it MUST NOT block verdict return to the hook agent
- Verdict → hook is synchronous and must return within the latency budget (< 50ms round-trip hook→engine→hook)
- Integration Bus delivery budget: < 100ms total (enrich + route + deliver)
- Delivery is at-least-once: every event gets a dedup key computed as `SHA256(rule_id + session_id + floor(timestamp / 60s))`
- Dead letter queue: failed events retained for 7 days with replay capability
- Integration Bus routing table lives in `policy.yaml` under `integrations.routing` — never hardcode routing in Go

## PSA Adapters

- Each PSA adapter must implement the `PSAAdapter` interface — no adapter-specific code in the bus itself
- Adapter must handle: ticket creation, ticket dedup (check for open ticket with same dedup key before creating), ticket resolution (when event is resolved via API)
- All auth credentials must be read from Vault via `vault.GetTenantCredentials()` — never from env vars at call time
- Ticket description: use the shared template defined in `ARCHITECTURE_V6.md` section 3 — all adapters must produce consistent human-readable content
- PSA API errors: retry with exponential backoff (1s, 4s, 16s, 64s), then move to DLQ and alert ops
- Idempotency: before creating a ticket, query PSA for existing open tickets with matching `[SLB-{event_id}]` reference — if found, skip creation and return existing ticket ID
- ConnectWise Invent certification: all CW adapter code must remain within the CW API spec — no undocumented endpoints

## SIEM Formatters

- Each formatter must produce output that validates against the target SIEM's official schema
- CEF: validate against ArcSight CEF Implementation Standard
- ECS: validate against Elastic ECS field reference (latest stable)
- Splunk CIM: validate against Splunk CIM reference
- Sentinel REST: validate against Log Analytics Data Collector API spec
- ATT&CK fields must be included in every formatter output — never omit `att&ck_id` and `att&ck_name`
- Minimum severity filter: respect `siem.min_severity` from tenant config — don't deliver LOW/AUDIT to SIEM unless tenant explicitly enables it
- Transport: CEF via syslog/TLS; ECS via Elasticsearch ingest API; Splunk HEC via HTTPS; Sentinel REST via HTTPS with HMAC-SHA256 SharedKey auth

## Webhook Engine

- All webhook URLs must be validated as HTTPS at config write time — reject HTTP URLs
- HMAC-SHA256 signing is mandatory — no unsigned webhook deliveries
- Signing secret rotation: engine must support zero-downtime rotation (accept both old and new secret for a 5-minute overlap window)
- Retry: 5 attempts per delivery, exponential backoff (1s, 2s, 4s, 8s, 16s)
- Timeout per attempt: 10 seconds
- Dead letter queue: failed events retained 7 days, with operator UI to replay
- Event filtering: respect `webhooks[n].events` list from tenant config — only deliver severity levels the tenant subscribed to

## Tenant Config Store

- Schema: defined in `ARCHITECTURE_V6.md` section 6 — do not add undocumented fields
- All credential fields: encrypted via Vault before writing to Postgres — never store plaintext credentials
- Access: only Integration Bus service account and REST API v1 service account have read access to Tenant Config Store — no other service
- Config changes: trigger an event in the audit log (who changed what, when)
- `dedup_window_min` default: 60 minutes — configurable per tenant between 5 and 1440 minutes
- `auto_close_on_resolve`: when true, the adapter must call the PSA close endpoint when `POST /events/{id}/resolve` is called via REST API

## ATT&CK Mapper

- The mapping table (21 rules → ATT&CK technique IDs) is the authoritative source — defined in `internal/attack_mapper/mappings.go`
- The table in `ARCHITECTURE_V6.md` section 5 must stay in sync with `mappings.go`
- If a new rule class is added without an ATT&CK mapping, the mapper must return a logged warning and a placeholder `T0000` — never panic or error
- ATT&CK technique IDs must include the subtechnique when applicable (e.g., `T1552.001`)
- MITRE ATT&CK version pin: update the version reference in `mappings.go` when techniques are updated upstream

## Adding a new PSA adapter (checklist)
- [ ] Create `internal/psa/{name}/adapter.go` implementing `PSAAdapter` interface
- [ ] Add unit tests with mock API server in `internal/psa/{name}/adapter_test.go`
- [ ] Add adapter to Integration Bus registry in `internal/integration_bus/registry.go`
- [ ] Add tenant config schema fields for the new PSA in `settings.json` and `mcp.json`
- [ ] Update `ARCHITECTURE_V6.md` section 3 with adapter spec
- [ ] Update architecture comparison table in section 13
- [ ] Add test fixture in `testdata/fixtures/`

## Adding a new SIEM formatter (checklist)
- [ ] Create `internal/siem/{format}/formatter.go` implementing `SIEMFormatter` interface
- [ ] Add unit tests validating output against SIEM spec in `_test.go`
- [ ] Add formatter to Integration Bus registry
- [ ] Update `ARCHITECTURE_V6.md` section 4
- [ ] Add policy.yaml `format` enum value and validate in policy validator
