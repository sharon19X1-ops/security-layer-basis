import type { AuditEvent, VerdictResponse } from '../types'

const BASE = '/api'

export async function sendEvent(payload: object): Promise<VerdictResponse> {
  const res = await fetch(`${BASE}/event`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  })
  if (!res.ok) throw new Error(`Event failed: ${res.status}`)
  return res.json()
}

export async function fetchEvents(limit = 50): Promise<AuditEvent[]> {
  const res = await fetch(`${BASE}/events?limit=${limit}`)
  if (!res.ok) throw new Error(`Fetch failed: ${res.status}`)
  return res.json()
}

export async function resetHITL(sessionId: string): Promise<void> {
  await fetch(`${BASE}/hitl/checkpoint?session_id=${sessionId}`, { method: 'POST' })
}
