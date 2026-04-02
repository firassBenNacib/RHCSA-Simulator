#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import shutil
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LABS_ROOT = ROOT / "scenarios" / "labs"
EXAMS_ROOT = ROOT / "scenarios" / "exams"
EXERCISES_ROOT = ROOT / "exercises"


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.rstrip() + "\n", encoding="utf-8")


def remove_tree(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)


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
            paragraph = [line]
            idx += 1
            while idx < len(block):
                nxt = block[idx].strip()
                if _is_list_line(nxt) or _is_key_value_line(nxt) or _is_section_heading(nxt):
                    break
                paragraph.append(nxt)
                idx += 1
            rendered.append(" ".join(paragraph))
            rendered.append("")
    while rendered and rendered[-1] == "":
        rendered.pop()
    return "\n".join(rendered)


def infer_system(task_text: str, requires_servervm: bool) -> str:
    lowered = task_text.lower()
    if re.search(r"\bon\s+clientvm\s+and\s+servervm\b|\bon\s+servervm\s+and\s+clientvm\b", lowered):
        return "clientvm + servervm"
    has_server = bool(re.search(r"\bon\s+servervm\b|\bas\s+user\s+[^,]+\s+on\s+servervm\b", lowered))
    if has_server:
        return "servervm"
    if requires_servervm and "servervm" in lowered and "clientvm" in lowered:
        return "clientvm + servervm"
    return "clientvm"


def code_block(lines: list[str]) -> str:
    payload = "\n".join(lines).rstrip() or "# No commands provided."
    return f"```bash\n{payload}\n```"


def infer_title_from_task(task_text: str) -> str:
    line = normalize_task_text(task_text).splitlines()[0].strip()
    line = re.sub(r"(?i)^on\s+(clientvm|servervm),\s*", "", line)
    line = re.sub(r"(?i)^as\s+user\s+[^,]+,\s*", "", line)
    line = line.rstrip(".")
    return textwrap.shorten(line, width=54, placeholder="…")


def get_task_title(task_titles: list[str], index: int, task_text: str) -> str:
    if index < len(task_titles):
        candidate = clean_text(task_titles[index]).rstrip(".")
        if candidate:
            return candidate
    return infer_title_from_task(task_text)


def get_task_points(task_points: list[int], index: int) -> int | None:
    return task_points[index] if index < len(task_points) else None


def render_task_heading(index: int, title: str, system: str, points: int | None) -> str:
    heading = f"## Task {index:02d} - {title} ({system})"
    if points is not None:
        heading += f" - {points} pts"
    return heading


def relpath(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def extract_servervm_remote_command(command: str) -> str | None:
    match = re.match(r"^\s*ssh\s+(?P<host>\S*servervm\S*)\s+(?P<remote>.+?)\s*$", command)
    if not match:
        return None
    remote = match.group("remote").strip()
    remote = re.sub(r"^\s*sudo\s+", "", remote)
    return remote or None


def normalize_check_entry(command: str, index: int) -> dict[str, object]:
    stripped = command.strip()
    remote = extract_servervm_remote_command(stripped)
    target = "servervm" if remote else "clientvm"
    effective = remote or stripped
    return {
        "index": index,
        "target": target,
        "original_command": stripped,
        "command": effective,
    }


def render_prompt(data: dict, lab: dict, exercise_checks: list[dict[str, object]]) -> str:
    requires_servervm = bool(data.get("flags", {}).get("requires_servervm", False))
    systems = "clientvm + servervm" if requires_servervm else "clientvm"
    lines = [
        f"# {data['title']}",
        "",
        f"Time: {data['time_limit_minutes']} minutes",
        f"Objectives: {', '.join(data.get('objective_tags', [])) or 'n/a'}",
        f"Systems: {systems}",
        "",
        normalize_task_text(data["description"]),
        "",
        "## Tasks",
        "",
    ]
    for index, task in enumerate(lab.get("tasks", []), start=1):
        title = get_task_title(lab.get("task_titles", []), index - 1, task)
        points = get_task_points(lab.get("task_points", []), index - 1)
        system = infer_system(task, requires_servervm)
        lines.append(render_task_heading(index, title, system, points))
        lines.append("")
        lines.append(render_task_body(task))
        lines.append("")
    if exercise_checks:
        lines.extend([
            "## Validation",
            "",
            "Use the generated `check.sh` file or the host command below after you finish:",
            "",
            "`./RHCSA.ps1 check`",
        ])
    return "\n".join(lines).rstrip()


def render_hints(title: str, hints: list[str]) -> str:
    lines = [f"# {title} Hints", ""]
    if not hints:
        lines.append("- No hints are defined for this lab.")
        return "\n".join(lines)
    for hint in hints:
        text = normalize_task_text(hint).rstrip(".")
        lines.append(f"- {text}.")
    return "\n".join(lines)


def render_solution(data: dict, lab: dict) -> str:
    requires_servervm = bool(data.get("flags", {}).get("requires_servervm", False))
    lines = [f"# {data['title']} Solution", ""]
    for index, task in enumerate(lab.get("tasks", []), start=1):
        title = get_task_title(lab.get("task_titles", []), index - 1, task)
        points = get_task_points(lab.get("task_points", []), index - 1)
        system = infer_system(task, requires_servervm)
        commands = lab.get("solution_commands", [])[index - 1]
        lines.append(render_task_heading(index, title, system, points))
        lines.append("")
        lines.append(code_block(commands))
        lines.append("")
    if lab.get("checks"):
        lines.append("## Verification")
        lines.append("")
        lines.append(code_block(lab["checks"]))
    return "\n".join(lines).rstrip()


def render_check_script(data: dict, checks: list[dict[str, object]]) -> str:
    lines = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        "",
        f"# Generated from {relpath((LABS_ROOT / data['id'] / 'scenario.json'))}",
        "# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.",
        "",
    ]
    if not checks:
        lines.append("# No automated checks are defined for this lab.")
        lines.append("echo \"No automated checks are defined for this lab.\"")
        return "\n".join(lines)

    for check in checks:
        lines.append(f"# Check {check['index']:02d} [{check['target']}]")
        if check["command"] != check["original_command"]:
            lines.append(f"# Source: {check['original_command']}")
        lines.append(str(check["command"]))
        lines.append("")
    return "\n".join(lines).rstrip()


def render_catalog(entries: list[dict[str, object]]) -> str:
    lines = [
        'title = "RHCSA Labs"',
        'track = "rhcsa"',
        f"count = {len(entries)}",
        "",
    ]
    for entry in entries:
        lines.append("[[exercise]]")
        lines.append(f'id = "{entry["id"]}"')
        lines.append(f'title = "{entry["title"].replace(chr(34), chr(92) + chr(34))}"')
        lines.append(f"duration_minutes = {entry['time_limit_minutes']}")
        lines.append(f"requires_servervm = {'true' if entry['requires_servervm'] else 'false'}")
        lines.append(f"objectives = {json.dumps(entry['objective_tags'])}")
        lines.append(f'prompt = "{entry["paths"]["prompt"]}"')
        lines.append(f'hint = "{entry["paths"]["hint"]}"')
        lines.append(f'check = "{entry["paths"]["check"]}"')
        lines.append(f'solution = "{entry["paths"]["solution"]}"')
        lines.append(f'metadata = "{entry["paths"]["metadata"]}"')
        lines.append(f'source_manifest = "{entry["source_manifest"]}"')
        lines.append("")
    return "\n".join(lines).rstrip()


def render_root_readme(entries: list[dict[str, object]]) -> str:
    lines = [
        "# RHCSA Exercises",
        "",
        "Generated lab exercise assets modeled after a dockerlings-style layout.",
        "",
        "- `prompt.md` contains the trainee handout for a focused lab.",
        "- `hint.md` contains the lab hints.",
        "- `check.sh` contains the generated validation commands.",
        "- `solution.md` contains command-oriented task solutions.",
        "- `exercise.json` is the machine-readable export used for host-side validation.",
        "- `catalog.json` contains the generated lab catalog for the TUI.",
        "- `exams.json` contains the generated exam catalog for the TUI.",
        "",
        f"Current lab count: {len(entries)}",
        "",
        "Regenerate these files after editing lab manifests:",
        "",
        "```powershell",
        "python .\\host\\generate_exercises.py",
        "```",
    ]
    return "\n".join(lines).rstrip()


def build_exam_entry(data: dict) -> dict[str, object]:
    exam_root = ROOT / "scenarios" / "exams" / data["id"]
    exam_tasks = exam_root / "EXAM_TASKS.md"
    exam_solution = exam_root / "EXAM_SOLUTION.md"
    return {
        "id": data["id"],
        "title": data["title"],
        "description": normalize_task_text(data["description"]),
        "time_limit_minutes": data["time_limit_minutes"],
        "objective_tags": data.get("objective_tags", []),
        "requires_servervm": bool(data.get("flags", {}).get("requires_servervm", False)),
        "password_recovery": bool(data.get("flags", {}).get("password_recovery", False)),
        "source_manifest": relpath(exam_root / "scenario.json"),
        "paths": {
            "tasks": relpath(exam_tasks),
            "solution": relpath(exam_solution),
        },
    }


def main() -> None:
    EXERCISES_ROOT.mkdir(parents=True, exist_ok=True)
    labs = []
    exams = []
    expected_ids: set[str] = set()

    for manifest_path in sorted(LABS_ROOT.glob("*/scenario.json")):
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
        supported_modes = [mode.lower() for mode in data.get("supported_modes", [])]
        if "lab" not in supported_modes:
            continue

        exercise_id = data["id"]
        expected_ids.add(exercise_id)
        exercise_root = EXERCISES_ROOT / exercise_id
        exercise_root.mkdir(parents=True, exist_ok=True)

        lab = data["content"]["lab"]
        checks = [normalize_check_entry(command, index) for index, command in enumerate(lab.get("checks", []), start=1)]

        prompt_path = exercise_root / "prompt.md"
        hint_path = exercise_root / "hint.md"
        check_path = exercise_root / "check.sh"
        solution_path = exercise_root / "solution.md"
        metadata_path = exercise_root / "exercise.json"

        write_text(prompt_path, render_prompt(data, lab, checks))
        write_text(hint_path, render_hints(data["title"], lab.get("hints", [])))
        write_text(check_path, render_check_script(data, checks))
        write_text(solution_path, render_solution(data, lab))

        task_entries = []
        requires_servervm = bool(data.get("flags", {}).get("requires_servervm", False))
        for index, task in enumerate(lab.get("tasks", []), start=1):
            task_entries.append({
                "index": index,
                "title": get_task_title(lab.get("task_titles", []), index - 1, task),
                "points": get_task_points(lab.get("task_points", []), index - 1),
                "system": infer_system(task, requires_servervm),
                "prompt": normalize_task_text(task),
                "solution_commands": lab.get("solution_commands", [])[index - 1],
            })

        metadata = {
            "id": exercise_id,
            "title": data["title"],
            "description": normalize_task_text(data["description"]),
            "time_limit_minutes": data["time_limit_minutes"],
            "objective_tags": data.get("objective_tags", []),
            "requires_servervm": requires_servervm,
            "source_manifest": relpath(manifest_path),
            "paths": {
                "prompt": relpath(prompt_path),
                "hint": relpath(hint_path),
                "check": relpath(check_path),
                "solution": relpath(solution_path),
                "metadata": relpath(metadata_path),
            },
            "tasks": task_entries,
            "hints": [normalize_task_text(item) for item in lab.get("hints", [])],
            "checks": checks,
        }
        write_text(metadata_path, json.dumps(metadata, indent=2))

        labs.append({
            "id": exercise_id,
            "title": data["title"],
            "description": normalize_task_text(data["description"]),
            "time_limit_minutes": data["time_limit_minutes"],
            "objective_tags": data.get("objective_tags", []),
            "requires_servervm": requires_servervm,
            "paths": metadata["paths"],
            "source_manifest": relpath(manifest_path),
        })

    for manifest_path in sorted(EXAMS_ROOT.glob("*/scenario.json")):
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
        supported_modes = [mode.lower() for mode in data.get("supported_modes", [])]
        if "exam" not in supported_modes:
            continue
        exams.append(build_exam_entry(data))

    for child in EXERCISES_ROOT.iterdir():
        if child.is_dir() and child.name not in expected_ids:
            remove_tree(child)

    write_text(EXERCISES_ROOT / "rhcsa-exercises.toml", render_catalog(labs))
    write_text(EXERCISES_ROOT / "catalog.json", json.dumps(labs, indent=2))
    write_text(EXERCISES_ROOT / "exams.json", json.dumps(exams, indent=2))
    write_text(EXERCISES_ROOT / "README.md", render_root_readme(labs))


if __name__ == "__main__":
    main()
