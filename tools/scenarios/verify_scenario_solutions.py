#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path
from functools import lru_cache


HOST_DIR = Path(__file__).resolve().parent
if str(HOST_DIR) not in sys.path:
    sys.path.insert(0, str(HOST_DIR))

from scenario_solution_normalizer import normalize_command_list  # noqa: E402
from smoke_test_scenarios import (  # noqa: E402
    EXAMS_DIR,
    LABS_DIR,
    ROOT,
    filter_ids,
    get_baseline_status,
    normalize_track,
    parse_check_output,
    resolve_scenario_token,
    run_ps,
    scenario_ids,
)


CONTROL_TOKENS = {"EOF", ":wq", ":x", "exit"}
COMMAND_PREFIXES = {
    "at",
    "blkid",
    "cat",
    "chmod",
    "chown",
    "chpasswd",
    "cp",
    "crontab",
    "curl",
    "dnf",
    "echo",
    "export",
    "fdisk",
    "firewall-cmd",
    "getent",
    "getenforce",
    "getfacl",
    "getsebool",
    "grubby",
    "groupadd",
    "hostnamectl",
    "id",
    "kill",
    "ln",
    "loginctl",
    "ls",
    "lvchange",
    "lvcreate",
    "lvextend",
    "lvreduce",
    "lvresize",
    "mkdir",
    "mkfs",
    "mkswap",
    "mount",
    "mountpoint",
    "mv",
    "nmcli",
    "parted",
    "partprobe",
    "passwd",
    "podman",
    "restorecon",
    "renice",
    "resize2fs",
    "rm",
    "rsync",
    "scp",
    "sed",
    "semanage",
    "setenforce",
    "setfacl",
    "setsebool",
    "sh",
    "ssh",
    "ssh-copy-id",
    "ssh-keygen",
    "su",
    "swapoff",
    "swapon",
    "systemctl",
    "tar",
    "test",
    "touch",
    "tune2fs",
    "umount",
    "useradd",
    "usermod",
    "vgcreate",
    "vim",
    "visudo",
    "xfs_growfs",
}


@dataclass
class ExecutionUnit:
    vm: str
    user: str
    script: str
    description: str
    requires_ssh_recovery: bool = False


@dataclass
class TaskPlan:
    supported: bool
    units: list[ExecutionUnit]
    final_vm: str | None = None
    final_user: str | None = None
    reason: str | None = None


def is_network_bounce_command(line: str) -> bool:
    stripped = line.strip()
    return stripped.startswith("nmcli connection down ") or stripped.startswith("nmcli con down ")


def is_network_restore_command(line: str) -> bool:
    stripped = line.strip()
    return stripped.startswith("nmcli connection up ") or stripped.startswith("nmcli con up ")


def split_top_level_and_clauses(command: str) -> list[str]:
    clauses: list[str] = []
    buffer: list[str] = []
    in_single = False
    in_double = False
    escaped = False
    i = 0
    while i < len(command):
        ch = command[i]
        if escaped:
            buffer.append(ch)
            escaped = False
            i += 1
            continue
        if ch == "\\" and not in_single:
            buffer.append(ch)
            escaped = True
            i += 1
            continue
        if ch == "'" and not in_double:
            in_single = not in_single
            buffer.append(ch)
            i += 1
            continue
        if ch == '"' and not in_single:
            in_double = not in_double
            buffer.append(ch)
            i += 1
            continue
        if not in_single and not in_double and command.startswith("&&", i):
            clause = "".join(buffer).strip()
            if clause:
                clauses.append(clause)
            buffer = []
            i += 2
            continue
        buffer.append(ch)
        i += 1
    clause = "".join(buffer).strip()
    if clause:
        clauses.append(clause)
    return clauses


def shell_token_spans(command: str) -> list[tuple[int, int, str]]:
    spans: list[tuple[int, int, str]] = []
    i = 0
    length = len(command)
    while i < length:
        while i < length and command[i].isspace():
            i += 1
        if i >= length:
            break
        start = i
        in_single = False
        in_double = False
        while i < length:
            ch = command[i]
            if ch == "'" and not in_double:
                in_single = not in_single
                i += 1
                continue
            if ch == '"' and not in_single:
                in_double = not in_double
                i += 1
                continue
            if ch == "\\" and not in_single and i + 1 < length:
                i += 2
                continue
            if not in_single and not in_double and command[i].isspace():
                break
            i += 1
        spans.append((start, i, command[start:i]))
    return spans


def resolve_exam_check_clause(clause: str) -> tuple[str, str]:
    stripped = clause.strip()
    negate_prefix = ""
    if stripped.startswith("!"):
        negate_prefix = "! "
        stripped = stripped[1:].lstrip()
    if not stripped.startswith("ssh "):
        return "client", clause.strip()

    token_spans = shell_token_spans(stripped)
    if not token_spans or token_spans[0][2] != "ssh":
        return "client", clause.strip()

    for _index, (_start, end, token) in enumerate(token_spans[1:], start=1):
        normalized = token.strip("'\"")
        if normalized.startswith("-"):
            continue
        if "server" not in normalized:
            continue
        remote_command = stripped[end:].lstrip()
        if remote_command.lower().startswith("sudo "):
            remote_command = remote_command[5:].lstrip()
        if not remote_command:
            return "client", clause.strip()
        return "server", f"{negate_prefix}{remote_command}".strip()

    return "client", clause.strip()


def script_requires_ssh_recovery(script: str) -> bool:
    lowered = script.lower()
    return any(
        marker in lowered
        for marker in (
            "systemctl restart sshd",
            "systemctl reload sshd",
            "systemctl restart ssh.service",
            "systemctl reload ssh.service",
        )
    )


def render_background_network_bounce(commands: list[str]) -> str:
    payload = base64.b64encode(("set -euo pipefail\n" + "\n".join(commands)).encode("utf-8")).decode("ascii")
    return "\n".join(
        [
            "bounce=$(mktemp /tmp/codex-netbounce-XXXXXX.sh)",
            "base64 -d > \"$bounce\" <<'__CODEX__'",
            payload,
            "__CODEX__",
            "chmod 700 \"$bounce\"",
            "nohup bash \"$bounce\" >/tmp/codex-netbounce.log 2>&1 </dev/null &",
        ]
    )


def load_manifest(kind: str, scenario_id: str) -> dict:
    base = LABS_DIR if kind == "lab" else EXAMS_DIR
    return json.loads((base / scenario_id / "scenario.json").read_text(encoding="utf-8"))


@lru_cache(maxsize=1)
def get_vagrant_executable() -> str:
    candidate = shutil.which("vagrant")
    if candidate:
        return candidate
    if os.name == "nt":
        fallback = Path(os.environ.get("ProgramFiles", r"C:\Program Files")) / "Vagrant" / "bin" / "vagrant.exe"
        if fallback.exists():
            return str(fallback)
    raise RuntimeError("Could not find the Vagrant executable. Install Vagrant or add it to PATH.")


@lru_cache(maxsize=1)
def get_ssh_executable() -> str:
    candidate = shutil.which("ssh")
    if candidate:
        return candidate
    if os.name == "nt":
        fallback = Path(os.environ.get("WINDIR", r"C:\Windows")) / "System32" / "OpenSSH" / "ssh.exe"
        if fallback.exists():
            return str(fallback)
    raise RuntimeError("Could not find ssh.exe. Install the OpenSSH Client or add ssh.exe to PATH.")


def shell_quote(value: str) -> str:
    return shlex.quote(value)


def default_vm_for_task(manifest: dict, task_text: str) -> str:
    lowered = task_text.lower()
    description_lower = str(manifest.get("description", "")).lower()
    if lowered.startswith("on server"):
        return "server"
    if lowered.startswith("on client"):
        return "client"
    if re.search(r"\bon client\b", lowered):
        return "client"
    if re.search(r"\bon server\b", lowered):
        return "server"
    if "server" in lowered and "client" not in lowered:
        return "server"
    if "client" in lowered and "server" not in lowered:
        return "client"
    if "server" in lowered and "client" in lowered:
        return "client"
    if "server" in description_lower and "client" not in description_lower:
        return "server"
    if "client" in description_lower and "server" not in description_lower:
        return "client"
    vm_scripts = manifest.get("vm_scripts", {})
    if len(vm_scripts) == 1:
        return next(iter(vm_scripts))
    if manifest.get("flags", {}).get("requires_server", False) and "client" not in description_lower:
        return "server"
    return "client"


def is_probable_shell_command(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return False
    if stripped in CONTROL_TOKENS:
        return True
    if stripped.startswith("#"):
        return True
    if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", stripped):
        first_token = stripped.split(None, 1)[0]
        assigned_value = first_token.split("=", 1)[1]
        if " " not in stripped or assigned_value.startswith(('"', "'", "$", "(")):
            return True
    if stripped.startswith(("export ", "unset ")):
        return True
    if any(token in stripped for token in ("&&", "||", "$(", "|", ";")):
        return True
    try:
        tokens = shlex.split(stripped)
    except ValueError:
        return False
    if not tokens:
        return False
    first = tokens[0]
    if first in COMMAND_PREFIXES:
        return True
    if first.startswith("/"):
        return True
    return False


def consume_literal_lines(
    lines: list[str],
    start: int,
    *,
    editor_mode: bool = False,
    path: str | None = None,
) -> tuple[list[str], int]:
    content: list[str] = []
    index = start
    while index < len(lines):
        candidate = lines[index].rstrip()
        if not candidate:
            index += 1
            continue
        lowered = candidate.lower()
        if editor_mode:
            if lowered.startswith("# run on ") or lowered.startswith("# on "):
                break
            if (
                candidate.startswith("#!")
                or lowered.startswith("# set:")
                or lowered.startswith("# ")
                or (candidate.startswith("/") and " " in candidate and ">>" not in candidate and "|" not in candidate)
            ):
                content.append(candidate)
                index += 1
                continue

            if path and not path.startswith("/usr/local/bin/"):
                stripped = candidate.lstrip()
                if (
                    re.match(r"^\[[^]]+\]$", stripped)
                    or re.match(r"^[A-Za-z0-9_.:-]+\s*=", stripped)
                    or stripped.startswith((";", "#"))
                ):
                    content.append(candidate)
                    index += 1
                    continue

            if path and path.startswith("/usr/local/bin/"):
                stripped = candidate.lstrip()
                if stripped == "exit":
                    break
                if (
                    path in stripped
                    and (
                        stripped.startswith("chmod ")
                        or stripped.startswith("chown ")
                        or stripped.startswith("restorecon ")
                        or stripped.startswith(path)
                    )
                ):
                    break
                content.append(candidate)
                index += 1
                continue
        if is_probable_shell_command(candidate):
            break
        content.append(candidate)
        index += 1
    return content, index


def extract_password(task_text: str, lines: list[str]) -> str | None:
    for line in lines:
        match = re.search(r"enter:\s*([A-Za-z0-9._-]+)", line, re.I)
        if match:
            return match.group(1)

    match = re.search(r"password(?:s)?[^.]*?\bto[: ]+([A-Za-z0-9._-]+)", task_text, re.I)
    if match:
        return match.group(1)

    return None


def render_append_unique(path: str, lines: list[str]) -> str:
    script_lines = []
    for line in lines:
        script_lines.append(
            f"grep -Fqx -- {shell_quote(line)} {shell_quote(path)} || echo {shell_quote(line)} >> {shell_quote(path)}"
        )
    return "\n".join(script_lines)


def render_write_file(path: str, lines: list[str], mode: str | None = None) -> str:
    body = "\n".join(lines)
    script = (
        f"install -d -m 755 {shell_quote(str(Path(path).parent))}\n"
        f"cat > {shell_quote(path)} <<'__CODEX__'\n"
        f"{body}\n"
        "__CODEX__"
    )
    if mode:
        script += f"\nchmod {mode} {shell_quote(path)}"
    return script


def render_key_value_updates(path: str, lines: list[str]) -> str:
    payload = json.dumps(lines)
    return f"""python3 - <<'PY'
from pathlib import Path
import json
path = Path({path!r})
path.parent.mkdir(parents=True, exist_ok=True)
desired = json.loads({payload!r})
existing = path.read_text(encoding='utf-8').splitlines() if path.exists() else []
if path == Path('/etc/ssh/sshd_config'):
    port_lines = [item for item in desired if item.split(None, 1)[0] == 'Port']
    if port_lines:
        existing = [line for line in existing if not line.lstrip().startswith('Port ')]
        existing.extend(port_lines)
        desired = [item for item in desired if item.split(None, 1)[0] != 'Port']
for item in desired:
    key = item.split(None, 1)[0]
    replaced = False
    updated = []
    for line in existing:
        stripped = line.lstrip()
        if stripped.startswith(key):
            updated.append(item)
            replaced = True
        else:
            updated.append(line)
    if not replaced:
        updated.append(item)
    existing = updated
path.write_text("\\n".join(existing) + "\\n", encoding='utf-8')
PY"""


def render_httpd_updates(path: str, lines: list[str]) -> str:
    payload = json.dumps(lines)
    return f"""python3 - <<'PY'
from pathlib import Path
import json
path = Path({path!r})
path.parent.mkdir(parents=True, exist_ok=True)
desired = json.loads({payload!r})
existing = path.read_text(encoding='utf-8').splitlines()
for item in desired:
    prefix = item.split()[0]
    replaced = False
    updated = []
    for line in existing:
        if prefix == "Listen" and line.lstrip().startswith("Listen "):
            updated.append(item)
            replaced = True
        else:
            updated.append(line)
    if not replaced:
        updated.append(item)
    existing = updated
path.write_text("\\n".join(existing) + "\\n", encoding='utf-8')
PY"""


def render_visudo(command: str, content: list[str], task_index: int) -> str:
    target = f"/etc/sudoers.d/codex-task-{task_index:02d}"
    match = re.search(r"-f\s+(\S+)", command)
    if match:
        target = match.group(1)
    return render_write_file(target, content, mode="440") + "\nvisudo -cf /etc/sudoers >/dev/null"


def render_crontab(command: str, content: list[str]) -> str:
    if not content:
        raise ValueError("Missing cron line after crontab -e")
    match = re.search(r"-u\s+(\S+)", command)
    if match:
        user = match.group(1)
        return (
            f"(crontab -l -u {shell_quote(user)} 2>/dev/null || true; "
            f"echo {shell_quote(content[0])}) | crontab -u {shell_quote(user)} -"
        )
    return f"(crontab -l 2>/dev/null || true; echo {shell_quote(content[0])}) | crontab -"


def render_passwd(command: str, password: str | None) -> str | None:
    if not password:
        return None
    tokens = shlex.split(command)
    if len(tokens) != 2:
        return None
    user = tokens[1]
    return f"echo {shell_quote(f'{user}:{password}')} | chpasswd"


def render_ssh_copy_id(command: str, current_user: str) -> str | None:
    tokens = shlex.split(command)
    if len(tokens) < 2:
        return None

    pubkey_path = f"/home/{current_user}/.ssh/id_ed25519.pub"
    port = "22"
    remote_spec: str | None = None
    i = 1
    while i < len(tokens):
        token = tokens[i]
        if token == "-i" and i + 1 < len(tokens):
            pubkey_path = tokens[i + 1].replace("~", f"/home/{current_user}", 1)
            i += 2
            continue
        if token == "-p" and i + 1 < len(tokens):
            port = tokens[i + 1]
            i += 2
            continue
        if token.startswith("-"):
            i += 1
            continue
        remote_spec = token
        i += 1

    if not remote_spec or "@" not in remote_spec:
        return None

    dest_user, dest_host = remote_spec.split("@", 1)
    return "::".join(
        [
            "__CODEX_SSH_COPY_ID__",
            current_user,
            dest_user,
            dest_host,
            port,
            pubkey_path,
        ]
    )


def resolve_vm_alias(hostname: str) -> str | None:
    if hostname in {"server", "192.168.122.3"}:
        return "server"
    if hostname in {"client", "192.168.122.2"}:
        return "client"
    return None


def execute_special_unit(unit: ExecutionUnit, timeout: int) -> subprocess.CompletedProcess[str] | None:
    marker = unit.script.strip()
    if marker.startswith("set -euo pipefail\n__CODEX_SSH_COPY_ID__::"):
        marker = marker.splitlines()[-1]
    if not marker.startswith("__CODEX_SSH_COPY_ID__::"):
        return None

    _, current_user, dest_user, dest_host, port, pubkey_path = marker.split("::", 5)
    dest_vm = resolve_vm_alias(dest_host)
    if dest_vm is None:
        raise RuntimeError(f"Unsupported ssh-copy-id destination host: {dest_host}")

    pubkey_proc = run_remote_script(unit.vm, "root", f"set -euo pipefail\ncat {shell_quote(pubkey_path)}", timeout)
    if pubkey_proc.returncode != 0:
        return pubkey_proc

    pubkey = pubkey_proc.stdout.strip()
    known_hosts_path = f"/home/{current_user}/.ssh/known_hosts"
    client_seed = "\n".join(
        [
            "set -euo pipefail",
            f"install -d -m 700 /home/{current_user}/.ssh",
            f"touch {shell_quote(known_hosts_path)}",
            f"ssh-keyscan -p {shell_quote(port)} -H {shell_quote(dest_host)} >> {shell_quote(known_hosts_path)} 2>/dev/null || true",
            f"chown {shell_quote(current_user)}:{shell_quote(current_user)} {shell_quote(known_hosts_path)}",
            f"chmod 600 {shell_quote(known_hosts_path)}",
        ]
    )
    seed_proc = run_remote_script(unit.vm, "root", client_seed, timeout)
    if seed_proc.returncode != 0:
        return seed_proc

    server_script = "\n".join(
        [
            "set -euo pipefail",
            f"install -d -m 700 -o {shell_quote(dest_user)} -g {shell_quote(dest_user)} /home/{dest_user}/.ssh",
            f"touch /home/{dest_user}/.ssh/authorized_keys",
            f"grep -Fqx -- {shell_quote(pubkey)} /home/{dest_user}/.ssh/authorized_keys || echo {shell_quote(pubkey)} >> /home/{dest_user}/.ssh/authorized_keys",
            f"chown {shell_quote(dest_user)}:{shell_quote(dest_user)} /home/{dest_user}/.ssh/authorized_keys",
            f"chmod 600 /home/{dest_user}/.ssh/authorized_keys",
        ]
    )
    return run_remote_script(dest_vm, "root", server_script, timeout)


def render_vim(path: str, content: list[str]) -> str | None:
    if not content:
        return None

    normalized_content = [
        line.replace("# Set:", "", 1).strip() if line.lstrip().startswith("# Set:") else line
        for line in content
    ]

    if path in {"/etc/hosts", "/etc/fstab"} or path.endswith(".bash_profile") or path.endswith(".bashrc"):
        return render_append_unique(path, normalized_content)

    if path in {"/etc/login.defs", "/etc/ssh/sshd_config", "/etc/chrony.conf", "/etc/systemd/journald.conf"}:
        return render_key_value_updates(path, normalized_content)

    if path == "/etc/httpd/conf/httpd.conf":
        return render_httpd_updates(path, normalized_content)

    if (
        path.startswith("/etc/yum.repos.d/")
        or path.startswith("/etc/exports.d/")
        or path.startswith("/etc/systemd/journald.conf.d/")
        or path.startswith("/etc/auto.master.d/")
        or path.startswith("/etc/auto.")
        or path.startswith("/etc/profile.d/")
        or path.startswith("/usr/local/bin/")
        or path.endswith(".repo")
        or path.endswith(".exports")
        or path.endswith(".conf")
        or path.endswith(".autofs")
    ):
        return render_write_file(path, normalized_content)

    if path in {"/etc/issue", "/etc/motd"}:
        return render_write_file(path, normalized_content)

    return None


def translate_task(
    manifest: dict,
    kind: str,
    task_index: int,
    *,
    initial_vm: str | None = None,
    initial_user: str = "root",
) -> TaskPlan:
    content = manifest["content"][kind]
    task_text = content["tasks"][task_index]
    normalized_lines = normalize_command_list(content["solution_commands"][task_index])
    password = extract_password(task_text, normalized_lines)

    current_vm = default_vm_for_task(manifest, task_text)
    current_user = "root"
    units: list[ExecutionUnit] = []
    buffer: list[str] = []

    def flush(description: str) -> None:
        nonlocal buffer
        if not buffer:
            return
        units.append(
            ExecutionUnit(
                vm=current_vm,
                user=current_user,
                script="set -euo pipefail\n" + "\n".join(buffer),
                description=description,
            )
        )
        buffer = []

    i = 0
    while i < len(normalized_lines):
        line = normalized_lines[i].rstrip()
        if not line:
            i += 1
            continue

        if line.startswith("#"):
            lowered = line.lower()
            if "run on server" in lowered or lowered.startswith("# on server"):
                flush(f"task {task_index + 1}")
                current_vm = "server"
            elif "run on client" in lowered or lowered.startswith("# on client"):
                flush(f"task {task_index + 1}")
                current_vm = "client"
            i += 1
            continue

        if line == "exit":
            flush(f"task {task_index + 1}")
            current_user = "root"
            i += 1
            continue

        if line.startswith("su - "):
            flush(f"task {task_index + 1}")
            parts = shlex.split(line)
            if len(parts) >= 3:
                current_user = parts[2]
                i += 1
                continue
            return TaskPlan(False, units, current_vm, current_user, f"Unsupported su syntax in task {task_index + 1}: {line}")

        if line.startswith("passwd "):
            rendered = render_passwd(line, password)
            if rendered is None:
                return TaskPlan(False, units, current_vm, current_user, f"Could not derive password for task {task_index + 1}: {line}")
            buffer.append(rendered)
            i += 1
            continue

        if line.startswith("ssh-copy-id "):
            flush(f"task {task_index + 1}")
            rendered = render_ssh_copy_id(line, current_user)
            if rendered is None:
                return TaskPlan(False, units, current_vm, current_user, f"Unsupported ssh-copy-id syntax in task {task_index + 1}: {line}")
            units.append(ExecutionUnit(current_vm, "root", rendered, f"task {task_index + 1}"))
            i += 1
            continue

        if line.startswith("visudo"):
            flush(f"task {task_index + 1}")
            content_lines, next_index = consume_literal_lines(normalized_lines, i + 1)
            if not content_lines:
                return TaskPlan(False, units, current_vm, current_user, f"Missing sudoers content after '{line}'")
            rendered = render_visudo(line, content_lines, task_index + 1)
            units.append(ExecutionUnit(current_vm, current_user, "set -euo pipefail\n" + rendered, f"task {task_index + 1}"))
            i = next_index
            continue

        if line.startswith("crontab -e"):
            flush(f"task {task_index + 1}")
            content_lines, next_index = consume_literal_lines(normalized_lines, i + 1)
            try:
                rendered = render_crontab(line, content_lines)
            except ValueError as exc:
                return TaskPlan(False, units, current_vm, current_user, f"Task {task_index + 1}: {exc}")
            units.append(ExecutionUnit(current_vm, current_user, "set -euo pipefail\n" + rendered, f"task {task_index + 1}"))
            i = next_index
            continue

        if line.startswith("vim "):
            flush(f"task {task_index + 1}")
            path = shlex.split(line)[1]
            content_lines, next_index = consume_literal_lines(normalized_lines, i + 1, editor_mode=True, path=path)
            rendered = render_vim(path, content_lines)
            if rendered is None:
                return TaskPlan(False, units, current_vm, current_user, f"Unsupported vim target in task {task_index + 1}: {path}")
            units.append(ExecutionUnit(current_vm, current_user, "set -euo pipefail\n" + rendered, f"task {task_index + 1}"))
            i = next_index
            continue

        if line.startswith("fdisk "):
            return TaskPlan(False, units, current_vm, current_user, f"Interactive partitioning is not auto-replayable in task {task_index + 1}")

        if is_network_bounce_command(line):
            flush(f"task {task_index + 1}")
            bounce_commands = [line]
            next_index = i + 1
            if next_index < len(normalized_lines) and is_network_restore_command(normalized_lines[next_index].rstrip()):
                bounce_commands.append(normalized_lines[next_index].rstrip())
                next_index += 1
            units.append(
                ExecutionUnit(
                    vm=current_vm,
                    user=current_user,
                    script="set -euo pipefail\n" + render_background_network_bounce(bounce_commands),
                    description=f"task {task_index + 1}",
                    requires_ssh_recovery=True,
                )
            )
            i = next_index
            continue

        buffer.append(line)
        i += 1

    flush(f"task {task_index + 1}")
    return TaskPlan(True, units, current_vm, current_user)


def run_remote_script(vm: str, user: str, script: str, timeout: int) -> subprocess.CompletedProcess[str]:
    payload_prefix = (
        "set -euo pipefail\n"
        'codex_ssh_bin="$(mktemp -d /tmp/codex-ssh-bin-XXXXXX)"\n'
        "trap 'rm -rf \"$codex_ssh_bin\"' EXIT\n"
        "cat >\"$codex_ssh_bin/ssh\" <<'__CODEX_SSH__'\n"
        "#!/bin/bash\n"
        "exec /usr/bin/ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \"$@\"\n"
        "__CODEX_SSH__\n"
        "cat >\"$codex_ssh_bin/scp\" <<'__CODEX_SCP__'\n"
        "#!/bin/bash\n"
        "exec /usr/bin/scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \"$@\"\n"
        "__CODEX_SCP__\n"
        "cat >\"$codex_ssh_bin/ssh-copy-id\" <<'__CODEX_SSH_COPY_ID__'\n"
        "#!/bin/bash\n"
        "exec /usr/bin/ssh-copy-id -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \"$@\"\n"
        "__CODEX_SSH_COPY_ID__\n"
        "chmod 700 \"$codex_ssh_bin/ssh\" \"$codex_ssh_bin/scp\" \"$codex_ssh_bin/ssh-copy-id\"\n"
        'export PATH="$codex_ssh_bin:$PATH"\n'
    )
    if user != "root" and "podman " in script:
        payload_prefix += (
            'export XDG_RUNTIME_DIR="/tmp/podman-run-$(id -u)"\n'
            'install -d -m 700 "$XDG_RUNTIME_DIR"\n'
        )
    payload_script = payload_prefix + script
    encoded = base64.b64encode(payload_script.encode("utf-8")).decode("ascii")
    remote_lines = [
        "tmp=$(mktemp /tmp/codex-solution-XXXXXX.sh)",
        "base64 -d > \"$tmp\" <<'__CODEX__'",
        encoded,
        "__CODEX__",
    ]
    if user == "root":
        remote_lines += [
            "sudo bash \"$tmp\"",
            "status=$?",
        ]
    else:
        remote_lines += [
            f"sudo chown {shell_quote(user)}:{shell_quote(user)} \"$tmp\"",
            "sudo chmod 700 \"$tmp\"",
            f"sudo runuser -l {shell_quote(user)} -c \"bash '$tmp'\"",
            "status=$?",
        ]
    remote_lines += [
        "sudo rm -f \"$tmp\"",
        "exit $status",
    ]
    remote_command = "\n".join(remote_lines)
    return subprocess.run(
        build_ssh_command(vm, remote_command),
        cwd=ROOT,
        text=True,
        errors="replace",
        capture_output=True,
        timeout=timeout,
    )


def execution_timeout_for_unit(unit: ExecutionUnit, default_timeout: int) -> int:
    script = unit.script
    if "podman load " in script or "podman build " in script:
        return max(default_timeout, 1800)
    return default_timeout


@lru_cache(maxsize=8)
def get_ssh_config(vm: str) -> dict[str, str]:
    if os.name != "nt":
        raise RuntimeError("Run verify_scenario_solutions.py with Windows Python from PowerShell.")
    proc = subprocess.run(
        [get_vagrant_executable(), "ssh-config", vm],
        cwd=ROOT,
        text=True,
        errors="replace",
        capture_output=True,
        timeout=60,
        check=True,
    )
    config: dict[str, str] = {}
    for raw_line in proc.stdout.splitlines():
        line = raw_line.strip()
        if not line or line.lower().startswith("host "):
            continue
        if " " not in line:
            continue
        key, value = line.split(None, 1)
        config[key] = value.strip().strip('"')
    required = {"HostName", "User", "Port", "IdentityFile"}
    missing = required - config.keys()
    if missing:
        raise RuntimeError(f"Missing SSH config keys for {vm}: {', '.join(sorted(missing))}")
    return config


@lru_cache(maxsize=8)
def get_secured_identity_file(identity_path: str) -> str:
    source = Path(identity_path)
    if os.name != "nt":
        return str(source)

    suffix = "".join(source.suffixes) or ".key"
    target = Path(tempfile.gettempdir()) / f"codex-vagrant-{source.stem}{suffix}"
    shutil.copyfile(source, target)
    principal = os.environ.get("USERNAME", "")
    subprocess.run(
        [
            "icacls.exe",
            str(target),
            "/inheritance:r",
            "/grant:r",
            f"{principal}:(F)",
        ],
        check=True,
        capture_output=True,
        text=True,
        errors="replace",
        timeout=30,
    )
    return str(target)


def build_ssh_command(vm: str, remote_command: str) -> list[str]:
    ssh_config = get_ssh_config(vm)
    null_known_hosts = "NUL" if os.name == "nt" else "/dev/null"
    identity_file = get_secured_identity_file(ssh_config["IdentityFile"])
    return [
        get_ssh_executable(),
        "-o",
        "BatchMode=yes",
        "-o",
        "PubkeyAuthentication=yes",
        "-o",
        "PreferredAuthentications=publickey",
        "-o",
        "PasswordAuthentication=no",
        "-o",
        "KbdInteractiveAuthentication=no",
        "-o",
        "StrictHostKeyChecking=no",
        "-o",
        "IdentitiesOnly=yes",
        "-o",
        f"UserKnownHostsFile={null_known_hosts}",
        "-o",
        "ConnectTimeout=5",
        "-o",
        "ServerAliveInterval=15",
        "-o",
        "ServerAliveCountMax=8",
        "-o",
        "TCPKeepAlive=yes",
        "-i",
        identity_file,
        "-p",
        ssh_config["Port"],
        f"{ssh_config['User']}@{ssh_config['HostName']}",
        remote_command,
    ]


def wait_for_vm_ssh(vm: str, timeout: int = 120) -> None:
    deadline = time.time() + timeout
    get_ssh_config.cache_clear()
    last_error: str | None = None
    while time.time() < deadline:
        try:
            probe = subprocess.run(
                build_ssh_command(vm, "true"),
                cwd=ROOT,
                text=True,
                errors="replace",
                capture_output=True,
                timeout=15,
            )
            if probe.returncode == 0:
                return
            last_error = (probe.stdout + probe.stderr).strip() or f"ssh probe exited {probe.returncode}"
        except Exception as exc:  # noqa: BLE001
            last_error = str(exc)
        time.sleep(5)
    raise RuntimeError(f"{vm} did not become SSH-ready within {timeout}s: {last_error or 'unknown error'}")


def clear_vagrant_process_locks() -> None:
    if os.name != "nt":
        return
    for image in ("ruby.exe", "vagrant.exe"):
        subprocess.run(
            ["cmd.exe", "/c", "taskkill", "/f", "/im", image],
            cwd=ROOT,
            text=True,
            errors="replace",
            capture_output=True,
            timeout=30,
        )
    time.sleep(5)


def rebuild_baseline(output: str, timeout_seconds: int) -> tuple[bool, str]:
    try:
        destroy_proc = run_ps("destroy", timeout_seconds=timeout_seconds)
        output += destroy_proc.stdout + destroy_proc.stderr
        if destroy_proc.returncode != 0:
            return False, output
        up_proc = run_ps("up", timeout_seconds=timeout_seconds)
        output += up_proc.stdout + up_proc.stderr
        if up_proc.returncode != 0:
            return False, output
    except subprocess.TimeoutExpired:
        output += f"Timed out rebuilding the baseline after {timeout_seconds}s.\n"
        return False, output
    return True, output


def run_exam_checks(manifest: dict, timeout: int) -> tuple[int, int, list[str]]:
    checks = manifest["content"]["exam"].get("checks", [])
    passed = 0
    failures: list[str] = []
    for index, command in enumerate(checks, start=1):
        print(f"  exam check {index}/{len(checks)}", flush=True)
        check_ok = True
        for clause_index, clause in enumerate(split_top_level_and_clauses(command), start=1):
            target_vm, effective_command = resolve_exam_check_clause(clause)
            proc = run_remote_script(target_vm, "root", f"set -euo pipefail\n{effective_command}", timeout)
            if proc.returncode != 0:
                failures.append(
                    (
                        f"check {index} clause {clause_index} [{target_vm}]: {clause}\n"
                        f"{proc.stdout}{proc.stderr}"
                    ).strip()
                )
                check_ok = False
                break
        if check_ok:
            passed += 1
    return passed, len(checks), failures


def start_or_reset_scenario(scenario_id: str, mode: str, track: str, start_timeout: int) -> tuple[bool, str]:
    attempts = 0
    output = ""
    transient_markers = (
        "Failed to confirm SSH banner readiness",
        "timeout during server version negotiating",
        "transient SSH/provider failure",
    )
    lock_markers = (
        "another process is already executing an action on the machine",
        "Vagrant locks each machine for access by only one process at a time",
        "has tried to lock the machine",
        "Failed to assign the machine to the session",
        "Failed to read SSH config",
        "The object is not ready",
        "E_ACCESSDENIED",
        "VBOX_E_VM_ERROR",
        "VBOX_E_FILE_ERROR",
    )
    reset_retry_markers = (
        "VBOX_E_INVALID_VM_STATE",
        "machine state: Running",
        "machine state: Starting",
        "Failed to restore snapshot 'base-clean'",
    )

    clear_vagrant_process_locks()

    while attempts < 3:
        attempts += 1
        try:
            start_proc = run_ps("start", "-Id", scenario_id, "-Mode", mode, "-Track", track, timeout_seconds=start_timeout)
        except subprocess.TimeoutExpired:
            output += f"Timed out starting {scenario_id} after {start_timeout}s.\n"
            if attempts < 3:
                clear_vagrant_process_locks()
                rebuilt, output = rebuild_baseline(output, start_timeout)
                if rebuilt:
                    time.sleep(5)
                    continue
            return False, output
        output += start_proc.stdout + start_proc.stderr
        if start_proc.returncode == 0:
            if "Already active:" not in output:
                return True, output
            try:
                destroy_proc = run_ps("destroy", timeout_seconds=start_timeout)
                output += destroy_proc.stdout + destroy_proc.stderr
                if destroy_proc.returncode == 0:
                    up_proc = run_ps("up", timeout_seconds=start_timeout)
                    output += up_proc.stdout + up_proc.stderr
                    if up_proc.returncode == 0:
                        retry_start_proc = run_ps("start", "-Id", scenario_id, "-Mode", mode, "-Track", track, timeout_seconds=start_timeout)
                        output += retry_start_proc.stdout + retry_start_proc.stderr
                        if retry_start_proc.returncode == 0:
                            return True, output
            except subprocess.TimeoutExpired:
                output += f"Timed out recovering active {scenario_id}; rebuilding baseline.\n"
                destroy_proc = run_ps("destroy", timeout_seconds=start_timeout)
                output += destroy_proc.stdout + destroy_proc.stderr
                if destroy_proc.returncode == 0:
                    up_proc = run_ps("up", timeout_seconds=start_timeout)
                    output += up_proc.stdout + up_proc.stderr
                    if up_proc.returncode == 0:
                        retry_start_proc = run_ps("start", "-Id", scenario_id, "-Mode", mode, "-Track", track, timeout_seconds=start_timeout)
                        output += retry_start_proc.stdout + retry_start_proc.stderr
                        if retry_start_proc.returncode == 0:
                            return True, output
            if any(marker in output for marker in transient_markers) and attempts < 3:
                time.sleep(5)
                continue
            return False, output

        if any(marker in output for marker in lock_markers + reset_retry_markers) and attempts < 3:
            clear_vagrant_process_locks()
            rebuilt, output = rebuild_baseline(output, start_timeout)
            if rebuilt:
                time.sleep(5)
                continue
        if any(marker in output for marker in transient_markers) and attempts < 3:
            time.sleep(5)
            continue
        return False, output

    return False, output


def wait_for_started_scenario(manifest: dict) -> None:
    if manifest["flags"].get("requires_server", False):
        wait_for_vm_ssh("server", timeout=180)
    wait_for_vm_ssh("client", timeout=180)

    delay = 2
    objective_tags = set(manifest.get("objective_tags", []))
    if "containers" in objective_tags:
        delay = 15
    elif manifest["flags"].get("requires_server", False):
        delay = 5

    if delay > 0:
        time.sleep(delay)


def apply_task_sequence(
    manifest: dict,
    kind: str,
    start_index: int,
    end_index: int,
    exec_timeout: int,
    *,
    initial_vm: str | None = None,
    initial_user: str = "root",
) -> tuple[bool, str | None, str | None, str]:
    current_vm = initial_vm
    current_user = initial_user

    for index in range(start_index, end_index + 1):
        plan = translate_task(manifest, kind, index, initial_vm=current_vm, initial_user=current_user)
        if not plan.supported:
            return False, f"Task {index + 1} unsupported: {plan.reason}", current_vm, current_user

        for unit in plan.units:
            unit_timeout = execution_timeout_for_unit(unit, exec_timeout)
            try:
                proc = execute_special_unit(unit, unit_timeout)
                if proc is None:
                    proc = run_remote_script(unit.vm, unit.user, unit.script, unit_timeout)
            except subprocess.TimeoutExpired:
                return (
                    False,
                    f"Task {index + 1} timed out on {unit.vm} as {unit.user} after {unit_timeout}s.",
                    current_vm,
                    current_user,
                )
            if proc.returncode != 0:
                return (
                    False,
                    f"Task {index + 1} failed on {unit.vm} as {unit.user}:\n{proc.stdout}{proc.stderr}".strip(),
                    current_vm,
                    current_user,
                )
            if unit.requires_ssh_recovery or script_requires_ssh_recovery(unit.script):
                time.sleep(2)
                try:
                    wait_for_vm_ssh(unit.vm, timeout=180)
                except Exception as exc:  # noqa: BLE001
                    return (
                        False,
                        f"Task {index + 1} failed waiting for {unit.vm} SSH recovery: {exc}",
                        current_vm,
                        current_user,
                    )
                time.sleep(2)

        current_vm = plan.final_vm
        current_user = plan.final_user or "root"

    return True, None, current_vm, current_user


def verify_lab(scenario_id: str, manifest: dict, track: str, exec_timeout: int, start_timeout: int) -> tuple[bool, list[str]]:
    messages: list[str] = []
    if manifest.get("flags", {}).get("password_recovery", False):
        return True, ["console-only password recovery workflow is skipped in SSH replay mode"]
    started, start_output = start_or_reset_scenario(scenario_id, "Lab", track, start_timeout)
    if not started:
        return False, [start_output]
    try:
        wait_for_started_scenario(manifest)
    except Exception as exc:  # noqa: BLE001
        return False, [str(exc)]

    previous_passed = 0
    task_count = len(manifest["content"]["lab"]["tasks"])
    check_count = len(manifest["content"]["lab"].get("checks", []))
    current_vm: str | None = None
    current_user = "root"

    for index in range(task_count):
        print(f"  lab task {index + 1}/{task_count}", flush=True)
        applied, error_message, current_vm, current_user = apply_task_sequence(
            manifest,
            "lab",
            index,
            index,
            exec_timeout,
            initial_vm=current_vm,
            initial_user=current_user,
        )
        if not applied:
            return False, [error_message or f"Task {index + 1} failed."]

        check_proc = run_ps("check", timeout_seconds=exec_timeout)
        check_output = check_proc.stdout + check_proc.stderr
        if "No active lab run found." in check_output:
            restarted, restart_output = start_or_reset_scenario(scenario_id, "Lab", track, start_timeout)
            if not restarted:
                return False, [restart_output, check_output]
            try:
                wait_for_started_scenario(manifest)
            except Exception as exc:  # noqa: BLE001
                return False, [restart_output, str(exc)]
            replayed, replay_error, current_vm, current_user = apply_task_sequence(
                manifest,
                "lab",
                0,
                index,
                exec_timeout,
                initial_vm=None,
                initial_user="root",
            )
            if not replayed:
                return False, [restart_output, replay_error or f"Failed replaying tasks through {index + 1}."]
            check_proc = run_ps("check", timeout_seconds=exec_timeout)
            check_output = restart_output + check_proc.stdout + check_proc.stderr
        if check_proc.returncode not in (0, 1):
            return False, [check_output]
        status, passed, total = parse_check_output(check_output)
        messages.append(f"task {index + 1}: {passed}/{total}")
        if passed < previous_passed:
            return False, [f"Task {index + 1} regressed the score: {passed} < {previous_passed}", check_output]
        if task_count == check_count and passed < index + 1:
            return False, [f"Task {index + 1} did not unlock the expected next check ({passed}/{total})", check_output]
        previous_passed = passed
        if index == task_count - 1 and status != "complete":
            return False, [f"Final lab state is {status} ({passed}/{total})", check_output]

    return True, messages


def verify_exam(scenario_id: str, manifest: dict, track: str, exec_timeout: int, start_timeout: int) -> tuple[bool, list[str]]:
    messages: list[str] = []
    started, start_output = start_or_reset_scenario(scenario_id, "Exam", track, start_timeout)
    if not started:
        return False, [start_output]
    try:
        wait_for_started_scenario(manifest)
    except Exception as exc:  # noqa: BLE001
        return False, [str(exc)]

    task_count = len(manifest["content"]["exam"]["tasks"])
    current_vm: str | None = None
    current_user = "root"
    for index in range(task_count):
        print(f"  exam task {index + 1}/{task_count}", flush=True)
        applied, error_message, current_vm, current_user = apply_task_sequence(
            manifest,
            "exam",
            index,
            index,
            exec_timeout,
            initial_vm=current_vm,
            initial_user=current_user,
        )
        if not applied:
            return False, [error_message or f"Task {index + 1} failed."]

    passed, total, failures = run_exam_checks(manifest, exec_timeout)
    messages.append(f"exam checks: {passed}/{total}")
    if passed != total:
        return False, messages + failures
    return True, messages


def audit_scenario(kind: str, scenario_id: str, manifest: dict) -> tuple[bool, list[str]]:
    content = manifest["content"][kind]
    failures: list[str] = []
    for index in range(len(content["tasks"])):
        plan = translate_task(manifest, kind, index)
        if not plan.supported:
            failures.append(f"task {index + 1}: {plan.reason}")
    return (len(failures) == 0), failures


def select_ids_for_kind(kind: str, args: argparse.Namespace) -> list[str]:
    ids = scenario_ids(kind, args.track)

    only = args.only
    start_from = args.start_from
    end_at = args.end_at

    if args.kind == "all":
        if only:
            resolved_only: list[str] = []
            for token in only:
                try:
                    resolved_only.append(resolve_scenario_token(ids, token))
                except SystemExit:
                    continue
            only = resolved_only or None

        if start_from:
            try:
                start_from = resolve_scenario_token(ids, start_from)
            except SystemExit:
                start_from = None

        if end_at:
            try:
                end_at = resolve_scenario_token(ids, end_at)
            except SystemExit:
                end_at = None

    return filter_ids(ids, start_from, end_at, only)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Replay authored scenario solutions and verify progressive lab checks or final exam checks."
    )
    parser.add_argument("--kind", choices=("lab", "exam", "all"), default="lab")
    parser.add_argument("--from", dest="start_from")
    parser.add_argument("--to", dest="end_at")
    parser.add_argument("--only", nargs="+")
    parser.add_argument("--ensure-up", action="store_true")
    parser.add_argument("--start-timeout", type=int, default=1200)
    parser.add_argument("--exec-timeout", type=int, default=1200)
    parser.add_argument("--track", default="rhcsa9", help="Scenario track to verify: rhcsa9, rhcsa10, or all.")
    parser.add_argument("--audit-only", action="store_true", help="Only audit whether tasks are auto-replayable; do not start scenarios.")
    args = parser.parse_args()
    args.track = normalize_track(args.track)

    if args.ensure_up:
        baseline_status = get_baseline_status()
        if baseline_status != "ready":
            up_proc = run_ps("up", timeout_seconds=args.start_timeout)
            sys.stdout.write(up_proc.stdout)
            sys.stderr.write(up_proc.stderr)
            if up_proc.returncode != 0:
                return up_proc.returncode
    elif not args.audit_only and get_baseline_status() not in {"ready", "available"}:
        print("Baseline is not ready. Run '.\\RHCSA.ps1 up' first or use '--ensure-up'.", file=sys.stderr)
        return 1

    failures: list[str] = []

    kinds = ("lab", "exam") if args.kind == "all" else (args.kind,)
    for kind in kinds:
        ids = select_ids_for_kind(kind, args)
        if not ids:
            continue
        print(f"\n== verify {kind}s ==")
        for index, scenario_id in enumerate(ids, start=1):
            print(f"[{index}/{len(ids)}] {scenario_id}")
            manifest = load_manifest(kind, resolve_scenario_token(scenario_ids(kind, args.track), scenario_id))
            if args.audit_only:
                ok, messages = audit_scenario(kind, scenario_id, manifest)
            elif kind == "lab":
                ok, messages = verify_lab(scenario_id, manifest, args.track, args.exec_timeout, args.start_timeout)
            else:
                ok, messages = verify_exam(scenario_id, manifest, args.track, args.exec_timeout, args.start_timeout)
            if ok:
                print("  ok")
                for message in messages:
                    print(f"    {message}")
            else:
                print("  fail")
                failures.append(f"[{kind}] {scenario_id}")
                for message in messages:
                    if message.strip():
                        print(f"    {message}")

    if failures:
        print("\nFailures:")
        for item in failures:
            print(f"- {item}")
        return 1

    if args.audit_only:
        print("\nAll audited scenarios are auto-replayable.")
    else:
        print("\nAll replayed scenarios passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
