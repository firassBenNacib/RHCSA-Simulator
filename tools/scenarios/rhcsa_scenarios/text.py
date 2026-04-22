from __future__ import annotations

import textwrap


def normalize_task_text(value: str) -> str:
    value = textwrap.dedent(value).strip("\n")
    lines = [line.rstrip() for line in value.splitlines()]
    if len(lines) == 1 and lines[0] and lines[0][-1] not in ".:!?":
        lines[0] += "."
    return "\n".join(lines).strip()
