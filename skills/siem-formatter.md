# Skill: SIEM Formatter Development

**Trigger:** Auto-loaded when working on files in `internal/siem/`, SIEM formatting, CEF, ECS, Splunk HEC, Sentinel, log forwarding, or syslog.

---

## Context

The SIEM Formatter transforms internal SLB events into the exact format required by each SIEM platform. One internal event can fan out to multiple SIEM outputs simultaneously if a tenant has multiple SIEMs configured.

## Four supported formats

| Format | SIEM targets | Transport |
|--------|-------------|-----------|
| CEF (Common Event Format) | Sentinel, Splunk, QRadar, ArcSight | syslog/UDP or syslog/TLS |
| ECS (Elastic Common Schema) | Elastic/OpenSearch, Kibana | HTTPS POST to Elasticsearch ingest pipeline |
| Splunk CIM | Splunk Enterprise, Splunk Cloud | HTTPS POST to HEC endpoint (port 8088) |
| Sentinel REST | Microsoft Sentinel / Log Analytics | HTTPS POST with HMAC-SHA256 SharedKey auth |

## Formatter interface

```go
type SIEMFormatter interface {
    Format(event Event, tenantCfg TenantSIEMConfig) ([]byte, error)
    ContentType() string  // "application/json" or "text/plain" for CEF
    Transport() Transport // SYSLOG | HTTPS
    Name() string
}
```

## Field requirements (all formats must include)

- Timestamp (ISO-8601)
- Rule ID and name
- Severity (mapped to SIEM-specific severity scale)
- Action taken
- Developer email (PII — check tenant config for PII masking setting)
- Device hostname
- IDE name
- **ATT&CK technique ID and name** — mandatory in all SIEM outputs
- Tenant ID
- ML confidence score

## CEF format specification

```
CEF:0|SecurityLayerBasis|SLB-Engine|6.0|{rule_id}|{rule_name}|{sev_1_10}|
  src={developer_ip} suser={developer_email} dvc={device_hostname}
  act={action} reason={ml_model}:{ml_score}
  cs1={ide} cs1Label=IDE
  cs2={rule_id} cs2Label=RuleID
  cs3={att&ck_id} cs3Label=ATTACKId
  cs4={tenant_id} cs4Label=TenantID
  msg={human_readable_description}
  rt={epoch_ms}
```

Severity mapping (CEF 0-10):
- CRITICAL → 10
- HIGH → 7
- MEDIUM → 5
- LOW → 3
- AUDIT → 1

## ECS format specification (key fields)

```json
{
  "@timestamp": "ISO-8601",
  "event.kind": "alert",
  "event.category": ["intrusion_detection"],
  "event.type": ["denied"],
  "event.severity": 1-10,
  "rule.id": "PI-001a",
  "rule.name": "Prompt Injection Detected",
  "rule.category": "ai-agent-security",
  "threat.technique.id": ["T1566"],
  "threat.technique.name": ["Phishing"],
  "threat.framework": "MITRE ATT&CK",
  "source.user.email": "alice@acme.com",
  "host.hostname": "DEVLAPTOP-A14",
  "process.name": "VS Code",
  "labels.tenant_id": "acme-corp",
  "labels.slb_version": "6.0"
}
```

## Splunk HEC format

```
POST https://{splunk_host}:8088/services/collector
Authorization: Splunk {hec_token}
{
  "time": epoch,
  "host": "{device_hostname}",
  "source": "security-layer-basis",
  "sourcetype": "slb:alert",
  "index": "security",
  "event": { ...CIM fields... }
}
```

Splunk CIM fields: `action`, `app`, `dest`, `severity`, `src_user`, `vendor_product`, `signature`, `category`

## Sentinel REST format

```
POST https://{workspace_id}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01
Log-Type: SLBSecurityEvents
Authorization: SharedKey {workspace_id}:{HMAC-SHA256}
```

HMAC-SHA256 SharedKey computation: per [Microsoft Log Analytics Data Collector API spec](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/data-collector-api).

## Minimum severity filter

Respect `siem.min_severity` from tenant config:
- If `min_severity: "MEDIUM"`, don't forward LOW or AUDIT events
- If `min_severity: "HIGH"`, don't forward MEDIUM, LOW, or AUDIT events
- Default: `MEDIUM`

## Testing

Formatter tests must validate output byte-for-byte (or field-by-field for JSON) against the SIEM spec:
```
internal/siem/cef/formatter_test.go      → 100% coverage required
internal/siem/ecs/formatter_test.go      → 100% coverage required
internal/siem/splunk/formatter_test.go
internal/siem/sentinel/formatter_test.go
```

Use golden file testing (`testdata/golden/cef_critical_event.txt`) for CEF string output.
