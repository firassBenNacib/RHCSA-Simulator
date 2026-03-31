#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCENARIOS_ROOT = ROOT / "scenarios"


def write_text(path: Path, content: str) -> None:
    path.write_text(content.rstrip() + "\n", encoding="utf-8")


def clean_text(value: str) -> str:
    return value.strip().rstrip(".")


def infer_system(task_text: str, requires_servervm: bool) -> str:
    lowered = task_text.lower()
    client_markers = (" on clientvm", " as admin on clientvm", " on the clientvm", " on clientvm.")
    server_markers = (" on servervm", " as admin on servervm", " as root on servervm", " on the servervm", " on servervm.")
    has_client = any(marker in lowered for marker in client_markers)
    has_server = any(marker in lowered for marker in server_markers)
    if has_client and has_server:
        return "clientvm + servervm"
    if has_client:
        return "clientvm"
    if has_server:
        return "servervm"
    return "clientvm"


def compact_title(task_text: str) -> str:
    text = clean_text(task_text)
    for separator in (",", " and ", " while ", " with "):
        head = text.split(separator, 1)[0].strip()
        if 8 <= len(head) <= 72:
            return head
    if len(text) <= 72:
        return text
    return text[:69].rstrip() + "..."


def code_block(lines: list[str]) -> str:
    payload = "\n".join(lines).rstrip()
    if not payload:
        payload = "# No commands provided."
    return f"```bash\n{payload}\n```"


def render_task_heading(index: int, title: str, system: str, points: int | None) -> str:
    heading = f"## Task {index:02d} - {title} ({system})"
    if points is not None:
        heading += f" - {points} pts"
    return heading


def get_task_title(task_titles: list[str], index: int, task_text: str) -> str:
    if index < len(task_titles):
        return clean_text(task_titles[index])
    return compact_title(task_text)


def get_task_points(task_points: list[int], index: int) -> int | None:
    if index < len(task_points):
        return task_points[index]
    return None


def render_tasks(
    tasks: list[str],
    task_titles: list[str],
    task_points: list[int],
    requires_servervm: bool,
) -> str:
    sections: list[str] = []
    for index, task in enumerate(tasks, start=1):
        system = infer_system(task, requires_servervm)
        title = get_task_title(task_titles, index - 1, task)
        points = get_task_points(task_points, index - 1)
        sections.append(render_task_heading(index, title, system, points))
        sections.append(clean_text(task) + ".")
        sections.append("")
    return "\n".join(sections).rstrip()


def render_hints(hints: list[str]) -> str:
    if not hints:
        return "Hints\nNo additional hints."

    lines = ["Hints"]
    for index, hint in enumerate(hints, start=1):
        lines.append(f"{index}. {clean_text(hint)}.")
    return "\n".join(lines)


def render_solution(
    tasks: list[str],
    task_titles: list[str],
    task_points: list[int],
    solution_commands: list[list[str]],
    checks: list[str],
    requires_servervm: bool,
) -> str:
    sections: list[str] = []
    for index, task in enumerate(tasks, start=1):
        system = infer_system(task, requires_servervm)
        title = get_task_title(task_titles, index - 1, task)
        points = get_task_points(task_points, index - 1)
        commands = solution_commands[index - 1] if index - 1 < len(solution_commands) else []
        sections.append(render_task_heading(index, title, system, points))
        sections.append(code_block(commands))
        sections.append("")

    if checks:
        sections.append("Verification")
        sections.append(code_block(checks))

    return "\n".join(sections).rstrip()


def metadata_lines(data: dict, mode: str) -> list[str]:
    objectives = ", ".join(data.get("objective_tags", []))
    return [
        f"Scenario ID: {data['id']}",
        f"Mode: {mode}",
        f"Time limit: {data['time_limit_minutes']} minutes",
        f"Objectives: {objectives}",
        "",
        clean_text(data["description"]) + ".",
        "",
    ]


for manifest_path in sorted(SCENARIOS_ROOT.glob("*/*/scenario.json")):
    scenario_root = manifest_path.parent
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    lab = data.get("content", {}).get("lab", {})
    exam = data.get("content", {}).get("exam", {})
    requires_servervm = bool(data.get("flags", {}).get("requires_servervm", False))

    lab_tasks_md = "\n".join(
        [
            f"# {data['title']} - Lab Tasks",
            *metadata_lines(data, "Lab"),
            render_tasks(
                lab.get("tasks", []),
                lab.get("task_titles", []),
                lab.get("task_points", []),
                requires_servervm,
            ),
            "",
            render_hints(lab.get("hints", [])),
            "",
            "Checks",
            code_block(lab.get("checks", [])),
        ]
    )

    lab_solution_md = "\n".join(
        [
            f"# {data['title']} - Lab Solution",
            *metadata_lines(data, "Lab"),
            render_solution(
                lab.get("tasks", []),
                lab.get("task_titles", []),
                lab.get("task_points", []),
                lab.get("solution_commands", []),
                lab.get("checks", []),
                requires_servervm,
            ),
        ]
    )

    exam_tasks_md = "\n".join(
        [
            f"# {data['title']} - Exam Tasks",
            *metadata_lines(data, "Exam"),
            render_tasks(
                exam.get("tasks", []),
                exam.get("task_titles", []),
                exam.get("task_points", []),
                requires_servervm,
            ),
        ]
    )

    exam_solution_md = "\n".join(
        [
            f"# {data['title']} - Exam Solution",
            *metadata_lines(data, "Exam"),
            render_solution(
                exam.get("tasks", []),
                exam.get("task_titles", []),
                exam.get("task_points", []),
                exam.get("solution_commands", []),
                exam.get("checks", []),
                requires_servervm,
            ),
        ]
    )

    write_text(scenario_root / "LAB_TASKS.md", lab_tasks_md)
    write_text(scenario_root / "LAB_SOLUTION.md", lab_solution_md)
    write_text(scenario_root / "EXAM_TASKS.md", exam_tasks_md)
    write_text(scenario_root / "EXAM_SOLUTION.md", exam_solution_md)
