import { useEventFeed } from '../../hooks/useEventFeed'
import { VerdictBadge } from '../VerdictBadge/VerdictBadge'

export function EventFeed() {
  const { events, error } = useEventFeed()

  if (error) return <p style={{ color: 'red' }}>Feed error: {error}</p>

  return (
    <div style={{ fontFamily: 'monospace', fontSize: 13 }}>
      <h3 style={{ margin: '0 0 8px' }}>Live Event Feed</h3>
      {events.length === 0 && (
        <p style={{ color: '#888' }}>No events yet. Trigger a scenario.</p>
      )}
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ borderBottom: '1px solid #333', textAlign: 'left' }}>
            <th style={{ padding: '4px 8px' }}>Time</th>
            <th style={{ padding: '4px 8px' }}>Type</th>
            <th style={{ padding: '4px 8px' }}>Verdict</th>
            <th style={{ padding: '4px 8px' }}>Rule</th>
            <th style={{ padding: '4px 8px' }}>Message</th>
          </tr>
        </thead>
        <tbody>
          {events.map((e, i) => (
            <tr key={i} style={{ borderBottom: '1px solid #222' }}>
              <td style={{ padding: '4px 8px', color: '#888' }}>
                {new Date(e.ts).toLocaleTimeString()}
              </td>
              <td style={{ padding: '4px 8px' }}>{e.event_type}</td>
              <td style={{ padding: '4px 8px' }}>
                <VerdictBadge verdict={e.verdict} />
              </td>
              <td style={{ padding: '4px 8px', color: '#60a5fa' }}>{e.rule_id || '—'}</td>
              <td style={{ padding: '4px 8px', color: '#ccc' }}>{e.message}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
