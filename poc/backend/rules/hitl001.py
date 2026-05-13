import uuid
from models.event import HookEvent, EventType
from models.verdict import VerdictResponse, Verdict
from rules.base import Rule
from config import HITL_THRESHOLD_SEC
from typing import Optional

HIGH_RISK_EVENTS = {
    EventType.SHELL_EXEC,
    EventType.NETWORK_REQUEST,
    EventType.MCP_CONNECT,
    EventType.SKILL_LOAD,
}


class HITL001(Rule):
    rule_id = "HITL-001"
    name = "High-Risk Action Without Human Oversight"
    severity = "HIGH"
    attck_id = "T1078"

    def evaluate(self, event: HookEvent) -> Optional[VerdictResponse]:
        if event.event_type not in HIGH_RISK_EVENTS:
            return None
        if not event.hitl_present and event.session_age_sec > HITL_THRESHOLD_SEC:
            return VerdictResponse(
                event_id=str(uuid.uuid4()),
                verdict=Verdict.WARN,
                rule_id=self.rule_id,
                message=(
                    f"AI agent has been running autonomously for "
                    f"{event.session_age_sec}s without a human checkpoint."
                ),
                attck_id=self.attck_id,
                severity=self.severity,
            )
        return None
