#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
LABS_DIR = ROOT / "scenarios" / "labs"
EXAMS_DIR = ROOT / "scenarios" / "exams"
RHC_SA = ROOT / "RHCSA.ps1"
RESULT_RE = re.compile(r"Result:\s+(complete|incomplete)\s+\((\d+)/(\d+)\)", re.I)
SCENARIO_RE = re.compile(r"(Lab|Exam):\s+([A-Za-z0-9._-]+)", re.I)
ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")


@dataclass
class SmokeResult:
    scenario_id: str
    kind: str
    ok: bool
    status: str
    passed: int
    total: int
    output: str
    fatal: bool = False


def windows_path(path: Path) -> str:
    if os.name == "nt":
        return str(path)
    proc = subprocess.run(
        ["wslpath", "-w", str(path)],
        text=True,
        capture_output=True,
        check=True,
    )
    return proc.stdout.strip()


def scenario_ids(kind: str) -> list[str]:
    base = LABS_DIR if kind == "lab" else EXAMS_DIR
    return [path.parent.name for path in sorted(base.glob("*/scenario.json"))]


def filter_ids(ids: list[str], start_from: str | None, only: list[str] | None) -> list[str]:
    if only:
        wanted = set(only)
        ids = [scenario_id for scenario_id in ids if scenario_id in wanted]
    if start_from:
        try:
            start_index = ids.index(start_from)
        except ValueError as exc:
            raise SystemExit(f"Unknown scenario id for --from: {start_from}") from exc
        ids = ids[start_index:]
    return ids


def run_ps(*args: str, timeout_seconds: int = 180) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            "powershell.exe",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            windows_path(RHC_SA),
            *args,
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
        timeout=timeout_seconds,
    )


def parse_check_output(output: str) -> tuple[str, int, int]:
    clean = ANSI_RE.sub("", output)
    match = RESULT_RE.search(clean)
    if not match:
        raise ValueError(f"Could not parse check output:\n{clean}")
    return match.group(1).lower(), int(match.group(2)), int(match.group(3))


def parse_reported_scenario(output: str) -> str | None:
    clean = ANSI_RE.sub("", output)
    match = SCENARIO_RE.search(clean)
    if not match:
        return None
    return match.group(2)


def is_fatal_environment_error(output: str) -> bool:
    clean = ANSI_RE.sub("", output)
    fatal_markers = (
        "VBoxManage.exe: error:",
        "Snapshot operation failed",
        "does not match the value",
        "provider for this Vagrant-managed machine is reporting that it is not yet ready for SSH",
        "Failed to assign the machine to the session",
        "Failed to read SSH config for",
        "failed. Command:",
    )
    return any(marker in clean for marker in fatal_markers)


def run_smoke(kind: str, scenario_id: str) -> SmokeResult:
    try:
        start_timeout = 420 if kind == "exam" else 240
        start_proc = run_ps("start", "-Id", scenario_id, "-Mode", kind.capitalize(), timeout_seconds=start_timeout)
    except subprocess.TimeoutExpired as exc:
        output = (exc.stdout or "") + (exc.stderr or "")
        return SmokeResult(scenario_id, kind, False, "timeout", 0, 0, output, fatal=True)
    if start_proc.returncode != 0:
        output = start_proc.stdout + start_proc.stderr
        return SmokeResult(
            scenario_id,
            kind,
            False,
            "error",
            0,
            0,
            output,
            fatal=is_fatal_environment_error(output),
        )

    start_output = start_proc.stdout + start_proc.stderr
    if "Already active:" in start_output:
        try:
            reset_proc = run_ps("reset", timeout_seconds=start_timeout)
        except subprocess.TimeoutExpired as exc:
            output = start_output + (exc.stdout or "") + (exc.stderr or "")
            return SmokeResult(scenario_id, kind, False, "timeout", 0, 0, output, fatal=True)
        if reset_proc.returncode != 0:
            output = start_output + reset_proc.stdout + reset_proc.stderr
            return SmokeResult(
                scenario_id,
                kind,
                False,
                "error",
                0,
                0,
                output,
                fatal=is_fatal_environment_error(output),
            )
        start_output += reset_proc.stdout + reset_proc.stderr

    if kind == "exam":
        return SmokeResult(scenario_id, kind, True, "ready", 0, 0, start_output)

    try:
        check_proc = run_ps("check", timeout_seconds=180)
    except subprocess.TimeoutExpired as exc:
        output = start_output + (exc.stdout or "") + (exc.stderr or "")
        return SmokeResult(scenario_id, kind, False, "timeout", 0, 0, output, fatal=True)
    output = start_output + check_proc.stdout + check_proc.stderr
    try:
        status, passed, total = parse_check_output(output)
    except ValueError:
        return SmokeResult(scenario_id, kind, False, "error", 0, 0, output, fatal=is_fatal_environment_error(output))

    reported = parse_reported_scenario(output)
    if reported and reported != scenario_id:
        return SmokeResult(
            scenario_id,
            kind,
            False,
            "error",
            0,
            0,
            f"Expected scenario {scenario_id}, but check reported {reported}.\n{output}",
            fatal=True,
        )

    ok = check_proc.returncode in (0, 1) and passed == 0 and status == "incomplete"
    return SmokeResult(scenario_id, kind, ok, status, passed, total, output)


def iter_selected_kinds(selection: str) -> Iterable[str]:
    if selection == "all":
        yield "lab"
        yield "exam"
    else:
        yield selection


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Start scenarios and verify they do not begin partially complete."
    )
    parser.add_argument(
        "--kind",
        choices=("lab", "exam", "all"),
        default="all",
        help="Scenario kind to smoke test.",
    )
    parser.add_argument(
        "--from",
        dest="start_from",
        help="Start from this scenario id within the selected kind.",
    )
    parser.add_argument(
        "--only",
        nargs="+",
        help="Only run the specified scenario ids.",
    )
    parser.add_argument(
        "--ensure-up",
        action="store_true",
        help="Run '.\\RHCSA.ps1 up' before the smoke test.",
    )
    args = parser.parse_args()

    if args.ensure_up:
        up_proc = run_ps("up")
        sys.stdout.write(up_proc.stdout)
        sys.stderr.write(up_proc.stderr)
        if up_proc.returncode != 0:
            return up_proc.returncode

    failures: list[SmokeResult] = []

    for kind in iter_selected_kinds(args.kind):
        ids = filter_ids(scenario_ids(kind), args.start_from, args.only)
        print(f"\n== {kind}s ==")
        for index, scenario_id in enumerate(ids, start=1):
            print(f"[{index}/{len(ids)}] {scenario_id}")
            result = run_smoke(kind, scenario_id)
            if result.ok:
                print(f"  ok: baseline is {result.status} ({result.passed}/{result.total})")
            else:
                failures.append(result)
                print(f"  fail: baseline is {result.status} ({result.passed}/{result.total})")
                if result.fatal:
                    print("  fatal: stopping early because the baseline or VM state is broken")
                    break
        if failures and failures[-1].fatal:
            break

    if failures:
        print("\nFailures:")
        for result in failures:
            print(f"- [{result.kind}] {result.scenario_id}: {result.status} ({result.passed}/{result.total})")
            for line in result.output.splitlines():
                if line.strip():
                    print(f"    {line}")
        return 1

    print("\nAll checked scenarios start at 0/N as expected.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
