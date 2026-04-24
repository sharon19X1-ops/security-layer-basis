# /integration-healthcheck

**Description:** Test live connectivity to all configured integration targets (PSA, SIEM, Webhooks) for a given tenant, and report the health status of each channel.

## What it does

1. Reads tenant config from Tenant Config Store (requires `SLB_DB_URL` and `VAULT_*` env vars)
2. For each enabled integration channel:
   - **PSA**: Sends a test API call (GET /boards or equivalent) to verify auth + connectivity
   - **SIEM**: Sends a test event to the SIEM ingest endpoint, checks for 200/202 response
   - **Webhooks**: Sends a test POST to each configured webhook URL with a test payload (HMAC-signed)
3. Reports per-channel: ✅ HEALTHY / ❌ FAILED / ⚠️  DEGRADED (slow response)
4. Reports Integration Bus DLQ depth (non-zero = events pending replay)

## Shell execution

```bash
# Health check for a specific tenant
go run cmd/integration-healthcheck/main.go --tenant acme-corp

# Health check for all tenants (ops use)
go run cmd/integration-healthcheck/main.go --all

# Dry-run mode (no actual calls, just validates config fields are present)
go run cmd/integration-healthcheck/main.go --tenant acme-corp --dry-run
```

## When to use
- After configuring a new tenant's PSA/SIEM credentials
- When a tenant reports they're not receiving PSA tickets or SIEM events
- During incident investigation (is the Integration Bus delivering?)
- Scheduled health check (see cron configuration in deployment docs)

## Expected output (healthy)
```
Integration Health — tenant: acme-corp
─────────────────────────────────────────
PSA (ConnectWise):    ✅ HEALTHY   (response: 200, 48ms)
SIEM (Sentinel):      ✅ HEALTHY   (event accepted, 92ms)
Webhook (Rewst):      ✅ HEALTHY   (200 OK, HMAC verified, 31ms)
Webhook (Zapier):     ✅ HEALTHY   (200 OK, 54ms)
DLQ depth:            0 events pending replay ✅
─────────────────────────────────────────
All channels healthy.
```

## Expected output (degraded)
```
Integration Health — tenant: acme-corp
─────────────────────────────────────────
PSA (ConnectWise):    ❌ FAILED    (HTTP 401 — check CW API key rotation)
SIEM (Sentinel):      ✅ HEALTHY   (92ms)
Webhook (Rewst):      ⚠️  SLOW     (2341ms — above 1s threshold)
DLQ depth:            47 events pending replay ⚠️
─────────────────────────────────────────
Action required: PSA auth failure. DLQ has 47 events to replay once PSA is fixed.
```
