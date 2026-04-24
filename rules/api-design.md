# API Design Rules

Applies to: REST API v1, webhook payloads, Integration Bus event schema.

## REST API v1 — General

- Base URL: `https://api.securitylayerbasis.io/v1/`
- All requests and responses: `application/json`
- Version in URL path, not header — API v2 will be at `/v2/`
- All endpoints require authentication (API Key header or OAuth2 Bearer)
- Rate limit headers must be returned on every response: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

## Authentication

- v1: API Key in header — `Authorization: ApiKey {key}`
- v1.1 target: OAuth2 Client Credentials — `Authorization: Bearer {token}`
- Scopes: `events:read`, `events:write`, `developers:read`, `skills:read`, `skills:write`, `policy:read`, `policy:write`, `webhooks:write`, `tenants:read` (MSSP only), `tenants:write` (MSSP only)
- Never accept credentials in query parameters

## URL design

- Resource nouns, plural: `/events`, `/developers`, `/skills`, `/webhooks`, `/tenants`
- Sub-resources: `/developers/{id}/risk-summary`, `/tenants/{id}/stats/summary`
- Actions (not pure REST resources): use POST with verb suffix: `/events/{id}/resolve`, `/skills/{id}/approve`, `/skills/{id}/block`, `/tenants/policy/broadcast`
- Filtering: query parameters only — `?severity=CRITICAL&rule_id=PI-001a&from=2027-01-01&to=2027-01-31`
- Pagination: cursor-based — `?limit=50&cursor={opaque_cursor}`. Response includes `next_cursor` when more pages exist.

## Response shape

Success:
```json
{
  "data": { ... },          // for single resource
  "meta": { "request_id": "uuid" }
}
```

List success:
```json
{
  "data": [ ... ],
  "meta": {
    "request_id": "uuid",
    "total": 1000,
    "limit": 50,
    "next_cursor": "opaque"
  }
}
```

Error:
```json
{
  "error": {
    "code": "TENANT_NOT_FOUND",
    "message": "Tenant acme-corp not found",
    "request_id": "uuid"
  }
}
```

## HTTP status codes
- `200` — success (GET, POST returning data)
- `201` — created (POST that creates a resource)
- `204` — success, no content (DELETE, resolve actions)
- `400` — bad request (validation error — include field-level detail in `error.details`)
- `401` — unauthorized (missing or invalid API key)
- `403` — forbidden (valid key but insufficient scope)
- `404` — not found
- `409` — conflict (duplicate ticket dedup key)
- `429` — rate limit exceeded (include `Retry-After` header)
- `500` — internal server error (never expose stack traces)

## Webhook payload design
- Every outbound webhook payload must include: `event_id`, `timestamp`, `tenant_id`, `rule_id`, `severity`, `action`, `att&ck_id`
- Signing: `X-SLB-Signature: sha256={HMAC-SHA256(raw_body, signing_secret)}`
- Headers: `X-SLB-Event-Id`, `X-SLB-Tenant`, `X-SLB-Timestamp`
- Payload fields: snake_case, ISO-8601 timestamps, severity as uppercase string enum
- Receivers must verify HMAC before processing — document this in all integration guides

## Versioning and backward compatibility
- Never remove or rename a field in a stable API response — add only, deprecate with warning
- Deprecated fields: annotate with `"_deprecated": true` in OpenAPI spec and add to release notes
- Breaking changes require a new API version (`/v2/`)
- OpenAPI 3.0 spec at `/v1/openapi.json` — must be updated whenever endpoint contract changes
- Sandbox environment mirrors production API contract: `https://api-sandbox.securitylayerbasis.io/v1/`

## Idempotency
- All write endpoints that can be retried must accept `Idempotency-Key: {uuid}` header
- PSA ticket creation: idempotency key = `rule_id + session_id + timestamp_bucket`
- Webhook delivery: idempotency enforced via `X-SLB-Event-Id` dedup on receiver side

## Security
- TLS 1.3 only — reject older TLS versions
- CORS: whitelist only — no wildcard origins on write endpoints
- Rate limit per tenant, per API key — never per IP (behind proxies)
- All API keys must be rotatable without downtime
- Log API key ID (not key value) in access logs for audit purposes
