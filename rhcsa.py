#!/usr/bin/env python3
"""Cross-platform compatibility entry point for the RHCSA simulator.

The simulator runtime remains implemented in PowerShell. This launcher keeps
that stable path in place while giving non-Windows users a Python command they
can use to reach the same interface when PowerShell Core is installed.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Sequence


PROJECT_ROOT = Path(__file__).resolve().parent
POWERSHELL_SCRIPT = PROJECT_ROOT / "RHCSA.ps1"


PYTHON_SCENARIO_COMMANDS = {
    "audit": PROJECT_ROOT / "tools" / "scenarios" / "audit_scenarios.py",
    "replay": PROJECT_ROOT / "host" / "verify_scenario_solutions.py",
    "smoke": PROJECT_ROOT / "host" / "smoke_test_scenarios.py",
}


def usage() -> str:
    return """RHCSA Simulator Python launcher

Usage:
  python rhcsa.py <command> [args...]
  python rhcsa.py scenario audit [args...]
  python rhcsa.py scenario replay [args...]
  python rhcsa.py scenario smoke [args...]

Examples:
  python rhcsa.py profile
  python rhcsa.py up
  python rhcsa.py start -Id rhcsa10-mock-exam-a -Mode Exam
  python rhcsa.py scenario replay --kind labs --track RHCSA10 --only lab-06-flatpak-remote --audit-only

Simulator commands delegate to RHCSA.ps1. On non-Windows systems, install
PowerShell Core and make pwsh available on PATH.
"""


def find_powershell() -> str | None:
    override = os.environ.get("RHCSA_POWERSHELL", "").strip()
    if override:
        return override

    for candidate in ("pwsh", "powershell"):
        resolved = shutil.which(candidate)
        if resolved:
            return resolved

    return None


def build_powershell_command(args: Sequence[str], *, executable: str, platform_name: str | None = None) -> list[str]:
    platform = platform_name or os.name
    command = [executable, "-NoProfile"]
    if platform == "nt":
        command.extend(["-ExecutionPolicy", "Bypass"])
    command.extend(["-File", str(POWERSHELL_SCRIPT)])
    command.extend(args)
    return command


def run_subprocess(command: Sequence[str]) -> int:
    completed = subprocess.run(command, cwd=PROJECT_ROOT, check=False)
    return int(completed.returncode)


def run_scenario_tool(args: Sequence[str]) -> int:
    if len(args) < 2 or args[1] in {"-h", "--help"}:
        print("Usage: python rhcsa.py scenario <audit|replay|smoke> [args...]", file=sys.stderr)
        return 2

    tool_name = args[1].lower()
    script = PYTHON_SCENARIO_COMMANDS.get(tool_name)
    if script is None:
        print(f"Unknown scenario command '{args[1]}'. Use audit, replay, or smoke.", file=sys.stderr)
        return 2

    return run_subprocess([sys.executable, str(script), *args[2:]])


def run_powershell(args: Sequence[str]) -> int:
    executable = find_powershell()
    if executable is None:
        print(
            "PowerShell was not found. Install PowerShell Core (pwsh) or set RHCSA_POWERSHELL.",
            file=sys.stderr,
        )
        return 127

    return run_subprocess(build_powershell_command(args, executable=executable))


def main(argv: Sequence[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    if not args or args[0] in {"-h", "--help"}:
        print(usage().rstrip())
        return 0

    if args[0].lower() == "scenario":
        return run_scenario_tool(args)

    return run_powershell(args)


if __name__ == "__main__":
    raise SystemExit(main())
