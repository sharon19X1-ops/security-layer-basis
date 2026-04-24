# Skill: PSA Adapter Development

**Trigger:** Auto-loaded when working on files in `internal/psa/`, `psa_adapter`, PSA ticket creation, ConnectWise, Autotask, HaloPSA, or Syncro integration.

---

## Context

You are working on the PSA Adapter Layer of Security Layer-Basis v6. This layer creates support tickets in the MSP's PSA platform whenever the detection engine emits a verdict of CRITICAL or HIGH severity (configurable per tenant).

## Four supported PSAs

| PSA | Auth | Ticket endpoint |
|-----|------|----------------|
| ConnectWise Manage | Basic (companyId + publicKey:privateKey, Base64) | `POST /v4_6_release/apis/3.0/service/tickets` |
| Autotask | API Key + Username header | `POST /atservicesrest/v1.0/Tickets` |
| HaloPSA | OAuth2 Client Credentials | `POST /api/Tickets` |
| Syncro | API Key header (`X-Syncro-Api-Key`) | `POST /api/v1/tickets` |

## Adapter interface

Every adapter must implement:
```go
type PSAAdapter interface {
    CreateTicket(ctx context.Context, event Event, tenantCfg TenantPSAConfig) (TicketRef, error)
    FindOpenTicket(ctx context.Context, dedupKey string, tenantCfg TenantPSAConfig) (TicketRef, bool, error)
    CloseTicket(ctx context.Context, ticketID string, tenantCfg TenantPSAConfig) error
    Name() string
}
```

## Ticket description template

All adapters must use the shared template (see `ARCHITECTURE_V6.md` section 3):
- Rule ID and name
- Severity and action taken
- Timestamp, developer, workstation, IDE
- MITRE ATT&CK technique ID and name
- Human-readable what-happened and what-was-stopped
- Recommended remediation step
- Reference: `SLB-{event_id} | Tenant: {tenant_id}`

## Dedup behavior

Before creating a ticket, the adapter must:
1. Compute dedup key: `SHA256(rule_id + session_id + floor(timestamp/60s))`
2. Call `FindOpenTicket(ctx, dedupKey, cfg)` — if a ticket exists, skip creation, return existing reference
3. If no ticket exists, create one and tag it with `[SLB-{event_id}]` in the description

## Priority mapping

```
CRITICAL → PSA priority 1
HIGH     → PSA priority 2
MEDIUM   → PSA priority 3
LOW      → PSA priority 4
```

## Error handling

- HTTP 401: log error, alert ops, move event to DLQ (credentials issue, needs human intervention)
- HTTP 429: retry with exponential backoff; respect `Retry-After` header
- HTTP 4xx (other): log event, move to DLQ, do not retry
- HTTP 5xx: retry with backoff up to 5 attempts, then move to DLQ
- Network timeout: treat as retriable, apply backoff

## Testing

Each adapter has a mock HTTP server test:
```
internal/psa/connectwise/adapter_test.go
internal/psa/autotask/adapter_test.go
internal/psa/halopsa/adapter_test.go
internal/psa/syncro/adapter_test.go
```

Use `httptest.NewServer` to mock PSA API responses. Test: ticket creation, dedup skip, close, auth error handling.

## Checklist when adding a new adapter
- [ ] Implement `PSAAdapter` interface
- [ ] Add to registry in `internal/integration_bus/registry.go`
- [ ] Add unit tests (mock server)
- [ ] Add fixture in `testdata/fixtures/`
- [ ] Update `ARCHITECTURE_V6.md` section 3
- [ ] Update `mcp.json` integrations section
- [ ] Update `rules/integration.md` checklist
