import json
from pathlib import Path
from typing import Optional


class SkillRegistry:
    def __init__(self):
        self._data: dict[str, dict] = {}
        self._load()

    def _load(self):
        path = Path(__file__).parent / "skills.json"
        with open(path) as f:
            skills = json.load(f)["skills"]
        self._data = {s["skill_id"]: s for s in skills}

    def lookup(self, skill_id: str) -> Optional[dict]:
        return self._data.get(skill_id)


skill_registry = SkillRegistry()
