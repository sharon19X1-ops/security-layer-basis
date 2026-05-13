export type EventType =
  | 'PROMPT_SUBMITTED'
  | 'COMPLETION_RECEIVED'
  | 'SHELL_EXEC'
  | 'FILE_WRITE'
  | 'NETWORK_REQUEST'
  | 'MCP_CONNECT'
  | 'SKILL_LOAD'
  | 'HITL_CHECKPOINT'

export type Verdict = 'ALLOW' | 'WARN' | 'BLOCK' | 'KILL_SESSION'
export type Severity = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL'

export interface AuditEvent {
  ts: string
  event_type: EventType
  payload: string
  verdict: Verdict
  rule_id: string
  severity: Severity
  message: string
}

export interface VerdictResponse {
  event_id: string
  verdict: Verdict
  rule_id: string
  message: string
  attck_id: string
  severity: Severity
}

export interface Scenario {
  id: string
  label: string
  description: string
  event: {
    session_id: string
    event_type: EventType
    payload: string
    hitl_present: boolean
    session_age_sec: number
    skill?: { skill_id: string; creator: string; registry: string; version_hash: string }
  }
}
