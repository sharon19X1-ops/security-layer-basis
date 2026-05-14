import uuid
from models.event import HookEvent, EventType
from models.verdict import VerdictResponse, Verdict
from rules.base import Rule
from registry.registry import skill_registry
from typing import Optional


class SI002(Rule):
    rule_id = "SI-002"
    name = "Unknown Skill — Not in Registry"
    severity = "HIGH"
    attck_id = "T1195.001"

    def evaluate(self, event: HookEvent) -> Optional[VerdictResponse]:
        if event.event_type != EventType.SKILL_LOAD or event.skill is None:
            return None
        result = skill_registry.lookup(event.skill.skill_id)
        if result is None:
            return VerdictResponse(
                event_id=str(uuid.uuid4()),
                verdict=Verdict.WARN,
                rule_id=self.rule_id,
                message=f"Skill '{event.skill.skill_id}' is not in the registry. Flagged for operator review.",
                attck_id=self.attck_id,
                severity=self.severity,
            )
        return None
