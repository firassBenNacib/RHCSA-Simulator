#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from rhcsa_scenarios.tracks import manifest_tracks, normalize_track


ROOT = Path(__file__).resolve().parents[2]
LABS_DIR = ROOT / "scenarios" / "labs"
EXAMS_DIR = ROOT / "scenarios" / "exams"
RHC_SA = ROOT / "RHCSA.ps1"
RESULT_RE = re.compile(r"Result:\s+(complete|incomplete)\s+\((\d+)/(\d+)\)", re.I)
SCENARIO_RE = re.compile(r"(Lab|Exam):\s+([A-Za-z0-9._-]+)", re.I)
BASELINE_RE = re.compile(r"Baseline:\s+(.+)", re.I)
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


def ensure_text(value: str | bytes | bytearray | memoryview | None) -> str:
    if value is None:
        return ""
    elif isinstance(value, str):
        return value
    elif isinstance(value, memoryview):
        value = value.tobytes()
        return value.decode("utf-8", errors="replace")
    elif isinstance(value, (bytes, bytearray)):
        return bytes(value).decode("utf-8", errors="replace")
    else:
        return ""


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


def scenario_matches_track(kind: str, scenario_id: str, track: str) -> bool:
    normalized = normalize_track(track)
    if normalized == "all":
        return True
    manifest_path = scenario_manifest_path(kind, scenario_id)
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    return normalized in manifest_tracks(data.get("tracks"))


def scenario_ids(kind: str, track: str = "all") -> list[str]:
    base = LABS_DIR if kind == "lab" else EXAMS_DIR
    ids = [path.parent.name for path in sorted(base.glob("*/scenario.json"))]
    return [scenario_id for scenario_id in ids if scenario_matches_track(kind, scenario_id, track)]


def normalize_scenario_token(value: str) -> str:
    return re.sub(r"[^a-z0-9]", "", value.lower())


def resolve_scenario_token(ids: list[str], token: str) -> str:
    if token in ids:
        return token

    prefix_matches = [scenario_id for scenario_id in ids if scenario_id.startswith(token)]
    if len(prefix_matches) == 1:
        return prefix_matches[0]
    if len(prefix_matches) > 1:
        raise SystemExit(
            f"Ambiguous scenario id '{token}'. Matches: {', '.join(prefix_matches)}"
        )

    normalized_token = normalize_scenario_token(token)
    normalized_matches = [
        scenario_id
        for scenario_id in ids
        if normalize_scenario_token(scenario_id).startswith(normalized_token)
    ]
    if len(normalized_matches) == 1:
        return normalized_matches[0]
    if len(normalized_matches) > 1:
        raise SystemExit(
            f"Ambiguous scenario id '{token}'. Matches: {', '.join(normalized_matches)}"
        )

    raise SystemExit(f"Unknown scenario id: {token}")


def scenario_manifest_path(kind: str, scenario_id: str) -> Path:
    base = LABS_DIR if kind == "lab" else EXAMS_DIR
    return base / scenario_id / "scenario.json"


def scenario_requires_server(kind: str, scenario_id: str) -> bool:
    manifest_path = scenario_manifest_path(kind, scenario_id)
    if not manifest_path.exists():
        return False
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    return bool(data.get("flags", {}).get("requires_server", False))


def filter_ids(ids: list[str], start_from: str | None, end_at: str | None, only: list[str] | None) -> list[str]:
    if only:
        wanted = {resolve_scenario_token(ids, token) for token in only}
        ids = [scenario_id for scenario_id in ids if scenario_id in wanted]
    if start_from:
        start_id = resolve_scenario_token(ids, start_from)
        start_index = ids.index(start_id)
        ids = ids[start_index:]
    if end_at:
        end_id = resolve_scenario_token(ids, end_at)
        end_index = ids.index(end_id)
        ids = ids[: end_index + 1]
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
        errors="replace",
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


def parse_baseline_status(output: str) -> str | None:
    clean = ANSI_RE.sub("", output)
    match = BASELINE_RE.search(clean)
    if not match:
        return None
    return match.group(1).strip().lower()


def get_baseline_status() -> str | None:
    proc = run_ps("status", timeout_seconds=60)
    if proc.returncode != 0:
        return None
    return parse_baseline_status(proc.stdout + proc.stderr)


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


def start_timeout_seconds(kind: str, scenario_id: str) -> int:
    if kind == "exam":
        return 900
    if scenario_requires_server(kind, scenario_id):
        return 720
    return 420


def check_timeout_seconds(kind: str, scenario_id: str) -> int:
    if kind == "exam":
        return 0
    if scenario_requires_server(kind, scenario_id):
        return 420
    return 300


def destroy_after_fatal_timeout() -> None:
    try:
        run_ps("destroy", timeout_seconds=240)
    except subprocess.TimeoutExpired:
        pass


def run_smoke(
    kind: str,
    scenario_id: str,
    track: str,
    start_timeout_override: int | None = None,
    check_timeout_override: int | None = None,
) -> SmokeResult:
    start_timeout = start_timeout_override or start_timeout_seconds(kind, scenario_id)
    try:
        start_proc = run_ps("start", "-Id", scenario_id, "-Mode", kind.capitalize(), "-Track", normalize_track(track), timeout_seconds=start_timeout)
    except subprocess.TimeoutExpired as exc:
        destroy_after_fatal_timeout()
        output = f"Timed out during start after {start_timeout}s.\n" + ensure_text(exc.stdout) + ensure_text(exc.stderr)
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
            destroy_after_fatal_timeout()
            output = (
                start_output
                + f"Timed out during reset after {start_timeout}s.\n"
                + ensure_text(exc.stdout)
                + ensure_text(exc.stderr)
            )
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

    check_timeout = check_timeout_override or check_timeout_seconds(kind, scenario_id)
    try:
        check_proc = run_ps("check", timeout_seconds=check_timeout)
    except subprocess.TimeoutExpired as exc:
        destroy_after_fatal_timeout()
        output = (
            start_output
            + f"Timed out during check after {check_timeout}s.\n"
            + ensure_text(exc.stdout)
            + ensure_text(exc.stderr)
        )
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
        "--to",
        dest="end_at",
        help="Stop at this scenario id within the selected kind.",
    )
    parser.add_argument(
        "--only",
        nargs="+",
        help="Only run the specified scenario ids.",
    )
    parser.add_argument(
        "--track",
        default="rhcsa9",
        help="Scenario track to smoke test: rhcsa9, rhcsa10, or all.",
    )
    parser.add_argument(
        "--ensure-up",
        action="store_true",
        help="Run '.\\RHCSA.ps1 up' before the smoke test.",
    )
    parser.add_argument(
        "--start-timeout",
        type=int,
        help="Override the per-scenario start/reset timeout in seconds.",
    )
    parser.add_argument(
        "--check-timeout",
        type=int,
        help="Override the per-scenario check timeout in seconds.",
    )
    args = parser.parse_args()

    if args.ensure_up:
        baseline_status = get_baseline_status()
        if baseline_status != "ready":
            up_timeout = max(args.start_timeout or 0, 1800)
            try:
                up_proc = run_ps("up", timeout_seconds=up_timeout)
            except subprocess.TimeoutExpired as exc:
                sys.stdout.write(ensure_text(exc.stdout))
                sys.stderr.write(ensure_text(exc.stderr))
                print(
                    f"'.\\RHCSA.ps1 up' timed out after {up_timeout}s while running under --ensure-up.",
                    file=sys.stderr,
                )
                return 1
            sys.stdout.write(up_proc.stdout)
            sys.stderr.write(up_proc.stderr)
            if up_proc.returncode != 0:
                return up_proc.returncode
    else:
        baseline_status = get_baseline_status()
        if baseline_status != "ready":
            print(
                "Baseline is not ready. Run '.\\RHCSA.ps1 up' first, or rerun with '--ensure-up'.",
                file=sys.stderr,
            )
            return 1

    failures: list[SmokeResult] = []
    track = normalize_track(args.track)

    for kind in iter_selected_kinds(args.kind):
        ids = filter_ids(scenario_ids(kind, track), args.start_from, args.end_at, args.only)
        print(f"\n== {kind}s ==")
        for index, scenario_id in enumerate(ids, start=1):
            print(f"[{index}/{len(ids)}] {scenario_id}")
            result = run_smoke(kind, scenario_id, track, args.start_timeout, args.check_timeout)
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
