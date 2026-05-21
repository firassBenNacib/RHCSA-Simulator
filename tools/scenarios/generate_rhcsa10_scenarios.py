#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import shutil
from pathlib import Path
from typing import Any

from generate_scenario_markdown import main as generate_scenario_markdown
from rhcsa_scenarios.lab_normalization import normalize_lab_block


ROOT = Path(__file__).resolve().parents[2]
LABS_ROOT = ROOT / "scenarios" / "labs" / "rhcsa10"
EXAMS_ROOT = ROOT / "scenarios" / "exams" / "rhcsa10"


CLIENT_SCRIPT_HEADER = "#!/usr/bin/env bash\nset -euo pipefail\nsource /usr/local/lib/rhcsa-scenario-helpers.sh\n"
SERVER_SCRIPT_HEADER = "#!/usr/bin/env bash\nset -euo pipefail\nsource /usr/local/lib/rhcsa-scenario-helpers.sh\n"

PRIVATE_CONNECTION_NAME = "System eth1"
PRIVATE_CONNECTION_LOOKUP = (
    f"connection_name={json.dumps(PRIVATE_CONNECTION_NAME)}; "
    "nmcli -g NAME connection show \"$connection_name\" >/dev/null 2>&1 || "
    "connection_name=\"$(private_dev=\"$(ip -o -4 addr show | awk '$4 ~ /^192\\.168\\.122\\./ {print $2; exit}')\"; "
    "nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v private_dev=\"$private_dev\" "
    "'$2 == private_dev {print $1; exit}')\""
)


def private_connection_commands(*commands: str) -> list[str]:
    visible_commands = [
        command.replace('"$connection_name"', f'"{PRIVATE_CONNECTION_NAME}"').replace("$connection_name", PRIVATE_CONNECTION_NAME)
        for command in commands
    ]
    return [
        f'nmcli connection show "{PRIVATE_CONNECTION_NAME}"',
        *visible_commands,
    ]


def private_connection_check(command: str) -> str:
    return f'{PRIVATE_CONNECTION_LOOKUP}; test -n "$connection_name" && {command}'


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    rendered = json.dumps(data, indent=2) + "\n"
    if path.exists() and path.read_text(encoding="utf-8") == rendered:
        return
    path.write_text(rendered, encoding="utf-8")


def write_script(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists() or path.read_text(encoding="utf-8") != content:
        path.write_text(content, encoding="utf-8")
    path.chmod(0o755)


def clean_generated() -> None:
    for child in list(LABS_ROOT.glob("lab-*")) + list(EXAMS_ROOT.glob("mock-exam-*")):
        if child.is_dir():
            shutil.rmtree(child)
    for legacy in (LABS_ROOT / "lab-49-flatpak-remote", LABS_ROOT / "lab-50-systemd-timer"):
        if legacy.exists():
            shutil.rmtree(legacy)


def scenario(kind: str, sid: str, title: str, description: str, tags: list[str], minutes: int, block: dict[str, Any], requires_server: bool = False, password_recovery: bool = False, vm_scripts: dict[str, str] | None = None) -> dict[str, Any]:
    if vm_scripts is None:
        vm_scripts = {}
    return {
        "id": sid,
        "title": title,
        "description": description,
        "objective_tags": tags,
        "supported_modes": [kind],
        "time_limit_minutes": minutes,
        "tracks": ["rhcsa10"],
        "rhel_major": 10,
        "vm_scripts": vm_scripts,
        "flags": {
            "password_recovery": password_recovery,
            "requires_server": requires_server,
        },
        "content": {kind: block},
    }


def lab(sid: str, title: str, description: str, tags: list[str], minutes: int, tasks: list[str], hints: list[str], checks: list[str], commands: list[list[str]], requires_server: bool = False, points: list[int] | None = None, vm_scripts: dict[str, str] | None = None) -> dict[str, Any]:
    return scenario(
        "lab", sid, title, description, tags, minutes,
        {
            "tasks": tasks,
            "hints": hints,
            "checks": checks,
            "solution_outline": ["Make the requested configuration persistent and verify it before finishing."],
            "task_titles": [task_title(task) for task in tasks],
            "task_points": points or [10 for _ in tasks],
            "solution_commands": commands,
        },
        requires_server=requires_server,
        vm_scripts=vm_scripts,
    )


def task_title(task: str) -> str:
    line = task.splitlines()[0].strip().rstrip(".")
    for prefix in ("On client, ", "On server, ", "As root, "):
        if line.startswith(prefix):
            line = line[len(prefix):]
    return line[:72]


def _lab_client_scripts() -> dict[str, str]:
    """Return a dict mapping lab ID -> client.sh content."""
    scripts: dict[str, str] = {}
    h = CLIENT_SCRIPT_HEADER

    scripts["lab-01-hostname-resolution"] = h + """
hostnamectl set-hostname client
rhcsa_remove_matching_lines 'server10.lab.example' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"
"""

    scripts["lab-02-ipv4-nmcli"] = h + """
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"
if [[ -n "${connection_name:-}" ]]; then
  nmcli connection modify "$connection_name" ipv4.gateway "" ipv4.dns "" connection.autoconnect no >/dev/null 2>&1 || true
fi
"""

    scripts["lab-03-ipv6-nmcli"] = h + """
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv6_profile "$connection_name"
if [[ -n "${connection_name:-}" ]]; then
  nmcli connection modify "$connection_name" connection.autoconnect no >/dev/null 2>&1 || true
fi
"""

    scripts["lab-04-rpm-repositories"] = h + """
rhcsa_reset_repo_directory /root/.repo-backup-lab04
"""

    scripts["lab-05-rpm-packages"] = h + """
rhcsa_reset_repo_directory /root/.repo-backup-lab05 rhcsa-local.repo
cat > /etc/yum.repos.d/rhcsa-local.repo <<'EOF'
[rhcsa-baseos]
name=RHCSA Local BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0

[rhcsa-appstream]
name=RHCSA Local AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf install -y tcpdump >/dev/null 2>&1 || true
dnf remove -y lsof >/dev/null 2>&1 || true
"""

    scripts["lab-06-flatpak-remote"] = h + """
dnf remove -y flatpak >/dev/null 2>&1 || true
flatpak remote-delete --system rhcsa10 >/dev/null 2>&1 || true
"""

    scripts["lab-07-flatpak-package"] = h + """
dnf install -y flatpak >/dev/null 2>&1 || true
flatpak uninstall --system -y org.rhcsa.Tools >/dev/null 2>&1 || true
flatpak remote-delete --system rhcsa10 >/dev/null 2>&1 || true
"""

    scripts["lab-10-find-copy"] = h + """
rm -rf /root/rhcsa10-found
install -m 0644 /dev/null /etc/skel/rhcsa10-small.conf
touch -t 202001010101 /etc/skel/rhcsa10-small.conf
"""

    scripts["lab-16-password-aging"] = h + """
userdel -r aging10 >/dev/null 2>&1 || true
if grep -q '^PASS_WARN_AGE' /etc/login.defs; then
  sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 14/' /etc/login.defs
else
  echo 'PASS_WARN_AGE 14' >> /etc/login.defs
fi
"""

    scripts["lab-18-ssh-key-auth"] = h + """
userdel -r key10 >/dev/null 2>&1 || true
"""

    scripts["lab-19-firewalld-service"] = h + """
systemctl disable --now firewalld >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-service=https >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
"""

    scripts["lab-20-selinux-mode"] = h + """
setenforce 0 2>/dev/null || true
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
"""

    scripts["lab-21-selinux-restorecon"] = h + """
mkdir -p /var/www/html
echo RHCSA10 > /var/www/html/rhcsa10.html
chcon -t user_tmp_t /var/www/html/rhcsa10.html 2>/dev/null || true
"""

    scripts["lab-22-selinux-port"] = h + """
semanage port -d -t http_port_t -p tcp 8010 >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-port=8010/tcp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
"""

    scripts["lab-23-selinux-boolean"] = h + """
setsebool -P httpd_can_network_connect off >/dev/null 2>&1 || true
setsebool httpd_can_network_connect off >/dev/null 2>&1 || true
"""

    scripts["lab-24-process-priority"] = h + """
if [ -s /run/rhcsa10-sleep.pid ]; then
    kill "$(cat /run/rhcsa10-sleep.pid)" >/dev/null 2>&1 || true
fi
rm -f /run/rhcsa10-sleep.pid
"""

    scripts["lab-25-tuned-profile"] = h + """
systemctl disable --now tuned >/dev/null 2>&1 || true
tuned-adm profile balanced >/dev/null 2>&1 || true
"""

    scripts["lab-26-persistent-journal"] = h + """
rm -rf /var/log/journal
sed -i 's/^Storage=persistent/Storage=auto/' /etc/systemd/journald.conf >/dev/null 2>&1 || true
systemctl restart systemd-journald >/dev/null 2>&1 || true
"""

    scripts["lab-27-rsyslog-logger"] = h + """
rm -f /etc/rsyslog.d/rhcsa10.conf /var/log/rhcsa10-local7.log
systemctl disable --now rsyslog >/dev/null 2>&1 || true
"""

    scripts["lab-28-chrony-client"] = h + """
systemctl disable --now chronyd >/dev/null 2>&1 || true
dnf remove -y chrony >/dev/null 2>&1 || true
rm -f /etc/chrony.conf
"""

    scripts["lab-29-default-target"] = h + """
systemctl set-default graphical.target >/dev/null 2>&1 || true
"""

    scripts["lab-32-cron"] = h + """
userdel -r cron10 >/dev/null 2>&1 || true
systemctl disable --now crond >/dev/null 2>&1 || true
"""

    scripts["lab-33-at-job"] = h + """
userdel -r at10 >/dev/null 2>&1 || true
systemctl disable --now atd >/dev/null 2>&1 || true
"""

    scripts["lab-34-grub-argument"] = h + """
grubby --update-kernel=ALL --remove-args="audit_backlog_limit=8192" >/dev/null 2>&1 || true
"""

    scripts["lab-35-root-recovery"] = h + """
rhcsa_configure_password_recovery enable
"""

    scripts["lab-36-xfs-label-mount"] = h + """
umount /mnt/rhcsa10data >/dev/null 2>&1 || true
sed -i '\\#/mnt/rhcsa10data#d' /etc/fstab
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
"""

    scripts["lab-37-swap"] = h + """
swapoff /dev/sdb1 2>/dev/null || true
sed -i '\\#/dev/sdb1#d' /etc/fstab
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
"""

    scripts["lab-38-lvm-create"] = h + """
umount /mnt/lvdata10 >/dev/null 2>&1 || true
sed -i '\\#/mnt/lvdata10#d' /etc/fstab
lvremove -fy /dev/vg10/lvdata >/dev/null 2>&1 || true
vgremove -fy vg10 >/dev/null 2>&1 || true
pvremove -ffy /dev/sdb >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
"""

    scripts["lab-39-lvm-extend"] = h + """
umount /mnt/grow10 >/dev/null 2>&1 || true
sed -i '\\#/mnt/grow10#d' /etc/fstab
lvremove -fy /dev/grow10/growlv >/dev/null 2>&1 || true
vgremove -fy grow10 >/dev/null 2>&1 || true
pvremove -ffy /dev/sdb >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
"""

    scripts["lab-40-vfat-filesystem"] = h + """
umount /mnt/vfat10 >/dev/null 2>&1 || true
sed -i '\\#/mnt/vfat10#d' /etc/fstab
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
"""

    scripts["lab-41-nfs-mount"] = h + """
dnf install -y nfs-utils >/dev/null 2>&1 || true
umount /mnt/serverdirect10 >/dev/null 2>&1 || true
sed -i '\\#/mnt/serverdirect10#d' /etc/fstab
rm -rf /mnt/serverdirect10
"""

    scripts["lab-42-autofs"] = h + """
systemctl disable --now autofs >/dev/null 2>&1 || true
rm -f /etc/auto.remote10 /etc/auto.master.d/rhcsa10.autofs
automount -u >/dev/null 2>&1 || true
rm -rf /remote10
"""

    scripts["lab-43-sticky-directory"] = h + """
groupdel share10 >/dev/null 2>&1 || true
rm -rf /srv/share10
"""

    scripts["lab-45-secure-copy"] = h + """
rm -f /root/rhcsa10-transfer.txt
"""

    scripts["lab-46-package-file-install"] = h + """
dnf remove -y tree >/dev/null 2>&1 || true
"""

    scripts["lab-48-service-network-boot"] = h + """
systemctl disable --now httpd >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-service=http >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
rm -f /var/www/html/rhcsa10-boot.html
"""

    return scripts


def _lab_server_scripts() -> dict[str, str]:
    """Return a dict mapping lab ID -> server.sh content."""
    scripts: dict[str, str] = {}
    h = SERVER_SCRIPT_HEADER

    scripts["lab-04-rpm-repositories"] = h + """
mkdir -p /root/.repo-backup-server-lab04
rhcsa_reset_repo_directory /root/.repo-backup-server-lab04
"""

    scripts["lab-18-ssh-key-auth"] = h + """
install -d -m 700 /root/.ssh
ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519_key10 -N '' -C 'key10-test' >/dev/null 2>&1 || true
"""

    scripts["lab-24-process-priority"] = h + """
if [ -s /run/rhcsa10-sleep.pid ]; then
  kill "$(cat /run/rhcsa10-sleep.pid)" >/dev/null 2>&1 || true
fi
rm -f /run/rhcsa10-sleep.pid
"""

    scripts["lab-26-persistent-journal"] = h + """
systemctl restart systemd-journald >/dev/null 2>&1 || true
rm -rf /var/log/journal
sed -i '/^Storage=/d' /etc/systemd/journald.conf 2>/dev/null || true
"""

    scripts["lab-28-chrony-client"] = h + """
dnf install -y chrony >/dev/null 2>&1 || true
cat > /etc/chrony.d/lab28-server.conf <<'EOF'
allow 192.168.122.0/24
local stratum 10
EOF
systemctl enable --now chronyd
"""

    scripts["lab-29-default-target"] = h + """
systemctl set-default graphical.target >/dev/null 2>&1 || true
"""

    scripts["lab-30-systemd-service"] = h + """
systemctl disable --now rhcsa10-service.service >/dev/null 2>&1 || true
rm -f /etc/systemd/system/rhcsa10-service.service /usr/local/sbin/rhcsa10-service.sh /var/tmp/rhcsa10-service.out
systemctl daemon-reload
"""

    scripts["lab-31-systemd-timer"] = h + """
systemctl disable --now rhcsa10-timer.timer >/dev/null 2>&1 || true
rm -f /etc/systemd/system/rhcsa10-timer.service /etc/systemd/system/rhcsa10-timer.timer /usr/local/sbin/rhcsa10-timer.sh /var/log/rhcsa10-timer.log
systemctl daemon-reload
"""

    scripts["lab-41-nfs-mount"] = h + """
mkdir -p /exports/direct
echo 'nfs direct mount lab 41' > /exports/direct/welcome.txt
chown -R nobody:nobody /exports/direct
cat > /etc/exports.d/lab41.exports <<'EOFX'
/exports/direct 192.168.122.0/24(rw,sync,no_root_squash)
EOFX
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
"""

    scripts["lab-42-autofs"] = h + """
mkdir -p /exports/autofs/projects
echo 'autofs lab 42' > /exports/autofs/projects/welcome.txt
chown -R nobody:nobody /exports/autofs/projects
cat > /etc/exports.d/lab42.exports <<'EOFX'
/exports/autofs/projects 192.168.122.0/24(rw,sync,no_root_squash)
EOFX
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
"""

    scripts["lab-45-secure-copy"] = h + """
systemctl enable --now sshd
"""

    return scripts


def _exam_scripts(seed: int) -> tuple[str, str]:
    """Return (client.sh content, server.sh content) for a given exam seed."""
    letter = chr(ord("a") + seed)
    user = f"user{letter}10"
    group = f"team{letter}10"
    remote = f"exam{letter}flatpak"
    timer = f"exam{letter}timer"

    client = CLIENT_SCRIPT_HEADER + f"""
# --- Reset hostname and network ---
hostnamectl set-hostname client
rhcsa_remove_matching_lines 'server{letter}.exam10.lab' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"

# --- Reset repos ---
rhcsa_reset_repo_directory /root/.repo-backup-exam-{letter}

# --- Remove flatpak remotes ---
flatpak remote-delete --system {remote} >/dev/null 2>&1 || true
flatpak uninstall --system -y org.rhcsa.Tools >/dev/null 2>&1 || true

# --- Remove users, groups, sudoers ---
userdel -r {user} >/dev/null 2>&1 || true
groupdel {group} >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/{group}-systemctl

# --- SELinux: reset boolean, remove port labels ---
setsebool httpd_can_network_connect 0 2>/dev/null || true
semanage port -d -t http_port_t -p tcp {8100 + seed} >/dev/null 2>&1 || true

# --- Firewalld: remove port, reset service ---
firewall-cmd --permanent --remove-port={8100 + seed}/tcp >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-service=https >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true

# --- SELinux context: mislabel file for restorecon task ---
mkdir -p /var/www/html
echo '{letter}' > /var/www/html/{letter}.html
chcon -t user_tmp_t /var/www/html/{letter}.html 2>/dev/null || true

# --- Remove sticky directory ---
rm -rf /srv/{group}
groupdel {group} >/dev/null 2>&1 || true

# --- Tuned: reset profile, disable tuned ---
systemctl disable --now tuned >/dev/null 2>&1 || true
tuned-adm profile balanced >/dev/null 2>&1 || true

# --- Journal: remove persistent config ---
rm -rf /var/log/journal
sed -i 's/^Storage=persistent/Storage=auto/' /etc/systemd/journald.conf >/dev/null 2>&1 || true

# --- Chrony: disable and strip config ---
systemctl disable --now chronyd >/dev/null 2>&1 || true
dnf remove -y chrony >/dev/null 2>&1 || true
rm -f /etc/chrony.conf

# --- Timer: remove any existing timer ---
rm -f /etc/systemd/system/{timer}.service /etc/systemd/system/{timer}.timer
rm -f /usr/local/sbin/{timer}.sh
systemctl disable --now {timer}.timer >/dev/null 2>&1 || true

# --- Cron: remove crontab ---
crontab -r -u {user} >/dev/null 2>&1 || true

# --- Autofs: remove configs ---
systemctl disable --now autofs >/dev/null 2>&1 || true
rm -f /etc/auto.remote{letter} /etc/auto.master.d/{letter}.autofs
automount -u >/dev/null 2>&1 || true
rm -rf /remote{letter}

# --- LVM: wipe /dev/sdb ---
umount /mnt/data{letter}10 >/dev/null 2>&1 || true
sed -i '\\#/mnt/data{letter}10#d' /etc/fstab
lvremove -fy /dev/vg{letter}10/data{letter} >/dev/null 2>&1 || true
vgremove -fy vg{letter}10 >/dev/null 2>&1 || true
pvremove -ffy /dev/sdb >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true

# --- Default target: reset to graphical ---
systemctl set-default graphical.target >/dev/null 2>&1 || true

# --- Packages: ensure lsof absent, tcpdump present ---
dnf remove -y lsof >/dev/null 2>&1 || true
dnf install -y tcpdump >/dev/null 2>&1 || true

# --- Kernel args: remove audit_backlog_limit ---
grubby --update-kernel=ALL --remove-args="audit_backlog_limit=8192" >/dev/null 2>&1 || true

# --- Scripts: remove leftover custom scripts ---
rm -f /usr/local/bin/{letter}-who /root/{letter}-shell-users.txt /root/{letter}-etc.tar.gz
rm -f /root/{letter}-original /root/{letter}-hard /root/{letter}-soft
"""

    server = SERVER_SCRIPT_HEADER + f"""
# --- Reset repos on server ---
mkdir -p /root/.repo-backup-server-exam-{letter}
rhcsa_reset_repo_directory /root/.repo-backup-server-exam-{letter}

# --- NFS exports ---
mkdir -p /exports/direct
echo 'exam {letter} direct' > /exports/direct/welcome.txt
chown -R nobody:nobody /exports/direct

mkdir -p /exports/autofs/projects
echo 'exam {letter} autofs' > /exports/autofs/projects/welcome.txt
chown -R nobody:nobody /exports/autofs/projects

cat > /etc/exports.d/exam-{letter}.exports <<'EOFX'
/exports/direct 192.168.122.0/24(rw,sync,no_root_squash)
/exports/autofs/projects 192.168.122.0/24(rw,sync,no_root_squash)
EOFX
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
"""

    return client, server


def _load_manifest(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _remove_path(path: Path) -> None:
    if path.is_dir():
        shutil.rmtree(path)
    elif path.exists():
        path.unlink()


def _cleanup_scripts_dir(scripts_dir: Path) -> None:
    if scripts_dir.is_dir() and not any(scripts_dir.iterdir()):
        scripts_dir.rmdir()


def _replace_lab_progression(
    block: dict[str, Any],
    tasks: list[str],
    checks: list[str],
    commands: list[list[str]],
    points: list[int] | None = None,
) -> dict[str, Any]:
    updated = dict(block)
    updated["tasks"] = tasks
    updated["checks"] = checks
    updated["solution_commands"] = commands
    updated["task_titles"] = [task_title(task) for task in tasks]
    updated["task_points"] = points or [10 for _ in tasks]
    return updated


def _server_check(command: str) -> str:
    if command.lstrip().startswith("# server "):
        return command
    return f"# server {command}"


def _ssh_server_check(command: str) -> str:
    escaped = command.replace("'", "'\"'\"'")
    return f"ssh server bash -lc 'set -euo pipefail; {escaped}'"


def _reorder_parallel(values: list[Any], order: list[int]) -> list[Any]:
    if len(values) != len(order):
        return values
    return [values[index] for index in order]


def _retarget_lab_to_server(block: dict[str, Any]) -> dict[str, Any]:
    updated = dict(block)
    updated["tasks"] = [
        task if re.search(r"\bon server\b", str(task), re.I) else f"On server, {str(task)[0].lower()}{str(task)[1:]}"
        for task in updated.get("tasks", [])
    ]
    updated["checks"] = [_server_check(str(check)) for check in updated.get("checks", [])]
    updated["task_titles"] = [task_title(task) for task in updated["tasks"]]
    return updated


def _repair_lab_progression(lab_id: str, block: dict[str, Any]) -> dict[str, Any]:
    """Fix RHCSA10 labs whose old task/check split could not score 1:1."""
    if lab_id == "lab-01-hostname-resolution":
        return _replace_lab_progression(
            block,
            [
                "On client, set the persistent hostname to client10.lab.example.",
                "On client, add a persistent hosts entry mapping server10.lab.example to 192.168.122.3.",
            ],
            [
                "hostnamectl --static | grep -qx client10.lab.example",
                "awk '$1 == \"192.168.122.3\" {for (i = 2; i <= NF; i++) if ($i == \"server10.lab.example\") found = 1} END {exit !found}' /etc/hosts && getent hosts server10.lab.example | grep -q '192.168.122.3'",
            ],
            [
                ["hostnamectl set-hostname client10.lab.example"],
                [
                    "echo '192.168.122.3 server10.lab.example' >> /etc/hosts",
                    "hostnamectl --static",
                    "getent hosts server10.lab.example",
                ],
            ],
            points=[10, 20],
        )

    if lab_id == "lab-02-ipv4-nmcli":
        return _replace_lab_progression(
            block,
            [
                "On client, configure the active lab connection with IPv4 address 192.168.122.45/24.",
                "On client, set gateway 192.168.122.1 and DNS server 192.168.122.3.",
                "On client, ensure the connection uses manual IPv4 configuration and autoconnects.",
            ],
            [
                private_connection_check("nmcli -g ipv4.addresses connection show \"$connection_name\" | grep -qx '192.168.122.45/24'"),
                private_connection_check("nmcli -g ipv4.gateway connection show \"$connection_name\" | grep -qx '192.168.122.1' && nmcli -g ipv4.dns connection show \"$connection_name\" | grep -qx '192.168.122.3'"),
                private_connection_check("nmcli -g ipv4.method connection show \"$connection_name\" | grep -qx manual && nmcli -g connection.autoconnect connection show \"$connection_name\" | grep -qx yes"),
            ],
            [
                private_connection_commands('nmcli connection modify "$connection_name" ipv4.addresses 192.168.122.45/24'),
                private_connection_commands('nmcli connection modify "$connection_name" ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3'),
                private_connection_commands(
                    'nmcli connection modify "$connection_name" ipv4.method manual connection.autoconnect yes',
                    'nmcli connection up "$connection_name"',
                ),
            ],
        )

    if lab_id == "lab-03-ipv6-nmcli":
        return _replace_lab_progression(
            block,
            [
                "On client, configure the active lab connection with IPv6 address fd00:10::45/64.",
                "On client, set IPv6 gateway fd00:10::1.",
                "On client, ensure IPv6 method is manual and the profile autoconnects.",
            ],
            [
                private_connection_check("nmcli -g ipv6.addresses connection show \"$connection_name\" | sed 's/\\\\//g' | grep -qx 'fd00:10::45/64'"),
                private_connection_check("nmcli -g ipv6.gateway connection show \"$connection_name\" | sed 's/\\\\//g' | grep -qx 'fd00:10::1'"),
                private_connection_check("nmcli -g ipv6.method connection show \"$connection_name\" | grep -qx manual && nmcli -g connection.autoconnect connection show \"$connection_name\" | grep -qx yes"),
            ],
            [
                private_connection_commands('nmcli connection modify "$connection_name" ipv6.method manual ipv6.addresses fd00:10::45/64'),
                private_connection_commands('nmcli connection modify "$connection_name" ipv6.gateway fd00:10::1'),
                private_connection_commands(
                    'nmcli connection modify "$connection_name" ipv6.method manual connection.autoconnect yes',
                    'nmcli connection up "$connection_name"',
                ),
            ],
        )

    if lab_id == "lab-04-rpm-repositories":
        return _replace_lab_progression(
            block,
            [
                "On client, configure a persistent BaseOS repository using http://server/repo/BaseOS/.",
                "On client, configure a persistent AppStream repository using http://server/repo/AppStream/.",
                "On client, disable GPG checks for both RHCSA10 repositories and verify both repositories are enabled.",
            ],
            [
                "grep -ERq '^\\[rhcsa10-baseos\\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://server/repo/BaseOS/?$' /etc/yum.repos.d",
                "grep -ERq '^\\[rhcsa10-appstream\\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://server/repo/AppStream/?$' /etc/yum.repos.d",
                "awk 'BEGIN{s=0} /^\\[rhcsa10-(baseos|appstream)\\]$/{repo=$0} /^gpgcheck=0$/{if (repo != \"\") s++} END{exit !(s >= 2)}' /etc/yum.repos.d/*.repo && dnf repolist --enabled | grep -Eq 'rhcsa10-baseos|rhcsa10-appstream'",
            ],
            [
                [
                    "cat > /etc/yum.repos.d/rhcsa10.repo <<'EOF'\n[rhcsa10-baseos]\nname=RHCSA10 BaseOS\nbaseurl=http://server/repo/BaseOS/\nenabled=1\ngpgcheck=1\nEOF",
                ],
                [
                    "cat >> /etc/yum.repos.d/rhcsa10.repo <<'EOF'\n\n[rhcsa10-appstream]\nname=RHCSA10 AppStream\nbaseurl=http://server/repo/AppStream/\nenabled=1\ngpgcheck=1\nEOF",
                ],
                [
                    "sed -i 's/^gpgcheck=.*/gpgcheck=0/' /etc/yum.repos.d/rhcsa10.repo",
                    "dnf clean all",
                    "dnf repolist --enabled",
                ],
            ],
        )

    if lab_id == "lab-07-flatpak-package":
        return _replace_lab_progression(
            block,
            [
                "Ensure the system Flatpak remote rhcsa10 exists and points to file:///opt/rhcsa/flatpak/repo.",
                "Install Flatpak application org.rhcsa.Tools from rhcsa10 for the system installation.",
            ],
            [
                "flatpak remotes --system --columns=name,url 2>/dev/null | awk '$1 == \"rhcsa10\" && $2 == \"file:///opt/rhcsa/flatpak/repo\" {found=1} END {exit !found}'",
                "flatpak list --system --app --columns=application 2>/dev/null | grep -qx org.rhcsa.Tools",
            ],
            [
                ["flatpak remote-add --system --if-not-exists --no-gpg-verify rhcsa10 file:///opt/rhcsa/flatpak/repo"],
                ["flatpak install --system -y rhcsa10 org.rhcsa.Tools"],
            ],
        )

    if lab_id == "lab-08-shell-script-args":
        return _replace_lab_progression(
            block,
            [
                "Create /usr/local/bin/rhcsa10-user-report with the required argument handling.",
                "Make the script executable and confirm it prints a supplied user's primary group.",
            ],
            [
                "test -f /usr/local/bin/rhcsa10-user-report",
                "test -x /usr/local/bin/rhcsa10-user-report && /usr/local/bin/rhcsa10-user-report 2>&1 | grep -qx 'usage: rhcsa10-user-report USER' && /usr/local/bin/rhcsa10-user-report root | grep -qx root",
            ],
            [
                [
                    "cat > /usr/local/bin/rhcsa10-user-report <<'EOF'\n#!/bin/bash\nif [ -z \"${1:-}\" ]; then\n  echo 'usage: rhcsa10-user-report USER' >&2\n  exit 2\nfi\nid -gn \"$1\"\nEOF",
                ],
                ["chmod +x /usr/local/bin/rhcsa10-user-report", "/usr/local/bin/rhcsa10-user-report root"],
            ],
        )

    if lab_id == "lab-10-find-copy":
        return _replace_lab_progression(
            block,
            [
                "Create /root/rhcsa10-found.",
                "Copy every file smaller than 1 KiB from /etc/skel to /root/rhcsa10-found while preserving mode and timestamps.",
            ],
            [
                "test -d /root/rhcsa10-found",
                "test -f /root/rhcsa10-found/rhcsa10-small.conf && test \"$(stat -c %a /etc/skel/rhcsa10-small.conf)\" = \"$(stat -c %a /root/rhcsa10-found/rhcsa10-small.conf)\" && test \"$(stat -c %Y /etc/skel/rhcsa10-small.conf)\" = \"$(stat -c %Y /root/rhcsa10-found/rhcsa10-small.conf)\"",
            ],
            [
                ["mkdir -p /root/rhcsa10-found"],
                ["find /etc/skel -type f -size -1k -exec cp -a {} /root/rhcsa10-found/ \\;", "find /root/rhcsa10-found -type f -ls"],
            ],
        )

    if lab_id == "lab-09-shell-loop":
        return _replace_lab_progression(
            block,
            [
                "Create /usr/local/bin/rhcsa10-lines.",
                "Make the script executable, read /etc/passwd, and overwrite /root/rhcsa10-lines.txt with every account name that starts with r.",
            ],
            [
                "test -f /usr/local/bin/rhcsa10-lines",
                "test -x /usr/local/bin/rhcsa10-lines && /usr/local/bin/rhcsa10-lines && test -s /root/rhcsa10-lines.txt && ! grep -Ev '^r' /root/rhcsa10-lines.txt >/dev/null 2>&1",
            ],
            [
                [
                    "cat > /usr/local/bin/rhcsa10-lines <<'EOF'\n#!/bin/bash\n: > /root/rhcsa10-lines.txt\nwhile IFS=: read -r name _; do\n  case \"$name\" in\n    r*) echo \"$name\" >> /root/rhcsa10-lines.txt ;;\n  esac\ndone < /etc/passwd\nEOF",
                ],
                ["chmod +x /usr/local/bin/rhcsa10-lines", "/usr/local/bin/rhcsa10-lines", "cat /root/rhcsa10-lines.txt"],
            ],
        )

    if lab_id == "lab-11-grep-regex":
        return _replace_lab_progression(
            block,
            [
                "Create /root/rhcsa10-shell-users.txt.",
                "Populate it with account names from /etc/passwd whose shell ends in sh, sorted alphabetically.",
            ],
            [
                "test -f /root/rhcsa10-shell-users.txt",
                "diff -u <(awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort) /root/rhcsa10-shell-users.txt && grep -q '^root$' /root/rhcsa10-shell-users.txt",
            ],
            [
                [": > /root/rhcsa10-shell-users.txt"],
                ["awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/rhcsa10-shell-users.txt", "cat /root/rhcsa10-shell-users.txt"],
            ],
        )

    if lab_id == "lab-12-archive-gzip":
        return _replace_lab_progression(
            block,
            ["Create /root/rhcsa10-etc.tar.gz as a gzip archive containing /etc/hosts and /etc/fstab."],
            ["test -f /root/rhcsa10-etc.tar.gz && file /root/rhcsa10-etc.tar.gz | grep -qi gzip && tar -tzf /root/rhcsa10-etc.tar.gz | grep -Eq 'etc/(hosts|fstab)'"],
            [["tar -czf /root/rhcsa10-etc.tar.gz /etc/hosts /etc/fstab", "tar -tzf /root/rhcsa10-etc.tar.gz"]],
        )

    if lab_id == "lab-13-links":
        checks = list(block.get("checks", []))
        checks[1] = "test -f /root/rhcsa10-original && test -f /root/rhcsa10-hard && test \"$(stat -c %i /root/rhcsa10-original)\" = \"$(stat -c %i /root/rhcsa10-hard)\""
        updated = dict(block)
        updated["checks"] = checks
        return updated

    if lab_id == "lab-16-password-aging":
        checks = list(block.get("checks", []))
        checks[2] = "chage -l aging10 | grep -Eq 'warning.*7|Warning.*7' && getent shadow aging10 | awk -F: '$6 == 7 {ok=1} END {exit !ok}'"
        updated = dict(block)
        updated["checks"] = checks
        return updated

    if lab_id == "lab-21-selinux-restorecon":
        return _replace_lab_progression(
            block,
            ["Restore the default SELinux context on /var/www/html/rhcsa10.html."],
            ["test \"$(cat /var/www/html/rhcsa10.html)\" = RHCSA10 && ls -Z /var/www/html/rhcsa10.html | grep -q httpd_sys_content_t"],
            [["restorecon -v /var/www/html/rhcsa10.html", "ls -Z /var/www/html/rhcsa10.html"]],
        )

    if lab_id == "lab-23-selinux-boolean":
        return _replace_lab_progression(
            block,
            [
                "Enable the httpd_can_network_connect SELinux boolean immediately.",
                "Make the httpd_can_network_connect SELinux boolean persistent.",
            ],
            [
                "getsebool httpd_can_network_connect | grep -Eq -- '--> on$'",
                "semanage boolean -l -C | grep -E '^httpd_can_network_connect\\s+\\(on\\s*,\\s*on\\)'",
            ],
            [
                ["setsebool httpd_can_network_connect on"],
                ["setsebool -P httpd_can_network_connect on", "semanage boolean -l | grep httpd_can_network_connect"],
            ],
        )

    if lab_id == "lab-28-chrony-client":
        return _replace_lab_progression(
            block,
            [
                "On client, install chrony if needed.",
                "On client, configure server as the only NTP source.",
                "On client, enable and start chronyd.",
            ],
            [
                "rpm -q chrony >/dev/null",
                "grep -Eq '^server server iburst$' /etc/chrony.conf",
                "systemctl is-enabled chronyd | grep -qx enabled && systemctl is-active chronyd | grep -qx active",
            ],
            [
                ["dnf install -y chrony"],
                [
                    "sed -i '/^pool /d;/^server /d' /etc/chrony.conf",
                    "echo 'server server iburst' >> /etc/chrony.conf",
                ],
                ["systemctl enable --now chronyd", "chronyc sources || true"],
            ],
        )

    if lab_id == "lab-29-default-target":
        return _retarget_lab_to_server(_replace_lab_progression(
            block,
            ["Set the default systemd target to multi-user.target without rebooting."],
            ["systemctl get-default | grep -qx multi-user.target && readlink /etc/systemd/system/default.target | grep -q multi-user.target"],
            [["systemctl set-default multi-user.target", "systemctl get-default"]],
        ))

    if lab_id == "lab-30-systemd-service":
        checks = list(block.get("checks", []))
        checks[1] = "test -f /etc/systemd/system/rhcsa10-service.service && grep -Fqx 'ExecStart=/usr/local/sbin/rhcsa10-service.sh' /etc/systemd/system/rhcsa10-service.service"
        checks[2] = "systemctl is-enabled rhcsa10-service.service | grep -qx enabled && grep -qx SERVICE10 /var/tmp/rhcsa10-service.out"
        commands = [list(command_group) for command_group in block.get("solution_commands", [])]
        if len(commands) >= 3:
            commands[2] = [
                "restorecon -v /usr/local/sbin/rhcsa10-service.sh /etc/systemd/system/rhcsa10-service.service || true",
                "systemctl daemon-reload",
                "systemctl enable --now rhcsa10-service.service",
            ]
        updated = dict(block)
        updated["checks"] = checks
        updated["solution_commands"] = commands
        return _retarget_lab_to_server(updated)

    if lab_id in {
        "lab-24-process-priority",
        "lab-26-persistent-journal",
        "lab-31-systemd-timer",
    }:
        return _retarget_lab_to_server(block)

    if lab_id == "lab-34-grub-argument":
        return _replace_lab_progression(
            block,
            ["Add kernel argument audit_backlog_limit=8192 persistently and regenerate the GRUB configuration."],
            ["grubby --info=ALL | grep -q 'audit_backlog_limit=8192' && grubby --default-kernel >/dev/null"],
            [["grubby --update-kernel=ALL --args='audit_backlog_limit=8192'", "grub2-mkconfig -o /boot/grub2/grub.cfg"]],
        )

    if lab_id == "lab-36-xfs-label-mount":
        checks = list(block.get("checks", []))
        checks[1] = "test -d /mnt/rhcsa10data"
        checks[2] = "findmnt -no TARGET /mnt/rhcsa10data | grep -qx /mnt/rhcsa10data && grep -Eq '^LABEL=RHCSA10DATA[[:space:]]+/mnt/rhcsa10data[[:space:]]+xfs[[:space:]]+defaults' /etc/fstab"
        commands = [list(command_group) for command_group in block.get("solution_commands", [])]
        if commands:
            commands[0] = [
                "parted -s /dev/sdb mklabel gpt mkpart primary xfs 1MiB 512MiB",
                "partprobe /dev/sdb || true",
                "udevadm settle",
                "mkfs.xfs -f -L RHCSA10DATA /dev/sdb1",
            ]
        updated = dict(block)
        updated["checks"] = checks
        updated["solution_commands"] = commands
        return updated

    if lab_id == "lab-37-swap":
        checks = list(block.get("checks", []))
        checks[0] = "blkid /dev/sdb1 | grep -q 'TYPE=\"swap\"'"
        checks[1] = "swapon --show=NAME --noheadings | grep -qx /dev/sdb1"
        updated = dict(block)
        updated["checks"] = checks
        return updated

    if lab_id == "lab-38-lvm-create":
        return _replace_lab_progression(
            block,
            [
                "Create physical volume /dev/sdb.",
                "Create volume group vg10.",
                "Create a 384 MiB logical volume lvdata formatted with XFS and mounted at /mnt/lvdata10 persistently.",
            ],
            [
                "pvs /dev/sdb >/dev/null",
                "vgs vg10 >/dev/null",
                "lvs /dev/vg10/lvdata >/dev/null && findmnt -no TARGET /mnt/lvdata10 | grep -qx /mnt/lvdata10 && grep -Eq '/dev/vg10/lvdata[[:space:]]+/mnt/lvdata10[[:space:]]+xfs' /etc/fstab",
            ],
            [
                [
                "wipefs -a /dev/sdb >/dev/null 2>&1 || true",
                "sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true",
                "pvcreate -ff -y /dev/sdb",
                ],
                ["vgcreate vg10 /dev/sdb"],
                [
                    "lvcreate -L 384M -n lvdata vg10",
                    "mkfs.xfs -f /dev/vg10/lvdata",
                    "mkdir -p /mnt/lvdata10",
                    "echo '/dev/vg10/lvdata /mnt/lvdata10 xfs defaults 0 0' >> /etc/fstab",
                    "mount -a",
                ],
            ],
        )

    if lab_id == "lab-39-lvm-extend":
        return _replace_lab_progression(
            block,
            [
                "Create volume group grow10 on /dev/sdb.",
                "Create logical volume growlv with size 384 MiB and XFS filesystem mounted at /mnt/grow10.",
                "Extend the logical volume and filesystem to at least 512 MiB.",
            ],
            [
                "vgs grow10 >/dev/null",
                "lvs /dev/grow10/growlv >/dev/null && findmnt -no TARGET /mnt/grow10 | grep -qx /mnt/grow10",
                "test $(lvs --noheadings -o LV_SIZE --units m --nosuffix /dev/grow10/growlv | awk '{printf \"%d\", $1}') -ge 512",
            ],
            [
                [
                    "wipefs -a /dev/sdb >/dev/null 2>&1 || true",
                    "sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true",
                    "pvcreate -ff -y /dev/sdb",
                    "vgcreate grow10 /dev/sdb",
                ],
                [
                    "lvcreate -L 384M -n growlv grow10",
                    "mkfs.xfs -f /dev/grow10/growlv",
                    "mkdir -p /mnt/grow10",
                    "mount /dev/grow10/growlv /mnt/grow10",
                ],
                ["lvextend -L 512M -r /dev/grow10/growlv"],
            ],
        )

    if lab_id == "lab-40-vfat-filesystem":
        checks = list(block.get("checks", []))
        checks[0] = "test -b /dev/sdb1"
        checks[1] = "blkid /dev/sdb1 | grep -q 'TYPE=\"vfat\"' && blkid /dev/sdb1 | grep -q 'LABEL_FATBOOT=\"RHCSA10VFAT\"\\|LABEL=\"RHCSA10VFAT\"'"
        checks[2] = "findmnt -no TARGET /mnt/vfat10 | grep -qx /mnt/vfat10 && grep -Eq '^LABEL=RHCSA10VFAT[[:space:]]+/mnt/vfat10[[:space:]]+vfat' /etc/fstab"
        updated = dict(block)
        updated["checks"] = checks
        return updated

    if lab_id == "lab-41-nfs-mount":
        return _replace_lab_progression(
            block,
            [
                "On client, create mount point /mnt/serverdirect10.",
                "On client, mount server:/exports/direct at /mnt/serverdirect10.",
                "On client, make the mount persistent across reboots.",
            ],
            [
                "test -d /mnt/serverdirect10",
                "findmnt -no SOURCE,TARGET /mnt/serverdirect10 | grep -qx 'server:/exports/direct /mnt/serverdirect10'",
                "grep -Eq '^server:/exports/direct[[:space:]]+/mnt/serverdirect10[[:space:]]+nfs' /etc/fstab",
            ],
            [
                ["mkdir -p /mnt/serverdirect10"],
                ["mount -t nfs server:/exports/direct /mnt/serverdirect10"],
                ["grep -Eq '^server:/exports/direct[[:space:]]+/mnt/serverdirect10[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/direct /mnt/serverdirect10 nfs defaults,_netdev 0 0' >> /etc/fstab"],
            ],
        )

    if lab_id == "lab-42-autofs":
        return _replace_lab_progression(
            block,
            [
                "On client, create the autofs parent mount point /remote10.",
                "On client, configure /remote10/projects to automount server:/exports/autofs/projects.",
                "On client, enable and start autofs.",
            ],
            [
                "test -d /remote10",
                "grep -Eq '^/remote10[[:space:]]+/etc/auto.remote10' /etc/auto.master.d/rhcsa10.autofs",
                "systemctl is-enabled autofs | grep -qx enabled && systemctl is-active autofs | grep -qx active",
            ],
            [
                ["mkdir -p /remote10"],
                [
                    "echo '/remote10 /etc/auto.remote10' > /etc/auto.master.d/rhcsa10.autofs",
                    "echo 'projects -ro server:/exports/autofs/projects' > /etc/auto.remote10",
                ],
                ["systemctl enable --now autofs", "ls /remote10/projects || true"],
            ],
        )

    if lab_id == "lab-45-secure-copy":
        return _replace_lab_progression(
            block,
            [
                "On client, create /root/rhcsa10-transfer.txt containing TRANSFER10.",
                "On client, copy the file to server:/root/rhcsa10-transfer.txt.",
            ],
            [
                "test -f /root/rhcsa10-transfer.txt",
                "# server test \"$(cat /root/rhcsa10-transfer.txt)\" = TRANSFER10",
            ],
            [
                ["echo TRANSFER10 > /root/rhcsa10-transfer.txt"],
                [
                    "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/runtime_generated_ed25519 /root/rhcsa10-transfer.txt root@server:/root/rhcsa10-transfer.txt",
                    "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/runtime_generated_ed25519 root@server 'cat /root/rhcsa10-transfer.txt'",
                ],
            ],
            points=[10, 20],
        )

    if lab_id == "lab-46-package-file-install":
        return _replace_lab_progression(
            block,
            ["Install the local tree RPM from /var/www/html/repo or the mounted ISO without enabling external repositories."],
            ["command -v tree >/dev/null && rpm -q tree >/dev/null"],
            [[
                "dnf install -y --disablerepo='*' --enablerepo=rhcsa-baseos --enablerepo=rhcsa-appstream tree",
                "rpm -q tree",
            ]],
        )

    if lab_id == "lab-47-documentation":
        return _replace_lab_progression(
            block,
            ["Write the first usage summary for useradd to /root/rhcsa10-man.txt using local documentation."],
            ["test -s /root/rhcsa10-man.txt && grep -Eqi 'SYNOPSIS|Usage:.*useradd' /root/rhcsa10-man.txt"],
            [[
                "if man useradd >/tmp/rhcsa10-useradd-man.txt 2>/dev/null; then man useradd | col -b | grep -m1 -A1 '^SYNOPSIS' > /root/rhcsa10-man.txt; else useradd --help | grep -m1 -A1 '^Usage' > /root/rhcsa10-man.txt; fi",
                "cat /root/rhcsa10-man.txt",
            ]],
        )

    if lab_id == "lab-48-service-network-boot":
        return _replace_lab_progression(
            block,
            [
                "Create /var/www/html/rhcsa10-boot.html containing BOOT10.",
                "Enable and start httpd.",
                "Allow the http service permanently in firewalld.",
            ],
            [
                "test \"$(cat /var/www/html/rhcsa10-boot.html 2>/dev/null)\" = BOOT10",
                "systemctl is-enabled httpd | grep -qx enabled && systemctl is-active httpd | grep -qx active",
                "firewall-cmd --permanent --query-service=http && firewall-cmd --query-service=http",
            ],
            [
                ["mkdir -p /var/www/html", "echo BOOT10 > /var/www/html/rhcsa10-boot.html", "restorecon -v /var/www/html/rhcsa10-boot.html || true"],
                ["systemctl enable --now httpd"],
                ["firewall-cmd --permanent --add-service=http", "firewall-cmd --reload"],
            ],
        )

    return block


def _write_scenario_scripts(scenario_root: Path, scripts: dict[str, str]) -> dict[str, str] | None:
    scripts_dir = scenario_root / "scripts"
    vm_scripts: dict[str, str] = {}

    for machine_name, content in scripts.items():
        relative_path = f"scripts/{machine_name}.sh"
        write_script(scenario_root / relative_path, content.rstrip() + "\n")
        vm_scripts[machine_name] = relative_path

    for machine_name in ("client", "server"):
        if machine_name in scripts:
            continue
        _remove_path(scripts_dir / f"{machine_name}.sh")

    _cleanup_scripts_dir(scripts_dir)
    return vm_scripts or None


def _update_lab_manifest(manifest_path: Path, client_scripts: dict[str, str], server_scripts: dict[str, str]) -> None:
    manifest = _load_manifest(manifest_path)
    scenario_root = manifest_path.parent
    lab_id = str(manifest["id"])
    lab_block = dict(manifest.get("content", {}).get("lab", {}))
    lab_block = _repair_lab_progression(lab_id, lab_block)
    manifest.setdefault("content", {})["lab"] = normalize_lab_block(lab_block)

    scenario_scripts: dict[str, str] = {}
    if lab_id in client_scripts:
        scenario_scripts["client"] = client_scripts[lab_id]
    if lab_id in server_scripts:
        scenario_scripts["server"] = server_scripts[lab_id]

    manifest["tracks"] = ["rhcsa10"]
    manifest["rhel_major"] = 10
    manifest["supported_modes"] = ["lab"]
    manifest["vm_scripts"] = _write_scenario_scripts(scenario_root, scenario_scripts)
    manifest.setdefault("flags", {})
    manifest["flags"]["password_recovery"] = lab_id == "lab-35-root-recovery"
    server_prerequisite_labs = {
        "lab-06-flatpak-remote",
        "lab-07-flatpak-package",
        "lab-05-rpm-packages",
    }
    has_server_task = any(re.search(r"\bon server\b", str(task), re.I) for task in lab_block.get("tasks", []))
    manifest["flags"]["requires_server"] = (
        bool(manifest["flags"].get("requires_server"))
        or ("server" in scenario_scripts)
        or (lab_id in server_prerequisite_labs)
        or has_server_task
    )

    write_json(manifest_path, manifest)


def _exam_seed_from_id(exam_id: str) -> int:
    match = re.fullmatch(r"rhcsa10-mock-exam-([a-h])", exam_id.strip())
    if not match:
        raise ValueError(f"Unsupported RHCSA10 exam id '{exam_id}'.")
    return ord(match.group(1)) - ord("a")


def _repair_exam_progression(exam_id: str, block: dict[str, Any]) -> dict[str, Any]:
    """Fix RHCSA10 exam tasks/checks that depended on old Vagrant NIC names."""
    updated = dict(block)
    tasks = list(updated.get("tasks", []))
    checks = list(updated.get("checks", []))
    commands = [list(command_group) for command_group in updated.get("solution_commands", [])]

    if exam_id == "rhcsa10-mock-exam-g":
        for index, task in enumerate(tasks):
            task_text = str(task)
            if "server:/exports/shareg" not in task_text and "Authorized exam-g server" not in task_text:
                continue
            tasks[index] = "(server) Set the server login message in /etc/motd to Authorized exam-g server."
            if index < len(checks):
                checks[index] = _ssh_server_check("grep -qx 'Authorized exam-g server' /etc/motd")
            if index < len(commands):
                commands[index] = [
                    "# On server:",
                    "echo 'Authorized exam-g server' > /etc/motd",
                ]

        for field_name in ("hints", "solution_outline"):
            values = [str(value) for value in updated.get(field_name, [])]
            updated[field_name] = [value.replace("NFS and package tasks", "server-side and package tasks") for value in values]

    for index, task in enumerate(tasks):
        task_text = str(task)
        match = re.fullmatch(
            r"Set System eth1 to ([0-9.]+/\d+) with gateway 192\.168\.122\.1 and DNS 192\.168\.122\.3\.",
            task_text,
        ) or re.fullmatch(
            r"Configure the active lab connection with IPv4 address ([0-9.]+/\d+), gateway 192\.168\.122\.1, and DNS 192\.168\.122\.3\.",
            task_text,
        )
        if not match:
            continue

        address = match.group(1)
        tasks[index] = (
            f"Configure System eth1 with IPv4 address {address}, "
            "gateway 192.168.122.1, and DNS 192.168.122.3."
        )

        if index < len(checks):
            checks[index] = private_connection_check(
                f"nmcli -g ipv4.addresses connection show \"$connection_name\" | grep -qx '{address}' "
                "&& nmcli -g ipv4.gateway connection show \"$connection_name\" | grep -qx '192.168.122.1' "
                "&& nmcli -g ipv4.dns connection show \"$connection_name\" | grep -qx '192.168.122.3' "
                "&& nmcli -g ipv4.method connection show \"$connection_name\" | grep -qx manual"
            )

        if index < len(commands):
            commands[index] = private_connection_commands(
                f'nmcli connection modify "$connection_name" ipv4.addresses {address} '
                "ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 "
                "ipv4.method manual connection.autoconnect yes",
                'nmcli connection up "$connection_name"',
            )

    for command_group in commands:
        for command_index, command in enumerate(command_group):
            if str(command).startswith("lvcreate -L 256M -n data"):
                command_group[command_index] = str(command).replace("-L 256M", "-L 384M", 1)

    exam_repo_commands = [
        "cat > /etc/yum.repos.d/rhcsa10-exam.repo <<'EOF'\n"
        "[rhcsa10-exam-baseos]\n"
        "name=RHCSA10 Exam BaseOS\n"
        "baseurl=http://server/repo/BaseOS/\n"
        "enabled=1\n"
        "gpgcheck=0\n"
        "\n"
        "[rhcsa10-exam-appstream]\n"
        "name=RHCSA10 Exam AppStream\n"
        "baseurl=http://server/repo/AppStream/\n"
        "enabled=1\n"
        "gpgcheck=0\n"
        "EOF",
        "dnf clean all",
    ]
    for index, command_group in enumerate(commands):
        joined_group = "\n".join(str(command) for command in command_group)
        if "dnf install -y lsof" not in joined_group and "dnf remove -y tcpdump" not in joined_group:
            continue
        if any("rhcsa10-exam.repo" in str(command) for command in command_group):
            continue
        commands[index] = [*exam_repo_commands, *command_group]

    for index, task in enumerate(tasks):
        if "persistent systemd journal storage" not in str(task).lower():
            continue
        if index < len(commands):
            commands[index] = [
                "mkdir -p /var/log/journal",
                "install -D -m 0644 /dev/null /etc/systemd/journald.conf",
                "grep -q '^Storage=' /etc/systemd/journald.conf && sed -i 's/^Storage=.*/Storage=persistent/' /etc/systemd/journald.conf || echo 'Storage=persistent' >> /etc/systemd/journald.conf",
                "systemctl restart systemd-journald",
            ]
        if index < len(checks):
            check_command = "test -d /var/log/journal && grep -Eq '^Storage=persistent$' /etc/systemd/journald.conf"
            checks[index] = _ssh_server_check(check_command) if re.search(r"\bon server\b|\(server\)", str(tasks[index]), re.I) else check_command

    for index, task in enumerate(tasks):
        if index >= len(checks):
            continue
        task_text = str(task).lower()
        if "on server, create the same baseos and appstream repository definitions" in task_text:
            checks[index] = _ssh_server_check(
                "grep -ERq '^baseurl=http://server/repo/BaseOS/?$' /etc/yum.repos.d && "
                "grep -ERq '^baseurl=http://server/repo/AppStream/?$' /etc/yum.repos.d"
            )

    exam_task_orders = {
        "rhcsa10-mock-exam-c": [0, 1, 14, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21],
        "rhcsa10-mock-exam-d": [0, 1, 17, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 19, 20, 21],
        "rhcsa10-mock-exam-e": [0, 1, 14, 15, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 16, 17, 18, 19, 20, 21],
        "rhcsa10-mock-exam-f": [0, 1, 21, 14, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20],
        "rhcsa10-mock-exam-h": [0, 1, 17, 21, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 19, 20],
    }
    order = exam_task_orders.get(exam_id)
    if order and sorted(order) == list(range(len(tasks))):
        tasks = _reorder_parallel(tasks, order)
        checks = _reorder_parallel(checks, order)
        commands = _reorder_parallel(commands, order)
        if len(updated.get("task_points", [])) == len(order):
            updated["task_points"] = _reorder_parallel(list(updated["task_points"]), order)

    updated["tasks"] = tasks
    updated["checks"] = checks
    updated["solution_commands"] = commands
    updated["task_titles"] = [task_title(task) for task in tasks]
    return updated


def _update_exam_manifest(manifest_path: Path) -> None:
    manifest = _load_manifest(manifest_path)
    scenario_root = manifest_path.parent
    seed = _exam_seed_from_id(str(manifest["id"]))
    client_script, server_script = _exam_scripts(seed)
    exam_block = dict(manifest.get("content", {}).get("exam", {}))

    manifest["tracks"] = ["rhcsa10"]
    manifest["rhel_major"] = 10
    manifest["supported_modes"] = ["exam"]
    manifest.setdefault("content", {})["exam"] = _repair_exam_progression(str(manifest["id"]), exam_block)
    if str(manifest["id"]) == "rhcsa10-mock-exam-g":
        manifest["description"] = (
            "Recovery + server administration focus: root password recovery, server-side login policy, "
            "process management, file search, systemd timers, swap, and LVM storage."
        )
    manifest.setdefault("flags", {})
    manifest["flags"]["requires_server"] = True
    manifest["vm_scripts"] = _write_scenario_scripts(
        scenario_root,
        {
            "client": client_script,
            "server": server_script,
        },
    )

    write_json(manifest_path, manifest)


def regenerate_rhcsa10_scenarios() -> None:
    client_scripts = _lab_client_scripts()
    server_scripts = _lab_server_scripts()

    for manifest_path in sorted(LABS_ROOT.glob("*/scenario.json")):
        _update_lab_manifest(manifest_path, client_scripts, server_scripts)

    for manifest_path in sorted(EXAMS_ROOT.glob("*/scenario.json")):
        _update_exam_manifest(manifest_path)

    generate_scenario_markdown()


def main() -> int:
    regenerate_rhcsa10_scenarios()
    return 0
if __name__ == "__main__":
    raise SystemExit(main())
