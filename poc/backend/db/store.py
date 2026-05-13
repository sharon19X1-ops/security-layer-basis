import sqlite3
from datetime import datetime

_conn: sqlite3.Connection | None = None


def init_db():
    global _conn
    _conn = sqlite3.connect(":memory:", check_same_thread=False)
    _conn.execute("""
        CREATE TABLE events (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            ts       TEXT NOT NULL,
            event_type TEXT NOT NULL,
            payload  TEXT NOT NULL,
            verdict  TEXT NOT NULL,
            rule_id  TEXT NOT NULL,
            severity TEXT NOT NULL,
            message  TEXT NOT NULL
        )
    """)
    _conn.commit()


def log_event(
    event_type: str,
    payload: str,
    verdict: str,
    rule_id: str,
    severity: str,
    message: str,
):
    _conn.execute(
        "INSERT INTO events (ts, event_type, payload, verdict, rule_id, severity, message) "
        "VALUES (?,?,?,?,?,?,?)",
        (datetime.utcnow().isoformat(), event_type, payload[:200], verdict, rule_id, severity, message),
    )
    _conn.commit()


def get_events(limit: int = 50) -> list[dict]:
    cur = _conn.execute(
        "SELECT ts, event_type, payload, verdict, rule_id, severity, message "
        "FROM events ORDER BY id DESC LIMIT ?",
        (limit,),
    )
    cols = [d[0] for d in cur.description]
    return [dict(zip(cols, row)) for row in cur.fetchall()]
