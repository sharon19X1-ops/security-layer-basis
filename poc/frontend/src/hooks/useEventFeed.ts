import { useState, useEffect } from 'react'
import { fetchEvents } from '../api/client'
import type { AuditEvent } from '../types'

export function useEventFeed(pollMs = 2000) {
  const [events, setEvents] = useState<AuditEvent[]>([])
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let active = true

    async function poll() {
      try {
        const data = await fetchEvents()
        if (active) setEvents(data)
      } catch (e) {
        if (active) setError(String(e))
      }
    }

    poll()
    const id = setInterval(poll, pollMs)
    return () => {
      active = false
      clearInterval(id)
    }
  }, [pollMs])

  return { events, error }
}
