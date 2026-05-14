import re
import uuid
from models.event import HookEvent, EventType
from models.verdict import VerdictResponse, Verdict
from rules.base import Rule
from typing import Optional

PATTERNS = [
    re.compile(r'bash\s+-i\s+>&\s+/dev/tcp', re.IGNORECASE),
    re.compile(r'nc\s+-e\s+/bin/(sh|bash)', re.IGNORECASE),
    re.compile(r'python.*socket.*connect.*subprocess', re.IGNORECASE | re.DOTALL),
    re.compile(r'powershell.*webclient.*downloadstring', re.IGNORECASE),
    re.compile(r'ncat\s+.*\s+-e\s+/bin', re.IGNORECASE),
    re.compile(r'rm\s+/tmp/f.*mkfifo.*cat.*\|.*/bin/sh.*nc', re.IGNORECASE | re.DOTALL),
]


class RS001(Rule):
    rule_id = "RS-001"
    name = "Reverse Shell Injection"
    severity = "CRITICAL"
    attck_id = "T1059"

    def evaluate(self, event: HookEvent) -> Optional[VerdictResponse]:
        if event.event_type not in (EventType.SHELL_EXEC, EventType.COMPLETION_RECEIVED):
            return None
        for pattern in PATTERNS:
            if pattern.search(event.payload):
                return VerdictResponse(
                    event_id=str(uuid.uuid4()),
                    verdict=Verdict.KILL_SESSION,
                    rule_id=self.rule_id,
                    message="Reverse shell injection detected. AI agent session terminated.",
                    attck_id=self.attck_id,
                    severity=self.severity,
                )
        return None
