#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import textwrap
from pathlib import Path
from typing import Any, TypedDict, cast

ROOT = Path(__file__).resolve().parents[1]
LABS_ROOT = ROOT / "scenarios" / "labs"
GENERATED_ROOT = ROOT / ".lab-state" / "generated"


class ExercisePaths(TypedDict):
    prompt: str
    hint: str
    check: str
    solution: str
    metadata: str


class CheckEntry(TypedDict):
    index: int
    target: str
    original_command: str
    command: str


class ExerciseMetadata(TypedDict):
    id: str
    title: str
    description: str
    time_limit_minutes: int
    objective_tags: list[str]
    requires_servervm: bool
    source_manifest: str
    source_hash: str
    paths: ExercisePaths
    checks: list[CheckEntry]


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.rstrip() + "\n", encoding="utf-8")


def remove_tree(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)


def relpath(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def normalize_task_text(value: str) -> str:
    value = textwrap.dedent(value).strip("\n")
    lines = [line.rstrip() for line in value.splitlines()]
    if len(lines) == 1 and lines[0] and lines[0][-1] not in ".:!?":
        lines[0] += "."
    return "\n".join(lines).strip()


def render_hints(title: str, hints: list[str]) -> str:
    lines = [f"# {title} Hints", ""]
    if not hints:
        lines.append("- No hints are defined for this lab.")
        return "\n".join(lines)
    for hint in hints:
        text = normalize_task_text(hint).rstrip(".")
        lines.append(f"- {text}.")
    return "\n".join(lines)


def extract_servervm_remote_command(command: str) -> str | None:
    match = re.match(r"^\s*ssh\s+(?P<host>\S*servervm\S*)\s+(?P<remote>.+?)\s*$", command)
    if not match:
        return None
    remote = command.strip()
    remote = re.sub(r"(?i)ssh\s+\S*servervm\S*\s+(?:sudo\s+)?", "", remote)
    remote = re.sub(r"\(\s+", "(", remote)
    remote = re.sub(r"\s+\)", ")", remote)
    remote = re.sub(r"\s{2,}", " ", remote)
    remote = remote.strip()
    return remote or None


def normalize_check_entry(command: str, index: int) -> CheckEntry:
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


def render_check_script(source_manifest: str, checks: list[CheckEntry]) -> str:
    lines: list[str] = []
    if not checks:
        lines.append("# No automated checks are defined for this lab.")
        lines.append('echo "No automated checks are defined for this lab."')
        return "\n".join(lines)

    for check in checks:
        lines.append(f"# Check {check['index']:02d} [{check['target']}]")
        if check["command"] != check["original_command"]:
            lines.append(f"# Source: {check['original_command']}")
        lines.append(check["command"])
        lines.append("")
    return "\n".join(lines).rstrip()


def manifest_hash(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build_runtime_cache(manifest_path: Path) -> ExerciseMetadata:
    data: dict[str, Any] = json.loads(manifest_path.read_text(encoding="utf-8"))
    supported_modes = [mode.lower() for mode in data.get("supported_modes", [])]
    if "lab" not in supported_modes:
        raise ValueError(f"{manifest_path} does not support lab mode")

    scenario_id = str(data["id"])
    scenario_root = manifest_path.parent
    runtime_root = GENERATED_ROOT / scenario_id
    runtime_root.mkdir(parents=True, exist_ok=True)

    prompt_path = runtime_root / "prompt.md"
    hint_path = runtime_root / "hint.md"
    check_path = runtime_root / "check.sh"
    solution_path = runtime_root / "solution.md"
    metadata_path = runtime_root / "exercise.json"

    lab = cast(dict[str, Any], data["content"]["lab"])
    checks = [normalize_check_entry(command, index) for index, command in enumerate(cast(list[str], lab.get("checks", [])), start=1)]

    shutil.copyfile(scenario_root / "LAB_TASKS.md", prompt_path)
    shutil.copyfile(scenario_root / "LAB_SOLUTION.md", solution_path)
    write_text(hint_path, render_hints(str(data["title"]), cast(list[str], lab.get("hints", []))))
    write_text(check_path, render_check_script(relpath(manifest_path), checks))

    metadata: ExerciseMetadata = {
        "id": scenario_id,
        "title": str(data["title"]),
        "description": normalize_task_text(str(data["description"])),
        "time_limit_minutes": int(data["time_limit_minutes"]),
        "objective_tags": cast(list[str], data.get("objective_tags", [])),
        "requires_servervm": bool(cast(dict[str, Any], data.get("flags", {})).get("requires_servervm", False)),
        "source_manifest": relpath(manifest_path),
        "source_hash": manifest_hash(manifest_path),
        "paths": {
            "prompt": relpath(prompt_path),
            "hint": relpath(hint_path),
            "check": relpath(check_path),
            "solution": relpath(solution_path),
            "metadata": relpath(metadata_path),
        },
        "checks": checks,
    }
    write_text(metadata_path, json.dumps(metadata, indent=2))
    return metadata


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate local lab runtime cache under .lab-state/generated.")
    parser.add_argument("scenario_ids", nargs="*", help="Optional lab ids to generate. Defaults to all lab scenarios.")
    parser.add_argument("--clean", action="store_true", help="Remove stale generated lab cache directories that no longer map to a scenario.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    GENERATED_ROOT.mkdir(parents=True, exist_ok=True)

    manifest_paths = sorted(LABS_ROOT.glob("*/scenario.json"))
    wanted = {scenario_id.strip() for scenario_id in args.scenario_ids if scenario_id.strip()}
    expected_ids: set[str] = set()

    for manifest_path in manifest_paths:
        if wanted and manifest_path.parent.name not in wanted:
            continue
        metadata = build_runtime_cache(manifest_path)
        expected_ids.add(metadata["id"])
        print(f"generated {metadata['id']}")

    if args.clean and not wanted:
        for child in GENERATED_ROOT.iterdir():
            if child.is_dir() and child.name not in expected_ids:
                remove_tree(child)


if __name__ == "__main__":
    main()
