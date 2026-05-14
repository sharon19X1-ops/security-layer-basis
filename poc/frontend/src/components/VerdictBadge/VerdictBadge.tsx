import type { Verdict } from '../../types'

const COLORS: Record<Verdict, string> = {
  ALLOW: '#22c55e',
  WARN: '#f59e0b',
  BLOCK: '#ef4444',
  KILL_SESSION: '#7c3aed',
}

const LABELS: Record<Verdict, string> = {
  ALLOW: 'ALLOW',
  WARN: '⚠ WARN',
  BLOCK: '🚫 BLOCK',
  KILL_SESSION: '🛑 KILL SESSION',
}

interface Props {
  verdict: Verdict
}

export function VerdictBadge({ verdict }: Props) {
  return (
    <span
      style={{
        background: COLORS[verdict],
        color: '#fff',
        padding: '2px 10px',
        borderRadius: 4,
        fontWeight: 700,
        fontSize: 12,
        letterSpacing: 0.5,
      }}
    >
      {LABELS[verdict]}
    </span>
  )
}
