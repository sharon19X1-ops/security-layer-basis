import httpx
import base64
from config import CW_SITE, CW_COMPANY_ID, CW_PUBLIC_KEY, CW_PRIVATE_KEY, CW_BOARD_ID

PRIORITY_MAP = {"CRITICAL": 1, "HIGH": 2, "MEDIUM": 3, "LOW": 4}


def _auth_header() -> dict:
    token = base64.b64encode(
        f"{CW_COMPANY_ID}+{CW_PUBLIC_KEY}:{CW_PRIVATE_KEY}".encode()
    ).decode()
    return {"Authorization": f"Basic {token}", "Content-Type": "application/json"}


async def create_ticket(
    rule_id: str,
    rule_name: str,
    severity: str,
    message: str,
    event_id: str,
) -> dict:
    if not CW_SITE:
        return {"status": "skipped", "reason": "CW_SITE not configured"}

    body = {
        "summary": f"[SLB] {rule_name} — {severity}",
        "board": {"id": CW_BOARD_ID},
        "company": {"identifier": CW_COMPANY_ID},
        "priority": {"id": PRIORITY_MAP.get(severity, 3)},
        "initialDescription": (
            f"Rule: {rule_id} — {rule_name}\n"
            f"Severity: {severity}\n"
            f"Message: {message}\n"
            f"Reference: SLB-{event_id}\n"
            f"SLB Version: POC-0.1"
        ),
    }

    async with httpx.AsyncClient() as client:
        r = await client.post(
            f"https://{CW_SITE}/v4_6_release/apis/3.0/service/tickets",
            json=body,
            headers=_auth_header(),
            timeout=10,
        )
        r.raise_for_status()
        return r.json()
