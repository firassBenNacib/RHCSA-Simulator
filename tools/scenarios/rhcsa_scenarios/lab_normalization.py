from __future__ import annotations

from copy import deepcopy
from typing import Any


def is_standalone_verification_task(task_text: str) -> bool:
    first_line = str(task_text).splitlines()[0].strip().rstrip(".").lower()
    if not first_line:
        return False

    if first_line.startswith(("verify ", "check ", "confirm ")):
        return True

    if first_line.startswith("use ") and " verify " in f" {first_line} ":
        return True

    return False


def _merge_check(previous: str, current: str) -> str:
    previous = str(previous).strip()
    current = str(current).strip()
    if previous and current:
        return f"({previous}) && ({current})"
    return previous or current


def normalize_lab_block(block: dict[str, Any]) -> dict[str, Any]:
    normalized = deepcopy(block)
    tasks = list(normalized.get("tasks", []))
    task_titles = list(normalized.get("task_titles", []))
    task_points = list(normalized.get("task_points", []))
    solution_commands = [list(item) for item in normalized.get("solution_commands", [])]
    checks = list(normalized.get("checks", []))

    new_tasks: list[str] = []
    new_task_titles: list[str] = []
    new_task_points: list[int] = []
    new_solution_commands: list[list[str]] = []
    new_checks: list[str] = []

    for index, task in enumerate(tasks):
        should_merge = index > 0 and is_standalone_verification_task(task) and len(new_tasks) > 0
        if should_merge:
            if index < len(solution_commands):
                new_solution_commands[-1].extend(solution_commands[index])
            if index < len(checks):
                prior_check = new_checks[-1] if new_checks else ""
                new_checks[-1] = _merge_check(prior_check, checks[index])
            if index < len(task_points):
                new_task_points[-1] += int(task_points[index])
            continue

        new_tasks.append(task)
        if index < len(task_titles):
            new_task_titles.append(task_titles[index])
        if index < len(task_points):
            new_task_points.append(int(task_points[index]))
        if index < len(solution_commands):
            new_solution_commands.append(solution_commands[index])
        if index < len(checks):
            new_checks.append(str(checks[index]))

    normalized["tasks"] = new_tasks
    normalized["task_titles"] = new_task_titles
    normalized["task_points"] = new_task_points
    normalized["solution_commands"] = new_solution_commands
    normalized["checks"] = new_checks
    return normalized
