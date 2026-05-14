import { useState } from 'react'
import { ScenarioPanel } from './components/ScenarioPanel/ScenarioPanel'
import { EventFeed } from './components/EventFeed/EventFeed'
import { IDEPanel } from './components/IDEPanel/IDEPanel'
import { HITLTimer } from './components/HITLTimer/HITLTimer'
import type { VerdictResponse } from './types'

export default function App() {
  const [lastVerdict, setLastVerdict] = useState<VerdictResponse | null>(null)

  return (
    <div
      style={{
        minHeight: '100vh',
        background: '#0f0f0f',
        color: '#e2e8f0',
        fontFamily: 'system-ui, sans-serif',
        padding: 24,
      }}
    >
      <header style={{ marginBottom: 24, borderBottom: '1px solid #222', paddingBottom: 16 }}>
        <h1 style={{ margin: 0, fontSize: 20 }}>
          Shield Security Layer-Basis — POC Dashboard
        </h1>
        <p style={{ margin: '4px 0 0', color: '#888', fontSize: 13 }}>
          DETECT → BLOCK · 4 rules active · Demo tenant
        </p>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, marginBottom: 24 }}>
        <ScenarioPanel onVerdict={setLastVerdict} />
        <IDEPanel lastVerdict={lastVerdict} />
      </div>

      <div style={{ marginBottom: 24 }}>
        <HITLTimer />
      </div>

      <div>
        <EventFeed />
      </div>
    </div>
  )
}
