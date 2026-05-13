# Security Layer-Basis — POC

Customer demo for the Security Layer-Basis detection platform.
Two-container setup: FastAPI backend (rules engine) + React dashboard (scenario simulator).

## Quick start

```bash
cp .env.example .env
# Edit .env — ConnectWise and webhook are optional for the demo
docker compose up
```

- Dashboard: http://localhost:3000
- API docs: http://localhost:8000/docs

## Demo script

1. Open the dashboard. Show the empty event feed.
2. Click **Credential Theft** → BLOCK fires → ticket created in ConnectWise.
3. Click **Agent Goes Rogue** → HITL-001 WARN fires → yellow banner in IDE panel.
4. Click **Unknown Skill** → SI-002 WARN fires → operator review flag.
5. Click **Reverse Shell** → KILL_SESSION fires → session terminated banner.

## Structure

```
poc/
├── backend/          # Python FastAPI — rules engine, audit log, integrations
├── frontend/         # React + Vite — scenario panel, live feed, IDE simulation
├── docker-compose.yml
└── .env.example
```

## What is mocked

- Hook agent (replaced by scenario buttons)
- mTLS / gRPC (plain HTTP)
- Vault (env vars)
- ML models (regex rules only)
- Multi-tenancy (single hardcoded demo tenant)

## What is real

- Rule logic (CE-001, RS-001, HITL-001, SI-002)
- ConnectWise PSA ticket creation (sandbox)
- HMAC-signed webhook delivery
- Audit log (SQLite in-memory)
