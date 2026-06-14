#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

from scenario_solution_normalizer import normalize_command_list
from rhcsa_scenarios.targets import (
    infer_check_target,
    infer_solution_target,
    infer_task_target,
    normalize_authored_wording,
    normalize_title_capitalization,
    prefix_task_target,
)

ROOT = Path(__file__).resolve().parents[2]
EXAMS_DIR = ROOT / "scenarios" / "exams"
POINTS = [5] * 12 + [4] * 10
NO_PROMPT_SSH_OPTS = "-o BatchMode=yes -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
JOURNALD_PERSISTENT_CHECK = (
    "files=\"\"; "
    "test -d /var/log/journal && "
    "systemctl is-active systemd-journald | grep -qx active && "
    "files=$(find /etc/systemd -maxdepth 2 \\( -path /etc/systemd/journald.conf -o -path '/etc/systemd/journald.conf.d/*.conf' \\) -type f 2>/dev/null); "
    "test -n \"$files\" && "
    "awk '"
    "FNR == 1 {in_journal=0} "
    "/^[[:space:]]*\\[Journal\\][[:space:]]*($|#)/ {in_journal=1; next} "
    "/^[[:space:]]*\\[/ {in_journal=0} "
    "in_journal && /^[[:space:]]*Storage[[:space:]]*=[[:space:]]*persistent[[:space:]]*($|#)/ {found=1} "
    "END {exit !found}"
    "' $files"
)


def discover_track(exam_id: str) -> str:
    for track in ("rhcsa9", "rhcsa10"):
        candidate = EXAMS_DIR / track / exam_id / "scenario.json"
        if candidate.exists():
            return track
    raise FileNotFoundError(f"Exam '{exam_id}' not found in any track under {EXAMS_DIR}")


def load_exam(exam_id: str) -> dict:
    track = discover_track(exam_id)
    return json.loads((EXAMS_DIR / track / exam_id / "scenario.json").read_text())


def save_exam(exam_id: str, data: dict) -> None:
    track = discover_track(exam_id)
    (EXAMS_DIR / track / exam_id / "scenario.json").write_text(json.dumps(data, indent=2) + "\n")


def block(title: str, task: str, commands: list[str]) -> tuple[str, str, list[str]]:
    return (title, task.strip(), commands)


def split_top_level_and_clauses(command: str) -> list[str]:
    clauses: list[str] = []
    buffer: list[str] = []
    in_single = False
    in_double = False
    escaped = False
    index = 0
    while index < len(command):
        char = command[index]
        if escaped:
            buffer.append(char)
            escaped = False
            index += 1
            continue
        if char == "\\" and not in_single:
            buffer.append(char)
            escaped = True
            index += 1
            continue
        if char == "'" and not in_double:
            in_single = not in_single
            buffer.append(char)
            index += 1
            continue
        if char == '"' and not in_single:
            in_double = not in_double
            buffer.append(char)
            index += 1
            continue
        if not in_single and not in_double and command.startswith("&&", index):
            clause = "".join(buffer).strip()
            if clause:
                clauses.append(clause)
            buffer = []
            index += 2
            continue
        buffer.append(char)
        index += 1
    clause = "".join(buffer).strip()
    if clause:
        clauses.append(clause)
    return clauses


def uses_shell_local_state(command: str) -> bool:
    return bool(re.search(r"(^|;\s*)[A-Za-z_][A-Za-z0-9_]*=", command)) or any(
        token in command for token in ("$files", "$rec", "$act", "$uuid")
    )


def split_exam_checks(checks: list[str]) -> list[str]:
    split_checks: list[str] = []
    for check in checks:
        local_state_group: list[str] = []
        for clause in split_top_level_and_clauses(check):
            if local_state_group or uses_shell_local_state(clause):
                local_state_group.append(clause)
                continue
            split_checks.append(clause)
        if local_state_group:
            split_checks.append(" && ".join(local_state_group))
    return split_checks


def rhcsa9_check_target_overrides(exam_id: str, checks: list[str], targets: list[str]) -> list[str]:
    updated = list(targets)
    server_chrony_enabled_check = False
    for index, check in enumerate(checks):
        if re.search(r"^grep -Eq '\^allow 192\\\.168\\\.122\\\.0/24\$' /etc/chrony\.conf$", check):
            updated[index] = "server"
            server_chrony_enabled_check = True
            continue
        if server_chrony_enabled_check and check == "systemctl is-enabled chronyd | grep -qx enabled":
            updated[index] = "server"
            server_chrony_enabled_check = False
            continue
        if (
            "/home/" in check and "/inbox/" in check
            or (exam_id in {"mock-exam-b", "mock-exam-f"} and check.startswith("grep -Eq '^Port 2222$' /etc/ssh/sshd_config"))
            or (exam_id in {"mock-exam-b", "mock-exam-f"} and 'port port="2222" protocol="tcp" accept' in check)
            or (exam_id in {"mock-exam-a", "mock-exam-c", "mock-exam-e"} and "systemd-journald" in check)
            or (exam_id == "mock-exam-d" and any(token in check for token in ("/etc/issue", "/etc/motd", "systemctl get-default", "systemctl is-enabled rsyslog", "systemctl is-enabled postfix")))
        ):
            updated[index] = "server"
            continue
    return updated


def generate_replay_key(user: str) -> list[str]:
    return [
        f"install -d -m 0700 -o {user} -g {user} /home/{user}/.ssh",
        f"test -f /home/{user}/.ssh/id_ed25519 || runuser -u {user} -- ssh-keygen -t ed25519 -N '' -f /home/{user}/.ssh/id_ed25519 -C {user}-exam-replay >/dev/null 2>&1",
        f"chmod 0600 /home/{user}/.ssh/id_ed25519",
        f"chmod 0644 /home/{user}/.ssh/id_ed25519.pub",
    ]


def install_replay_key_with_ssh_copy_id(source_user: str, dest_user: str, *, port: int = 2222) -> list[str]:
    return [
        f"su - {source_user}",
        f"ssh-copy-id -i /home/{source_user}/.ssh/id_ed25519.pub -p {port} {dest_user}@server",
    ]


def ssh_server_check(command: str) -> str:
    escaped = command.replace("'", "'\"'\"'")
    return f"ssh server bash -lc 'set -euo pipefail; {escaped}'"


def repo_commands(label: str) -> list[str]:
    return [
        "cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'",
        "[rhcsa9-exam-baseos]",
        f"name=RHCSA9 {label} BaseOS",
        "baseurl=http://server/repo/BaseOS/",
        "enabled=1",
        "gpgcheck=0",
        "",
        "[rhcsa9-exam-appstream]",
        f"name=RHCSA9 {label} AppStream",
        "baseurl=http://server/repo/AppStream/",
        "enabled=1",
        "gpgcheck=0",
        "EOF",
        "dnf clean all",
    ]


STRICT_RHCSA9_REPO_CHECK = (
    "test -f /etc/yum.repos.d/rhcsa9-exam.repo && "
    "grep -Eq '^baseurl=http://server/repo/BaseOS/?$' /etc/yum.repos.d/rhcsa9-exam.repo && "
    "grep -Eq '^baseurl=http://server/repo/AppStream/?$' /etc/yum.repos.d/rhcsa9-exam.repo && "
    "[ \"$(grep -Ec '^enabled=1$' /etc/yum.repos.d/rhcsa9-exam.repo)\" -ge 2 ] && "
    "[ \"$(grep -Ec '^gpgcheck=0$' /etc/yum.repos.d/rhcsa9-exam.repo)\" -ge 2 ]"
)


def rhcsa9_network_commands(ip: str, hostname: str) -> list[str]:
    return [
        "CONN=\"System eth1\"",
        f"nmcli connection modify \"$CONN\" ipv4.addresses {ip}/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
        f"hostnamectl set-hostname {hostname}",
    ]


def rhcsa9_network_check(ip: str, hostname: str) -> str:
    return (
        f"hostnamectl --static | grep -qx {hostname} && "
        "CONN=\"System eth1\"; "
        f"nmcli -g ipv4.addresses connection show \"$CONN\" | grep -Fqx {ip}/24 && "
        "nmcli -g ipv4.gateway connection show \"$CONN\" | grep -Fqx 192.168.122.1 && "
        "nmcli -g ipv4.dns connection show \"$CONN\" | grep -Fq 192.168.122.3"
    )


def rhcsa9_root_step(letter: str) -> tuple[str, str, list[str]]:
    return block(
        "Root Recovery",
        "On client, recover root access from the console and set the root password to cinder9.",
        [
            "# At the boot menu, edit the selected kernel entry.",
            "# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.",
            "passwd root",
            "# enter: cinder9",
            "touch /.autorelabel",
            "exec /sbin/init",
        ],
    )


def rhcsa9_client_network_step(letter: str, ip: str) -> tuple[str, str, list[str]]:
    hostname = f"client-{letter}.exam9.lab"
    return block(
        "Client IPv4 Networking",
        f"On client, configure persistent IPv4 networking.\n\nIP address: {ip}/24\nGateway: 192.168.122.1\nDNS: 192.168.122.3\nHostname: {hostname}",
        rhcsa9_network_commands(ip, hostname),
    )


def rhcsa9_server_network_step(letter: str) -> tuple[str, str, list[str]]:
    hostname = f"server-{letter}.exam9.lab"
    return block(
        "Server IPv4 Networking",
        f"On server, configure persistent IPv4 networking.\n\nIP address: 192.168.122.3/24\nGateway: 192.168.122.1\nDNS: 192.168.122.3\nHostname: {hostname}",
        ["# On server:", *rhcsa9_network_commands("192.168.122.3", hostname)],
    )


def rhcsa9_client_repo_step(letter: str) -> tuple[str, str, list[str]]:
    return block(
        "Client RPM Repositories",
        "On client, configure enabled BaseOS and AppStream repositories from http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.",
        repo_commands(letter.upper()),
    )


def rhcsa9_server_repo_step(letter: str) -> tuple[str, str, list[str]]:
    return block(
        "Server RPM Repositories",
        "On server, configure enabled BaseOS and AppStream repositories from http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.",
        ["# On server:", *repo_commands(letter.upper())],
    )


def rhcsa9_package_step(letter: str) -> tuple[str, str, list[str]]:
    remove_pkg = "dos2unix" if letter in {"a", "c", "e", "g"} else "tcpdump"
    install_pkg = "tree" if letter in {"a", "d", "g"} else "lsof"
    return block(
        "Client Package Management",
        f"On client, install {install_pkg} from the configured repositories and remove {remove_pkg} if it is installed.",
        [
            f"dnf install -y {install_pkg}",
            f"dnf remove -y {remove_pkg} || true",
        ],
    )


def rhcsa9_users_step(letter: str) -> tuple[str, str, list[str]]:
    group = f"ops{letter}9"
    users = [f"ana{letter}9", f"dev{letter}9", f"audit{letter}9"]
    return block(
        "Client Users and Group",
        f"On client, create group {group}. Create users {users[0]}, {users[1]}, and {users[2]}; {users[2]} must use /sbin/nologin. Set each password to cinder9 and add {users[0]} and {users[1]} to {group}.",
        [
            f"getent group {group} >/dev/null || groupadd {group}",
            f"id {users[0]} >/dev/null 2>&1 || useradd -m {users[0]}",
            f"id {users[1]} >/dev/null 2>&1 || useradd -m {users[1]}",
            f"id {users[2]} >/dev/null 2>&1 || useradd -M -s /sbin/nologin {users[2]}",
            f"usermod -s /sbin/nologin {users[2]}",
            f"printf '{users[0]}:cinder9\\n{users[1]}:cinder9\\n{users[2]}:cinder9\\n' | chpasswd",
            f"gpasswd -a {users[0]} {group}",
            f"gpasswd -a {users[1]} {group}",
        ],
    )


def rhcsa9_password_sudo_step(letter: str) -> tuple[str, str, list[str]]:
    user = f"ana{letter}9"
    group = f"ops{letter}9"
    return block(
        "Client Password Aging and Sudo",
        f"On client, set maximum password age 60 days and warning period 7 days for {user}. Allow members of {group} to run /usr/bin/systemctl with sudo without a password.",
        [
            f"chage -M 60 -W 7 {user}",
            f"echo '%{group} ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/{group}-systemctl",
            f"chmod 0440 /etc/sudoers.d/{group}-systemctl",
            f"bash -c 'visudo -cf /etc/sudoers.d/{group}-systemctl >/dev/null'",
        ],
    )


def rhcsa9_shared_dir_step(letter: str) -> tuple[str, str, list[str]]:
    group = f"ops{letter}9"
    path = f"/srv/{group}"
    return block(
        "Client Shared Directory",
        f"On client, create {path} owned by root:{group} with permissions 2770 and a default ACL granting {group} full access.",
        [
            f"mkdir -p {path}",
            f"chown root:{group} {path}",
            f"chmod 2770 {path}",
            f"setfacl -m d:g:{group}:rwx {path}",
        ],
    )


def rhcsa9_script_step(letter: str) -> tuple[str, str, list[str]]:
    script = f"/usr/local/bin/report-{letter}9"
    output = f"/root/report-{letter}9.txt"
    return block(
        "Client Report Script",
        f"On client, create executable script {script} that writes the active state of sshd, chronyd, and firewalld to {output}.",
        [
            f"cat > {script} <<'SCRIPT'",
            "#!/bin/bash",
            f": > {output}",
            "for service in sshd chronyd firewalld; do",
            f"  systemctl is-active \"$service\" >> {output} || true",
            "done",
            "SCRIPT",
            f"chmod +x {script}",
            script,
        ],
    )


def rhcsa9_swap_step(letter: str) -> tuple[str, str, list[str]]:
    swapfile = f"/swap{letter}9"
    return block(
        "Client Swap Persistence",
        f"On client, create a 512 MiB swap file at {swapfile}, activate it immediately, and make it persistent.",
        [
            f"swapoff {swapfile} >/dev/null 2>&1 || true",
            f"sed -i '\\#{swapfile}#d' /etc/fstab",
            f"rm -f {swapfile}",
            f"dd if=/dev/zero of={swapfile} bs=1M count=512",
            f"chmod 0600 {swapfile}",
            f"mkswap {swapfile}",
            f"echo '{swapfile} swap swap defaults 0 0' >> /etc/fstab",
            f"swapon {swapfile}",
        ],
    )


def rhcsa9_lvm_step(letter: str) -> tuple[str, str, list[str]]:
    vg = f"vg{letter}9"
    lv = f"data{letter}9"
    mountpoint = f"/mnt/{lv}"
    return block(
        "Client LVM Mount",
        f"On client, create volume group {vg} on /dev/sdb, create logical volume {lv} with size 320 MiB, format it as XFS, and mount it persistently at {mountpoint}.",
        [
            f"umount {mountpoint} >/dev/null 2>&1 || true",
            f"sed -i '\\#{mountpoint}#d' /etc/fstab",
            f"lvremove -ff /dev/{vg}/{lv} >/dev/null 2>&1 || true",
            f"vgremove -ff {vg} >/dev/null 2>&1 || true",
            "pvremove -ff -y /dev/sdb1 >/dev/null 2>&1 || true",
            "wipefs -a /dev/sdb1 >/dev/null 2>&1 || true",
            "wipefs -a /dev/sdb >/dev/null 2>&1 || true",
            "parted -s /dev/sdb -- mklabel gpt mkpart primary 1MiB 100%",
            "partprobe /dev/sdb || true",
            "udevadm settle",
            "pvcreate -ff -y /dev/sdb1",
            f"vgcreate {vg} /dev/sdb1",
            f"lvcreate -n {lv} -L 320M {vg}",
            f"mkfs.xfs -f /dev/{vg}/{lv}",
            f"mkdir -p {mountpoint}",
            f"uuid=$(blkid -s UUID -o value /dev/{vg}/{lv})",
            f"echo \"UUID=$uuid {mountpoint} xfs defaults 0 0\" >> /etc/fstab",
            "mount -a",
        ],
    )


def rhcsa9_container_step(letter: str) -> tuple[str, str, list[str]]:
    user = f"pod{letter}9"
    name = f"web{letter}9"
    return block(
        "Client Rootless Container",
        f"On client, create user {user}, enable lingering for that user, and run a rootless container named {name} from localhost/rhcsa-httpd-base:latest.",
        [
            f"id {user} >/dev/null 2>&1 || useradd -m {user}",
            f"echo '{user}:cinder9' | chpasswd",
            f"loginctl enable-linger {user}",
            f"runuser -l {user} -c 'podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true'",
            f"runuser -l {user} -c 'podman rm -f {name} >/dev/null 2>&1 || true'",
            f"runuser -l {user} -c 'podman run -d --name {name} localhost/rhcsa-httpd-base:latest'",
        ],
    )


def rhcsa9_server_user_step(letter: str) -> tuple[str, str, list[str]]:
    group = f"srv{letter}9"
    user = f"svc{letter}9"
    return block(
        "Server User and Sudo",
        f"On server, create group {group}, create user {user} with password cinder9, add {user} to {group}, and allow {group} to run /usr/bin/systemctl with sudo without a password.",
        [
            "# On server:",
            f"getent group {group} >/dev/null || groupadd {group}",
            f"id {user} >/dev/null 2>&1 || useradd -m {user}",
            f"echo '{user}:cinder9' | chpasswd",
            f"gpasswd -a {user} {group}",
            f"echo '%{group} ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/{group}-systemctl",
            f"chmod 0440 /etc/sudoers.d/{group}-systemctl",
            f"bash -c 'visudo -cf /etc/sudoers.d/{group}-systemctl >/dev/null'",
        ],
    )


def rhcsa9_server_http_step(letter: str, port: int) -> tuple[str, str, list[str]]:
    return block(
        "Server Web Service",
        f"On server, publish /var/www/html/exam-{letter}.html containing RHCSA9-{letter.upper()}, configure httpd to listen on TCP port {port}, label the port for httpd, and open it permanently in firewalld.",
        [
            "# On server:",
            "mkdir -p /var/www/html",
            f"echo RHCSA9-{letter.upper()} > /var/www/html/exam-{letter}.html",
            f"restorecon -v /var/www/html/exam-{letter}.html || true",
            f"cat > /etc/httpd/conf.d/exam-{letter}.conf <<'EOF'\nListen {port}\nEOF",
            f"semanage port -a -t http_port_t -p tcp {port} 2>/dev/null || semanage port -m -t http_port_t -p tcp {port}",
            f"firewall-cmd --permanent --add-port={port}/tcp",
            "firewall-cmd --reload",
            "systemctl enable --now httpd",
            "systemctl restart httpd",
        ],
    )


def rhcsa9_server_journal_step(letter: str) -> tuple[str, str, list[str]]:
    return block(
        "Server Persistent Journal",
        "On server, enable persistent systemd journal storage and restart systemd-journald.",
        [
            "# On server:",
            "mkdir -p /var/log/journal /etc/systemd/journald.conf.d",
            "cat > /etc/systemd/journald.conf.d/99-persistent.conf <<'EOF'",
            "[Journal]",
            "Storage=persistent",
            "EOF",
            "systemctl restart systemd-journald",
            "journalctl --flush",
        ],
    )


def rhcsa9_server_timer_step(letter: str, minutes: int) -> tuple[str, str, list[str]]:
    timer = f"audit{letter}9"
    return block(
        "Server Systemd Timer",
        f"On server, create and enable {timer}.timer so it runs every {minutes} minutes and appends server-{letter} to /var/log/{timer}.log.",
        [
            "# On server:",
            f"cat > /usr/local/sbin/{timer}.sh <<'EOF'",
            "#!/bin/bash",
            f"echo server-{letter} >> /var/log/{timer}.log",
            "EOF",
            f"chmod +x /usr/local/sbin/{timer}.sh",
            f"cat > /etc/systemd/system/{timer}.service <<'EOF'",
            "[Unit]",
            f"Description=Server {letter.upper()} audit marker",
            "",
            "[Service]",
            "Type=oneshot",
            f"ExecStart=/usr/local/sbin/{timer}.sh",
            "EOF",
            f"cat > /etc/systemd/system/{timer}.timer <<'EOF'",
            "[Unit]",
            f"Description=Run server {letter.upper()} audit marker",
            "",
            "[Timer]",
            f"OnCalendar=*:0/{minutes}",
            "Persistent=true",
            "",
            "[Install]",
            "WantedBy=timers.target",
            "EOF",
            "systemctl daemon-reload",
            f"systemctl enable --now {timer}.timer",
        ],
    )


def rhcsa9_server_policy_step(letter: str) -> tuple[str, str, list[str]]:
    path = f"/srv/server-{letter}9"
    group = f"srv{letter}9"
    return block(
        "Server Boot Target and Directory",
        f"On server, set the default boot target to multi-user.target and create {path} owned by root:{group} with permissions 2770.",
        [
            "# On server:",
            "systemctl set-default multi-user.target",
            f"getent group {group} >/dev/null || groupadd {group}",
            f"mkdir -p {path}",
            f"chown root:{group} {path}",
            f"chmod 2770 {path}",
        ],
    )


def rhcsa9_both_nfs_step(letter: str) -> tuple[str, str, list[str]]:
    export_path = f"/exports/rhcsa9-{letter}"
    mountpoint = f"/mnt/rhcsa9-{letter}"
    return block(
        "Client Server NFS Mount",
        f"On server, export {export_path} to 192.168.122.0/24. On client, mount server:{export_path} persistently at {mountpoint}.",
        [
            "# On server:",
            f"mkdir -p {export_path}",
            f"echo exam-{letter} > {export_path}/README",
            f"cat > /etc/exports.d/rhcsa9-{letter}.exports <<'EOF'",
            f"{export_path} 192.168.122.0/24(rw,sync,no_root_squash)",
            "EOF",
            "systemctl enable --now nfs-server",
            "firewall-cmd --permanent --add-service=nfs",
            "firewall-cmd --permanent --add-service=mountd",
            "firewall-cmd --permanent --add-service=rpc-bind",
            "firewall-cmd --reload",
            "exportfs -arv",
            "# On client:",
            f"mkdir -p {mountpoint}",
            f"grep -Eq '^server:{export_path}[[:space:]]+{mountpoint}[[:space:]]+nfs' /etc/fstab || echo 'server:{export_path} {mountpoint} nfs defaults,_netdev 0 0' >> /etc/fstab",
            "mount -a",
        ],
    )


def rhcsa9_both_ssh_step(letter: str) -> tuple[str, str, list[str]]:
    user = f"copy{letter}9"
    return block(
        "Client Server SSH Key",
        f"On server, create user {user} with password cinder9. On client, configure key-based SSH login for root to {user}@server.",
        [
            "# On server:",
            f"id {user} >/dev/null 2>&1 || useradd -m {user}",
            f"echo '{user}:cinder9' | chpasswd",
            "# On client:",
            "test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa9-exam >/dev/null 2>&1",
            f"ssh-copy-id -i /root/.ssh/id_ed25519.pub {user}@server",
        ],
    )


def rhcsa9_both_copy_step(letter: str) -> tuple[str, str, list[str]]:
    user = f"copy{letter}9"
    return block(
        "Client Server Secure Copy",
        f"On client, create /root/exam-{letter}-copy.txt containing RHCSA9-{letter.upper()} and copy it to server:/home/{user}/exam-{letter}-copy.txt.",
        [
            f"echo RHCSA9-{letter.upper()} > /root/exam-{letter}-copy.txt",
            f"scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-{letter}-copy.txt {user}@server:/home/{user}/exam-{letter}-copy.txt",
        ],
    )


def rhcsa9_both_chrony_step(letter: str) -> tuple[str, str, list[str]]:
    return block(
        "Client Server Time Sync",
        "On server, enable chronyd for the lab network. On client, configure chronyd to use server as its only time source.",
        [
            "# On server:",
            "systemctl enable --now chronyd",
            "firewall-cmd --permanent --add-service=ntp >/dev/null 2>&1 || true",
            "firewall-cmd --reload >/dev/null 2>&1 || true",
            "# On client:",
            "cat > /etc/chrony.conf <<'EOF'",
            "server server iburst",
            "makestep 1.0 3",
            "EOF",
            "systemctl enable --now chronyd",
        ],
    )


def rhcsa9_balanced_exam(exam_id: str) -> tuple[list[tuple[str, str, list[str]]], list[str], bool] | None:
    if not re.fullmatch(r"mock-exam-[a-h]", exam_id):
        return None
    letter = exam_id.rsplit("-", 1)[1]
    seed = ord(letter) - ord("a")
    client_ip = f"192.168.122.{40 + seed}"
    port = 8300 + seed
    minutes = 5 + seed
    user = f"pod{letter}9"
    container = f"web{letter}9"
    group = f"ops{letter}9"
    server_group = f"srv{letter}9"
    server_user = f"svc{letter}9"
    copy_user = f"copy{letter}9"
    vg = f"vg{letter}9"
    lv = f"data{letter}9"
    timer = f"audit{letter}9"
    export_path = f"/exports/rhcsa9-{letter}"
    mountpoint = f"/mnt/rhcsa9-{letter}"
    server_dir = f"/srv/server-{letter}9"
    script = f"/usr/local/bin/report-{letter}9"
    output = f"/root/report-{letter}9.txt"

    blocks = [
        rhcsa9_root_step(letter),
        rhcsa9_client_network_step(letter, client_ip),
        rhcsa9_client_repo_step(letter),
        rhcsa9_package_step(letter),
        rhcsa9_users_step(letter),
        rhcsa9_password_sudo_step(letter),
        rhcsa9_shared_dir_step(letter),
        rhcsa9_script_step(letter),
        rhcsa9_swap_step(letter),
        rhcsa9_lvm_step(letter),
        rhcsa9_container_step(letter),
        rhcsa9_server_network_step(letter),
        rhcsa9_server_repo_step(letter),
        rhcsa9_server_user_step(letter),
        rhcsa9_server_http_step(letter, port),
        rhcsa9_server_journal_step(letter),
        rhcsa9_server_timer_step(letter, minutes),
        rhcsa9_server_policy_step(letter),
        rhcsa9_both_nfs_step(letter),
        rhcsa9_both_ssh_step(letter),
        rhcsa9_both_copy_step(letter),
        rhcsa9_both_chrony_step(letter),
    ]
    checks = [
        "echo cinder9 | su - root -c 'whoami' 2>/dev/null | grep -qx root",
        rhcsa9_network_check(client_ip, f"client-{letter}.exam9.lab"),
        STRICT_RHCSA9_REPO_CHECK,
        ("rpm -q tree >/dev/null" if letter in {"a", "d", "g"} else "rpm -q lsof >/dev/null"),
        f"getent group {group} >/dev/null && id -nG ana{letter}9 | tr ' ' '\\n' | grep -qx {group} && id -nG dev{letter}9 | tr ' ' '\\n' | grep -qx {group} && getent passwd audit{letter}9 | awk -F: '$7 == \"/sbin/nologin\" {{found=1}} END {{exit !found}}'",
        f"chage -l ana{letter}9 | grep -Eq 'Maximum.*60' && chage -l ana{letter}9 | grep -Eq 'warning.*7' && grep -Eq '^%{group}[[:space:]]+ALL=\\(ALL\\)[[:space:]]+NOPASSWD:[[:space:]]*/usr/bin/systemctl$' /etc/sudoers.d/{group}-systemctl",
        f"stat -c '%U:%G:%a' /srv/{group} | grep -qx root:{group}:2770 && getfacl -p /srv/{group} | grep -Eq '^default:group:{group}:rwx$'",
        f"test -x {script} && {script} >/dev/null && test -s {output}",
        f"swapon --show=NAME --noheadings | grep -qx '/swap{letter}9' && awk '$1 == \"/swap{letter}9\" && $2 == \"swap\" && $3 == \"swap\" {{found=1}} END {{exit !found}}' /etc/fstab",
        f"lvs /dev/{vg}/{lv} >/dev/null 2>&1 && findmnt -no TARGET /mnt/{lv} | grep -qx /mnt/{lv} && awk '$2 == \"/mnt/{lv}\" && $3 == \"xfs\" {{found=1}} END {{exit !found}}' /etc/fstab",
        f"runuser -l {user} -c 'podman ps --format {{{{.Names}}}}' | grep -qx {container} && loginctl show-user {user} | grep -Eq '^Linger=yes$'",
        ssh_server_check(rhcsa9_network_check("192.168.122.3", f"server-{letter}.exam9.lab")),
        ssh_server_check(STRICT_RHCSA9_REPO_CHECK),
        ssh_server_check(f"getent group {server_group} >/dev/null && id -nG {server_user} | tr ' ' '\\n' | grep -qx {server_group} && grep -Eq '^%{server_group}[[:space:]]+ALL=\\(ALL\\)[[:space:]]+NOPASSWD:[[:space:]]*/usr/bin/systemctl$' /etc/sudoers.d/{server_group}-systemctl"),
        ssh_server_check(f"grep -Fxq RHCSA9-{letter.upper()} /var/www/html/exam-{letter}.html && grep -Eq '^Listen[[:space:]]+{port}$' /etc/httpd/conf.d/exam-{letter}.conf && semanage port -l | awk '$1 == \"http_port_t\" && $2 == \"tcp\" && $0 ~ /(^|[ ,]){port}([, ]|$)/ {{found=1}} END {{exit !found}}' && firewall-cmd --permanent --query-port={port}/tcp && systemctl is-enabled httpd | grep -qx enabled && systemctl is-active httpd | grep -qx active"),
        ssh_server_check(JOURNALD_PERSISTENT_CHECK),
        ssh_server_check(f"systemctl is-enabled {timer}.timer | grep -qx enabled && grep -Eq '^OnCalendar=\\*:0/{minutes}$' /etc/systemd/system/{timer}.timer && grep -Fxq 'echo server-{letter} >> /var/log/{timer}.log' /usr/local/sbin/{timer}.sh"),
        ssh_server_check(f"systemctl get-default | grep -qx multi-user.target && stat -c '%U:%G:%a' {server_dir} | grep -qx root:{server_group}:2770"),
        f"findmnt -no SOURCE,TARGET {mountpoint} | grep -qx 'server:{export_path} {mountpoint}' && grep -Eq '^server:{export_path}[[:space:]]+{mountpoint}[[:space:]]+nfs([[:space:]]|$)' /etc/fstab && {ssh_server_check(f'grep -Eq \"^{export_path}[[:space:]]+192\\\\.168\\\\.122\\\\.0/24\" /etc/exports.d/rhcsa9-{letter}.exports && systemctl is-active nfs-server | grep -qx active')}",
        f"runuser -l root -c 'ssh -o BatchMode=yes -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null {copy_user}@server true'",
        ssh_server_check(f"grep -Fxq RHCSA9-{letter.upper()} /home/{copy_user}/exam-{letter}-copy.txt"),
        f"grep -Eq '^server[[:space:]]+server[[:space:]]+iburst$' /etc/chrony.conf && systemctl is-enabled chronyd | grep -qx enabled && {ssh_server_check('systemctl is-enabled chronyd | grep -qx enabled && systemctl is-active chronyd | grep -qx active')}",
    ]
    return blocks, checks, True


def apply_blocks(exam_id: str, *, title: str, description: str, objective_tags: list[str], password_recovery: bool, blocks: list[tuple[str, str, list[str]]], checks: list[str]) -> None:
    track = discover_track(exam_id)
    if track == "rhcsa9":
        balanced = rhcsa9_balanced_exam(exam_id)
        if balanced is not None:
            blocks, checks, password_recovery = balanced
            description = "A 22-task RHCSA9 mock exam covering persistent networking, repositories, users, services, storage, NFS, SSH, and rootless containers across client and server."
            objective_tags = ["boot-and-recovery", "networking-and-firewall", "software-management", "users-sudo-ssh", "storage-lvm", "containers"]
    data = load_exam(exam_id)
    exam = data["content"]["exam"]
    data["title"] = title
    data["description"] = normalize_authored_wording(description).replace("A 22 task", "A 22-task")
    data["objective_tags"] = objective_tags
    data["flags"]["password_recovery"] = password_recovery
    command_groups = [normalize_command_list(item[2]) for item in blocks]
    task_targets = [infer_task_target(item[1], command_groups[index]) for index, item in enumerate(blocks)]
    exam["task_titles"] = [normalize_title_capitalization(item[0]) for item in blocks]
    exam["tasks"] = [
        prefix_task_target(item[1], task_targets[index])
        for index, item in enumerate(blocks)
    ]
    exam["solution_commands"] = command_groups
    exam["task_points"] = POINTS
    exam["checks"] = [
        normalize_authored_wording(check)
        for check in split_exam_checks(checks)
    ]
    exam["task_targets"] = task_targets
    exam["solution_targets"] = [
        infer_solution_target(command_groups[index], task_targets[index])
        for index in range(len(command_groups))
    ]
    check_targets = [
        infer_check_target(check, requires_server=bool(data.get("flags", {}).get("requires_server", False)))
        for check in exam["checks"]
    ]
    if track == "rhcsa9":
        check_targets = rhcsa9_check_target_overrides(exam_id, exam["checks"], check_targets)
    exam["check_targets"] = check_targets
    exam["target_balance"] = {
        "client_only": task_targets.count("client"),
        "server_only": task_targets.count("server"),
        "client_server": task_targets.count("both"),
    }
    save_exam(exam_id, data)


def main() -> int:
    apply_blocks(
        "mock-exam-a",
        title="Mock Exam A",
        description="A 22 task RHCSA practice mock exam focused on recovery, repositories, Apache, sudo delegation, storage, and rootless containers.",
        objective_tags=["boot-and-recovery", "networking-and-firewall", "users-sudo-ssh", "storage-lvm", "containers"],
        password_recovery=True,
        blocks=[
            block("Root Recovery", "Recover root access on client from the console.\n\nSet the root password to: cinder9", [
                "# At the boot menu, edit the selected kernel entry.",
                "# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.",
                "passwd root",
                "# enter: cinder9",
                "touch /.autorelabel",
                "exec /sbin/init",
            ]),
            block("Client Network", "Configure networking on client with the following settings:\n\nIP ADDRESS: 192.168.122.26\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: client.exam-a.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.26/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname client.exam-a.lab",
            ]),
            block("Bootloader Kernel Argument", "Configure the bootloader on client so every installed kernel boots with the kernel argument audit_backlog_limit=8192.\n\nRequirements:\n- The change must persist across reboots.\n- Do not rely on a one-time GRUB edit.", [
                "grubby --update-kernel=ALL --args=\"audit_backlog_limit=8192\"",
            ]),
            block("Client Repositories", "Configure a repository file on client with the following settings:\n\nBaseOS: http://server/repo/BaseOS/\nAppStream: http://server/repo/AppStream/\ngpgcheck: disabled\nRepositories: enabled", [
                "cat > /etc/yum.repos.d/opsa.repo <<'EOF'",
                "[opsa-baseos]",
                "name=OpsA BaseOS",
                "baseurl=http://server/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[opsa-appstream]",
                "name=OpsA AppStream",
                "baseurl=http://server/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Server Repositories", "Configure the same repository file on server.\n\nBaseOS: http://server/repo/BaseOS/\nAppStream: http://server/repo/AppStream/\ngpgcheck: disabled\nRepositories: enabled", [
                "# Run on server",
                "cat > /etc/yum.repos.d/opsa.repo <<'EOF'",
                "[opsa-baseos]",
                "name=OpsA BaseOS",
                "baseurl=http://server/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[opsa-appstream]",
                "name=OpsA AppStream",
                "baseurl=http://server/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Apache SELinux Port", "Configure Apache on client so it serves the existing site on TCP port 8282.\n\nRequirements:\n- Start the service automatically at boot.\n- Open the port permanently in the firewall.\n- Make the SELinux change required for the new port.\n- Leave the existing document root content in place.", [
                "sed -i 's/^Listen .*/Listen 8282/' /etc/httpd/conf/httpd.conf",
                "systemctl enable --now httpd",
                "firewall-cmd --permanent --add-port=8282/tcp",
                "firewall-cmd --reload",
                "semanage port -a -t http_port_t -p tcp 8282 || semanage port -m -t http_port_t -p tcp 8282",
                "systemctl restart httpd",
            ]),
            block("Users And Group", "Create group sysopsa and ensure users violet and amber have sysopsa as a supplementary group. Create user frost without a home directory and with login shell /sbin/nologin.", [
                "groupadd sysopsa",
                "useradd violet",
                "gpasswd -a violet sysopsa",
                "useradd amber",
                "gpasswd -a amber sysopsa",
                "useradd -M -s /sbin/nologin frost",
            ]),
            block("User Passwords", "Set the password of violet, amber, and frost to cinder9.", [
                "echo cinder9 | passwd --stdin violet",
                "echo cinder9 | passwd --stdin amber",
                "echo cinder9 | passwd --stdin frost",
            ]),
            block("Delegated Sudo", "Allow members of sysopsa to run /usr/sbin/useradd through sudo. Allow violet to run /usr/bin/passwd for other users without a sudo password prompt. Use sudoers drop-ins.", [
                "visudo -f /etc/sudoers.d/sysopsa-useradd",
                "%sysopsa ALL=(root) /usr/sbin/useradd",
                "visudo -f /etc/sudoers.d/violet-passwd",
                "violet ALL=(root) NOPASSWD: /usr/bin/passwd",
            ]),
            block("Setgid Directory", "Create /srv/sysopsa owned by root:sysopsa with mode 2770 so new files inherit the sysopsa group.", [
                "install -d -m 2770 -o root -g sysopsa /srv/sysopsa",
            ]),
            block("Cron Logger", "Configure a cron job for amber that runs every 2 minutes and logs the message \"exam-a tick\".", [
                "(crontab -l -u amber 2>/dev/null; echo '*/2 * * * * logger \"exam-a tick\"') | crontab -u amber -",
            ]),
        block("Host Entry", "Add a persistent hosts entry on client so api.exam-a.lab resolves to 192.168.122.3.", [
            "grep -q 'api.exam-a.lab' /etc/hosts || echo '192.168.122.3 api.exam-a.lab' >> /etc/hosts",
        ]),
        block("Fixed UID User", "Create user ash420 with UID 4420 and set its password to cinder9.", [
            "useradd -u 4420 ash420",
            "echo cinder9 | passwd --stdin ash420",
        ]),
        block("Find And Copy", "Find all files under /opt/exam-a/find that are owned by amber and were modified within the last 24 hours. Copy them to /root/amber-files while preserving the source directory structure.", [
            "mkdir -p /root/amber-files",
            "find /opt/exam-a/find -user amber -mtime -1 -type f -exec cp --parents {} /root/amber-files \\;",
        ]),
        block("Grep Filter", "Extract lines containing delta from /usr/share/dict/words into /root/delta-lines.", [
            "grep delta /usr/share/dict/words > /root/delta-lines",
        ]),
        block("Archive", "Create /root/etc-opsa.tar.bz2 containing /etc.", [
            "tar -cjf /root/etc-opsa.tar.bz2 /etc",
        ]),
        block("Service Report Script", "Create executable script /usr/local/bin/opsa-report that writes the active state of each service listed in /usr/local/share/exam-a/services.lst to /root/opsa-services.txt.", [
            "cat > /usr/local/bin/opsa-report <<'SCRIPT'",
            "#!/bin/bash",
            "> /root/opsa-services.txt",
            "for svc in $(cat /usr/local/share/exam-a/services.lst); do",
            "  systemctl is-active \"$svc\" >> /root/opsa-services.txt",
            "done",
            "SCRIPT",
            "chmod +x /usr/local/bin/opsa-report",
            "/usr/local/bin/opsa-report",
        ]),
        block("Swap Space", "On /dev/sdb, create a 700 MiB swap partition.\n\nRequirements:\n- Enable it immediately.\n- Configure it persistently.", [
            "for dev in /dev/sdb[0-9]*; do [ -e \"$dev\" ] || continue; swapoff \"$dev\" >/dev/null 2>&1 || true; findmnt -nr -S \"$dev\" -o TARGET 2>/dev/null | sort -r | xargs -r umount >/dev/null 2>&1 || true; done",
            "for vg in $(pvs --noheadings -o vg_name /dev/sdb[0-9]* 2>/dev/null | awk 'NF{print $1}' | sort -u); do vgchange -an \"$vg\" >/dev/null 2>&1 || true; done",
            "for dev in /dev/sdb[0-9]*; do [ -e \"$dev\" ] || continue; pvremove -ffy \"$dev\" >/dev/null 2>&1 || true; wipefs -a \"$dev\" >/dev/null 2>&1 || true; done",
            "partx -d /dev/sdb >/dev/null 2>&1 || true",
            "wipefs -a /dev/sdb >/dev/null 2>&1 || true",
            "blockdev --rereadpt /dev/sdb || true",
            "partprobe /dev/sdb || true",
            "udevadm settle",
            "parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 701MiB",
            "partprobe /dev/sdb",
            "mkswap /dev/sdb1",
            "swapon /dev/sdb1",
            "uuid=$(blkid -s UUID -o value /dev/sdb1)",
            "echo \"UUID=$uuid swap swap defaults 0 0\" >> /etc/fstab",
        ]),
        block("Resize Existing LV", "Resize /dev/reviewvga/reviewa so the final size is 320 MiB without losing data.", [
            "lvextend -L 320M /dev/reviewvga/reviewa",
            "resize2fs /dev/reviewvga/reviewa",
        ]),
        block("Rootless Container", "As user oriona, build localhost/opsa-web:latest from /opt/rhcsa/workspaces/exam-a/Containerfile, then run container pdfa with /opt/inc mounted to /data/input and /opt/outa mounted to /data/output.", [
            "su - oriona",
            "cd /opt/rhcsa/workspaces/exam-a",
            "podman build -t localhost/opsa-web:latest .",
            "podman run -d --name pdfa -v /opt/inc:/data/input:Z -v /opt/outa:/data/output:Z localhost/opsa-web:latest",
            "exit",
        ]),
        block("Container Autostart", "Generate and enable a systemd user service for pdfa and enable lingering for oriona.", [
            "su - oriona",
            "mkdir -p ~/.config/systemd/user",
            "cd ~/.config/systemd/user",
            "podman generate systemd --name pdfa --files --new",
            "systemctl --user daemon-reload",
            "systemctl --user enable --now container-pdfa.service",
            "exit",
            "loginctl enable-linger oriona",
        ]),
        block("Persistent Journal", "On server, enable persistent systemd journal storage and restart systemd-journald.", [
            "# Run on server",
            "mkdir -p /var/log/journal",
            "mkdir -p /etc/systemd/journald.conf.d",
            "cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'",
            "[Journal]",
            "Storage=persistent",
            "EOF",
            "systemctl restart systemd-journald",
            "journalctl --flush",
        ]),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'client.exam-a.lab' && grubby --info=ALL | grep -Eq 'args=.*audit_backlog_limit=8192' && grep -Fqx '192.168.122.3 api.exam-a.lab' /etc/hosts",
            "curl -fsS http://localhost:8282 >/dev/null && semanage port -l | grep -Eq '^http_port_t\\b.*\\b8282\\b' && curl -fsS http://server/repo/BaseOS/repodata/repomd.xml >/dev/null && curl -fsS http://server/repo/AppStream/repodata/repomd.xml >/dev/null",
            "getent group sysopsa >/dev/null && id -nG violet | tr ' ' '\\n' | grep -qx sysopsa && id -nG amber | tr ' ' '\\n' | grep -qx sysopsa && getent passwd frost | awk -F: '{print $6\":\"$7}' | grep -qx ':/sbin/nologin' && grep -Eq '^%sysopsa .* /usr/sbin/useradd$' /etc/sudoers.d/sysopsa-useradd && grep -Eq '^violet .*NOPASSWD: /usr/bin/passwd$' /etc/sudoers.d/violet-passwd && stat -c '%U:%G %a' /srv/sysopsa | grep -qx 'root:sysopsa 2770' && crontab -l -u amber | grep -Fqx '*/2 * * * * logger \"exam-a tick\"'",
            "getent passwd ash420 | awk -F: '{print $3}' | grep -qx '4420' && test -f /root/amber-files/opt/exam-a/find/a/file1.txt && grep -qx 'delta' /root/delta-lines && test -f /root/etc-opsa.tar.bz2 && /usr/local/bin/opsa-report >/dev/null && test -s /root/opsa-services.txt",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1==\"reviewa\" && $2==\"reviewvga\" && $3>=319 && $3<=321{f=1} END{exit !f}'",
            f"runuser -l oriona -c 'podman ps --format {{{{.Names}}}}' | grep -qx pdfa && runuser -l oriona -c 'systemctl --user is-enabled container-pdfa.service' | grep -qx enabled && loginctl show-user oriona | grep -Eq '^Linger=yes$' && {JOURNALD_PERSISTENT_CHECK}",
        ],
    )

    apply_blocks(
        "mock-exam-b",
        title="Mock Exam B",
        description="A 22 task RHCSA practice mock exam emphasizing chrony, SSH hardening, user defaults, and storage administration.",
        objective_tags=["networking-and-firewall", "users-sudo-ssh", "processes-logs-tuning", "storage-lvm"],
        password_recovery=False,
        blocks=[
            block("Client Network", "Configure networking on client with the following settings:\n\nIP ADDRESS: 192.168.122.27\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: client.exam-b.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.27/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname client.exam-b.lab",
            ]),
            block("Host Entry", "Add a persistent hosts entry so registry.exam-b.lab resolves to 192.168.122.3.", [
                "grep -q 'registry.exam-b.lab' /etc/hosts || echo '192.168.122.3 registry.exam-b.lab' >> /etc/hosts",
            ]),
            block("Chrony Server", "Configure chronyd on server so it serves time to 192.168.122.0/24 and starts automatically at boot.", [
                "# Run on server",
                "cat > /etc/chrony.conf <<'EOF'",
                "driftfile /var/lib/chrony/drift",
                "makestep 1.0 3",
                "rtcsync",
                "allow 192.168.122.0/24",
                "local stratum 10",
                "EOF",
                "systemctl enable --now chronyd",
            ]),
            block("Chrony Client", "Configure chronyd on client so it synchronizes only with server and starts automatically at boot.", [
                "cat > /etc/chrony.conf <<'EOF'",
                "server server iburst",
                "driftfile /var/lib/chrony/drift",
                "makestep 1.0 3",
                "rtcsync",
                "EOF",
                "systemctl enable --now chronyd",
            ]),
            block("Useradd Defaults", "Set the default inactive period for newly created local users to 20 days.", [
                "useradd -D -f 20",
            ]),
            block("No-Home UID User", "Create user cato421 with UID 4421, no home directory, and password cinder9.", [
                "useradd -M -u 4421 cato421",
                "echo cinder9 | passwd --stdin cato421",
            ]),
        block("Login User With Password Aging", "Create user jonas with a home directory, password cinder9, and password aging of maximum 45 days, minimum 5 days, warning 7 days.", [
            "useradd jonas",
            "echo cinder9 | passwd --stdin jonas",
            "chage -M 45 -m 5 -W 7 jonas",
        ]),
            block("Pwquality Policy", "Configure pwquality so passwords require a minimum length of 12 and at least 3 character classes.", [
                "mkdir -p /etc/security/pwquality.conf.d",
                "cat > /etc/security/pwquality.conf.d/coremesh.conf <<'EOF'",
                "minlen = 12",
                "minclass = 3",
                "EOF",
            ]),
            block("Delegated Sudo", "Allow mira to restart firewalld on client through sudo without a password prompt. Use a sudoers drop-in.", [
                "visudo -f /etc/sudoers.d/mira-firewalld",
                "mira ALL=(root) NOPASSWD: /usr/bin/systemctl restart firewalld",
            ]),
            block("SSH Port", "On server, configure sshd to listen on TCP port 2222 and keep password and public key authentication enabled.", [
                "# Run on server",
                "python3 - <<'EOF'",
                "from pathlib import Path",
                "import re",
                "p = Path('/etc/ssh/sshd_config')",
                "text = p.read_text()",
                "for key, val in [('Port', '2222'), ('PasswordAuthentication', 'yes'), ('PubkeyAuthentication', 'yes')]:",
                "    if re.search(rf'^\\s*{key}\\s+', text, flags=re.M):",
                "        text = re.sub(rf'^\\s*{key}\\s+.*$', f'{key} {val}', text, flags=re.M)",
                "    else:",
                "        text += f'\\n{key} {val}\\n'",
                "p.write_text(text)",
                "EOF",
                "semanage port -l | grep -Eq '^ssh_port_t\\b.*\\b2222\\b' || semanage port -a -t ssh_port_t -p tcp 2222",
                "systemctl restart sshd",
            ]),
            block("Rich Rule", "On server, add a permanent rich firewall rule allowing TCP port 2222 only from 192.168.122.0/24.", [
                "# Run on server",
                "firewall-cmd --permanent --add-rich-rule='rule family=\"ipv4\" source address=\"192.168.122.0/24\" port protocol=\"tcp\" port=\"2222\" accept'",
                "firewall-cmd --reload",
            ]),
        block("SSH Key Generation", "Create user mira with a home directory and password cinder9, then as mira on client, generate an ED25519 SSH key pair with no passphrase.", [
            "id mira >/dev/null 2>&1 || useradd mira",
            "echo cinder9 | passwd --stdin mira",
            *generate_replay_key("mira"),
        ]),
            block("Passwordless SSH", "On server, create user meshremote with password cinder9 if it does not already exist. Then install mira's public key for meshremote and verify passwordless SSH access on port 2222.", [
                "# Run on server",
                "id meshremote >/dev/null 2>&1 || useradd meshremote",
                "echo cinder9 | passwd --stdin meshremote",
                "install -d -m 0755 -o meshremote -g meshremote /home/meshremote/inbox",
                "# Run on client",
                *install_replay_key_with_ssh_copy_id("mira", "meshremote"),
                f"ssh -p 2222 {NO_PROMPT_SSH_OPTS} meshremote@server true",
            ]),
        block("Rsync Transfer", "On client, use rsync over SSH port 2222 to copy /opt/exam-b/report.txt to /home/meshremote/inbox/report.txt on server.", [
            "# Run on client",
            f"runuser -l mira -c 'rsync -e \"ssh -p 2222 {NO_PROMPT_SSH_OPTS}\" /opt/exam-b/report.txt meshremote@server:/home/meshremote/inbox/report.txt'",
        ]),
        block("User Umask", "Set a personal umask of 027 for mira.", [
            "echo 'umask 027' >> /home/mira/.bash_profile",
        ]),
        block("Find And Copy", "Find all files under /opt/exam-b/find that are owned by mira and were modified within the last 24 hours. Copy them to /root/mira-files while preserving the source directory structure.", [
            "mkdir -p /root/mira-files",
            "find /opt/exam-b/find -user mira -mtime -1 -type f -exec cp --parents {} /root/mira-files \\;",
        ]),
        block("Grep Filter", "Extract lines containing proto from /usr/share/dict/words into /root/proto-lines.", [
            "grep proto /usr/share/dict/words > /root/proto-lines",
        ]),
        block("Archive", "Create /root/usr-local-b.tar.bz2 containing /usr/local.", [
            "tar -cjf /root/usr-local-b.tar.bz2 /usr/local",
        ]),
        block("Shell Script", "Create executable script /usr/local/bin/corecheck that writes the active state of each unit listed in /usr/local/share/exam-b/units.lst to /root/coremesh-units.txt.", [
            "cat > /usr/local/bin/corecheck <<'SCRIPT'",
            "#!/bin/bash",
            "> /root/coremesh-units.txt",
            "for unit in $(cat /usr/local/share/exam-b/units.lst); do",
            "  systemctl is-active \"$unit\" >> /root/coremesh-units.txt",
            "done",
            "SCRIPT",
            "chmod +x /usr/local/bin/corecheck",
            "/usr/local/bin/corecheck",
        ]),
        block("Swap Space", "On /dev/sdb, create a 600 MiB swap partition.\n\nRequirements:\n- Enable it immediately.\n- Configure it persistently.", [
            "parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 601MiB",
            "partprobe /dev/sdb",
            "mkswap /dev/sdb1",
            "swapon /dev/sdb1",
            "uuid=$(blkid -s UUID -o value /dev/sdb1)",
            "echo \"UUID=$uuid swap swap defaults 0 0\" >> /etc/fstab",
        ]),
        block("Create And Mount LV", "On /dev/sdc, create a volume group reviewvgb with a physical extent size of 8 MiB and a logical volume reviewb of 50 extents. Format it with ext4 and mount it persistently on /mnt/reviewb.", [
            "parted -s /dev/sdc -- mklabel gpt mkpart primary 1MiB 100% set 1 lvm on",
            "partprobe /dev/sdc",
            "pvcreate /dev/sdc1",
            "vgcreate -s 8M reviewvgb /dev/sdc1",
            "lvcreate -n reviewb -l 50 reviewvgb",
            "mkfs.ext4 /dev/reviewvgb/reviewb",
            "mkdir -p /mnt/reviewb",
            "uuid=$(blkid -s UUID -o value /dev/reviewvgb/reviewb)",
            "echo \"UUID=$uuid /mnt/reviewb ext4 defaults 0 0\" >> /etc/fstab",
            "mount -a",
        ]),
        block("Recommended Tuned Profile", "Apply the recommended tuned profile and leave it active.", [
            "tuned-adm profile \"$(tuned-adm recommend)\"",
        ]),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'client.exam-b.lab' && grep -Fqx '192.168.122.3 registry.exam-b.lab' /etc/hosts",
            "grep -Eq '^server server iburst$' /etc/chrony.conf && systemctl is-enabled chronyd | grep -qx enabled && grep -Eq '^allow 192\\.168\\.122\\.0/24$' /etc/chrony.conf && systemctl is-enabled chronyd | grep -qx enabled",
            "useradd -D | grep -Eq 'INACTIVE=20' && getent passwd cato421 | awk -F: '{print $3\":\"$6}' | grep -qx '4421:' && chage -l jonas | grep -Eq 'Maximum.*45' && grep -Eq '^minlen\\s*=\\s*12$' /etc/security/pwquality.conf.d/coremesh.conf && grep -Eq '^minclass\\s*=\\s*3$' /etc/security/pwquality.conf.d/coremesh.conf && grep -Eq '^mira .*NOPASSWD: /usr/bin/systemctl restart firewalld$' /etc/sudoers.d/mira-firewalld",
            f"grep -Eq '^Port 2222$' /etc/ssh/sshd_config && firewall-cmd --list-rich-rules | grep -Fq 'port port=\"2222\" protocol=\"tcp\" accept' && runuser -l mira -c 'ssh -p 2222 {NO_PROMPT_SSH_OPTS} meshremote@server true' && test -f /home/meshremote/inbox/report.txt",
            "test -f /root/mira-files/opt/exam-b/find/a/file1.txt && grep -q 'proto' /root/proto-lines && test -f /root/usr-local-b.tar.bz2 && /usr/local/bin/corecheck >/dev/null && test -s /root/coremesh-units.txt",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1==\"reviewb\" && $2==\"reviewvgb\" && $3>=299 && $3<=301{f=1} END{exit !f}' && tuned-adm active | grep -Eq 'virtual-guest|throughput-performance'",
        ],
    )

    apply_blocks(
        "mock-exam-c",
        title="Mock Exam C",
        description="A 22 task RHCSA practice mock exam centered on recovery, boot persistence, NFS, ACLs, journald, and rootless containers.",
        objective_tags=["boot-and-recovery", "filesystems-and-autofs", "users-sudo-ssh", "storage-lvm", "containers"],
        password_recovery=True,
        blocks=[
            block("Root Recovery", "Recover root access on client from the console.\n\nSet the root password to: cinder9", [
                "# At the boot menu, edit the selected kernel entry.",
                "# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.",
                "passwd root",
                "# enter: cinder9",
                "touch /.autorelabel",
                "exec /sbin/init",
            ]),
            block("Client Network", "Configure networking on client with the following settings:\n\nIP ADDRESS: 192.168.122.28\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: client.exam-c.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.28/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname client.exam-c.lab",
            ]),
            block("Bootloader Kernel Argument", "Configure the bootloader on client so every installed kernel boots with the kernel argument audit_backlog_limit=8192.", [
                "grubby --update-kernel=ALL --args=\"audit_backlog_limit=8192\"",
            ]),
            block("Host Entry", "Add a persistent hosts entry so vault.exam-c.lab resolves to 192.168.122.3.", [
                "grep -q 'vault.exam-c.lab' /etc/hosts || echo '192.168.122.3 vault.exam-c.lab' >> /etc/hosts",
            ]),
            block("Direct NFS Mount", "Persistently mount server:/exports/bluec on /mnt/bluec using /etc/fstab.", [
                "mkdir -p /mnt/bluec",
                "grep -q '/mnt/bluec' /etc/fstab || echo 'server:/exports/bluec /mnt/bluec nfs defaults,_netdev 0 0' >> /etc/fstab",
                "mount -a",
            ]),
            block("Users And Group", "Create group infrac and users talia and ren with infrac as a supplementary group. Set the password of both users to cinder9.", [
                "groupadd infrac",
                "id talia >/dev/null 2>&1 || useradd -m talia",
                "gpasswd -a talia infrac",
                "id ren >/dev/null 2>&1 || useradd -m ren",
                "gpasswd -a ren infrac",
                "echo cinder9 | passwd --stdin talia",
                "echo cinder9 | passwd --stdin ren",
            ]),
            block("Default ACL Directory", "Create /srv/infrac owned by root:infrac with mode 2770 and a default ACL that grants group infrac rwx on new files and directories.", [
                "install -d -m 2770 -o root -g infrac /srv/infrac",
                "setfacl -d -m g:infrac:rwx /srv/infrac",
            ]),
            block("No-Home User", "Create user remote63 without a home directory and with login shell /sbin/nologin.", [
                "useradd -M -s /sbin/nologin remote63",
            ]),
            block("At Job", "Queue a one-time at job as user ren that appends the message \"exam-c audit\" to /root/exam-c-at.log in 2 minutes.", [
                "echo 'echo \"exam-c audit\" >> /root/exam-c-at.log' | at now + 2 minutes",
                "systemctl enable --now atd",
            ]),
            block("Per-User Password Aging", "Set password aging for talia to maximum 45 days, minimum 5 days, warning 7 days.", [
                "chage -M 45 -m 5 -W 7 talia",
            ]),
            block("Persistent Journal", "On server, enable persistent systemd journal storage and restart systemd-journald.", [
                "# Run on server",
                "mkdir -p /var/log/journal",
                "mkdir -p /etc/systemd/journald.conf.d",
                "cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'",
                "[Journal]",
                "Storage=persistent",
                "EOF",
                "systemctl restart systemd-journald",
                "journalctl --flush",
            ]),
            block("User Umask", "Set a personal umask of 027 for user ren.", [
                "echo 'umask 027' >> /home/ren/.bash_profile",
            ]),
        block("Per-User Login Message", "Append a login message for ren to ~/.bash_profile that prints \"exam-c access\" when ren logs in.", [
            "echo 'echo exam-c access' >> /home/ren/.bash_profile",
        ]),
        block("Fixed UID User", "Create user kian431 with UID 4431 and set its password to cinder9.", [
            "useradd -u 4431 kian431",
            "echo cinder9 | passwd --stdin kian431",
        ]),
        block("Find And Copy", "Find all files under /opt/exam-c/find that are owned by ren and were modified in the last 24 hours, then copy them to /root/ren-files while preserving the directory structure.", [
            "mkdir -p /root/ren-files",
            "find /opt/exam-c/find -type f -user ren -mtime -1 -exec cp --parents {} /root/ren-files \\;",
        ]),
        block("Grep Filter", "Extract lines containing orbit from /usr/share/dict/words into /root/orbit-lines.", [
            "grep orbit /usr/share/dict/words > /root/orbit-lines",
        ]),
        block("Archive", "Create /root/etc-c.tar.bz2 containing /etc.", [
            "tar -cjf /root/etc-c.tar.bz2 /etc",
        ]),
        block("Service Status Script", "Create executable script /usr/local/bin/northcheck that writes the active state of each service listed in /usr/local/share/exam-c/check.lst to /root/north-services.txt.", [
            "cat > /usr/local/bin/northcheck <<'SCRIPT'",
            "#!/usr/bin/env bash",
            "while read -r svc; do",
            "  systemctl is-active \"$svc\" >> /root/north-services.txt",
            "done < /usr/local/share/exam-c/check.lst",
            "SCRIPT",
            "chmod 755 /usr/local/bin/northcheck",
            "/usr/local/bin/northcheck",
        ]),
        block("Swap Space", "On /dev/sdb, create a 700 MiB swap partition.\n\nRequirements:\n- Enable it immediately.\n- Configure it persistently.", [
            "parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 701MiB",
            "partprobe /dev/sdb",
            "mkswap /dev/sdb1",
            "swapon /dev/sdb1",
            "uuid=$(blkid -s UUID -o value /dev/sdb1)",
            "echo \"UUID=$uuid swap swap defaults 0 0\" >> /etc/fstab",
        ]),
        block("Resize Existing LV", "Resize /dev/reviewvgc/reviewc so the final size is 340 MiB without losing data.", [
            "lvextend -L 340M /dev/reviewvgc/reviewc",
            "resize2fs /dev/reviewvgc/reviewc",
        ]),
        block("Rootless Container", "As user eirac, build localhost/northstar-web:latest from /opt/rhcsa/workspaces/exam-c/Containerfile, then run container pdfc with /opt/inc mounted to /data/input and /opt/outc mounted to /data/output.", [
            "su - eirac",
            "cd /opt/rhcsa/workspaces/exam-c",
            "podman build -t localhost/northstar-web:latest .",
            "podman run -d --name pdfc -v /opt/inc:/data/input:Z -v /opt/outc:/data/output:Z localhost/northstar-web:latest",
            "exit",
        ]),
        block("Container Autostart", "Generate and enable a systemd user service for pdfc and enable lingering for eirac.", [
            "su - eirac",
            "mkdir -p ~/.config/systemd/user",
            "cd ~/.config/systemd/user",
            "podman generate systemd --name pdfc --files --new",
            "systemctl --user daemon-reload",
            "systemctl --user enable --now container-pdfc.service",
            "exit",
            "loginctl enable-linger eirac",
        ]),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'client.exam-c.lab' && grep -Fqx '192.168.122.3 vault.exam-c.lab' /etc/hosts && grubby --info=ALL | grep -Eq 'args=.*audit_backlog_limit=8192'",
            "mount | grep -Eq 'server:/exports/bluec on /mnt/bluec type nfs' && grep -q '/mnt/bluec' /etc/fstab && getent group infrac >/dev/null && id -nG talia | tr ' ' '\\n' | grep -qx infrac && id -nG ren | tr ' ' '\\n' | grep -qx infrac && getfacl -p /srv/infrac | grep -Fq 'default:group:infrac:rwx' && getent passwd remote63 | awk -F: '{print $6\":\"$7}' | grep -qx ':/sbin/nologin'",
            f"chage -l talia | grep -Eq 'Maximum.*45' && grep -Fqx 'umask 027' /home/ren/.bash_profile && grep -Fqx 'echo exam-c access' /home/ren/.bash_profile && {JOURNALD_PERSISTENT_CHECK}",
            "getent passwd kian431 | awk -F: '{print $3}' | grep -qx '4431' && test -f /root/ren-files/opt/exam-c/find/a/file1.txt && grep -q 'orbit' /root/orbit-lines && test -f /root/etc-c.tar.bz2 && /usr/local/bin/northcheck >/dev/null && test -s /root/northstar-services.txt",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1==\"reviewc\" && $2==\"reviewvgc\" && $3>=339 && $3<=341{f=1} END{exit !f}'",
            "runuser -l eirac -c 'podman ps --format {{.Names}}' | grep -qx pdfc && runuser -l eirac -c 'systemctl --user is-enabled container-pdfc.service' | grep -qx enabled && loginctl show-user eirac | grep -Eq '^Linger=yes$'",
        ],
    )

    apply_blocks(
        "mock-exam-d",
        title="Mock Exam D",
        description="A 22 task RHCSA practice mock exam focused on repository hygiene, account defaults, server service state, and logical volume provisioning.",
        objective_tags=["networking-and-firewall", "users-sudo-ssh", "software-management", "storage-lvm"],
        password_recovery=False,
        blocks=[
            block("Client Network", "Configure networking on client with the following settings:\n\nIP ADDRESS: 192.168.122.36\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: client.summit.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.36/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname client.summit.lab",
            ]),
            block("Host Entry", "Add a persistent hosts entry so mirror.summit.lab resolves to 192.168.122.3.", [
                "grep -q 'mirror.summit.lab' /etc/hosts || echo '192.168.122.3 mirror.summit.lab' >> /etc/hosts",
            ]),
            block("Client Repositories", "Configure a repository file on client with BaseOS and AppStream served from server, enabled, and with gpgcheck disabled.", [
                "cat > /etc/yum.repos.d/summit.repo <<'EOF'",
                "[summit-baseos]",
                "name=Summit BaseOS",
                "baseurl=http://server/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[summit-appstream]",
                "name=Summit AppStream",
                "baseurl=http://server/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Server Repositories", "Configure the same repository file on server.", [
                "# Run on server",
                "cat > /etc/yum.repos.d/summit.repo <<'EOF'",
                "[summit-baseos]",
                "name=Summit BaseOS",
                "baseurl=http://server/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[summit-appstream]",
                "name=Summit AppStream",
                "baseurl=http://server/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Useradd Defaults", "Set the default inactive period for newly created local users to 14 days.", [
                "useradd -D -f 14",
            ]),
            block("No-Home User", "Create user trainee54 without a home directory and set its password to cinder9.", [
                "useradd -M trainee54",
                "echo cinder9 | passwd --stdin trainee54",
            ]),
            block("Admin User", "Create user kara with a home directory and set its password to cinder9.", [
                "useradd kara",
                "echo cinder9 | passwd --stdin kara",
            ]),
            block("Delegated Sudo", "Allow kara to run /usr/bin/systemctl restart rsyslog and /usr/bin/systemctl status sshd through sudo. Use a sudoers drop-in.", [
                "visudo -f /etc/sudoers.d/kara-systemctl",
                "kara ALL=(root) NOPASSWD: /usr/bin/systemctl restart rsyslog, /usr/bin/systemctl status sshd",
            ]),
            block("Server Login Messages", "On server, configure both /etc/issue and /etc/motd to contain the line Summit maintenance host.", [
                "# Run on server",
                "echo 'Summit maintenance host' > /etc/issue",
                "echo 'Summit maintenance host' > /etc/motd",
            ]),
            block("Server Default Target", "On server, set the default target to multi-user.target, ensure rsyslog is enabled, and ensure postfix is disabled.", [
                "# Run on server",
                "systemctl set-default multi-user.target",
                "systemctl enable --now rsyslog",
                "systemctl disable --now postfix",
            ]),
            block("Package Management", "On server, install tree and remove dos2unix.", [
                "# Run on server",
                "dnf install -y tree",
                "dnf remove -y dos2unix",
            ]),
            block("Password Aging Defaults", "Set password aging defaults so newly created users have maximum 60 days, minimum 2 days, and warning 7 days.", [
                "sed -ri 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS\t60/; s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS\t2/; s/^PASS_WARN_AGE.*/PASS_WARN_AGE\t7/' /etc/login.defs",
            ]),
            block("Forced Password Change", "Create user miles with a home directory, set its password to cinder9, and force a password change on first login.", [
                "useradd miles",
                "echo cinder9 | passwd --stdin miles",
                "chage -d 0 miles",
            ]),
            block("Fixed UID User", "Create user cedar540 with UID 4540 and set its password to cinder9.", [
                "useradd -u 4540 cedar540",
                "echo cinder9 | passwd --stdin cedar540",
            ]),
            block("User Umask", "Set a personal umask of 027 for miles.", [
                "echo 'umask 027' >> /home/miles/.bash_profile",
            ]),
        block("Audit Directory", "Create /srv/summit-audit on client with mode 0750 and ownership root:root.", [
            "install -d -m 0750 -o root -g root /srv/summit-audit",
        ]),
        block("Find And Copy", "Find all files under /opt/exam-d/find that are owned by foragerd and were modified within the last 24 hours. Copy them to /root/foragerd-files while preserving the source directory structure.", [
            "mkdir -p /root/foragerd-files",
            "find /opt/exam-d/find -user foragerd -mtime -1 -type f -exec cp --parents {} /root/foragerd-files \\;",
        ]),
        block("Grep Filter", "Extract lines containing alpha from /usr/share/dict/words into /root/alpha-lines.", [
            "grep alpha /usr/share/dict/words > /root/alpha-lines",
        ]),
        block("Archive", "Create /root/summit-etc.tar.gz containing /etc.", [
            "tar -czf /root/summit-etc.tar.gz /etc",
        ]),
        block("Shell Script", "Create executable script /usr/local/bin/summit-scan that writes the active state of each unit listed in /usr/local/share/exam-d/units.lst to /root/summit-units.txt.", [
            "cat > /usr/local/bin/summit-scan <<'SCRIPT'",
            "#!/bin/bash",
            "> /root/summit-units.txt",
            "for unit in $(cat /usr/local/share/exam-d/units.lst); do",
            "  systemctl is-active \"$unit\" >> /root/summit-units.txt",
            "done",
            "SCRIPT",
            "chmod +x /usr/local/bin/summit-scan",
            "/usr/local/bin/summit-scan",
        ]),
        block("Swap Space", "On /dev/sdb, create a 512 MiB swap partition.\n\nRequirements:\n- Enable it immediately.\n- Configure it persistently.", [
            "parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 513MiB",
            "partprobe /dev/sdb",
            "mkswap /dev/sdb1",
            "swapon /dev/sdb1",
            "uuid=$(blkid -s UUID -o value /dev/sdb1)",
            "echo \"UUID=$uuid swap swap defaults 0 0\" >> /etc/fstab",
        ]),
        block("Create And Mount LV", "On /dev/sdc, create a volume group summitvg with a physical extent size of 16 MiB and a logical volume summitlv of 16 extents. Format it with xfs and mount it persistently on /mnt/summitlv.", [
            "parted -s /dev/sdc -- mklabel gpt mkpart primary 1MiB 100% set 1 lvm on",
            "partprobe /dev/sdc",
            "pvcreate /dev/sdc1",
            "vgcreate -s 16M summitvg /dev/sdc1",
            "lvcreate -n summitlv -l 16 summitvg",
            "mkfs.xfs -f /dev/summitvg/summitlv",
            "mkdir -p /mnt/summitlv",
            "uuid=$(blkid -s UUID -o value /dev/summitvg/summitlv)",
            "echo \"UUID=$uuid /mnt/summitlv xfs defaults 0 0\" >> /etc/fstab",
            "mount -a",
        ]),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'client.summit.lab' && grep -Fqx '192.168.122.3 mirror.summit.lab' /etc/hosts && curl -fsS http://server/repo/BaseOS/repodata/repomd.xml >/dev/null && curl -fsS http://server/repo/AppStream/repodata/repomd.xml >/dev/null",
            "useradd -D | grep -Eq 'INACTIVE=14' && getent passwd trainee54 | awk -F: '{print $6}' | grep -qx '' && getent passwd cedar540 | awk -F: '{print $3}' | grep -qx '4540' && grep -Eq '^kara .*NOPASSWD: /usr/bin/systemctl restart rsyslog, /usr/bin/systemctl status sshd$' /etc/sudoers.d/kara-systemctl && grep -Eq '^PASS_MAX_DAYS\\s+60$' /etc/login.defs && grep -Eq '^PASS_MIN_DAYS\\s+2$' /etc/login.defs && grep -Eq '^PASS_WARN_AGE\\s+7$' /etc/login.defs && grep -Fqx 'umask 027' /home/miles/.bash_profile && stat -c '%a %U:%G' /srv/summit-audit | grep -qx '750 root:root'",
            "chage -l miles | grep -Eq 'Last password change.*password must be changed' || chage -l miles | grep -Eq 'Password expires.*password must be changed'",
            "test -f /root/foragerd-files/opt/exam-d/find/a/file1.txt && grep -q 'alpha' /root/alpha-lines && test -f /root/summit-etc.tar.gz && /usr/local/bin/summit-scan >/dev/null && test -s /root/summit-units.txt",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && findmnt /mnt/summitlv >/dev/null && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1==\"summitlv\" && $2==\"summitvg\" && $3>=255 && $3<=257{f=1} END{exit !f}'",
            "grep -Fqx 'Summit maintenance host' /etc/issue && grep -Fqx 'Summit maintenance host' /etc/motd && systemctl get-default | grep -qx multi-user.target && systemctl is-enabled rsyslog | grep -qx enabled && systemctl is-enabled postfix | grep -qx disabled && rpm -q tree >/dev/null && ! rpm -q dos2unix >/dev/null 2>&1",
        ],
    )

    apply_blocks(
        "mock-exam-e",
        title="Mock Exam E",
        description="A 22 task RHCSA practice mock exam focused on offline repositories, Apache document roots, ACLs, NFS, and storage maintenance.",
        objective_tags=["networking-and-firewall", "software-management", "filesystems-and-autofs", "users-sudo-ssh", "storage-lvm"],
        password_recovery=False,
        blocks=[
            block("Client Network", "Configure networking on client with the following settings:\n\nIP ADDRESS: 192.168.122.37\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: client.exam-e.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.37/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname client.exam-e.lab",
            ]),
            block("Host Entry", "Add a persistent hosts entry so registry.exam-e.lab resolves to 192.168.122.3.", [
                "grep -q 'registry.exam-e.lab' /etc/hosts || echo '192.168.122.3 registry.exam-e.lab' >> /etc/hosts",
            ]),
            block("Client Repositories", "Configure a repository file on client with BaseOS and AppStream served from server, enabled, and with gpgcheck disabled.", [
                "cat > /etc/yum.repos.d/exam-e.repo <<'EOF'",
                "[harbor-baseos]",
                "name=RHCSA BaseOS",
                "baseurl=http://server/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[harbor-appstream]",
                "name=RHCSA AppStream",
                "baseurl=http://server/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Server Repositories", "Configure the same repository file on server.", [
                "# Run on server",
                "cat > /etc/yum.repos.d/exam-e.repo <<'EOF'",
                "[harbor-baseos]",
                "name=RHCSA BaseOS",
                "baseurl=http://server/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[harbor-appstream]",
                "name=RHCSA AppStream",
                "baseurl=http://server/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Apache Custom Docroot", "Configure Apache on client so it serves /srv/harbor-web on TCP port 8181.\n\nRequirements:\n- Start automatically at boot.\n- Open the port permanently in the firewall.\n- Apply the SELinux changes needed for the custom document root and port.", [
                "dnf install -y httpd",
                "mkdir -p /srv/harbor-web",
                "printf 'exam-e portal\\n' > /srv/harbor-web/index.html",
                "sed -i 's/^Listen .*/Listen 8181/' /etc/httpd/conf/httpd.conf",
                "cat > /etc/httpd/conf.d/harborgrid.conf <<'EOF'",
                "<VirtualHost *:8181>",
                "    DocumentRoot \"/srv/harbor-web\"",
                "</VirtualHost>",
                "EOF",
                "semanage fcontext -a -t httpd_sys_content_t '/srv/harbor-web(/.*)?' || semanage fcontext -m -t httpd_sys_content_t '/srv/harbor-web(/.*)?'",
                "restorecon -Rv /srv/harbor-web",
                "firewall-cmd --permanent --add-port=8181/tcp",
                "firewall-cmd --reload",
                "systemctl enable --now httpd",
            ]),
            block("Harbor Users", "Create group harborops and create users lena and ivor with harborops as a supplementary group at creation time. Set the password of both users to cinder9.", [
                "groupadd harborops",
                "useradd -G harborops lena",
                "useradd -G harborops ivor",
                "echo cinder9 | passwd --stdin lena",
                "echo cinder9 | passwd --stdin ivor",
            ]),
            block("Password Aging", "Set password aging for ivor to maximum 30 days, minimum 2 days, and warning 7 days.", [
                "chage -M 30 -m 2 -W 7 ivor",
            ]),
            block("Default ACL Directory", "Create /srv/harbor-drop owned by root:harborops with mode 2770 and a default ACL that grants harborops rwx on new files and directories.", [
                "install -d -m 2770 -o root -g harborops /srv/harbor-drop",
                "setfacl -d -m g:harborops:rwx /srv/harbor-drop",
            ]),
            block("No-Home Remote User", "Create user harborremote without a home directory, with shell /sbin/nologin, and set its password to cinder9.", [
                "useradd -M -s /sbin/nologin harborremote",
                "echo cinder9 | passwd --stdin harborremote",
            ]),
            block("Pwquality Policy", "Configure pwquality so passwords require a minimum length of 12 and at least 3 character classes.", [
                "mkdir -p /etc/security/pwquality.conf.d",
                "cat > /etc/security/pwquality.conf.d/harborgrid.conf <<'EOF'",
                "minlen = 12",
                "minclass = 3",
                "EOF",
            ]),
            block("At Job", "Queue a one-time at job as user ivor that appends the message \"exam-e tick\" to /root/exam-e-at.log in 2 minutes.", [
                "runuser -l ivor -c 'echo \"echo exam-e tick >> /root/exam-e-at.log\" | at now + 2 minutes'",
                "systemctl enable --now atd",
            ]),
            block("Direct NFS Mount", "Persistently mount server:/exports/harborhome on /mnt/harborhome using /etc/fstab.", [
                "mkdir -p /mnt/harborhome",
                "grep -q '/mnt/harborhome' /etc/fstab || echo 'server:/exports/harborhome /mnt/harborhome nfs defaults,_netdev 0 0' >> /etc/fstab",
                "mount -a",
            ]),
            block("Persistent Journal", "On server, enable persistent systemd journal storage and restart systemd-journald.", [
                "# Run on server",
                "mkdir -p /var/log/journal",
                "mkdir -p /etc/systemd/journald.conf.d",
                "cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'",
                "[Journal]",
                "Storage=persistent",
                "EOF",
                "systemctl restart systemd-journald",
                "journalctl --flush",
            ]),
            block("Per-User Login Message", "Append a login message for ivor to ~/.bash_profile that prints \"exam-e access\" when ivor logs in.", [
                "echo 'echo exam-e access' >> /home/ivor/.bash_profile",
            ]),
        block("Fixed UID User", "Create user maple551 with UID 4551, no home directory, shell /sbin/nologin, and password cinder9.", [
            "useradd -M -u 4551 -s /sbin/nologin maple551",
            "echo cinder9 | passwd --stdin maple551",
        ]),
        block("Find And Copy", "Find all files under /opt/exam-e/find that are owned by scoutte and were modified within the last 24 hours. Copy them to /root/scoutte-files while preserving the source directory structure.", [
            "mkdir -p /root/scoutte-files",
            "find /opt/exam-e/find -user scoutte -mtime -1 -type f -exec cp --parents {} /root/scoutte-files \\;",
        ]),
        block("Grep Filter", "Extract lines containing beacon from /usr/share/dict/words into /root/beacon-lines.", [
            "grep beacon /usr/share/dict/words > /root/beacon-lines",
        ]),
        block("Archive", "Create /root/var-tmp-harbor.tar.bz2 containing /var/tmp.", [
            "tar -cjf /root/var-tmp-harbor.tar.bz2 /var/tmp",
        ]),
        block("Shell Script", "Create executable script /usr/local/bin/harbor-check that writes the active state of each service listed in /usr/local/share/exam-e/services.lst to /root/harbor-services.txt.", [
            "cat > /usr/local/bin/harbor-check <<'SCRIPT'",
            "#!/bin/bash",
            "> /root/harbor-services.txt",
            "for svc in $(cat /usr/local/share/exam-e/services.lst); do",
            "  systemctl is-active \"$svc\" >> /root/harbor-services.txt",
            "done",
            "SCRIPT",
            "chmod +x /usr/local/bin/harbor-check",
            "/usr/local/bin/harbor-check",
        ]),
        block("Swap Space", "On /dev/sdb, create a 640 MiB swap partition.\n\nRequirements:\n- Enable it immediately.\n- Configure it persistently.", [
            "parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 641MiB",
            "partprobe /dev/sdb",
            "mkswap /dev/sdb1",
            "swapon /dev/sdb1",
            "uuid=$(blkid -s UUID -o value /dev/sdb1)",
            "echo \"UUID=$uuid swap swap defaults 0 0\" >> /etc/fstab",
        ]),
        block("Resize Existing LV", "Resize /dev/reviewvge/reviewe so the final size is 360 MiB without losing the existing filesystem data.", [
            "lvextend -L 360M /dev/reviewvge/reviewe",
            "resize2fs /dev/reviewvge/reviewe",
        ]),
        block("Recommended Tuned Profile", "Apply the recommended tuned profile and leave it active.", [
            "tuned-adm profile \"$(tuned-adm recommend)\"",
        ]),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'client.exam-e.lab' && grep -Fqx '192.168.122.3 registry.exam-e.lab' /etc/hosts && curl -fsS http://server/repo/BaseOS/repodata/repomd.xml >/dev/null && curl -fsS http://server/repo/AppStream/repodata/repomd.xml >/dev/null",
            "curl -fsS http://localhost:8181 | grep -Fq 'exam-e portal' && findmnt -no TARGET,SOURCE /mnt/harborhome | grep -Eq '^/mnt/harborhome server:/exports/harborhome$'",
            f"getent group harborops >/dev/null && id -nG lena | tr ' ' '\\n' | grep -qx harborops && id -nG ivor | tr ' ' '\\n' | grep -qx harborops && chage -l ivor | grep -Eq 'Maximum.*30' && getfacl -p /srv/harbor-drop | grep -Fq 'default:group:harborops:rwx' && getent passwd harborremote | awk -F: '{{print $6\":\"$7}}' | grep -qx ':/sbin/nologin' && grep -Eq '^minlen\\s*=\\s*12$' /etc/security/pwquality.conf.d/harborgrid.conf && grep -Eq '^minclass\\s*=\\s*3$' /etc/security/pwquality.conf.d/harborgrid.conf && atq | grep -q ivor && grep -Fqx 'echo exam-e access' /home/ivor/.bash_profile && {JOURNALD_PERSISTENT_CHECK}",
            "getent passwd maple551 | awk -F: '{print $3\":\"$6\":\"$7}' | grep -qx '4551::/sbin/nologin' && test -f /root/scoutte-files/opt/exam-e/find/a/file1.txt && grep -q 'beacon' /root/beacon-lines && test -f /root/var-tmp-harbor.tar.bz2 && /usr/local/bin/harbor-check >/dev/null && test -s /root/harbor-services.txt",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1==\"reviewe\" && $2==\"reviewvge\" && $3>=359 && $3<=361{f=1} END{exit !f}'",
            "rec=\"$(tuned-adm recommend | awk '{print $1}')\"; act=\"$(tuned-adm active | sed -E 's/.*: ([^ ]+).*/\\1/')\"; test -n \"$rec\" && test \"$act\" = \"$rec\"",
        ],
    )

    apply_blocks(
        "mock-exam-f",
        title="Mock Exam F",
        description="A 22 task RHCSA practice mock exam centered on chrony, SSH hardening, account defaults, rsync, and storage administration.",
        objective_tags=["networking-and-firewall", "users-sudo-ssh", "processes-logs-tuning", "storage-lvm"],
        password_recovery=False,
        blocks=[
            block("Client Network", "Configure networking on client with the following settings:\n\nIP ADDRESS: 192.168.122.38\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: client.exam-f.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.38/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname client.exam-f.lab",
            ]),
            block("Host Entry", "Add a persistent hosts entry so db.exam-f.lab resolves to 192.168.122.3.", [
                "grep -q 'db.exam-f.lab' /etc/hosts || echo '192.168.122.3 db.exam-f.lab' >> /etc/hosts",
            ]),
            block("Chrony Server", "Configure chronyd on server so it serves time to 192.168.122.0/24 and starts automatically at boot.", [
                "# Run on server",
                "cat > /etc/chrony.conf <<'EOF'",
                "driftfile /var/lib/chrony/drift",
                "makestep 1.0 3",
                "rtcsync",
                "allow 192.168.122.0/24",
                "local stratum 10",
                "EOF",
                "systemctl enable --now chronyd",
            ]),
            block("Chrony Client", "Configure chronyd on client so it synchronizes only with server and starts automatically at boot.", [
                "cat > /etc/chrony.conf <<'EOF'",
                "server server iburst",
                "driftfile /var/lib/chrony/drift",
                "makestep 1.0 3",
                "rtcsync",
                "EOF",
                "systemctl enable --now chronyd",
            ]),
            block("SSH Port", "On server, configure sshd to listen on TCP port 2222 and keep both password and public key authentication enabled.", [
                "# Run on server",
                "python3 - <<'EOF'",
                "from pathlib import Path",
                "import re",
                "p = Path('/etc/ssh/sshd_config')",
                "text = p.read_text()",
                "for key, val in [('Port', '2222'), ('PasswordAuthentication', 'yes'), ('PubkeyAuthentication', 'yes')]:",
                "    if re.search(rf'^\\s*{key}\\s+', text, flags=re.M):",
                "        text = re.sub(rf'^\\s*{key}\\s+.*$', f'{key} {val}', text, flags=re.M)",
                "    else:",
                "        text += f'\\n{key} {val}\\n'",
                "p.write_text(text)",
                "EOF",
                "semanage port -l | grep -Eq '^ssh_port_t\\b.*\\b2222\\b' || semanage port -a -t ssh_port_t -p tcp 2222",
                "systemctl restart sshd",
            ]),
            block("Rich Rule", "On server, add a permanent rich firewall rule allowing TCP port 2222 only from 192.168.122.0/24.", [
                "# Run on server",
                "firewall-cmd --permanent --add-rich-rule='rule family=\"ipv4\" source address=\"192.168.122.0/24\" port protocol=\"tcp\" port=\"2222\" accept'",
                "firewall-cmd --reload",
            ]),
            block("Useradd Defaults", "Set the default inactive period for newly created local users to 14 days.", [
                "useradd -D -f 14",
            ]),
            block("No-Home UID User", "Create user pine560 with UID 4560, no home directory, shell /sbin/nologin, and password cinder9.", [
                "useradd -M -u 4560 -s /sbin/nologin pine560",
                "echo cinder9 | passwd --stdin pine560",
            ]),
            block("Admin User", "Create user elio with a home directory and password cinder9.", [
                "useradd elio",
                "echo cinder9 | passwd --stdin elio",
            ]),
            block("Delegated Sudo", "Allow elio to restart firewalld on client through sudo without a password prompt. Use a sudoers drop-in.", [
                "visudo -f /etc/sudoers.d/elio-firewalld",
                "elio ALL=(root) NOPASSWD: /usr/bin/systemctl restart firewalld",
            ]),
            block("SSH Key Generation", "As elio on client, generate an ED25519 SSH key pair with no passphrase.", [
                *generate_replay_key("elio"),
            ]),
            block("Remote Account", "Create user backupf on server with a home directory and password cinder9. Create /home/backupf/inbox and make backupf the owner.", [
                "# Run on server",
                "useradd backupf",
                "echo cinder9 | passwd --stdin backupf",
                "install -d -m 0755 -o backupf -g backupf /home/backupf/inbox",
            ]),
            block("Passwordless SSH", "Install elio's public key for backupf on server and verify passwordless SSH access on port 2222.", [
                "# Run on client",
                *install_replay_key_with_ssh_copy_id("elio", "backupf"),
                f"ssh -p 2222 {NO_PROMPT_SSH_OPTS} backupf@server true",
            ]),
            block("Rsync Transfer", "On client, use rsync over SSH port 2222 as elio to copy /opt/exam-f/aurora-report.txt to /home/backupf/inbox/report.txt on server.", [
                "# Run on client",
                f"runuser -l elio -c 'rsync -e \"ssh -p 2222 {NO_PROMPT_SSH_OPTS}\" /opt/exam-f/aurora-report.txt backupf@server:/home/backupf/inbox/report.txt'",
            ]),
        block("User Umask", "Set a personal umask of 027 for elio.", [
            "echo 'umask 027' >> /home/elio/.bash_profile",
        ]),
        block("Find And Copy", "Find all files under /opt/exam-f/find that are owned by seekerf and were modified within the last 24 hours. Copy them to /root/seekerf-files while preserving the source directory structure.", [
            "mkdir -p /root/seekerf-files",
            "find /opt/exam-f/find -user seekerf -mtime -1 -type f -exec cp --parents {} /root/seekerf-files \\;",
        ]),
        block("Grep Filter", "Extract lines containing comet from /usr/share/dict/words into /root/comet-lines.", [
            "grep comet /usr/share/dict/words > /root/comet-lines",
        ]),
        block("Archive", "Create /root/usr-local-f.tar.gz containing /usr/local.", [
            "tar -czf /root/usr-local-f.tar.gz /usr/local",
        ]),
        block("Shell Script", "Create executable script /usr/local/bin/aurora-report that writes the active state of each unit listed in /usr/local/share/exam-f/units.lst to /root/aurora-units.txt.", [
            "cat > /usr/local/bin/aurora-report <<'SCRIPT'",
            "#!/bin/bash",
            "> /root/aurora-units.txt",
            "for unit in $(cat /usr/local/share/exam-f/units.lst); do",
            "  systemctl is-active \"$unit\" >> /root/aurora-units.txt",
            "done",
            "SCRIPT",
            "chmod +x /usr/local/bin/aurora-report",
            "/usr/local/bin/aurora-report",
        ]),
        block("Swap Space", "On /dev/sdb, create a 704 MiB swap partition.\n\nRequirements:\n- Enable it immediately.\n- Configure it persistently.", [
            "parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 705MiB",
            "partprobe /dev/sdb",
            "mkswap /dev/sdb1",
            "swapon /dev/sdb1",
            "uuid=$(blkid -s UUID -o value /dev/sdb1)",
            "echo \"UUID=$uuid swap swap defaults 0 0\" >> /etc/fstab",
        ]),
        block("Create And Mount LV", "On /dev/sdc, create a volume group auroravg with a physical extent size of 8 MiB and a logical volume auroralv of 50 extents. Format it with xfs and mount it persistently on /mnt/auroralv.", [
            "parted -s /dev/sdc -- mklabel gpt mkpart primary 1MiB 100% set 1 lvm on",
            "partprobe /dev/sdc",
            "pvcreate /dev/sdc1",
            "vgcreate -s 8M auroravg /dev/sdc1",
            "lvcreate -n auroralv -l 50 auroravg",
            "mkfs.xfs -f /dev/auroravg/auroralv",
            "mkdir -p /mnt/auroralv",
            "uuid=$(blkid -s UUID -o value /dev/auroravg/auroralv)",
            "echo \"UUID=$uuid /mnt/auroralv xfs defaults 0 0\" >> /etc/fstab",
            "mount -a",
        ]),
            block("Recommended Tuned Profile", "Apply the recommended tuned profile and leave it active.", [
                "tuned-adm profile \"$(tuned-adm recommend)\"",
            ]),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'client.aurora.lab' && grep -Fqx '192.168.122.3 db.aurora.lab' /etc/hosts",
            "grep -Eq '^server server iburst$' /etc/chrony.conf && systemctl is-enabled chronyd | grep -qx enabled && grep -Eq '^allow 192\\.168\\.122\\.0/24$' /etc/chrony.conf && systemctl is-enabled chronyd | grep -qx enabled && grep -Eq '^Port 2222$' /etc/ssh/sshd_config && firewall-cmd --list-rich-rules | grep -Fq 'port port=\"2222\" protocol=\"tcp\" accept'",
            "useradd -D | grep -Eq 'INACTIVE=14' && getent passwd pine560 | awk -F: '{print $3\":\"$6\":\"$7}' | grep -qx '4560::/sbin/nologin' && grep -Eq '^elio .*NOPASSWD: /usr/bin/systemctl restart firewalld$' /etc/sudoers.d/elio-firewalld && grep -Fqx 'umask 027' /home/elio/.bash_profile",
            f"runuser -l elio -c 'ssh -p 2222 {NO_PROMPT_SSH_OPTS} backupf@server true' && test -f /home/backupf/inbox/report.txt",
            "test -f /root/seekerf-files/opt/exam-f/find/a/file1.txt && grep -q 'comet' /root/comet-lines && test -f /root/usr-local-f.tar.gz && /usr/local/bin/aurora-report >/dev/null && test -s /root/aurora-units.txt",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && findmnt -no TARGET,SOURCE,FSTYPE /mnt/auroralv | grep -Eq '^/mnt/auroralv /dev/mapper/auroravg-auroralv xfs$' && rec=\"$(tuned-adm recommend | awk '{print $1}')\"; act=\"$(tuned-adm active | sed -E 's/.*: ([^ ]+).*/\\1/')\"; test -n \"$rec\" && test \"$act\" = \"$rec\"",
        ],
    )

    apply_blocks(
        "mock-exam-g",
        title="Mock Exam G",
        description="A 22 task RHCSA practice mock exam combining recovery, NFS, sticky directories, SSH key transfer, process handling, and rootless containers.",
        objective_tags=["boot-and-recovery", "filesystems-and-autofs", "users-sudo-ssh", "storage-lvm", "containers"],
        password_recovery=True,
        blocks=[
            block("Root Recovery", "Recover root access on client from the console.\n\nSet the root password to: cinder9", [
                "# At the boot menu, edit the selected kernel entry.",
                "# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.",
                "passwd root",
                "# enter: cinder9",
                "touch /.autorelabel",
                "exec /sbin/init",
            ]),
            block("Client Network", "Configure networking on client with the following settings:\n\nIP ADDRESS: 192.168.122.39\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: client.deltaforge.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.39/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname client.deltaforge.lab",
            ]),
            block("Bootloader Kernel Argument", "Configure the bootloader on client so every installed kernel boots with the kernel argument audit_backlog_limit=8192.", [
                "grubby --update-kernel=ALL --args=\"audit_backlog_limit=8192\"",
            ]),
            block("Host Entry", "Add a persistent hosts entry so vault.deltaforge.lab resolves to 192.168.122.3.", [
                "grep -q 'vault.deltaforge.lab' /etc/hosts || echo '192.168.122.3 vault.deltaforge.lab' >> /etc/hosts",
            ]),
            block("Direct NFS Mount", "Mount the server export server:/exports/delta-home persistently on client at /mnt/delta-home using NFS.", [
                "mkdir -p /mnt/delta-home",
                "grep -q '/mnt/delta-home' /etc/fstab || echo 'server:/exports/delta-home /mnt/delta-home nfs defaults,_netdev 0 0' >> /etc/fstab",
                "mount -a",
            ]),
            block("Ops User And Group", "Create group deltaops and create user pavel with deltaops as a supplementary group. Set the password of pavel to cinder9.", [
                "groupadd deltaops",
                "useradd -G deltaops pavel",
                "echo cinder9 | passwd --stdin pavel",
            ]),
            block("Sticky Shared Directory", "Create /projects/delta-drop owned by root:deltaops with mode 3770 so group ownership is inherited and only file owners can delete their own files.", [
                "install -d -m 3770 -o root -g deltaops /projects/delta-drop",
            ]),
            block("No-Home Audit User", "Create user auditg without a home directory and with login shell /sbin/nologin.", [
                "useradd -M -s /sbin/nologin auditg",
            ]),
        block("Password Aging And Umask", "Set password aging for pavel to maximum 45 days, minimum 5 days, warning 7 days, and set a personal umask of 027 for pavel.", [
            "chage -M 45 -m 5 -W 7 pavel",
            "echo 'umask 027' >> /home/pavel/.bash_profile",
        ]),
            block("Copy User On Both Systems", "Create user copyg on both systems with password cinder9.", [
                "useradd copyg",
                "echo cinder9 | passwd --stdin copyg",
                "# Run on server",
                "useradd copyg",
                "echo cinder9 | passwd --stdin copyg",
                "install -d -m 0755 -o copyg -g copyg /home/copyg/inbox",
            ]),
            block("SSH Key And Secure Copy", "As copyg on client, generate an ED25519 SSH key pair with no passphrase, install it on server, and copy /opt/exam-g/copyg-payload.txt to /home/copyg/inbox/payload.txt on server.", [
                *generate_replay_key("copyg"),
                "# Run on client",
                *install_replay_key_with_ssh_copy_id("copyg", "copyg", port=22),
                f"scp {NO_PROMPT_SSH_OPTS} /opt/exam-g/copyg-payload.txt copyg@server:/home/copyg/inbox/payload.txt",
            ]),
            block("At Job", "Queue a one-time at job as user pavel that appends the message \"exam-g tick\" to /root/exam-g-at.log in 2 minutes.", [
                "systemctl enable --now atd",
                "runuser -l pavel -c 'echo \"echo exam-g tick >> /root/exam-g-at.log\" | at now + 2 minutes'",
            ]),
        block("Per-User Login Message", "Append a login message for pavel to ~/.bash_profile that prints \"exam-g access\" when pavel logs in.", [
            "echo 'echo exam-g access' >> /home/pavel/.bash_profile",
        ]),
        block("Find And Copy", "Find all files under /opt/exam-g/find that are owned by trackerg and were modified within the last 24 hours, then copy them to /root/trackerg-files while preserving the source directory structure.", [
            "mkdir -p /root/trackerg-files",
            "find /opt/exam-g/find -user trackerg -mtime -1 -type f -exec cp --parents {} /root/trackerg-files \\;",
        ]),
        block("Grep Filter", "Extract lines containing ember from /usr/share/dict/words into /root/ember-lines.", [
            "grep ember /usr/share/dict/words > /root/ember-lines",
        ]),
        block("Archive", "Create /root/etc-g.tar.bz2 containing /etc.", [
            "tar -cjf /root/etc-g.tar.bz2 /etc",
        ]),
        block("Persistent Journal", "On client, enable persistent systemd journal storage and restart systemd-journald.", [
            "mkdir -p /var/log/journal",
            "mkdir -p /etc/systemd/journald.conf.d",
            "cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'",
            "[Journal]",
            "Storage=persistent",
            "EOF",
            "systemctl restart systemd-journald",
            "journalctl --flush",
        ]),
        block("Process Renice And Kill", "User workerg has a CPU-bound process whose PID is stored in /home/workerg/cpu.pid and a sleep process whose PID is stored in /home/workerg/sleep.pid. Terminate the CPU-bound process and change the nice value of the sleep process to 10.", [
            "kill \"$(cat /home/workerg/cpu.pid)\"",
            "renice 10 -p \"$(cat /home/workerg/sleep.pid)\"",
        ]),
        block("Swap Space", "On /dev/sdb, create a 736 MiB swap partition and configure it persistently.", [
            "parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 737MiB",
            "partprobe /dev/sdb",
            "mkswap /dev/sdb1",
            "swapon /dev/sdb1",
            "uuid=$(blkid -s UUID -o value /dev/sdb1)",
            "echo \"UUID=$uuid swap swap defaults 0 0\" >> /etc/fstab",
        ]),
        block("Create And Mount LV", "On /dev/sdc, create a volume group deltavg with a physical extent size of 16 MiB and a logical volume deltalv with 40 extents. Format it with ext4 and mount it persistently at /mnt/deltalv.", [
            "parted -s /dev/sdc -- mklabel gpt mkpart primary 1MiB 701MiB set 1 lvm on",
            "partprobe /dev/sdc",
            "pvcreate /dev/sdc1",
            "vgcreate -s 16M deltavg /dev/sdc1",
            "lvcreate -n deltalv -l 40 deltavg",
            "mkfs.ext4 /dev/deltavg/deltalv",
            "mkdir -p /mnt/deltalv",
            "uuid=$(blkid -s UUID -o value /dev/deltavg/deltalv)",
            "echo \"UUID=$uuid /mnt/deltalv ext4 defaults 0 0\" >> /etc/fstab",
            "mount -a",
        ]),
        block("Rootless Container", "As user solg, build localhost/deltaforge-web:latest from /opt/rhcsa/workspaces/exam-g/Containerfile, then run container pdfg with /opt/inc mounted to /data/input and /opt/outg mounted to /data/output.", [
            "su - solg",
            "cd /opt/rhcsa/workspaces/exam-g",
            "podman build -t localhost/deltaforge-web:latest .",
            "podman run -d --name pdfg -v /opt/inc:/data/input:Z -v /opt/outg:/data/output:Z localhost/deltaforge-web:latest",
            "exit",
        ]),
        block("Container Autostart", "Generate and enable a systemd user service for pdfg and enable lingering for solg.", [
            "su - solg",
            "mkdir -p ~/.config/systemd/user",
            "cd ~/.config/systemd/user",
            "podman generate systemd --name pdfg --files --new",
            "systemctl --user daemon-reload",
            "systemctl --user enable --now container-pdfg.service",
            "exit",
            "loginctl enable-linger solg",
        ]),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'client.deltaforge.lab' && grep -Fqx '192.168.122.3 vault.deltaforge.lab' /etc/hosts && grubby --info=ALL | grep -Eq 'args=.*audit_backlog_limit=8192'",
            "mount | grep -Eq 'server:/exports/delta-home on /mnt/delta-home type nfs' && getent group deltaops >/dev/null && id -nG pavel | tr ' ' '\\n' | grep -qx deltaops && stat -c '%a %U:%G' /projects/delta-drop | grep -qx '3770 root:deltaops' && getent passwd auditg | awk -F: '{print $6\":\"$7}' | grep -qx ':/sbin/nologin'",
            "chage -l pavel | grep -Eq 'Maximum.*45' && grep -Fqx 'umask 027' /home/pavel/.bash_profile && grep -Fqx 'echo exam-g access' /home/pavel/.bash_profile && atq | grep -q pavel",
            f"runuser -l copyg -c 'ssh {NO_PROMPT_SSH_OPTS} copyg@server true' && test -f /home/copyg/inbox/payload.txt",
            f"test -f /root/trackerg-files/opt/exam-g/find/a/file1.txt && grep -q 'ember' /root/ember-lines && test -f /root/etc-g.tar.bz2 && {JOURNALD_PERSISTENT_CHECK} && ! ps -p \"$(cat /home/workerg/cpu.pid)\" >/dev/null 2>&1 && ps -o ni= -p \"$(cat /home/workerg/sleep.pid)\" | tr -d ' ' | grep -qx '10'",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && findmnt -no TARGET,SOURCE,FSTYPE /mnt/deltalv | grep -Eq '^/mnt/deltalv /dev/mapper/deltavg-deltalv ext4$' && runuser -l solg -c 'systemctl --user is-enabled container-pdfg.service' | grep -qx enabled && runuser -l solg -c 'systemctl --user is-active container-pdfg.service' | grep -qx active && loginctl show-user solg | grep -Eq '^Linger=yes$'",
        ],
    )

    apply_blocks(
        "mock-exam-h",
        title="Mock Exam H",
        description="A 22 task RHCSA practice mock exam covering repositories, SELinux HTTP changes, chrony, package work, and container inspection.",
        objective_tags=["networking-and-firewall", "software-management", "users-sudo-ssh", "processes-logs-tuning", "storage-lvm", "containers"],
        password_recovery=False,
        blocks=[
            block("Client Network", "Configure networking on client with the following settings:\n\nIP ADDRESS: 192.168.122.40\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: client.exam-h.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.40/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname client.exam-h.lab",
            ]),
            block("Host Entry", "Add a persistent hosts entry so registry.exam-h.lab resolves to 192.168.122.3.", [
                "grep -q 'registry.exam-h.lab' /etc/hosts || echo '192.168.122.3 registry.exam-h.lab' >> /etc/hosts",
            ]),
            block("Client Repositories", "Configure a repository file on client with BaseOS and AppStream served from server, enabled, and with gpgcheck disabled.", [
                "cat > /etc/yum.repos.d/exam-h.repo <<'EOF'",
                "[silver-baseos]",
                "name=RHCSA BaseOS",
                "baseurl=http://server/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[silver-appstream]",
                "name=RHCSA AppStream",
                "baseurl=http://server/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Server Repositories", "Configure the same repository file on server.", [
                "# Run on server",
                "cat > /etc/yum.repos.d/exam-h.repo <<'EOF'",
                "[silver-baseos]",
                "name=RHCSA BaseOS",
                "baseurl=http://server/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[silver-appstream]",
                "name=RHCSA AppStream",
                "baseurl=http://server/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Apache SELinux Port", "Configure Apache on client so it serves the existing site on TCP port 8181.\n\nRequirements:\n- Start automatically at boot.\n- Open the port permanently in the firewall.\n- Apply the SELinux change required for the new port.", [
                "dnf install -y httpd",
                "sed -i 's/^Listen .*/Listen 8181/' /etc/httpd/conf/httpd.conf",
                "firewall-cmd --permanent --add-port=8181/tcp",
                "firewall-cmd --reload",
                "semanage port -a -t http_port_t -p tcp 8181 || semanage port -m -t http_port_t -p tcp 8181",
                "systemctl enable --now httpd",
            ]),
            block("Pwquality Policy", "Configure pwquality so passwords require a minimum length of 12 and at least 3 character classes.", [
                "mkdir -p /etc/security/pwquality.conf.d",
                "cat > /etc/security/pwquality.conf.d/silverpeak.conf <<'EOF'",
                "minlen = 12",
                "minclass = 3",
                "EOF",
            ]),
            block("No-Home User", "Create user agingh without a home directory, with shell /sbin/nologin, and set its password to cinder9.", [
                "useradd -M -s /sbin/nologin agingh",
                "echo cinder9 | passwd --stdin agingh",
            ]),
            block("Per-User Password Aging", "Set password aging for agingh to minimum 2 days, maximum 30 days, warning 7 days, and force a password change at the next login.", [
                "chage -m 2 -M 30 -W 7 agingh",
                "chage -d 0 agingh",
            ]),
            block("Sticky Directory", "Create /srv/silver-drop as a sticky directory with ownership root:root and mode 1777.", [
                "install -d -m 1777 -o root -g root /srv/silver-drop",
            ]),
            block("Chrony Server", "Configure chronyd on server so it serves time to 192.168.122.0/24 and starts automatically at boot.", [
                "# Run on server",
                "cat > /etc/chrony.conf <<'EOF'",
                "driftfile /var/lib/chrony/drift",
                "makestep 1.0 3",
                "rtcsync",
                "allow 192.168.122.0/24",
                "local stratum 10",
                "EOF",
                "systemctl enable --now chronyd",
            ]),
            block("Chrony Client", "Configure chronyd on client so it synchronizes only with server and starts automatically at boot.", [
                "cat > /etc/chrony.conf <<'EOF'",
                "server server iburst",
                "driftfile /var/lib/chrony/drift",
                "makestep 1.0 3",
                "rtcsync",
                "EOF",
                "systemctl enable --now chronyd",
            ]),
            block("Firewalld Rich Rule", "On client, add a permanent rich firewall rule allowing TCP port 2222 only from 192.168.122.0/24.", [
                "firewall-cmd --permanent --add-rich-rule='rule family=\"ipv4\" source address=\"192.168.122.0/24\" port protocol=\"tcp\" port=\"2222\" accept'",
                "firewall-cmd --reload",
            ]),
        block("Useradd Defaults", "Set the default inactive period for newly created local users to 10 days.", [
            "useradd -D -f 10",
        ]),
        block("Find And Copy", "Find all files under /opt/exam-h/find that are owned by watcherh and were modified within the last 24 hours, then copy them to /root/watcherh-files while preserving the source directory structure.", [
            "mkdir -p /root/watcherh-files",
            "find /opt/exam-h/find -user watcherh -mtime -1 -type f -exec cp --parents {} /root/watcherh-files \\;",
        ]),
        block("Grep Filter", "Extract lines containing silver from /usr/share/dict/words into /root/silver-lines.", [
            "grep silver /usr/share/dict/words > /root/silver-lines",
        ]),
        block("Archive", "Create /root/usr-local-h.tar.gz containing /usr/local.", [
            "tar -czf /root/usr-local-h.tar.gz /usr/local",
        ]),
        block("Swap Space", "On /dev/sdb, create a 672 MiB swap partition and configure it persistently.", [
            "parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 673MiB",
            "partprobe /dev/sdb",
            "mkswap /dev/sdb1",
            "swapon /dev/sdb1",
            "uuid=$(blkid -s UUID -o value /dev/sdb1)",
            "echo \"UUID=$uuid swap swap defaults 0 0\" >> /etc/fstab",
        ]),
        block("Resize Existing LV", "Resize /dev/reviewvgh/reviewh so the final size is 320 MiB without losing the existing file system or data.", [
            "lvextend -L 320M /dev/reviewvgh/reviewh",
            "resize2fs /dev/reviewvgh/reviewh",
        ]),
        block("Boot Target And Services", "Configure client to boot into multi-user.target by default. Ensure rsyslog is enabled and running. If postfix is installed, disable it and stop it.", [
            "systemctl set-default multi-user.target",
            "systemctl enable --now rsyslog",
            "systemctl disable --now postfix",
        ]),
        block("Install And Remove Packages", "Use the prepared local repositories to install the packages tree and dos2unix on client. Remove dos2unix and leave tree installed.", [
            "dnf install -y tree dos2unix",
            "dnf remove -y dos2unix",
        ]),
        block("Inspect Container Image", "Create user inspecth with password cinder9 if it does not already exist. As that user, load /opt/rhcsa/container-assets/rhcsa-httpd-base.tar into local storage and write the configured working directory of localhost/rhcsa-httpd-base:latest to /home/inspecth/workdir.txt.", [
            "id inspecth >/dev/null 2>&1 || useradd -m inspecth",
            "echo cinder9 | passwd --stdin inspecth",
            "su - inspecth",
            "podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar",
            "podman image inspect localhost/rhcsa-httpd-base:latest --format {{.Config.WorkingDir}} > ~/workdir.txt",
            "exit",
        ]),
        block("Recommended Tuned Profile", "Apply the recommended tuned profile and leave it active.", [
            "tuned-adm profile \"$(tuned-adm recommend)\"",
        ]),
    ],
    checks=[
            "hostnamectl --static | grep -qx 'client.exam-h.lab' && grep -Fqx '192.168.122.3 registry.exam-h.lab' /etc/hosts && curl -fsS http://server/repo/BaseOS/repodata/repomd.xml >/dev/null && curl -fsS http://server/repo/AppStream/repodata/repomd.xml >/dev/null",
            "curl -fsS http://localhost:8181 >/dev/null && semanage port -l | grep -Eq '^http_port_t\\b.*\\b8181\\b' && firewall-cmd --list-rich-rules | grep -Fq 'port port=\"2222\" protocol=\"tcp\" accept'",
            "grep -Eq '^minlen\\s*=\\s*12$' /etc/security/pwquality.conf.d/silverpeak.conf && grep -Eq '^minclass\\s*=\\s*3$' /etc/security/pwquality.conf.d/silverpeak.conf && getent passwd agingh | awk -F: '{print $6\":\"$7}' | grep -qx ':/sbin/nologin' && chage -l agingh | grep -Eq 'Minimum.*2' && chage -l agingh | grep -Eq 'Maximum.*30' && chage -l agingh | grep -Eq 'warning.*7' && chage -l agingh | grep -Eq 'password must be changed|must be changed' && useradd -D | grep -Eq 'INACTIVE=10' && stat -c '%a %U:%G' /srv/silver-drop | grep -qx '1777 root:root'",
            "grep -Eq '^server server iburst$' /etc/chrony.conf && systemctl is-enabled chronyd | grep -qx enabled && grep -Eq '^allow 192\\.168\\.122\\.0/24$' /etc/chrony.conf && systemctl is-enabled chronyd | grep -qx enabled",
            "test -f /root/watcherh-files/opt/exam-h/find/a/file1.txt && grep -q 'silver' /root/silver-lines && test -f /root/usr-local-h.tar.gz && swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1==\"reviewh\" && $2==\"reviewvgh\" && $3>=319 && $3<=321{f=1} END{exit !f}' && systemctl get-default | grep -qx multi-user.target && systemctl is-enabled rsyslog | grep -qx enabled && systemctl is-enabled postfix | grep -qx disabled && rpm -q tree >/dev/null && ! rpm -q dos2unix >/dev/null 2>&1",
            "runuser -l inspecth -c 'podman image exists localhost/rhcsa-httpd-base:latest' && test -s /home/inspecth/workdir.txt && rec=\"$(tuned-adm recommend | awk '{print $1}')\"; act=\"$(tuned-adm active | sed -E 's/.*: ([^ ]+).*/\\1/')\"; test -n \"$rec\" && test \"$act\" = \"$rec\"",
        ],
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
