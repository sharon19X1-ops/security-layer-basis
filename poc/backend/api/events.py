import uuid
from fastapi import APIRouter
from models.event import HookEvent
from models.verdict import VerdictResponse, Verdict
from rules import RULE_CHAIN
from db.store import log_event
from integrations.connectwise import create_ticket
from integrations.webhook import deliver
from hitl.timer import hitl_tracker

router = APIRouter()


@router.post("/event", response_model=VerdictResponse)
async def ingest_event(event: HookEvent):
    if event.hitl_present:
        hitl_tracker.human_interaction(event.session_id)

    if event.session_age_sec == 0:
        event.session_age_sec = hitl_tracker.seconds_since_interaction(event.session_id)

    verdict = None
    for rule in RULE_CHAIN:
        verdict = rule.evaluate(event)
        if verdict:
            break

    if verdict is None:
        verdict = VerdictResponse(
            event_id=str(uuid.uuid4()),
            verdict=Verdict.ALLOW,
            rule_id="",
            message="Event allowed.",
            severity="LOW",
        )

    log_event(
        event_type=event.event_type.value,
        payload=event.payload,
        verdict=verdict.verdict.value,
        rule_id=verdict.rule_id,
        severity=verdict.severity,
        message=verdict.message,
    )

    if verdict.severity in ("CRITICAL", "HIGH") and verdict.verdict != Verdict.ALLOW:
        await create_ticket(
            rule_id=verdict.rule_id,
            rule_name=verdict.message[:60],
            severity=verdict.severity,
            message=verdict.message,
            event_id=verdict.event_id,
        )
        await deliver(verdict.model_dump())

    return verdict


@router.post("/hitl/checkpoint")
async def hitl_checkpoint(session_id: str):
    hitl_tracker.human_interaction(session_id)
    return {"status": "ok", "session_id": session_id}
