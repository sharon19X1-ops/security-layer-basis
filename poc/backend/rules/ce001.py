import re
import uuid
from models.event import HookEvent, EventType
from models.verdict import VerdictResponse, Verdict
from rules.base import Rule
from typing import Optional

PATTERNS = [
    re.compile(r'(cat|echo|print|type)\s.*(\..env|id_rsa|\.pem|credentials|secret|token)', re.IGNORECASE),
    re.compile(r'curl.+\|\s*sh', re.IGNORECASE),
    re.compile(r'export\s+\w+\s*=.*\$\{?[A-Z_]+\}?.*&&.*curl', re.IGNORECASE),
    re.compile(r'base64\s.*(\..env|\.pem|id_rsa)', re.IGNORECASE),
    re.compile(r'aws\s+secretsmanager.*get-secret.*\|.*curl', re.IGNORECASE),
]


class CE001(Rule):
    rule_id = "CE-001"
    name = "Credential Exfiltration — Shell"
    severity = "CRITICAL"
    attck_id = "T1552.001"

    def evaluate(self, event: HookEvent) -> Optional[VerdictResponse]:
        if event.event_type not in (EventType.SHELL_EXEC, EventType.COMPLETION_RECEIVED):
            return None
        for pattern in PATTERNS:
            if pattern.search(event.payload):
                return VerdictResponse(
                    event_id=str(uuid.uuid4()),
                    verdict=Verdict.BLOCK,
                    rule_id=self.rule_id,
                    message="Credential exfiltration attempt detected and blocked.",
                    attck_id=self.attck_id,
                    severity=self.severity,
                )
        return None
