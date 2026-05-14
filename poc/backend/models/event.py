from pydantic import BaseModel
from enum import Enum
from typing import Optional


class EventType(str, Enum):
    PROMPT_SUBMITTED = "PROMPT_SUBMITTED"
    COMPLETION_RECEIVED = "COMPLETION_RECEIVED"
    SHELL_EXEC = "SHELL_EXEC"
    FILE_WRITE = "FILE_WRITE"
    NETWORK_REQUEST = "NETWORK_REQUEST"
    MCP_CONNECT = "MCP_CONNECT"
    SKILL_LOAD = "SKILL_LOAD"
    HITL_CHECKPOINT = "HITL_CHECKPOINT"


class SkillIdentity(BaseModel):
    skill_id: str
    creator: str = ""
    registry: str = "unknown"
    version_hash: str = ""


class HookEvent(BaseModel):
    session_id: str
    developer_id: str = "demo-dev-001"
    tenant_id: str = "demo-tenant"
    ide: str = "vscode"
    agent: str = "claude-code"
    event_type: EventType
    payload: str = ""
    hitl_present: bool = True
    session_age_sec: int = 0
    skill: Optional[SkillIdentity] = None
