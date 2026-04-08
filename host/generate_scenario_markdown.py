#!/usr/bin/env python3
from __future__ import annotations

import json
import re
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


def _split_blocks(text: str) -> list[list[str]]:
    blocks: list[list[str]] = []
    current: list[str] = []
    for raw in normalize_task_text(text).splitlines():
        line = raw.rstrip()
        if not line.strip():
            if current:
                blocks.append(current)
                current = []
            continue
        current.append(line)
    if current:
        blocks.append(current)
    return blocks


def _is_list_line(line: str) -> bool:
    stripped = line.strip()
    return bool(re.match(r"^([-*]|\d+[.)])\s+", stripped))


def _is_section_heading(line: str) -> bool:
    stripped = line.strip()
    return stripped.endswith(":") and ":" not in stripped[:-1] and len(stripped) <= 40


def _is_key_value_line(line: str) -> bool:
    stripped = line.strip()
    if _is_list_line(stripped) or _is_section_heading(stripped):
        return False
    if ":" not in stripped:
        return False
    key, value = stripped.split(":", 1)
    key = key.strip()
    value = value.strip()
    if not key or not value:
        return False
    if len(key) > 32:
        return False
    if key.endswith((".", ",", ";", "!", "?")):
        return False
    if len(key.split()) > 4:
        return False
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9 /()_-]*", key):
        return False
    return True


def _title_case_label(label: str) -> str:
    cleaned = re.sub(r"\s+", " ", label.strip())
    replacements = {
        "Ip ": "IP ",
        "Ipv4": "IPv4",
        "Ipv6": "IPv6",
        "Dns ": "DNS ",
        "Url": "URL",
        "Uid": "UID",
        "Gid": "GID",
        "Os": "OS",
        "Baseos": "BaseOS",
        "Appstream": "AppStream",
        "Gpgcheck": "gpgcheck",
        "Host Name": "Hostname",
    }
    if cleaned.isupper() or cleaned.islower():
        cleaned = cleaned.title()
    for old, new in replacements.items():
        cleaned = cleaned.replace(old, new)
    return cleaned


def render_task_body(value: str) -> str:
    rendered: list[str] = []
    for block in _split_blocks(value):
        if all(_is_key_value_line(line) for line in block):
            for line in block:
                key, val = line.split(":", 1)
                rendered.append(f"- **{_title_case_label(key)}:** {val.strip()}")
            rendered.append("")
            continue

        idx = 0
        while idx < len(block):
            line = block[idx].strip()
            if _is_section_heading(line):
                rendered.append(f"**{line[:-1].strip()}**")
                idx += 1
                while idx < len(block) and _is_list_line(block[idx].strip()):
                    rendered.append(block[idx].strip())
                    idx += 1
                rendered.append("")
                continue
            if _is_key_value_line(line):
                group = []
                while idx < len(block) and _is_key_value_line(block[idx].strip()):
                    group.append(block[idx].strip())
                    idx += 1
                for item in group:
                    key, val = item.split(":", 1)
                    rendered.append(f"- **{_title_case_label(key)}:** {val.strip()}")
                rendered.append("")
                continue
            if _is_list_line(line):
                rendered.append(line)
                idx += 1
                continue
            para = [line]
            idx += 1
            while idx < len(block):
                nxt = block[idx].strip()
                if _is_list_line(nxt) or _is_key_value_line(nxt) or _is_section_heading(nxt):
                    break
                para.append(nxt)
                idx += 1
            rendered.append(" ".join(para))
            rendered.append("")
    while rendered and rendered[-1] == "":
        rendered.pop()
    return "\n".join(rendered)


def infer_system(task_text: str, requires_servervm: bool, default_system: str = "clientvm") -> str:
    lowered = task_text.lower()
    if re.search(r"\bon\s+clientvm\s+and\s+servervm\b|\bon\s+servervm\s+and\s+clientvm\b", lowered):
        return "clientvm + servervm"
    has_client = bool(re.search(r"\bon\s+clientvm\b|\bas\s+user\s+[^,]+\s+on\s+clientvm\b", lowered))
    has_server = bool(re.search(r"\bon\s+servervm\b|\bas\s+user\s+[^,]+\s+on\s+servervm\b", lowered))
    if has_client and has_server:
        return "clientvm + servervm"
    if has_server:
        return "servervm"
    return default_system


def infer_default_system(description: str, tasks, requires_servervm: bool) -> str:
    combined = "\n".join([description, *tasks]).lower()
    has_client = bool(re.search(r"\bclientvm\b", combined))
    has_server = bool(re.search(r"\bservervm\b", combined))
    if has_server and not has_client:
        return "servervm"
    return "clientvm"


def code_block(lines: list[str]) -> str:
    payload = "\n".join(lines).rstrip() or "# No commands provided."
    return f"```bash\n{payload}\n```"


def _generic_title(title: str) -> bool:
    return bool(re.fullmatch(r"(?i)(part|task|question)\s+\d+", title.strip()))


def infer_title_from_task(task_text: str) -> str:
    line = normalize_task_text(task_text).splitlines()[0].strip()
    line = re.sub(r"(?i)^on\s+(clientvm|servervm),\s*", "", line)
    line = re.sub(r"(?i)^as\s+user\s+[^,]+,\s*", "", line)
    line = line.rstrip('.')
    return textwrap.shorten(line, width=72, placeholder='…')


def render_task_heading(index: int, title: str, system: str, points: int | None, label: str) -> str:
    heading = f"## {label} {index:02d} - {title} ({system})"
    if points is not None:
        heading += f" - {points} pts"
    return heading


def get_task_title(task_titles: list[str], index: int, task_text: str) -> str:
    if index < len(task_titles):
        candidate = clean_text(task_titles[index]).rstrip('.')
        if candidate and not _generic_title(candidate) and not candidate.endswith(("...", "…")):
            return candidate
    return infer_title_from_task(task_text)


def get_task_points(task_points: list[int], index: int) -> int | None:
    return task_points[index] if index < len(task_points) else None


def render_tasks(tasks, task_titles, task_points, requires_servervm, label, default_system):
    sections = []
    for index, task in enumerate(tasks, start=1):
        system = infer_system(task, requires_servervm, default_system)
        title = get_task_title(task_titles, index - 1, task)
        points = get_task_points(task_points, index - 1)
        sections.append(render_task_heading(index, title, system, points, label))
        sections.append("")
        sections.append(render_task_body(task))
        sections.append("")
        sections.append("---")
        sections.append("")
    if sections and sections[-2:] == ["---", ""]:
        sections = sections[:-2]
    return "\n".join(sections).rstrip()


def render_solution(tasks, task_titles, task_points, solution_commands, checks, requires_servervm, label, default_system):
    sections = []
    for index, task in enumerate(tasks, start=1):
        system = infer_system(task, requires_servervm, default_system)
        title = get_task_title(task_titles, index - 1, task)
        points = get_task_points(task_points, index - 1)
        commands = solution_commands[index - 1] if index - 1 < len(solution_commands) else []
        sections.append(render_task_heading(index, title, system, points, label))
        sections.append("")
        sections.append(code_block(commands))
        sections.append("")
        sections.append("---")
        sections.append("")
    if sections and sections[-2:] == ["---", ""]:
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


def collect_systems(tasks, requires_servervm: bool, default_system: str) -> list[str]:
    systems: list[str] = []
    for task in tasks:
        inferred = infer_system(task, requires_servervm, default_system)
        for system in ("clientvm", "servervm"):
            if system in inferred and system not in systems:
                systems.append(system)
    if systems:
        return systems
    if requires_servervm:
        return ["clientvm", "servervm"]
    return ["clientvm"]


def systems_table(tasks, requires_servervm: bool, default_system: str):
    systems = collect_systems(tasks, requires_servervm, default_system)
    if systems == ["clientvm"]:
        return "\n".join([
            "### Systems",
            "- clientvm",
            "",
        ])
    if systems == ["servervm"]:
        return "\n".join([
            "### Systems",
            "- servervm",
            "",
        ])
    return "\n".join(["### Systems", *[f"- {system}" for system in systems], ""])


def metadata_lines(data, mode, tasks, default_system):
    lines = [
        "## Overview",
        summary_table(data, mode),
        "",
        normalize_task_text(data["description"]),
        "",
        systems_table(tasks, bool(data.get("flags", {}).get("requires_servervm", False)), default_system),
        "## General Instructions",
        "1. Unless a task states otherwise, make all changes persistent across reboots.",
    ]
    if mode == "Exam":
        lines.append("2. Read the whole handout before you begin so you can sequence cross-system work efficiently.")
        lines.append("3. Use the exact scenario variables shown in each question.")
        lines.append("4. Keep SELinux enforcing unless a question explicitly directs otherwise.")
    else:
        lines.append("2. Use only persistent configuration methods.")
        lines.append("3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.")
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
        lab_tasks = lab.get("tasks", [])
        lab_default_system = infer_default_system(data["description"], lab_tasks, requires_servervm)
        lab_tasks_md = "\n".join([
            f"# {data['title']}",
            "",
            "## Lab Tasks",
            *metadata_lines(data, "Lab", lab_tasks, lab_default_system),
            render_tasks(lab_tasks, lab.get("task_titles", []), lab.get("task_points", []), requires_servervm, "Task", lab_default_system),
        ])
        lab_solution_md = "\n".join([
            f"# {data['title']}",
            "",
            "## Lab Solution",
            *metadata_lines(data, "Lab", lab_tasks, lab_default_system),
            render_solution(lab_tasks, lab.get("task_titles", []), lab.get("task_points", []), lab.get("solution_commands", []), lab.get("checks", []), requires_servervm, "Task", lab_default_system),
        ])
        write_text(scenario_root / "LAB_TASKS.md", lab_tasks_md)
        write_text(scenario_root / "LAB_SOLUTION.md", lab_solution_md)
    else:
        remove_if_exists(scenario_root / "LAB_TASKS.md")
        remove_if_exists(scenario_root / "LAB_SOLUTION.md")

    if "exam" in supported_modes:
        exam_tasks = exam.get("tasks", [])
        exam_default_system = infer_default_system(data["description"], exam_tasks, requires_servervm)
        exam_tasks_md = "\n".join([
            f"# {data['title']}",
            "",
            "## Exam Tasks",
            *metadata_lines(data, "Exam", exam_tasks, exam_default_system),
            render_tasks(exam_tasks, exam.get("task_titles", []), exam.get("task_points", []), requires_servervm, "Question", exam_default_system),
        ])
        exam_solution_md = "\n".join([
            f"# {data['title']}",
            "",
            "## Exam Solution",
            *metadata_lines(data, "Exam", exam_tasks, exam_default_system),
            render_solution(exam_tasks, exam.get("task_titles", []), exam.get("task_points", []), exam.get("solution_commands", []), exam.get("checks", []), requires_servervm, "Question", exam_default_system),
        ])
        write_text(scenario_root / "EXAM_TASKS.md", exam_tasks_md)
        write_text(scenario_root / "EXAM_SOLUTION.md", exam_solution_md)
    else:
        remove_if_exists(scenario_root / "EXAM_TASKS.md")
        remove_if_exists(scenario_root / "EXAM_SOLUTION.md")
