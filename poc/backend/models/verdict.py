from pydantic import BaseModel
from enum import Enum


class Verdict(str, Enum):
    ALLOW = "ALLOW"
    WARN = "WARN"
    BLOCK = "BLOCK"
    KILL_SESSION = "KILL_SESSION"


class VerdictResponse(BaseModel):
    event_id: str
    verdict: Verdict
    rule_id: str = ""
    message: str = ""
    attck_id: str = ""
    severity: str = "LOW"
