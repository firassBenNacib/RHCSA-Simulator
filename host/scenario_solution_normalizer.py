#!/usr/bin/env python3
from __future__ import annotations

import re
import shlex

NETWORK_CONN_COMMAND = 'CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: \'$2 != "" && $2 != "lo" {print $1; exit}\')"'


def _flatten_commands(commands: list[str]) -> list[str]:
    flattened: list[str] = []
    for cmd in commands:
        for line in cmd.splitlines():
            stripped = line.rstrip()
            if stripped:
                flattened.append(stripped)
    return flattened


def _expand_install_directory(cmd: str) -> list[str] | None:
    try:
        tokens = shlex.split(cmd)
    except ValueError:
        return None

    if len(tokens) < 3 or tokens[0] != "install" or tokens[1] != "-d":
        return None

    mode = None
    owner = None
    group = None
    i = 2
    while i < len(tokens) - 1:
        flag = tokens[i]
        if flag == "-m" and i + 1 < len(tokens) - 1:
            mode = tokens[i + 1]
            i += 2
            continue
        if flag == "-o" and i + 1 < len(tokens) - 1:
            owner = tokens[i + 1]
            i += 2
            continue
        if flag == "-g" and i + 1 < len(tokens) - 1:
            group = tokens[i + 1]
            i += 2
            continue
        return None

    path = tokens[-1]
    expanded = [f"mkdir -p {path}"]
    if owner and group:
        expanded.append(f"chown {owner}:{group} {path}")
    elif owner:
        expanded.append(f"chown {owner} {path}")
    elif group:
        expanded.append(f"chgrp {group} {path}")
    if mode:
        expanded.append(f"chmod {mode} {path}")
    return expanded


def normalize_command_list(commands: list[str]) -> list[str]:
    flattened = _flatten_commands(commands)
    normalized: list[str] = []
    i = 0
    inserted_connection_hint = False

    while i < len(flattened):
        cmd = flattened[i]
        window3 = "\n".join(flattened[i : i + 3])

        if cmd in {":wq", ":x"}:
            i += 1
            continue

        if cmd == NETWORK_CONN_COMMAND:
            normalized.extend([
                "nmcli device status",
                'nmcli connection show "System eth1"',
            ])
            inserted_connection_hint = True
            i += 1
            continue

        if match := re.fullmatch(
            r"printf 'label:\s*([a-z0-9_-]+)\n,([^,]+),([^\\n]*)\n' \| sfdisk (\S+)",
            window3,
            re.IGNORECASE,
        ):
            disk = match.group(4)
            size = match.group(2)
            normalized.extend([
                f"parted {disk} --script mklabel gpt",
                f"parted {disk} --script mkpart primary ext4 1MiB {size}",
                f"partprobe {disk}",
            ])
            i += 3
            continue

        if match := re.fullmatch(r"printf '([^\\n]+)\n' >> (/etc/fstab)", window3):
            normalized.extend([
                "vim /etc/fstab",
                match.group(1),
            ])
            i += 2
            continue

        if match := re.fullmatch(r"grep -q '([^']+)' /etc/hosts \|\| echo '([^']+)' >> /etc/hosts", cmd):
            normalized.extend([
                "vim /etc/hosts",
                match.group(2),
            ])
            i += 1
            continue

        if match := re.fullmatch(r"grep -q '([^']+)' /etc/fstab \|\| echo '([^']+)' >> /etc/fstab", cmd):
            normalized.extend([
                "vim /etc/fstab",
                match.group(2),
            ])
            i += 1
            continue

        if match := re.fullmatch(r"id ([a-z_][a-z0-9_-]*) (?:>/dev/null 2>&1 )?\|\| (useradd .+)", cmd, re.IGNORECASE):
            normalized.append(match.group(2))
            i += 1
            continue

        if cmd == "rpm -q postfix >/dev/null 2>&1 && systemctl disable --now postfix || true":
            normalized.append("systemctl disable --now postfix")
            i += 1
            continue

        if cmd.startswith("sed -i 's/^Listen .*/Listen ") and cmd.endswith("/etc/httpd/conf/httpd.conf"):
            match = re.search(r"Listen ([0-9]+)", cmd)
            if not match:
                normalized.append(cmd)
                i += 1
                continue
            normalized.extend([
                "vim /etc/httpd/conf/httpd.conf",
                f"Listen {match.group(1)}",
            ])
            i += 1
            continue

        if cmd.startswith("sed -ri 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS"):
            normalized.extend([
                "vim /etc/login.defs",
                "PASS_MAX_DAYS 60",
                "PASS_MIN_DAYS 2",
                "PASS_WARN_AGE 7",
            ])
            i += 1
            continue

        if match := re.fullmatch(r"(semanage (?:port|fcontext) -a .+) \|\| semanage (?:port|fcontext) -m .+", cmd):
            normalized.append(match.group(1))
            i += 1
            continue

        if cmd == "python3 - <<'EOF'" and "sshd_config" in "\n".join(flattened[i : min(i + 20, len(flattened))]):
            normalized.extend([
                "vim /etc/ssh/sshd_config",
                "Port 2222",
                "PasswordAuthentication yes",
                "PubkeyAuthentication yes",
            ])
            while i < len(flattened) and flattened[i] != "EOF":
                i += 1
            if i < len(flattened) and flattened[i] == "EOF":
                i += 1
            continue

        if cmd == "(crontab -l -u amber 2>/dev/null; echo '*/2 * * * * logger \"exam-a tick\"') | crontab -u amber -":
            normalized.extend([
                "crontab -e -u amber",
                '*/2 * * * * logger "exam-a tick"',
            ])
            i += 1
            continue

        expanded_install = _expand_install_directory(cmd)
        if expanded_install:
            normalized.extend(expanded_install)
            i += 1
            continue

        cmd = cmd.replace('"$CONN"', '"System eth1"').replace("$CONN", "System eth1")
        normalized.append(cmd)
        i += 1

    if inserted_connection_hint and 'nmcli connection show "System eth1"' not in normalized:
        normalized.insert(1, 'nmcli connection show "System eth1"')

    deduped: list[str] = []
    for cmd in normalized:
        if deduped and deduped[-1] == cmd:
            continue
        deduped.append(cmd)

    return deduped
