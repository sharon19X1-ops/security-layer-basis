import { useState, useEffect } from 'react'
import { resetHITL } from '../../api/client'

const SESSION_ID = 'demo-session-001'
const THRESHOLD = 300

export function HITLTimer() {
  const [elapsed, setElapsed] = useState(0)
  const [running, setRunning] = useState(false)

  useEffect(() => {
    if (!running) return
    const id = setInterval(() => setElapsed((s) => s + 1), 1000)
    return () => clearInterval(id)
  }, [running])

  const pct = Math.min((elapsed / THRESHOLD) * 100, 100)
  const color = elapsed > THRESHOLD ? '#ef4444' : elapsed > 200 ? '#f59e0b' : '#22c55e'

  async function handleReset() {
    await resetHITL(SESSION_ID)
    setElapsed(0)
    setRunning(false)
  }

  return (
    <div style={{ fontFamily: 'monospace' }}>
      <h4 style={{ margin: '0 0 8px' }}>HITL Session Timer (HITL-001 demo)</h4>
      <div style={{ background: '#222', borderRadius: 4, height: 12, marginBottom: 8 }}>
        <div
          style={{
            background: color,
            width: `${pct}%`,
            height: '100%',
            borderRadius: 4,
            transition: 'width 0.5s',
          }}
        />
      </div>
      <p style={{ margin: '0 0 8px', color: elapsed > THRESHOLD ? '#ef4444' : '#ccc' }}>
        {elapsed}s elapsed / {THRESHOLD}s threshold
        {elapsed > THRESHOLD && ' — HITL-001 will fire on next high-risk event'}
      </p>
      <button onClick={() => setRunning(true)} disabled={running} style={{ marginRight: 8 }}>
        Start autonomous run
      </button>
      <button onClick={handleReset}>Human checkpoint (reset)</button>
    </div>
  )
}
