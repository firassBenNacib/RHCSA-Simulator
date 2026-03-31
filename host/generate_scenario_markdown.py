#!/usr/bin/env python3
from __future__ import annotations

import json
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCENARIOS_ROOT = ROOT / "scenarios"


def write_text(path: Path, content: str) -> None:
    path.write_text(content.rstrip() + "\n", encoding="utf-8")


def clean_text(value: str) -> str:
    return value.strip()


def normalize_task_text(value: str) -> str:
    value = textwrap.dedent(value).strip("\n")
    lines = [line.rstrip() for line in value.splitlines()]
    if len(lines) == 1 and lines[0] and lines[0][-1] not in ".:!?":
        lines[0] += "."
    return "\n".join(lines).strip()


def infer_system(task_text: str, requires_servervm: bool) -> str:
    lowered = task_text.lower()
    client_markers = (" on clientvm", " on the clientvm", " on clientvm.")
    server_markers = (" on servervm", " on the servervm", " on servervm.")
    has_client = any(marker in lowered for marker in client_markers)
    has_server = any(marker in lowered for marker in server_markers)
    if has_client and has_server:
        return "clientvm + servervm"
    if has_server:
        return "servervm"
    return "clientvm" if not requires_servervm else "clientvm"


def code_block(lines: list[str]) -> str:
    payload = "\n".join(lines).rstrip() or "# No commands provided."
    return f"```bash\n{payload}\n```"


def render_task_heading(index: int, title: str, system: str, points: int | None, label: str) -> str:
    heading = f"## {label} {index:02d} — {title}"
    meta = [f"**System:** {system}"]
    if points is not None:
        meta.append(f"**Points:** {points}")
    return heading + "\n" + "  \n".join(meta)


def get_task_title(task_titles: list[str], index: int, task_text: str) -> str:
    if index < len(task_titles):
        return clean_text(task_titles[index]).rstrip('.')
    return clean_text(task_text[:72]).rstrip('.')


def get_task_points(task_points: list[int], index: int) -> int | None:
    return task_points[index] if index < len(task_points) else None


def render_tasks(tasks, task_titles, task_points, requires_servervm, label):
    sections = []
    for index, task in enumerate(tasks, start=1):
        system = infer_system(task, requires_servervm)
        title = get_task_title(task_titles, index - 1, task)
        points = get_task_points(task_points, index - 1)
        sections.append(render_task_heading(index, title, system, points, label))
        sections.append("")
        sections.append(normalize_task_text(task))
        sections.append("")
        sections.append("---")
        sections.append("")
    if sections and sections[-2:] == ["---", ""]:
        sections = sections[:-2]
    return "\n".join(sections).rstrip()


def render_hints(hints):
    lines = ["### Hints"]
    if not hints:
        lines.append("- No additional hints.")
        return "\n".join(lines)
    for hint in hints:
        lines.append(f"- {clean_text(hint).rstrip('.') }.")
    return "\n".join(lines)


def render_solution(tasks, task_titles, task_points, solution_commands, checks, requires_servervm, label):
    sections = []
    for index, task in enumerate(tasks, start=1):
        system = infer_system(task, requires_servervm)
        title = get_task_title(task_titles, index - 1, task)
        points = get_task_points(task_points, index - 1)
        commands = solution_commands[index - 1] if index - 1 < len(solution_commands) else []
        sections.append(render_task_heading(index, title, system, points, label))
        sections.append("")
        sections.append("#### Commands")
        sections.append(code_block(commands))
        sections.append("")
        sections.append("---")
        sections.append("")
    if checks:
        sections.append("### Verification")
        sections.append(code_block(checks))
    elif sections and sections[-2:] == ["---", ""]:
        sections = sections[:-2]
    return "\n".join(sections).rstrip()


def summary_table(data, mode):
    objectives = ", ".join(data.get("objective_tags", [])) or "n/a"
    return "\n".join([
        "| Field | Value |",
        "|---|---|",
        f"| Scenario ID | `{data['id']}` |",
        f"| Mode | {mode} |",
        f"| Time limit | {data['time_limit_minutes']} minutes |",
        f"| Objectives | {objectives} |",
    ])


def metadata_lines(data, mode):
    lines = [
        "### Overview",
        summary_table(data, mode),
        "",
        normalize_task_text(data["description"]),
        "",
        "### General Instructions",
        "1. Unless a task states otherwise, make all changes persistent across reboots.",
    ]
    if mode == "Exam":
        lines.append("2. Use the exact scenario variables shown in each question.")
        lines.append("3. Keep SELinux enforcing unless a question explicitly directs otherwise.")
    else:
        lines.append("2. Use only persistent configuration methods.")
    lines.append("")
    return lines


def remove_if_exists(path: Path) -> None:
    if path.exists():
        path.unlink()


for manifest_path in sorted(SCENARIOS_ROOT.glob("*/*/scenario.json")):
    scenario_root = manifest_path.parent
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    supported_modes = [m.lower() for m in data.get("supported_modes", [])]
    requires_servervm = bool(data.get("flags", {}).get("requires_servervm", False))
    lab = data.get("content", {}).get("lab", {})
    exam = data.get("content", {}).get("exam", {})

    if "lab" in supported_modes:
        lab_tasks_md = "\n".join([
            f"# {data['title']}",
            "",
            "## Lab Tasks",
            *metadata_lines(data, "Lab"),
            render_tasks(lab.get("tasks", []), lab.get("task_titles", []), lab.get("task_points", []), requires_servervm, "Task"),
            "",
            render_hints(lab.get("hints", [])),
            "",
            "### Checks",
            code_block(lab.get("checks", [])),
        ])
        lab_solution_md = "\n".join([
            f"# {data['title']}",
            "",
            "## Lab Solution",
            *metadata_lines(data, "Lab"),
            render_solution(lab.get("tasks", []), lab.get("task_titles", []), lab.get("task_points", []), lab.get("solution_commands", []), lab.get("checks", []), requires_servervm, "Task"),
        ])
        write_text(scenario_root / "LAB_TASKS.md", lab_tasks_md)
        write_text(scenario_root / "LAB_SOLUTION.md", lab_solution_md)
    else:
        remove_if_exists(scenario_root / "LAB_TASKS.md")
        remove_if_exists(scenario_root / "LAB_SOLUTION.md")

    if "exam" in supported_modes:
        exam_tasks_md = "\n".join([
            f"# {data['title']}",
            "",
            "## Exam Tasks",
            *metadata_lines(data, "Exam"),
            render_tasks(exam.get("tasks", []), exam.get("task_titles", []), exam.get("task_points", []), requires_servervm, "Question"),
        ])
        exam_solution_md = "\n".join([
            f"# {data['title']}",
            "",
            "## Exam Solution",
            *metadata_lines(data, "Exam"),
            render_solution(exam.get("tasks", []), exam.get("task_titles", []), exam.get("task_points", []), exam.get("solution_commands", []), exam.get("checks", []), requires_servervm, "Question"),
        ])
        write_text(scenario_root / "EXAM_TASKS.md", exam_tasks_md)
        write_text(scenario_root / "EXAM_SOLUTION.md", exam_solution_md)
    else:
        remove_if_exists(scenario_root / "EXAM_TASKS.md")
        remove_if_exists(scenario_root / "EXAM_SOLUTION.md")
