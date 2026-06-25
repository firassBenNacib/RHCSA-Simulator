from __future__ import annotations

import importlib.util
from pathlib import Path
from unittest import mock

import pytest


ROOT = Path(__file__).resolve().parents[3]
LAUNCHER = ROOT / "rhcsa.py"


def load_launcher():
    spec = importlib.util.spec_from_file_location("rhcsa_launcher", LAUNCHER)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_windows_powershell_command_uses_execution_policy() -> None:
    launcher = load_launcher()

    command = launcher.build_powershell_command(["profile"], executable="powershell", platform_name="nt")

    assert command == [
        "powershell",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(ROOT / "RHCSA.ps1"),
        "profile",
    ]


def test_non_windows_powershell_command_uses_pwsh_without_execution_policy() -> None:
    launcher = load_launcher()

    command = launcher.build_powershell_command(["up"], executable="pwsh", platform_name="posix")

    assert command == ["pwsh", "-NoProfile", "-File", str(ROOT / "RHCSA.ps1"), "up"]


def test_help_does_not_require_powershell(capsys) -> None:
    launcher = load_launcher()

    result = launcher.main(["--help"])

    captured = capsys.readouterr()
    assert result == 0
    assert "RHCSA Simulator Python launcher" in captured.out
    assert "scenario replay" in captured.out


def test_scenario_replay_uses_python_tool() -> None:
    launcher = load_launcher()

    with mock.patch.object(launcher, "run_subprocess", return_value=0) as run_subprocess:
        result = launcher.main(["scenario", "replay", "--kind", "labs", "--audit-only"])

    assert result == 0
    command = run_subprocess.call_args.args[0]
    assert command[0]
    assert command[1] == str(ROOT / "host" / "verify_scenario_solutions.py")
    assert command[2:] == ["--kind", "labs", "--audit-only"]


def test_missing_powershell_returns_clear_error(capsys) -> None:
    launcher = load_launcher()

    with mock.patch.object(launcher, "find_powershell", return_value=None):
        result = launcher.main(["profile"])

    captured = capsys.readouterr()
    assert result == 127
    assert "PowerShell was not found" in captured.err


@pytest.mark.parametrize(
    "args",
    [
        ["up"],
        ["destroy"],
        ["start", "-Id", "rhcsa10-mock-exam-a", "-Mode", "Exam"],
        ["check"],
        ["repo", "import", "rhel-10.2-x86_64-dvd.iso"],
        ["profile", "RHCSA10"],
    ],
)
def test_common_simulator_commands_delegate_to_powershell(args: list[str]) -> None:
    launcher = load_launcher()

    with (
        mock.patch.object(launcher, "find_powershell", return_value="pwsh"),
        mock.patch.object(launcher, "run_subprocess", return_value=0) as run_subprocess,
    ):
        result = launcher.main(args)

    assert result == 0
    command = run_subprocess.call_args.args[0]
    assert command[0] == "pwsh"
    assert "-NoProfile" in command
    file_index = command.index("-File")
    assert command[file_index + 1] == str(ROOT / "RHCSA.ps1")
    assert command[file_index + 2 :] == args
