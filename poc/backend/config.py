import os
from dotenv import load_dotenv

load_dotenv()

CW_SITE = os.getenv("CW_SITE", "")
CW_COMPANY_ID = os.getenv("CW_COMPANY_ID", "")
CW_PUBLIC_KEY = os.getenv("CW_PUBLIC_KEY", "")
CW_PRIVATE_KEY = os.getenv("CW_PRIVATE_KEY", "")
CW_BOARD_ID = int(os.getenv("CW_BOARD_ID", "1"))

WEBHOOK_URL = os.getenv("WEBHOOK_URL", "")
WEBHOOK_SECRET = os.getenv("WEBHOOK_SECRET", "demo-secret")

HITL_THRESHOLD_SEC = int(os.getenv("HITL_THRESHOLD_SEC", "300"))
