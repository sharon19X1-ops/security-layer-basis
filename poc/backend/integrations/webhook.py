import hashlib
import hmac
import json
import time
import httpx
from config import WEBHOOK_URL, WEBHOOK_SECRET


async def deliver(payload: dict) -> dict:
    if not WEBHOOK_URL:
        return {"status": "skipped", "reason": "WEBHOOK_URL not configured"}

    body = json.dumps(payload)
    sig = hmac.new(WEBHOOK_SECRET.encode(), body.encode(), hashlib.sha256).hexdigest()

    headers = {
        "Content-Type": "application/json",
        "X-SLB-Signature": f"sha256={sig}",
        "X-SLB-Timestamp": str(int(time.time())),
        "X-SLB-Version": "POC-0.1",
    }

    async with httpx.AsyncClient() as client:
        r = await client.post(WEBHOOK_URL, content=body, headers=headers, timeout=10)
        return {"status": r.status_code}
