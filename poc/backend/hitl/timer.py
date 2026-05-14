import time
from threading import Lock


class HITLSessionTracker:
    """Tracks last human interaction time per session."""

    def __init__(self):
        self._sessions: dict[str, float] = {}
        self._lock = Lock()

    def human_interaction(self, session_id: str):
        with self._lock:
            self._sessions[session_id] = time.time()

    def seconds_since_interaction(self, session_id: str) -> int:
        with self._lock:
            last = self._sessions.get(session_id)
        if last is None:
            return 0
        return int(time.time() - last)

    def reset(self, session_id: str):
        with self._lock:
            self._sessions.pop(session_id, None)


hitl_tracker = HITLSessionTracker()
