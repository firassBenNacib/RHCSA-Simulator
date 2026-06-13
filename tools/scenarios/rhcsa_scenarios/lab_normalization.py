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
    task_targets = list(normalized.get("task_targets", []))
    solution_targets = list(normalized.get("solution_targets", []))
    check_targets = list(normalized.get("check_targets", []))

    new_tasks: list[str] = []
    new_task_titles: list[str] = []
    new_task_points: list[int] = []
    new_solution_commands: list[list[str]] = []
    new_checks: list[str] = []
    new_task_targets: list[str] = []
    new_solution_targets: list[str] = []
    new_check_targets: list[str] = []

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
            if index < len(task_targets) and new_task_targets:
                if new_task_targets[-1] != task_targets[index]:
                    new_task_targets[-1] = "both"
            if index < len(solution_targets) and new_solution_targets:
                if new_solution_targets[-1] != solution_targets[index]:
                    new_solution_targets[-1] = "both"
            if index < len(check_targets) and new_check_targets:
                if new_check_targets[-1] != check_targets[index]:
                    new_check_targets[-1] = "both"
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
        if index < len(task_targets):
            new_task_targets.append(str(task_targets[index]))
        if index < len(solution_targets):
            new_solution_targets.append(str(solution_targets[index]))
        if index < len(check_targets):
            new_check_targets.append(str(check_targets[index]))

    normalized["tasks"] = new_tasks
    normalized["task_titles"] = new_task_titles
    normalized["task_points"] = new_task_points
    normalized["solution_commands"] = new_solution_commands
    normalized["checks"] = new_checks
    if task_targets:
        normalized["task_targets"] = new_task_targets
    if solution_targets:
        normalized["solution_targets"] = new_solution_targets
    if check_targets:
        normalized["check_targets"] = new_check_targets
    return normalized
