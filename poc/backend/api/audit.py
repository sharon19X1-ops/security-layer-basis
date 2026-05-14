from fastapi import APIRouter, Query
from db.store import get_events

router = APIRouter()


@router.get("/events")
async def list_events(limit: int = Query(default=50, le=200)):
    return get_events(limit=limit)
