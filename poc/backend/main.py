from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.events import router as events_router
from api.audit import router as audit_router
from api.health import router as health_router
from db.store import init_db

app = FastAPI(title="Security Layer-Basis POC", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(events_router)
app.include_router(audit_router)
app.include_router(health_router)


@app.on_event("startup")
async def startup():
    init_db()
