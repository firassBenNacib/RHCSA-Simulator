#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

from scenario_solution_normalizer import normalize_command_list


ROOT = Path(__file__).resolve().parents[2]
SCENARIOS_ROOT = ROOT / "scenarios"


def normalize_file(path: Path) -> bool:
    data = json.loads(path.read_text(encoding="utf-8"))
    mode = "lab" if "lab" in data["content"] else "exam"
    content = data["content"][mode]
    commands = content.get("solution_commands", [])
    normalized = [normalize_command_list(block) for block in commands]
    if normalized == commands:
        return False
    content["solution_commands"] = normalized
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return True


def main() -> int:
    updated = 0
    for path in sorted(SCENARIOS_ROOT.rglob("scenario.json")):
        if normalize_file(path):
            updated += 1
    print(f"Normalized {updated} scenario files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
