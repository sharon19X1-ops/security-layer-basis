from abc import ABC, abstractmethod
from models.event import HookEvent
from models.verdict import VerdictResponse
from typing import Optional


class Rule(ABC):
    rule_id: str
    name: str
    severity: str
    attck_id: str

    @abstractmethod
    def evaluate(self, event: HookEvent) -> Optional[VerdictResponse]:
        """Return VerdictResponse if the rule fires, None if it passes."""
        ...
