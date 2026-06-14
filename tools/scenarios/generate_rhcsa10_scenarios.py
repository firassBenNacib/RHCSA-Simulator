#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import shutil
import textwrap
from pathlib import Path
from typing import Any

from generate_scenario_markdown import main as generate_scenario_markdown
from rhcsa_scenarios.lab_normalization import normalize_lab_block
from rhcsa_scenarios.targets import (
    infer_check_target,
    infer_solution_target,
    infer_task_target,
    normalize_authored_wording,
    normalize_title_capitalization,
    prefix_task_target,
    scope_from_targets,
)


ROOT = Path(__file__).resolve().parents[2]
LABS_ROOT = ROOT / "scenarios" / "labs" / "rhcsa10"
EXAMS_ROOT = ROOT / "scenarios" / "exams" / "rhcsa10"


CLIENT_SCRIPT_HEADER = "#!/usr/bin/env bash\nset -euo pipefail\nsource /usr/local/lib/rhcsa-scenario-helpers.sh\n"
SERVER_SCRIPT_HEADER = "#!/usr/bin/env bash\nset -euo pipefail\nsource /usr/local/lib/rhcsa-scenario-helpers.sh\n"
FLATPAK_REPO_SETUP = """rhcsa_reset_repo_directory /root/.repo-backup-flatpak rhcsa-flatpak.repo
cat > /etc/yum.repos.d/rhcsa-flatpak.repo <<'EOF'
[rhcsa-flatpak-baseos]
name=RHCSA Flatpak BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0

[rhcsa-flatpak-appstream]
name=RHCSA Flatpak AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
"""

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
    rendered = content.replace("\r\n", "\n").replace("\r", "\n")
    if not rendered.endswith("\n"):
        rendered += "\n"
    encoded = rendered.encode("utf-8")
    if not path.exists() or path.read_bytes() != encoded:
        path.write_text(rendered, encoding="utf-8", newline="\n")
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
        "title": normalize_title_capitalization(title),
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
    for prefix in ("On client and server, ", "On server and client, ", "On client, ", "On server, ", "As root, "):
        if line.startswith(prefix):
            line = line[len(prefix):]
    specific = specific_task_title(line)
    if specific:
        return normalize_title_capitalization(specific)
    first_sentence = re.split(r"\.\s+", line, maxsplit=1)[0].strip()
    if 12 <= len(first_sentence) <= 72:
        line = first_sentence
    line = textwrap.shorten(line, width=72, placeholder="", break_long_words=False, break_on_hyphens=False)
    line = line.rstrip(" ,;:-_/.")
    if line:
        line = line[0].upper() + line[1:]
    return normalize_title_capitalization(line)


def specific_task_title(line: str) -> str:
    lowered = line.lower()
    patterns = [
        (r"recover root access", "Recover root password"),
        (r"set the hostname|set hostname", "Set hostname"),
        (r"configure (the )?(network connection|system eth1|eth1)", "Configure eth1 networking"),
        (r"(bootloader|kernel boot argument|default grub)", "Persist kernel boot argument"),
        (r"baseos.*appstream.*repositor", "Configure BaseOS and AppStream repositories"),
        (r"flatpak remote(?: named)?\s+([a-z0-9_-]+).*?(pointing to|file://)", None),
        (r"install org\.rhcsa\.tools", "Install Flatpak application"),
        (r"ensure org\.rhcsa\.tools is not installed", "Remove Flatpak application"),
        (r"allow members of .*sudo|allow .* to run .*sudo", "Configure sudo access"),
        (r"password aging|maximum password age", "Configure password aging"),
        (r"(/usr/local/bin/[a-z0-9_-]+|primary group)", "Create user lookup script"),
        (r"write all usernames", "List shell users"),
        (r"exam-[a-h]-report.*copy|copy it to", "Copy exam report to server"),
        (r"save the output of https?://", "Save web service response"),
        (r"distribute the public key|generate an ssh key pair.*copy", "Configure SSH key authentication"),
        (r"publish /var/www/html", "Publish web content"),
        (r"create and enable .*\.timer", "Configure systemd timer"),
        (r"create volume group", "Create volume group"),
        (r"create group .* user .* add|create group .* and user", "Create user and group"),
        (r"httpd_can_network_connect", "Persist SELinux boolean"),
        (r"persistent systemd journal|journald", "Enable persistent journal"),
        (r"chronyd|chrony", "Configure chrony time source"),
        (r"export /exports|server:/exports", "Configure NFS export and mount"),
        (r"gzip archive|tar\.gz", "Create gzip archive"),
        (r"cron job", "Schedule cron job"),
        (r"at job", "Schedule at job"),
        (r"swap partition", "Configure persistent swap"),
        (r"physical volume.*logical volume|logical volume", "Configure LVM storage"),
        (r"route local[0-9]", "Route rsyslog messages"),
    ]
    for pattern, title in patterns:
        match = re.search(pattern, lowered)
        if not match:
            continue
        if title is None and "flatpak remote" in pattern:
            remote = match.group(1) if match.groups() else ""
            return f"Configure Flatpak remote {remote}" if remote else "Configure Flatpak remote"
        return title or ""
    return ""


def exam_client_ip(letter: str) -> str:
    return f"192.168.122.{60 + ord(letter) - ord('a')}"


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
""" + FLATPAK_REPO_SETUP + """
dnf remove -y flatpak >/dev/null 2>&1 || true
flatpak remote-delete --system rhcsa10 >/dev/null 2>&1 || true
"""

    scripts["lab-07-flatpak-package"] = h + """
""" + FLATPAK_REPO_SETUP + """
rpm -q flatpak >/dev/null 2>&1 || dnf install -y flatpak >/dev/null 2>&1 || true
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
rm -f /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf /etc/systemd/journald.conf.d/persistent.conf
sed -i '/^[[:space:]]*Storage[[:space:]]*=.*persistent/d' /etc/systemd/journald.conf >/dev/null 2>&1 || true
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
swap_uuid="$(blkid -s UUID -o value /dev/sdb1 2>/dev/null || true)"
swapoff /dev/sdb1 2>/dev/null || true
if [ -n "$swap_uuid" ]; then
  sed -i "\\#^UUID=$swap_uuid[[:space:]]#d;\\#^/dev/disk/by-uuid/$swap_uuid[[:space:]]#d" /etc/fstab
fi
sed -i '\\#^/dev/sdb1[[:space:]]#d' /etc/fstab
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
partprobe /dev/sdb >/dev/null 2>&1 || true
udevadm settle
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
partprobe /dev/sdb >/dev/null 2>&1 || true
udevadm settle
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

    scripts["lab-05-rpm-packages"] = h + """
rhcsa_reset_repo_directory /root/.repo-backup-server-lab05 rhcsa-local.repo
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
dnf remove -y lsof >/dev/null 2>&1 || true
"""

    scripts["lab-06-flatpak-remote"] = h + """
rhcsa_reset_repo_directory /root/.repo-backup-server-flatpak rhcsa-flatpak.repo
"""

    scripts["lab-07-flatpak-package"] = h + """
dnf install -y flatpak >/dev/null 2>&1 || true
rm -rf /opt/rhcsa/flatpak/repo
"""

    scripts["lab-18-ssh-key-auth"] = h + """
userdel -r key10 >/dev/null 2>&1 || true
"""

    scripts["lab-19-firewalld-service"] = h + """
systemctl disable --now firewalld >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-service=https >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
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
systemctl restart systemd-journald >/dev/null 2>&1 || true
rm -rf /var/log/journal
rm -f /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf /etc/systemd/journald.conf.d/persistent.conf
sed -i '/^[[:space:]]*Storage[[:space:]]*=.*persistent/d' /etc/systemd/journald.conf 2>/dev/null || true
"""

    scripts["lab-27-rsyslog-logger"] = h + """
rm -f /etc/rsyslog.d/rhcsa10.conf /var/log/rhcsa10-local7.log
systemctl disable --now rsyslog >/dev/null 2>&1 || true
"""

    scripts["lab-28-chrony-client"] = h + """
dnf install -y chrony >/dev/null 2>&1 || true
cat > /etc/chrony.conf <<'EOF'
driftfile /var/lib/chrony/drift
pool 2.rhel.pool.ntp.org iburst
makestep 1.0 3
logdir /var/log/chrony
EOF
systemctl disable --now chronyd >/dev/null 2>&1 || true
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

    scripts["lab-32-cron"] = h + """
userdel -r cron10 >/dev/null 2>&1 || true
systemctl disable --now crond >/dev/null 2>&1 || true
"""

    scripts["lab-33-at-job"] = h + """
userdel -r at10 >/dev/null 2>&1 || true
systemctl disable --now atd >/dev/null 2>&1 || true
"""

    scripts["lab-43-sticky-directory"] = h + """
groupdel share10 >/dev/null 2>&1 || true
rm -rf /srv/share10
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

    scripts["lab-46-package-file-install"] = h + """
rhcsa_reset_repo_directory /root/.repo-backup-server-lab46 rhcsa-local.repo
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
dnf remove -y tree >/dev/null 2>&1 || true
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

    scripts["lab-48-service-network-boot"] = h + """
systemctl disable --now httpd >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-service=http >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
rm -f /var/www/html/rhcsa10-boot.html
"""

    return scripts


def _exam_scripts(seed: int) -> tuple[str, str]:
    """Return (client.sh content, server.sh content) for a given exam seed."""
    letter = chr(ord("a") + seed)
    user = f"user{letter}10"
    group = f"team{letter}10"
    remote = f"exam{letter}flatpak"
    timer = f"exam{letter}timer"
    exam_extra_client_reset = ""
    exam_extra_server_reset = "\n"
    if letter == "g":
        exam_extra_client_reset += """
# --- Exam G find dataset and users ---
userdel -r grant10 >/dev/null 2>&1 || true
userdel -r hazel10 >/dev/null 2>&1 || true
userdel -r copy10 >/dev/null 2>&1 || true
userdel -r noaccess70 >/dev/null 2>&1 || true
groupdel devg10 >/dev/null 2>&1 || true
rm -rf /srv/devg10 /opt/exam-g/find /home/hazel10 /home/grant10 /home/copy10
mkdir -p /opt/exam-g/find/recent /opt/exam-g/find/archive
echo 'grant recent' > /opt/exam-g/find/recent/grant-a.txt
echo 'grant archive' > /opt/exam-g/find/archive/grant-old.txt
echo 'root recent' > /opt/exam-g/find/recent/root-a.txt
touch -d '2 days ago' /opt/exam-g/find/archive/grant-old.txt
chown 3017:0 /opt/exam-g/find/recent/grant-a.txt /opt/exam-g/find/archive/grant-old.txt
chown root:root /opt/exam-g/find/recent/root-a.txt
mkdir -p /usr/share/dict
cat > /usr/share/dict/words <<'EOFWORDS'
alpha
database
metadata
kernel
EOFWORDS
"""
    if letter == "d":
        exam_extra_client_reset += """
# --- Exam D service and logging cleanup ---
systemctl disable --now examd-heartbeat.service >/dev/null 2>&1 || true
rm -f /etc/systemd/system/examd-heartbeat.service /usr/local/sbin/examd-heartbeat.sh /var/log/examd-heartbeat.log
rm -f /etc/rsyslog.d/examd-local5.conf /var/log/examd-local5.log
systemctl daemon-reload >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-service=http >/dev/null 2>&1 || true
firewall-cmd --remove-service=http >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
"""
    if letter == "b":
        exam_extra_client_reset += """
# --- Exam B permissions and package cleanup ---
userdel -r auditorb10 >/dev/null 2>&1 || true
dnf remove -y tree >/dev/null 2>&1 || true
rm -rf /srv/teamb10
"""
    if letter == "c":
        exam_extra_client_reset += """
# --- Exam C web service cleanup ---
systemctl disable --now httpd >/dev/null 2>&1 || true
rm -f /etc/httpd/conf.d/examc-port.conf /var/www/html/examc.html
: > /etc/motd
"""
    if letter == "e":
        exam_extra_client_reset += """
# --- Exam E label filesystem cleanup ---
umount /mnt/exame-label >/dev/null 2>&1 || true
sed -i '\\#/mnt/exame-label#d' /etc/fstab
for dev in /dev/sdc[0-9]* /dev/sdc; do
    [ -e "$dev" ] || continue
    wipefs -a "$dev" >/dev/null 2>&1 || true
done
sgdisk --zap-all /dev/sdc >/dev/null 2>&1 || true
partprobe /dev/sdc >/dev/null 2>&1 || true
rm -rf /mnt/exame-label
rm -f /root/e-useradd-help.txt
"""
    if letter == "f":
        exam_extra_client_reset += """
# --- Exam F storage and service cleanup ---
swapoff /dev/sdc1 >/dev/null 2>&1 || true
sed -i '/[[:space:]]swap[[:space:]]/d' /etc/fstab
for dev in /dev/sdc[0-9]* /dev/sdc; do
    [ -e "$dev" ] || continue
    wipefs -a "$dev" >/dev/null 2>&1 || true
done
sgdisk --zap-all /dev/sdc >/dev/null 2>&1 || true
partprobe /dev/sdc >/dev/null 2>&1 || true
systemctl disable --now examf-cleanup.service >/dev/null 2>&1 || true
rm -f /etc/systemd/system/examf-cleanup.service /usr/local/sbin/examf-cleanup.sh /var/log/examf-cleanup.log
systemctl daemon-reload >/dev/null 2>&1 || true
rm -rf /opt/exam-f/find /root/examf-rootfiles
mkdir -p /opt/exam-f/find/a /opt/exam-f/find/b
echo FROOT > /opt/exam-f/find/a/root.conf
echo FUSER > /opt/exam-f/find/b/user.conf
chown root:root /opt/exam-f/find/a/root.conf
chown nobody:nobody /opt/exam-f/find/b/user.conf
"""
    if letter == "h":
        exam_extra_client_reset += """
# --- Exam H client marker cleanup ---
rm -f /var/tmp/examh-client.txt
"""
        exam_extra_server_reset += """
# --- Exam H server role cleanup ---
hostnamectl set-hostname server
rhcsa_remove_matching_lines 'clienth.exam10.lab' /etc/hosts
rm -f /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf /etc/systemd/journald.conf.d/persistent.conf
rm -rf /var/log/journal
rm -f /etc/rsyslog.d/examh-local6.conf /var/log/examh-local6.log
firewall-cmd --permanent --remove-port=2208/tcp >/dev/null 2>&1 || true
firewall-cmd --remove-port=2208/tcp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
"""

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
{exam_extra_client_reset}

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
rm -f /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf /etc/systemd/journald.conf.d/persistent.conf
sed -i '/^[[:space:]]*Storage[[:space:]]*=.*persistent/d' /etc/systemd/journald.conf >/dev/null 2>&1 || true

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
partprobe /dev/sdb >/dev/null 2>&1 || true
udevadm settle

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
{exam_extra_server_reset}# --- NFS cleanup ---
rm -f /etc/exports.d/exam-{letter}.exports /etc/exports.d/exam-{letter}-integrated.exports
exportfs -ar >/dev/null 2>&1 || true
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


STRICT_REPO_CHECK = (
    "awk '"
    "function flush(){"
    "if(baseurl ~ /^http:\\/\\/server\\/repo\\/BaseOS\\/?$/ && enabled == \"1\" && gpgcheck == \"0\") base=1;"
    "if(baseurl ~ /^http:\\/\\/server\\/repo\\/AppStream\\/?$/ && enabled == \"1\" && gpgcheck == \"0\") app=1"
    "}"
    "function value(){sub(/^[^=]*=/, \"\"); gsub(/^[ \\t]+|[ \\t]+$/, \"\"); return $0}"
    "/^[[:space:]]*\\[/ {flush(); baseurl=enabled=gpgcheck=\"\"; next}"
    "/^[[:space:]]*baseurl[[:space:]]*=/ {baseurl=value(); next}"
    "/^[[:space:]]*enabled[[:space:]]*=/ {enabled=value(); next}"
    "/^[[:space:]]*gpgcheck[[:space:]]*=/ {gpgcheck=value(); next}"
    "END{flush(); exit !(base && app)}"
    "' /etc/yum.repos.d/*.repo"
)
SELINUX_HTTPD_BOOLEAN_CHECK = (
    "getsebool httpd_can_network_connect | grep -Eq -- '--> on$' && "
    "semanage boolean -l -C | grep -E '^httpd_can_network_connect\\s+\\(on\\s*,\\s*on\\)'"
)
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
JOURNALD_PERSISTENT_COMMANDS = [
    "mkdir -p /var/log/journal /etc/systemd/journald.conf.d",
    "cat > /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf <<'EOF'\n[Journal]\nStorage=persistent\nEOF",
    "systemctl restart systemd-journald",
    "journalctl --flush",
]


def _flatpak_remote_check(remote: str) -> str:
    return (
        "flatpak remotes --system --columns=name,url 2>/dev/null | "
        f"awk '$1 == \"{remote}\" && $2 == \"file:///opt/rhcsa/flatpak/repo\" "
        "{found=1} END {exit !found}'"
    )


def _flatpak_installed_check() -> str:
    return "flatpak list --system --app --columns=application 2>/dev/null | grep -qx org.rhcsa.Tools"


def _flatpak_absent_check() -> str:
    return "! flatpak list --system --app --columns=application 2>/dev/null | grep -qx org.rhcsa.Tools"


def _lvm_mount_check(letter: str) -> str:
    return (
        f"lv_path=/dev/vg{letter}10/data{letter}; "
        f"mapper_path=/dev/mapper/vg{letter}10-data{letter}; "
        f"mountpoint=/mnt/data{letter}10; "
        'lv_uuid="$(blkid -s UUID -o value "$lv_path")"; '
        'lvs "$lv_path" >/dev/null 2>&1 && '
        'findmnt -no TARGET "$mountpoint" | grep -qx "$mountpoint" && '
        'awk -v dev="$lv_path" -v mapper="$mapper_path" -v uuid="$lv_uuid" -v target="$mountpoint" '
        '\'$1 !~ /^#/ && $2 == target && $3 == "xfs" && '
        '($1 == dev || $1 == mapper || $1 == "UUID=" uuid || $1 == "/dev/disk/by-uuid/" uuid) '
        "{found=1} END {exit !found}' /etc/fstab"
    )


def _swap_persistence_check(device: str = "/dev/sdb1") -> str:
    return (
        f"swap_uuid=\"$(blkid -s UUID -o value {device})\"; "
        'test -n "$swap_uuid" && '
        f"swapon --show=NAME --noheadings | grep -qx {device} && "
        f"awk -v dev=\"{device}\" -v uuid=\"$swap_uuid\" "
        '\'$1 !~ /^#/ && $2 == "swap" && $3 == "swap" && '
        '($1 == dev || $1 == "UUID=" uuid || $1 == "/dev/disk/by-uuid/" uuid) '
        "{found=1} END {exit !found}' /etc/fstab"
    )


def _nfs_mount_check(mountpoint: str) -> str:
    return (
        f"findmnt -no SOURCE,TARGET {mountpoint} | grep -qx 'server:/exports/direct {mountpoint}' && "
        f"grep -Eq '^server:/exports/direct[[:space:]]+{mountpoint}[[:space:]]+nfs([[:space:]]|$)' /etc/fstab"
    )


def _replace_exam_step(
    tasks: list[Any],
    checks: list[str],
    commands: list[list[str]],
    index: int,
    task: str,
    check: str,
    command_group: list[str],
) -> None:
    if index < len(tasks):
        tasks[index] = task
    if index < len(checks):
        checks[index] = check
    if index < len(commands):
        commands[index] = command_group


def _insert_exam_step(
    tasks: list[Any],
    checks: list[str],
    commands: list[list[str]],
    index: int,
    task: str,
    check: str,
    command_group: list[str],
) -> None:
    tasks.insert(index, task)
    checks.insert(index, check)
    commands.insert(index, command_group)


def _server_repo_commands() -> list[str]:
    return [
        "# On server:",
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


def _client_repo_commands() -> list[str]:
    return [
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


def _both_repo_step(letter: str) -> tuple[str, str, list[str]]:
    return (
        "On client and server, create enabled BaseOS and AppStream repository definitions using "
        "http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.",
        f"{STRICT_REPO_CHECK} && {_ssh_server_check(STRICT_REPO_CHECK)}",
        [*_client_repo_commands(), *_server_repo_commands()],
    )


ROOT_RECOVERY_CHECK = "echo cinder9 | su - root -c whoami 2>/dev/null | grep -qx root"


def _ensure_client_root_recovery(tasks: list[Any], checks: list[str], commands: list[list[str]]) -> None:
    existing_index = next(
        (
            index
            for index, task in enumerate(tasks)
            if "recover root access" in str(task).lower() or "root password recovery" in str(task).lower()
        ),
        None,
    )
    if existing_index is not None:
        task_text = str(tasks[existing_index]).strip()
        match = re.match(
            r"On client, recover root access from the console and set the root password to cinder9\.\s+Then\s+(.+)$",
            task_text,
            flags=re.I | re.S,
        )
        if match:
            remainder = match.group(1).strip()
            tasks[existing_index] = (
                "On client, recover root access and configure the client hostname. "
                "Set the root password to cinder9. "
                f"Then {remainder[0].lower()}{remainder[1:] if len(remainder) > 1 else ''}"
            )
        return

    target_index = next(
        (
            index
            for index, task in enumerate(tasks)
            if re.search(r"\bon client\b", str(task), re.I)
            and re.search(r"\bhostname\b", str(task), re.I)
        ),
        0,
    )

    original_task = str(tasks[target_index]).strip()
    normalized_task = re.sub(r"^\s*On client,\s*", "", original_task, flags=re.I)
    tasks[target_index] = (
        "On client, recover root access and configure the client hostname. "
        "Set the root password to cinder9. "
        f"Then {normalized_task[0].lower()}{normalized_task[1:] if len(normalized_task) > 1 else ''}"
    )
    if target_index < len(checks):
        checks[target_index] = f"{ROOT_RECOVERY_CHECK} && {checks[target_index]}"
    if target_index < len(commands):
        commands[target_index] = [
            "echo 'root:cinder9' | chpasswd",
            *commands[target_index],
        ]


def _server_hostname_step(letter: str) -> tuple[str, str, list[str]]:
    client_ip = exam_client_ip(letter)
    network_check = (
        'connection_name="System eth1"; '
        'nmcli -g NAME connection show "$connection_name" >/dev/null 2>&1 || '
        'connection_name="$(private_dev="$(ip -o -4 addr show | awk \'$4 ~ /^192\\.168\\.122\\./ {print $2; exit}\')"; '
        'nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v private_dev="$private_dev" \'$2 == private_dev {print $1; exit}\')"; '
        'test -n "$connection_name" && '
        "nmcli -g ipv4.addresses connection show \"$connection_name\" | grep -qx '192.168.122.3/24' && "
        "nmcli -g ipv4.gateway connection show \"$connection_name\" | grep -qx '192.168.122.1' && "
        "nmcli -g ipv4.dns connection show \"$connection_name\" | grep -qx '192.168.122.3' && "
        "nmcli -g ipv4.method connection show \"$connection_name\" | grep -qx manual"
    )
    return (
        "On server, configure the server hostname and persistent IPv4 networking. "
        f"Set hostname to server{letter}.exam10.lab, map client{letter}.exam10.lab to {client_ip}, "
        "and configure eth1 with address 192.168.122.3/24, gateway 192.168.122.1, "
        "and DNS resolver 192.168.122.3.",
        _ssh_server_check(
            f"hostnamectl --static | grep -qx server{letter}.exam10.lab && "
            f"awk '$1 == \"{client_ip}\" {{for (i = 2; i <= NF; i++) if ($i == \"client{letter}.exam10.lab\") found = 1}} END {{exit !found}}' /etc/hosts && "
            f"{network_check}"
        ),
        [
            "# On server:",
            f"hostnamectl set-hostname server{letter}.exam10.lab",
            f"grep -Eq '^{re.escape(client_ip)}[[:space:]]+client{letter}\\.exam10\\.lab$' /etc/hosts || echo '{client_ip} client{letter}.exam10.lab' >> /etc/hosts",
            'connection_name="System eth1"',
            'nmcli -g NAME connection show "$connection_name" >/dev/null 2>&1 || connection_name="$(private_dev="$(ip -o -4 addr show | awk \'$4 ~ /^192\\.168\\.122\\./ {print $2; exit}\')"; nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v private_dev="$private_dev" \'$2 == private_dev {print $1; exit}\')"',
            'nmcli connection modify "$connection_name" ipv4.addresses 192.168.122.3/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes',
            'nmcli connection up "$connection_name"',
        ],
    )


def _server_user_step(letter: str) -> tuple[str, str, list[str]]:
    return (
        f"On server, create group server{letter}10 and user srv{letter}10 with password cinder9, then add the user to server{letter}10.",
        _ssh_server_check(
            f"getent group server{letter}10 >/dev/null && id -nG srv{letter}10 | tr ' ' '\\n' | grep -qx server{letter}10"
        ),
        [
            "# On server:",
            f"getent group server{letter}10 >/dev/null || groupadd server{letter}10",
            f"id srv{letter}10 >/dev/null 2>&1 || useradd srv{letter}10",
            f"gpasswd -a srv{letter}10 server{letter}10",
            f"echo 'srv{letter}10:cinder9' | chpasswd",
        ],
    )


def _server_sudo_step(letter: str) -> tuple[str, str, list[str]]:
    return (
        f"On server, allow members of server{letter}10 to run /usr/bin/systemctl with sudo without a password.",
        _ssh_server_check(
            f"grep -Eq '^%server{letter}10[[:space:]]+ALL=\\(ALL\\)[[:space:]]+NOPASSWD:[[:space:]]*/usr/bin/systemctl$' "
            f"/etc/sudoers.d/server{letter}10-systemctl && visudo -cf /etc/sudoers.d/server{letter}10-systemctl >/dev/null"
        ),
        [
            "# On server:",
            f"getent group server{letter}10 >/dev/null || groupadd server{letter}10",
            f"echo '%server{letter}10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/server{letter}10-systemctl",
            f"chmod 0440 /etc/sudoers.d/server{letter}10-systemctl",
        ],
    )


def _server_http_step(letter: str, port: int) -> tuple[str, str, list[str]]:
    return (
        f"On server, publish /var/www/html/server-{letter}.html containing RHCSA10-{letter.upper()} and serve httpd on TCP port {port}.",
        _ssh_server_check(
            f"grep -Fxq RHCSA10-{letter.upper()} /var/www/html/server-{letter}.html && "
            f"grep -Eq '^Listen[[:space:]]+{port}$' /etc/httpd/conf.d/exam-{letter}-port.conf && "
            f"semanage port -l | awk '$1 == \"http_port_t\" && $2 == \"tcp\" && $0 ~ /(^|[ ,]){port}([, ]|$)/ {{found=1}} END {{exit !found}}' && "
            f"firewall-cmd --permanent --query-port={port}/tcp && firewall-cmd --query-port={port}/tcp && "
            "systemctl is-enabled httpd | grep -qx enabled && systemctl is-active httpd | grep -qx active"
        ),
        [
            "# On server:",
            "mkdir -p /var/www/html",
            f"echo RHCSA10-{letter.upper()} > /var/www/html/server-{letter}.html",
            f"restorecon -v /var/www/html/server-{letter}.html || true",
            f"cat > /etc/httpd/conf.d/exam-{letter}-port.conf <<'EOF'\nListen {port}\nEOF",
            f"semanage port -a -t http_port_t -p tcp {port} 2>/dev/null || semanage port -m -t http_port_t -p tcp {port}",
            f"firewall-cmd --permanent --add-port={port}/tcp",
            "firewall-cmd --reload",
            "systemctl enable --now httpd",
            "systemctl restart httpd",
        ],
    )


def _server_journald_step() -> tuple[str, str, list[str]]:
    return (
        "On server, enable persistent systemd journal storage.",
        _ssh_server_check(JOURNALD_PERSISTENT_CHECK),
        ["# On server:", *JOURNALD_PERSISTENT_COMMANDS],
    )


def _server_selinux_boolean_step() -> tuple[str, str, list[str]]:
    return (
        "On server, persistently enable the SELinux boolean httpd_can_network_connect.",
        _ssh_server_check(SELINUX_HTTPD_BOOLEAN_CHECK),
        [
            "# On server:",
            "setsebool -P httpd_can_network_connect on",
            "getsebool httpd_can_network_connect",
        ],
    )


def _server_timer_step(letter: str, minutes: int = 10) -> tuple[str, str, list[str]]:
    timer = f"server{letter}timer"
    return (
        f"On server, create and enable {timer}.timer so it appends SERVER-{letter.upper()} to /var/log/{timer}.log every {minutes} minutes.",
        _ssh_server_check(
            f"systemctl is-enabled {timer}.timer | grep -qx enabled && "
            f"grep -Eq '^OnCalendar=\\*:0/{minutes}$' /etc/systemd/system/{timer}.timer && "
            f"grep -Fxq 'echo SERVER-{letter.upper()} >> /var/log/{timer}.log' /usr/local/sbin/{timer}.sh"
        ),
        [
            "# On server:",
            f"cat > /usr/local/sbin/{timer}.sh <<'EOF'\n#!/bin/bash\necho SERVER-{letter.upper()} >> /var/log/{timer}.log\nEOF",
            f"chmod +x /usr/local/sbin/{timer}.sh",
            f"cat > /etc/systemd/system/{timer}.service <<'EOF'\n[Unit]\nDescription=Server {letter.upper()} timer job\n\n[Service]\nType=oneshot\nExecStart=/usr/local/sbin/{timer}.sh\nEOF",
            f"cat > /etc/systemd/system/{timer}.timer <<'EOF'\n[Unit]\nDescription=Run server {letter.upper()} timer job\n\n[Timer]\nOnCalendar=*:0/{minutes}\nPersistent=true\n\n[Install]\nWantedBy=timers.target\nEOF",
            "systemctl daemon-reload",
            f"systemctl enable --now {timer}.timer",
        ],
    )


def _server_rsyslog_step(letter: str, facility: str = "local5") -> tuple[str, str, list[str]]:
    return (
        f"On server, route {facility} log messages to /var/log/server-{letter}-{facility}.log and write a test message.",
        _ssh_server_check(
            f"grep -Eq '^{facility}\\.\\*[[:space:]]+/var/log/server-{letter}-{facility}\\.log$' "
            f"/etc/rsyslog.d/server-{letter}-{facility}.conf && "
            "systemctl is-active rsyslog | grep -qx active && "
            f"grep -Fq 'server-{letter}-{facility}' /var/log/server-{letter}-{facility}.log"
        ),
        [
            "# On server:",
            f"cat > /etc/rsyslog.d/server-{letter}-{facility}.conf <<'EOF'\n{facility}.* /var/log/server-{letter}-{facility}.log\nEOF",
            "systemctl enable --now rsyslog",
            "systemctl restart rsyslog",
            f"logger -p {facility}.info 'server-{letter}-{facility}'",
            "sleep 1",
        ],
    )


def _server_default_target_step() -> tuple[str, str, list[str]]:
    return (
        "On server, set the default boot target to multi-user.target without rebooting.",
        _ssh_server_check("systemctl get-default | grep -qx multi-user.target"),
        [
            "# On server:",
            "systemctl set-default multi-user.target",
            "systemctl get-default",
        ],
    )


def _server_shared_dir_step(letter: str) -> tuple[str, str, list[str]]:
    return (
        f"On server, create /srv/server{letter}10 owned by root:server{letter}10 with mode 2770.",
        _ssh_server_check(
            f"getent group server{letter}10 >/dev/null && stat -c '%U:%G:%a' /srv/server{letter}10 | grep -qx root:server{letter}10:2770"
        ),
        [
            "# On server:",
            f"getent group server{letter}10 >/dev/null || groupadd server{letter}10",
            f"mkdir -p /srv/server{letter}10",
            f"chown root:server{letter}10 /srv/server{letter}10",
            f"chmod 2770 /srv/server{letter}10",
        ],
    )


def _both_nfs_step(letter: str) -> tuple[str, str, list[str]]:
    export_path = f"/exports/exam-{letter}"
    mountpoint = f"/mnt/{letter}projects"
    source = f"server:{export_path}"
    return (
        f"On server, export {export_path} to the 192.168.122.0/24 network. On client, mount {source} persistently at {mountpoint}.",
        (
            f"findmnt -no SOURCE,TARGET {mountpoint} | grep -qx '{source} {mountpoint}' && "
            f"grep -Eq '^{source}[[:space:]]+{mountpoint}[[:space:]]+nfs([[:space:]]|$)' /etc/fstab && "
            f"{_ssh_server_check(f'grep -Eq \"^{export_path}[[:space:]]+192\\\\.168\\\\.122\\\\.0/24\" /etc/exports.d/exam-{letter}-integrated.exports && systemctl is-active nfs-server | grep -qx active')}"
        ),
        [
            "# On server:",
            f"mkdir -p {export_path}",
            f"echo 'exam {letter} export' > {export_path}/README",
            f"cat > /etc/exports.d/exam-{letter}-integrated.exports <<'EOF'\n{export_path} 192.168.122.0/24(rw,sync,no_root_squash)\nEOF",
            "systemctl enable --now nfs-server",
            "firewall-cmd --permanent --add-service=nfs",
            "firewall-cmd --permanent --add-service=mountd",
            "firewall-cmd --permanent --add-service=rpc-bind",
            "firewall-cmd --reload",
            "exportfs -arv",
            "# On client:",
            f"mkdir -p {mountpoint}",
            f"grep -Eq '^{source}[[:space:]]+{mountpoint}[[:space:]]+nfs' /etc/fstab || echo '{source} {mountpoint} nfs defaults,_netdev 0 0' >> /etc/fstab",
            "mount -a",
        ],
    )


def _both_scp_step(letter: str) -> tuple[str, str, list[str]]:
    return (
        f"On client, create /root/exam-{letter}-report.txt containing REPORT-{letter.upper()} and copy it to server:/root/exam-{letter}-report.txt.",
        _ssh_server_check(f"grep -Fxq REPORT-{letter.upper()} /root/exam-{letter}-report.txt"),
        [
            f"echo REPORT-{letter.upper()} > /root/exam-{letter}-report.txt",
            "test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa10-exam >/dev/null 2>&1",
            "ssh-copy-id -i /root/.ssh/id_ed25519.pub root@server",
            f"scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-{letter}-report.txt root@server:/root/exam-{letter}-report.txt",
        ],
    )


def _both_chrony_step(letter: str) -> tuple[str, str, list[str]]:
    return (
        "On server, make chronyd available as the lab time source. On client, configure chronyd to use server as its only time source.",
        (
            "grep -Eq '^server[[:space:]]+server[[:space:]]+iburst' /etc/chrony.conf && "
            "systemctl is-enabled chronyd | grep -qx enabled && systemctl is-active chronyd | grep -qx active && "
            f"{_ssh_server_check('systemctl is-enabled chronyd | grep -qx enabled && systemctl is-active chronyd | grep -qx active')}"
        ),
        [
            *_server_repo_commands(),
            "dnf install -y chrony",
            "systemctl enable --now chronyd",
            "firewall-cmd --permanent --add-service=ntp >/dev/null 2>&1 || true",
            "firewall-cmd --reload >/dev/null 2>&1 || true",
            "# On client:",
            *_client_repo_commands(),
            "dnf install -y chrony",
            "cat > /etc/chrony.conf <<'EOF'\nserver server iburst\nmakestep 1.0 3\nEOF",
            "systemctl enable --now chronyd",
        ],
    )


def _both_web_verify_step(letter: str, port: int) -> tuple[str, str, list[str]]:
    return (
        f"On client, add a hosts entry for server{letter}.exam10.lab and save the output of http://server{letter}.exam10.lab:{port}/server-{letter}.html to /root/server-{letter}-web-check.txt.",
        f"grep -Fxq RHCSA10-{letter.upper()} /root/server-{letter}-web-check.txt",
        [
            f"grep -Eq '^192\\.168\\.122\\.3[[:space:]]+server{letter}\\.exam10\\.lab$' /etc/hosts || echo '192.168.122.3 server{letter}.exam10.lab' >> /etc/hosts",
            f"curl -s http://server{letter}.exam10.lab:{port}/server-{letter}.html > /root/server-{letter}-web-check.txt",
        ],
    )


def _exam_points(task_count: int) -> list[int]:
    if task_count == 23:
        return [5 for _ in range(8)] + [4 for _ in range(15)]
    if task_count == 22:
        return [5 for _ in range(12)] + [4 for _ in range(10)]
    raise ValueError(f"Unsupported RHCSA10 exam task count {task_count}")


def _task_target(task: Any, command_group: list[str]) -> str:
    return infer_task_target(task, command_group)


def _apply_target_metadata(block: dict[str, Any], requires_server: bool = False, include_balance: bool = False) -> None:
    targets = [
        _task_target(task, commands)
        for task, commands in zip(block.get("tasks", []), block.get("solution_commands", []))
    ]
    block["task_targets"] = targets
    block["solution_targets"] = [
        infer_solution_target(commands, targets[index] if index < len(targets) else "client")
        for index, commands in enumerate(block.get("solution_commands", []))
    ]
    block["check_targets"] = [
        infer_check_target(check, requires_server=requires_server)
        for check in block.get("checks", [])
    ]
    if include_balance:
        block["target_balance"] = {
            "client_only": targets.count("client"),
            "server_only": targets.count("server"),
            "client_server": targets.count("both"),
        }


def _clean_exam_task_wording(task: Any) -> str:
    text = normalize_authored_wording(task)
    for target in ("client", "server"):
        if re.match(rf"^\s*On {target},", text, re.I):
            text = re.sub(rf"\s+on (the )?{target}\b", "", text, flags=re.I)
    text = text.replace(" by using a sudoers drop-in", "")
    text = text.replace(" by using a sudoers drop-in file", "")
    text = text.replace("Use a sudoers drop-in file.", "")
    text = text.replace("Then use scp to copy", "Then copy")
    text = text.replace("configure chronyd to use server as its only time source", "configure chronyd with server as its only time source")
    text = re.sub(
        r"using http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled",
        "with BaseOS at http://server/repo/BaseOS/ and AppStream at http://server/repo/AppStream/; disable GPG checks",
        text,
    )
    text = re.sub(r"\busing (/dev/[a-z0-9]+)\b", r"from \1", text)
    return re.sub(r"[ \t]+\n", "\n", text).strip()


def _apply_rhcsa10_exam_diversity(exam_id: str, tasks: list[Any], checks: list[str], commands: list[list[str]]) -> None:
    """Vary selected RHCSA10 exams beyond the base generated exam skeleton."""
    if exam_id == "rhcsa10-mock-exam-b":
        _replace_exam_step(
            tasks,
            checks,
            commands,
            3,
            "On client, install the tree package from the configured offline repositories.",
            "command -v tree >/dev/null && rpm -q tree >/dev/null",
            [
                "cat > /etc/yum.repos.d/rhcsa10-exam.repo <<'EOF'\n[rhcsa10-exam-baseos]\nname=RHCSA10 Exam BaseOS\nbaseurl=http://server/repo/BaseOS/\nenabled=1\ngpgcheck=0\n\n[rhcsa10-exam-appstream]\nname=RHCSA10 Exam AppStream\nbaseurl=http://server/repo/AppStream/\nenabled=1\ngpgcheck=0\nEOF",
                "dnf clean all",
                "dnf install -y tree",
                "rpm -q tree",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            4,
            "On client, create /srv/teamb10 as a shared directory for group teamb10.",
            "getent group teamb10 >/dev/null && stat -c '%U:%G:%a' /srv/teamb10 | grep -qx root:teamb10:3770",
            [
                "getent group teamb10 >/dev/null || groupadd teamb10",
                "mkdir -p /srv/teamb10",
                "chown root:teamb10 /srv/teamb10",
                "chmod 3770 /srv/teamb10",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            5,
            "Create group teamb10, create user userb10, set password cinder9, and add the user to teamb10.",
            "getent group teamb10 >/dev/null && id -nG userb10 | tr ' ' '\\n' | grep -qx teamb10",
            [
                "getent group teamb10 >/dev/null || groupadd teamb10",
                "id userb10 >/dev/null 2>&1 || useradd userb10",
                "gpasswd -a userb10 teamb10",
                "echo 'userb10:cinder9' | chpasswd",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            6,
            "On client, create user auditorb10 with UID 6102 and shell /sbin/nologin.",
            "id -u auditorb10 | grep -qx 6102 && getent passwd auditorb10 | awk -F: '$7 == \"/sbin/nologin\" {found=1} END {exit !found}'",
            [
                "id auditorb10 >/dev/null 2>&1 || useradd -u 6102 -s /sbin/nologin auditorb10",
                "usermod -u 6102 -s /sbin/nologin auditorb10",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            18,
            "On client, set a default ACL on /srv/teamb10 that gives group teamb10 full access to new files.",
            "getfacl -p /srv/teamb10 | grep -Eq '^default:group:teamb10:rwx$'",
            [
                "setfacl -m g:teamb10:rwx,d:g:teamb10:rwx /srv/teamb10",
                "getfacl -p /srv/teamb10",
            ],
        )

    if exam_id == "rhcsa10-mock-exam-c":
        _replace_exam_step(
            tasks,
            checks,
            commands,
            2,
            "On client, publish a web page /var/www/html/examc.html containing EXAMC and enable httpd.",
            (
                "test \"$(cat /var/www/html/examc.html 2>/dev/null)\" = EXAMC && "
                "systemctl is-enabled httpd | grep -qx enabled && systemctl is-active httpd | grep -qx active"
            ),
            [
                "mkdir -p /var/www/html",
                "echo EXAMC > /var/www/html/examc.html",
                "restorecon -v /var/www/html/examc.html || true",
                "systemctl enable --now httpd",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            3,
            "On client, configure httpd to listen on TCP port 8102 and make the port usable by the web service.",
            (
                "grep -Eq '^Listen[[:space:]]+8102$' /etc/httpd/conf.d/examc-port.conf && "
                "semanage port -l | awk '$1 == \"http_port_t\" && $2 == \"tcp\" && "
                "$0 ~ /(^|[ ,])8102([, ]|$)/ {found=1} END {exit !found}' && "
                "systemctl is-active httpd | grep -qx active && "
                "ss -ltn | awk '$4 ~ /(^|:)8102$/ {found=1} END {exit !found}'"
            ),
            [
                "cat > /etc/httpd/conf.d/examc-port.conf <<'EOF'\nListen 8102\nEOF",
                "semanage port -a -t http_port_t -p tcp 8102 2>/dev/null || semanage port -m -t http_port_t -p tcp 8102",
                "systemctl restart httpd",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            4,
            "On client, set the login message to RHCSA10-C authorized access only.",
            "grep -Fxq 'RHCSA10-C authorized access only' /etc/motd",
            [
                "echo 'RHCSA10-C authorized access only' > /etc/motd",
            ],
        )

    if exam_id == "rhcsa10-mock-exam-d":
        _replace_exam_step(
            tasks,
            checks,
            commands,
            10,
            "On client, create and enable a custom systemd service named examd-heartbeat.service.",
            (
                "systemctl is-enabled examd-heartbeat.service | grep -qx enabled && "
                "systemctl is-active examd-heartbeat.service | grep -qx active && "
                "grep -Fxq 'exam-d heartbeat' /var/log/examd-heartbeat.log"
            ),
            [
                "cat > /usr/local/sbin/examd-heartbeat.sh <<'EOF'\n#!/bin/bash\necho 'exam-d heartbeat' >> /var/log/examd-heartbeat.log\nEOF",
                "chmod +x /usr/local/sbin/examd-heartbeat.sh",
                "cat > /etc/systemd/system/examd-heartbeat.service <<'EOF'\n[Unit]\nDescription=Exam D heartbeat\n\n[Service]\nType=oneshot\nRemainAfterExit=yes\nExecStart=/usr/local/sbin/examd-heartbeat.sh\n\n[Install]\nWantedBy=multi-user.target\nEOF",
                "systemctl daemon-reload",
                "systemctl enable --now examd-heartbeat.service",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            11,
            "On client, route local5 log messages to /var/log/examd-local5.log and write a test message.",
            (
                "grep -Eq '^local5\\.\\*[[:space:]]+/var/log/examd-local5\\.log$' /etc/rsyslog.d/examd-local5.conf && "
                "systemctl is-active rsyslog | grep -qx active && "
                "grep -Fq 'exam-d local5' /var/log/examd-local5.log"
            ),
            [
                "cat > /etc/rsyslog.d/examd-local5.conf <<'EOF'\nlocal5.* /var/log/examd-local5.log\nEOF",
                "systemctl enable --now rsyslog",
                "systemctl restart rsyslog",
                "logger -p local5.info 'exam-d local5'",
                "sleep 1",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            20,
            "On client, allow the http service permanently in firewalld and reload the firewall.",
            "firewall-cmd --permanent --query-service=http && firewall-cmd --query-service=http",
            [
                "firewall-cmd --permanent --add-service=http",
                "firewall-cmd --reload",
                "firewall-cmd --query-service=http",
            ],
        )

    if exam_id == "rhcsa10-mock-exam-e":
        _replace_exam_step(
            tasks,
            checks,
            commands,
            3,
            "On client, create a labeled XFS filesystem on /dev/sdc1 and mount it persistently at /mnt/exame-label.",
            (
                "findmnt -no TARGET /mnt/exame-label | grep -qx /mnt/exame-label && "
                "blkid -s LABEL -o value /dev/sdc1 | grep -qx EXAME10 && "
                "awk '$1 == \"LABEL=EXAME10\" && $2 == \"/mnt/exame-label\" && $3 == \"xfs\" "
                "{found=1} END {exit !found}' /etc/fstab"
            ),
            [
                "parted -s /dev/sdc -- mklabel gpt mkpart primary xfs 1MiB 513MiB",
                "partprobe /dev/sdc || true",
                "udevadm settle",
                "mkfs.xfs -f -L EXAME10 /dev/sdc1",
                "mkdir -p /mnt/exame-label",
                "sed -i '\\#/mnt/exame-label#d' /etc/fstab",
                "echo 'LABEL=EXAME10 /mnt/exame-label xfs defaults 0 0' >> /etc/fstab",
                "mount -a",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            4,
            "On client, add audit_backlog_limit=8192 to all installed kernel entries.",
            (
                "grubby --info=ALL | awk -F= '$1 == \"args\" {count++; "
                "if ($0 !~ /(^|[[:space:]\"])audit_backlog_limit=8192([[:space:]\"]|$)/) missing=1} "
                "END {exit !(count > 0 && missing == 0)}'"
            ),
            [
                "grubby --update-kernel=ALL --args='audit_backlog_limit=8192'",
                "grubby --info=ALL | grep audit_backlog_limit",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            19,
            "On client, save the first useradd help usage line to /root/e-useradd-help.txt.",
            "grep -Eiq '^Usage:[[:space:]]+useradd\\b' /root/e-useradd-help.txt",
            [
                "useradd --help | sed -n '1p' > /root/e-useradd-help.txt",
                "test -s /root/e-useradd-help.txt",
            ],
        )

    if exam_id == "rhcsa10-mock-exam-f":
        _replace_exam_step(
            tasks,
            checks,
            commands,
            2,
            "On client, copy regular files owned by root from /opt/exam-f/find to /root/examf-rootfiles while preserving paths.",
            (
                "test -f /root/examf-rootfiles/opt/exam-f/find/a/root.conf && "
                "! test -e /root/examf-rootfiles/opt/exam-f/find/b/user.conf"
            ),
            [
                "mkdir -p /root/examf-rootfiles",
                "find /opt/exam-f/find -type f -user root -exec cp --parents -t /root/examf-rootfiles {} +",
                "find /root/examf-rootfiles -type f -print",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            3,
            "On client, create a 500 MiB swap partition on /dev/sdc and make it active and persistent.",
            _swap_persistence_check("/dev/sdc1"),
            [
                "parted -s /dev/sdc -- mklabel gpt mkpart primary linux-swap 1MiB 501MiB",
                "partprobe /dev/sdc || true",
                "udevadm settle",
                "mkswap /dev/sdc1",
                "uuid=$(blkid -s UUID -o value /dev/sdc1)",
                "echo \"UUID=$uuid swap swap defaults 0 0\" >> /etc/fstab",
                "swapon /dev/sdc1",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            19,
            "On client, create and enable examf-cleanup.service so it writes F-CLEANUP to /var/log/examf-cleanup.log when started.",
            (
                "systemctl is-enabled examf-cleanup.service | grep -qx enabled && "
                "systemctl is-active examf-cleanup.service | grep -qx active && "
                "grep -Fxq F-CLEANUP /var/log/examf-cleanup.log"
            ),
            [
                "cat > /usr/local/sbin/examf-cleanup.sh <<'EOF'\n#!/bin/bash\necho F-CLEANUP >> /var/log/examf-cleanup.log\nEOF",
                "chmod +x /usr/local/sbin/examf-cleanup.sh",
                "cat > /etc/systemd/system/examf-cleanup.service <<'EOF'\n[Unit]\nDescription=Exam F cleanup marker\n\n[Service]\nType=oneshot\nRemainAfterExit=yes\nExecStart=/usr/local/sbin/examf-cleanup.sh\n\n[Install]\nWantedBy=multi-user.target\nEOF",
                "systemctl daemon-reload",
                "systemctl enable --now examf-cleanup.service",
            ],
        )

    if exam_id == "rhcsa10-mock-exam-h":
        client_ip = exam_client_ip("h")
        _replace_exam_step(
            tasks,
            checks,
            commands,
            2,
            f"On server, set hostname to serverh.exam10.lab and map clienth.exam10.lab to {client_ip}.",
            _ssh_server_check(
                "hostnamectl --static | grep -qx serverh.exam10.lab && "
                f"grep -Eq '^{re.escape(client_ip)}[[:space:]]+clienth\\.exam10\\.lab$' /etc/hosts"
            ),
            [
                "# On server:",
                "hostnamectl set-hostname serverh.exam10.lab",
                f"grep -Eq '^{re.escape(client_ip)}[[:space:]]+clienth\\.exam10\\.lab$' /etc/hosts || echo '{client_ip} clienth.exam10.lab' >> /etc/hosts",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            3,
            "On client, create /var/tmp/examh-client.txt containing HCLIENT.",
            "grep -Fxq HCLIENT /var/tmp/examh-client.txt",
            [
                "echo HCLIENT > /var/tmp/examh-client.txt",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            9,
            "On server, configure persistent systemd journal storage.",
            _ssh_server_check(JOURNALD_PERSISTENT_CHECK),
            [
                "# On server:",
                *JOURNALD_PERSISTENT_COMMANDS,
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            14,
            "On server, route local6 log messages to /var/log/examh-local6.log and write a test message.",
            _ssh_server_check(
                "grep -Eq '^local6\\.\\*[[:space:]]+/var/log/examh-local6\\.log$' /etc/rsyslog.d/examh-local6.conf && "
                "systemctl is-active rsyslog | grep -qx active && "
                "grep -Fq 'exam-h local6' /var/log/examh-local6.log"
            ),
            [
                "# On server:",
                "cat > /etc/rsyslog.d/examh-local6.conf <<'EOF'\nlocal6.* /var/log/examh-local6.log\nEOF",
                "systemctl enable --now rsyslog",
                "systemctl restart rsyslog",
                "logger -p local6.info 'exam-h local6'",
                "sleep 1",
            ],
        )
        _replace_exam_step(
            tasks,
            checks,
            commands,
            17,
            "On server, allow TCP port 2208 permanently in firewalld and reload the firewall.",
            "firewall-cmd --permanent --query-port=2208/tcp && firewall-cmd --query-port=2208/tcp",
            [
                "# On server:",
                "firewall-cmd --permanent --add-port=2208/tcp",
                "firewall-cmd --reload",
                "firewall-cmd --query-port=2208/tcp",
            ],
        )


def _replace_step_from_factory(
    tasks: list[Any],
    checks: list[str],
    commands: list[list[str]],
    index: int,
    step: tuple[str, str, list[str]],
) -> None:
    task, check, command_group = step
    _replace_exam_step(tasks, checks, commands, index, task, check, command_group)


def _insert_step_from_factory(
    tasks: list[Any],
    checks: list[str],
    commands: list[list[str]],
    index: int,
    step: tuple[str, str, list[str]],
) -> None:
    task, check, command_group = step
    existing_indexes = [existing_index for existing_index, existing_task in enumerate(tasks) if existing_task == task]
    if existing_indexes:
        keep_index = existing_indexes[0]
        tasks[keep_index] = task
        checks[keep_index] = check
        commands[keep_index] = command_group
        for duplicate_index in reversed(existing_indexes[1:]):
            del tasks[duplicate_index]
            del checks[duplicate_index]
            del commands[duplicate_index]
        return
    _insert_exam_step(tasks, checks, commands, index, task, check, command_group)


def _apply_rhcsa10_exam_target_balance(
    exam_id: str,
    tasks: list[Any],
    checks: list[str],
    commands: list[list[str]],
) -> None:
    letter = chr(ord("a") + _exam_seed_from_id(exam_id))
    server_web_port = 8200 + _exam_seed_from_id(exam_id)

    if exam_id == "rhcsa10-mock-exam-a":
        _replace_step_from_factory(tasks, checks, commands, 4, _both_repo_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 5, _server_hostname_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 12, _both_scp_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 13, _server_http_step(letter, server_web_port))
        _replace_step_from_factory(tasks, checks, commands, 14, _server_timer_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 16, _server_user_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 17, _server_shared_dir_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 18, _server_selinux_boolean_step())
        _replace_step_from_factory(tasks, checks, commands, 20, _server_journald_step())
        _replace_step_from_factory(tasks, checks, commands, 21, _both_chrony_step(letter))
        _insert_step_from_factory(tasks, checks, commands, len(tasks), _both_nfs_step(letter))

    if exam_id == "rhcsa10-mock-exam-b":
        _replace_step_from_factory(tasks, checks, commands, 2, _both_repo_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 9, _both_scp_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 12, _server_timer_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 14, _server_http_step(letter, server_web_port))
        _replace_step_from_factory(tasks, checks, commands, 15, _server_user_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 16, _server_sudo_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 17, _server_journald_step())
        _replace_step_from_factory(tasks, checks, commands, 18, _server_rsyslog_step(letter, "local5"))
        _replace_step_from_factory(tasks, checks, commands, 19, _both_nfs_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 20, _server_default_target_step())

    if exam_id == "rhcsa10-mock-exam-c":
        _replace_step_from_factory(tasks, checks, commands, 4, _server_hostname_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 5, _server_shared_dir_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 9, _both_repo_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 14, _server_sudo_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 16, _server_http_step(letter, server_web_port))
        _replace_step_from_factory(tasks, checks, commands, 17, _server_journald_step())
        _replace_step_from_factory(tasks, checks, commands, 18, _server_timer_step(letter, 5))
        _replace_step_from_factory(tasks, checks, commands, 19, _both_nfs_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 20, _both_web_verify_step(letter, server_web_port))
        _replace_step_from_factory(tasks, checks, commands, 21, _server_rsyslog_step(letter, "local6"))
        _insert_step_from_factory(tasks, checks, commands, len(tasks), _both_scp_step(letter))

    if exam_id == "rhcsa10-mock-exam-d":
        _replace_step_from_factory(tasks, checks, commands, 3, _server_timer_step(letter, 10))
        _replace_step_from_factory(tasks, checks, commands, 7, _server_journald_step())
        _replace_step_from_factory(tasks, checks, commands, 8, _both_chrony_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 9, _both_repo_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 10, _server_http_step(letter, server_web_port))
        _replace_step_from_factory(tasks, checks, commands, 11, _server_rsyslog_step(letter, "local5"))
        _replace_step_from_factory(tasks, checks, commands, 13, _server_sudo_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 14, _server_user_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 17, _both_scp_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 19, _both_nfs_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 20, _server_default_target_step())

    if exam_id == "rhcsa10-mock-exam-e":
        _replace_step_from_factory(tasks, checks, commands, 2, _both_repo_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 6, _server_user_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 7, _server_sudo_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 12, _server_timer_step(letter, 10))
        _replace_step_from_factory(tasks, checks, commands, 14, _server_http_step(letter, server_web_port))
        _replace_step_from_factory(tasks, checks, commands, 15, _server_shared_dir_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 17, _server_rsyslog_step(letter, "local5"))
        _replace_step_from_factory(tasks, checks, commands, 18, _both_nfs_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 19, _both_scp_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 21, _server_journald_step())
        _insert_step_from_factory(tasks, checks, commands, len(tasks), _both_web_verify_step(letter, server_web_port))

    if exam_id == "rhcsa10-mock-exam-f":
        _replace_step_from_factory(tasks, checks, commands, 2, _both_scp_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 7, _server_journald_step())
        _replace_step_from_factory(tasks, checks, commands, 12, _server_default_target_step())
        _replace_step_from_factory(tasks, checks, commands, 14, _both_nfs_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 15, _server_timer_step(letter, 10))
        _replace_step_from_factory(tasks, checks, commands, 16, _server_http_step(letter, server_web_port))
        _replace_step_from_factory(tasks, checks, commands, 17, _both_repo_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 19, _server_rsyslog_step(letter, "local6"))
        _replace_step_from_factory(tasks, checks, commands, 20, _server_shared_dir_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 21, _server_user_step(letter))

    if exam_id == "rhcsa10-mock-exam-g":
        _replace_step_from_factory(tasks, checks, commands, 4, _both_repo_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 15, _server_rsyslog_step(letter, "local5"))
        _replace_step_from_factory(tasks, checks, commands, 16, _server_shared_dir_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 17, _server_user_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 18, _server_http_step(letter, server_web_port))
        _replace_step_from_factory(tasks, checks, commands, 19, _server_timer_step(letter, 12))
        _insert_step_from_factory(tasks, checks, commands, len(tasks), _both_nfs_step(letter))

    if exam_id == "rhcsa10-mock-exam-h":
        _replace_step_from_factory(tasks, checks, commands, 3, _both_scp_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 4, _server_timer_step(letter, 10))
        _replace_step_from_factory(tasks, checks, commands, 10, _server_shared_dir_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 16, _both_chrony_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 17, _server_http_step(letter, server_web_port))
        _replace_step_from_factory(tasks, checks, commands, 18, _both_repo_step(letter))
        _replace_step_from_factory(tasks, checks, commands, 20, _server_sudo_step(letter))


def _reorder_parallel(values: list[Any], order: list[int]) -> list[Any]:
    if len(values) != len(order):
        return values
    return [values[index] for index in order]


def _move_parallel_item(values: list[Any], source_index: int, target_index: int) -> list[Any]:
    if not (0 <= source_index < len(values)):
        return values
    moved = list(values)
    item = moved.pop(source_index)
    moved.insert(target_index, item)
    return moved


def _has_explicit_target(task_text: str) -> bool:
    return bool(re.search(r"^\s*\((client|server)\)(?=\s|$)|\bon\s+(client|server)\b", task_text, re.I))


def _prefix_client_task(task_text: str) -> str:
    if _has_explicit_target(task_text):
        return task_text
    stripped = str(task_text).strip()
    return f"On client, {stripped[0].lower()}{stripped[1:]}" if stripped else str(task_text)


def _order_user_prerequisites(
    tasks: list[str],
    checks: list[str],
    commands: list[list[str]],
    points: list[Any],
) -> tuple[list[str], list[str], list[list[str]], list[Any]]:
    for create_index, task in enumerate(list(tasks)):
        match = re.search(r"\bcreate user\s+([a-z0-9_-]+)\b", str(task), re.I)
        if not match:
            continue

        user = match.group(1)
        dependent_indexes = [
            index
            for index, candidate in enumerate(tasks)
            if index != create_index
            and re.search(rf"\b{re.escape(user)}\b", str(candidate), re.I)
            and not re.search(r"\bcreate user\b", str(candidate), re.I)
        ]
        if not dependent_indexes:
            continue

        first_dependent = min(dependent_indexes)
        if create_index <= first_dependent:
            continue

        tasks = _move_parallel_item(tasks, create_index, first_dependent)
        checks = _move_parallel_item(checks, create_index, first_dependent)
        commands = _move_parallel_item(commands, create_index, first_dependent)
        if points:
            points = _move_parallel_item(points, create_index, first_dependent)

    return tasks, checks, commands, points


def _order_flatpak_prerequisites(
    tasks: list[str],
    checks: list[str],
    commands: list[list[str]],
    points: list[Any],
) -> tuple[list[str], list[str], list[list[str]], list[Any]]:
    for install_index, task in enumerate(list(tasks)):
        match = re.search(r"\bInstall org\.rhcsa\.Tools from\s+([a-z0-9_-]+)\b", str(task), re.I)
        if not match:
            continue

        remote = match.group(1)
        remote_index = next(
            (
                index
                for index, candidate in enumerate(tasks)
                if re.search(rf"\bCreate system Flatpak remote\s+{re.escape(remote)}\b", str(candidate), re.I)
            ),
            None,
        )
        if remote_index is None or remote_index <= install_index:
            continue

        tasks = _move_parallel_item(tasks, remote_index, install_index)
        checks = _move_parallel_item(checks, remote_index, install_index)
        commands = _move_parallel_item(commands, remote_index, install_index)
        if points:
            points = _move_parallel_item(points, remote_index, install_index)

    return tasks, checks, commands, points


def _retarget_lab_to_server(block: dict[str, Any]) -> dict[str, Any]:
    updated = dict(block)
    updated["tasks"] = [
        task if re.search(r"\bon server\b", str(task), re.I) else f"On server, {str(task)[0].lower()}{str(task)[1:]}"
        for task in updated.get("tasks", [])
    ]
    updated["checks"] = [_server_check(str(check)) for check in updated.get("checks", [])]
    updated["task_titles"] = [task_title(task) for task in updated["tasks"]]
    return updated


def _lab_scope(block: dict[str, Any], requires_server: bool) -> str:
    return scope_from_targets(block.get("task_targets", []), requires_server=requires_server)


def _clean_lab_task_wording(task: Any) -> str:
    text = normalize_authored_wording(task)
    text = text.replace(" by using a sudoers drop-in", "")
    text = text.replace(" by using a sudoers drop-in file", "")
    text = text.replace("Use a sudoers drop-in file.", "")
    return re.sub(r"[ \t]+\n", "\n", text).strip()


def _repair_lab_progression(lab_id: str, block: dict[str, Any]) -> dict[str, Any]:
    """Fix RHCSA10 labs whose old task/check split could not score 1:1."""
    if lab_id == "lab-01-hostname-resolution":
        return _replace_lab_progression(
            block,
            [
                "On server, set the persistent hostname to server10.lab.example.",
                "On client, set the persistent hostname to client10.lab.example.",
                "On client, add a persistent hosts entry mapping server10.lab.example to 192.168.122.3.",
            ],
            [
                "# server hostnamectl --static | grep -qx server10.lab.example",
                "hostnamectl --static | grep -qx client10.lab.example",
                "awk '$1 == \"192.168.122.3\" {for (i = 2; i <= NF; i++) if ($i == \"server10.lab.example\") found = 1} END {exit !found}' /etc/hosts && getent hosts server10.lab.example | grep -q '192.168.122.3'",
            ],
            [
                ["# On server:", "hostnamectl set-hostname server10.lab.example"],
                ["hostnamectl set-hostname client10.lab.example"],
                [
                    "echo '192.168.122.3 server10.lab.example' >> /etc/hosts",
                    "hostnamectl --static",
                    "getent hosts server10.lab.example",
                ],
            ],
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
                "On client, configure a persistent BaseOS repository. BaseOS URL: http://server/repo/BaseOS/.",
                "On client, configure a persistent AppStream repository. AppStream URL: http://server/repo/AppStream/.",
                "On client, disable GPG checks for both RHCSA10 repositories and verify both repositories are enabled.",
                "On server, configure matching BaseOS and AppStream repositories with GPG checks disabled.",
            ],
            [
                "grep -ERq '^\\[rhcsa10-baseos\\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://server/repo/BaseOS/?$' /etc/yum.repos.d",
                "grep -ERq '^\\[rhcsa10-appstream\\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://server/repo/AppStream/?$' /etc/yum.repos.d",
                "awk 'BEGIN{s=0} /^\\[rhcsa10-(baseos|appstream)\\]$/{repo=$0} /^enabled=1$/{if (repo != \"\") e++} /^gpgcheck=0$/{if (repo != \"\") g++} END{exit !(e >= 2 && g >= 2)}' /etc/yum.repos.d/*.repo && dnf repolist --enabled | grep -Eq 'rhcsa10-baseos|rhcsa10-appstream'",
                "# server grep -ERq '^\\[rhcsa10-baseos\\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://server/repo/BaseOS/?$' /etc/yum.repos.d && grep -ERq '^\\[rhcsa10-appstream\\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://server/repo/AppStream/?$' /etc/yum.repos.d && awk 'BEGIN{s=0} /^\\[rhcsa10-(baseos|appstream)\\]$/{repo=$0} /^enabled=1$/{if (repo != \"\") e++} /^gpgcheck=0$/{if (repo != \"\") g++} END{exit !(e >= 2 && g >= 2)}' /etc/yum.repos.d/*.repo",
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
                [
                    "cat > /etc/yum.repos.d/rhcsa10.repo <<'EOF'\n[rhcsa10-baseos]\nname=RHCSA10 BaseOS\nbaseurl=http://server/repo/BaseOS/\nenabled=1\ngpgcheck=0\n\n[rhcsa10-appstream]\nname=RHCSA10 AppStream\nbaseurl=http://server/repo/AppStream/\nenabled=1\ngpgcheck=0\nEOF",
                    "dnf clean all",
                    "dnf repolist --enabled",
                ],
            ],
        )

    if lab_id == "lab-05-rpm-packages":
        return _replace_lab_progression(
            block,
            [
                "On client, install the lsof package.",
                "On client, remove the tcpdump package if it is installed.",
                "On server, install the lsof package.",
            ],
            [
                "rpm -q lsof >/dev/null",
                "! rpm -q tcpdump >/dev/null 2>&1",
                "# server rpm -q lsof >/dev/null",
            ],
            [
                ["dnf install -y lsof"],
                ["dnf remove -y tcpdump", "rpm -q tcpdump || true"],
                ["# On server", "dnf install -y lsof"],
            ],
        )

    if lab_id == "lab-06-flatpak-remote":
        return _replace_lab_progression(
            block,
            [
                "On server, configure BaseOS and AppStream repositories for Flatpak package access with GPG checks disabled.",
                "On client, install the flatpak package if it is not already installed.",
                "On client, configure a system Flatpak remote named rhcsa10 that points to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.",
            ],
            [
                "# server grep -ERq '^\\[rhcsa-flatpak-baseos\\]$' /etc/yum.repos.d && grep -ERq '^\\[rhcsa-flatpak-appstream\\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://server/repo/BaseOS/?$' /etc/yum.repos.d && grep -ERq '^baseurl=http://server/repo/AppStream/?$' /etc/yum.repos.d && [ \"$(grep -Ec '^gpgcheck=0$' /etc/yum.repos.d/rhcsa-flatpak.repo)\" -ge 2 ]",
                "rpm -q flatpak >/dev/null",
                "flatpak remotes --system --columns=name,url 2>/dev/null | awk '$1 == \"rhcsa10\" && $2 == \"file:///opt/rhcsa/flatpak/repo\" {found=1} END {exit !found}'",
            ],
            [
                [
                    "# On server",
                    "cat > /etc/yum.repos.d/rhcsa-flatpak.repo <<'EOF'\n[rhcsa-flatpak-baseos]\nname=RHCSA Flatpak BaseOS\nbaseurl=http://server/repo/BaseOS/\nenabled=1\ngpgcheck=0\n\n[rhcsa-flatpak-appstream]\nname=RHCSA Flatpak AppStream\nbaseurl=http://server/repo/AppStream/\nenabled=1\ngpgcheck=0\nEOF",
                ],
                ["dnf install -y flatpak"],
                ["flatpak remote-add --system --if-not-exists --no-gpg-verify rhcsa10 file:///opt/rhcsa/flatpak/repo"],
            ],
        )

    if lab_id == "lab-07-flatpak-package":
        return _replace_lab_progression(
            block,
            [
                "On server, install Flatpak repository tooling and rebuild the metadata under /opt/rhcsa/flatpak/repo.",
                "On client, ensure the system Flatpak remote rhcsa10 exists and points to file:///opt/rhcsa/flatpak/repo.",
                "On client, install Flatpak application org.rhcsa.Tools from rhcsa10 for the system installation.",
            ],
            [
                "# server test -s /opt/rhcsa/flatpak/repo/summary",
                "flatpak remotes --system --columns=name,url 2>/dev/null | awk '$1 == \"rhcsa10\" && $2 == \"file:///opt/rhcsa/flatpak/repo\" {found=1} END {exit !found}'",
                "flatpak list --system --app --columns=application 2>/dev/null | grep -qx org.rhcsa.Tools",
            ],
            [
                [
                    "# On server",
                    "dnf install -y flatpak ostree",
                    "install -d -m 755 /opt/rhcsa/flatpak/repo",
                    "ostree init --repo=/opt/rhcsa/flatpak/repo --mode=archive-z2",
                    "flatpak build-update-repo /opt/rhcsa/flatpak/repo",
                ],
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

    if lab_id == "lab-18-ssh-key-auth":
        return _replace_lab_progression(
            block,
            [
                "On client, create user key10 and set password cinder9.",
                "On server, create user key10 and set password cinder9.",
                "On client, generate an ED25519 SSH key pair for key10 with no passphrase.",
                "On client, configure key-based SSH authentication so key10 can log in to key10@server without a password prompt.",
            ],
            [
                "getent passwd key10 >/dev/null",
                "# server getent passwd key10 >/dev/null",
                "test -f /home/key10/.ssh/id_ed25519.pub && stat -c '%U:%a' /home/key10/.ssh | grep -qx 'key10:700'",
                "runuser -l key10 -c 'ssh -o BatchMode=yes -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null key10@server true'",
            ],
            [
                ["useradd -m key10", "echo 'key10:cinder9' | chpasswd"],
                ["# On server", "useradd -m key10", "echo 'key10:cinder9' | chpasswd"],
                ["su - key10", "ssh-keygen -t ed25519 -N \"\" -f ~/.ssh/id_ed25519"],
                ["su - key10", "ssh-copy-id -i ~/.ssh/id_ed25519.pub key10@server"],
            ],
        )

    if lab_id == "lab-21-selinux-restorecon":
        return _replace_lab_progression(
            block,
            ["Restore the default SELinux context on /var/www/html/rhcsa10.html."],
            ["test \"$(cat /var/www/html/rhcsa10.html)\" = RHCSA10 && ls -Z /var/www/html/rhcsa10.html | grep -q httpd_sys_content_t"],
            [["restorecon -v /var/www/html/rhcsa10.html", "ls -Z /var/www/html/rhcsa10.html"]],
        )

    if lab_id == "lab-23-selinux-boolean":
        return _retarget_lab_to_server(
            _replace_lab_progression(
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
        )

    if lab_id == "lab-28-chrony-client":
        return _replace_lab_progression(
            block,
            [
                "On server, configure chronyd as a local time source for the 192.168.122.0/24 network.",
                "On client, install chrony if needed.",
                "On client, configure server as the only NTP source.",
                "On client, enable and start chronyd.",
            ],
            [
                "# server systemctl is-enabled chronyd | grep -qx enabled && systemctl is-active chronyd | grep -qx active && grep -Eq '^allow 192\\.168\\.122\\.0/24$' /etc/chrony.conf && grep -Eq '^local stratum 10$' /etc/chrony.conf",
                "rpm -q chrony >/dev/null",
                "grep -Eq '^server server iburst$' /etc/chrony.conf",
                "systemctl is-enabled chronyd | grep -qx enabled && systemctl is-active chronyd | grep -qx active",
            ],
            [
                [
                    "# On server",
                    "cat > /etc/chrony.conf <<'EOF'\ndriftfile /var/lib/chrony/drift\nmakestep 1.0 3\nallow 192.168.122.0/24\nlocal stratum 10\nlogdir /var/log/chrony\nEOF",
                    "systemctl enable --now chronyd",
                ],
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
        "lab-31-systemd-timer",
    }:
        return _retarget_lab_to_server(block)

    if lab_id == "lab-26-persistent-journal":
        return _retarget_lab_to_server(
            _replace_lab_progression(
                block,
                [
                    "On server, create the persistent systemd journal directory.",
                    "On server, configure systemd-journald to store logs persistently and flush current journal data.",
                ],
                [
                    "test -d /var/log/journal",
                    JOURNALD_PERSISTENT_CHECK,
                ],
                [
                    [
                        "mkdir -p /var/log/journal",
                    ],
                    [
                        "mkdir -p /etc/systemd/journald.conf.d",
                        "cat > /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf <<'EOF'\n[Journal]\nStorage=persistent\nEOF",
                        "systemctl restart systemd-journald",
                        "journalctl --flush",
                    ],
                ],
            )
        )

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
        checks[2] = _swap_persistence_check()
        commands = [list(command_group) for command_group in block.get("solution_commands", [])]
        if len(commands) >= 3:
            commands[0] = [
                "parted -s /dev/sdb mklabel gpt mkpart primary linux-swap 1MiB 513MiB",
                "partprobe /dev/sdb || true",
                "udevadm settle",
                "mkswap /dev/sdb1",
            ]
            commands[2] = [
                "uuid=$(blkid -s UUID -o value /dev/sdb1)",
                "echo \"UUID=$uuid swap swap defaults 0 0\" >> /etc/fstab",
            ]
        updated = dict(block)
        updated["checks"] = checks
        updated["solution_commands"] = commands
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
        checks[0] = "parted -sm /dev/sdb unit MiB print | awk -F: '$1 == \"1\" && int($4) >= 250 && int($4) <= 260 {ok=1} END {exit !ok}'"
        checks[1] = "blkid /dev/sdb1 | grep -q 'TYPE=\"vfat\"' && blkid /dev/sdb1 | grep -q 'LABEL_FATBOOT=\"RHCSA10VFAT\"\\|LABEL=\"RHCSA10VFAT\"'"
        checks[2] = "findmnt -no TARGET /mnt/vfat10 | grep -qx /mnt/vfat10 && grep -Eq '^LABEL=RHCSA10VFAT[[:space:]]+/mnt/vfat10[[:space:]]+vfat' /etc/fstab"
        updated = dict(block)
        updated["checks"] = checks
        commands = [list(command_group) for command_group in block.get("solution_commands", [])]
        if len(commands) >= 3:
            commands[0] = [
                "wipefs -a /dev/sdb >/dev/null 2>&1 || true",
                "sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true",
                "parted -s /dev/sdb mklabel gpt mkpart primary fat32 1MiB 257MiB",
                "partprobe /dev/sdb || true",
                "udevadm settle",
            ]
            commands[1] = ["mkfs.vfat -F 32 -n RHCSA10VFAT /dev/sdb1"]
            updated["solution_commands"] = commands
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
                    "test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa10-transfer >/dev/null 2>&1",
                    "ssh-copy-id -i /root/.ssh/id_ed25519.pub root@server",
                    "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/rhcsa10-transfer.txt root@server:/root/rhcsa10-transfer.txt",
                    "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 root@server 'cat /root/rhcsa10-transfer.txt'",
                ],
            ],
            points=[10, 20],
        )

    if lab_id == "lab-46-package-file-install":
        return _replace_lab_progression(
            block,
            [
                "On client, install the local tree RPM from /var/www/html/repo or the mounted ISO without enabling external repositories.",
                "On server, install the tree package from the local repositories.",
            ],
            [
                "command -v tree >/dev/null && rpm -q tree >/dev/null",
                "# server command -v tree >/dev/null && rpm -q tree >/dev/null",
            ],
            [
                [
                    "dnf install -y --disablerepo='*' --enablerepo=rhcsa-baseos --enablerepo=rhcsa-appstream tree",
                    "rpm -q tree",
                ],
                ["# On server", "dnf install -y tree", "rpm -q tree"],
            ],
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
                "On server, create /var/www/html/rhcsa10-boot.html containing BOOT10.",
                "On server, enable httpd and allow the http service permanently in firewalld.",
                "On client, save the server web page output to /root/rhcsa10-boot-check.txt.",
            ],
            [
                "# server test \"$(cat /var/www/html/rhcsa10-boot.html 2>/dev/null)\" = BOOT10",
                "# server systemctl is-enabled httpd | grep -qx enabled && systemctl is-active httpd | grep -qx active && firewall-cmd --permanent --query-service=http && firewall-cmd --query-service=http",
                "grep -Fxq BOOT10 /root/rhcsa10-boot-check.txt",
            ],
            [
                ["# On server:", "mkdir -p /var/www/html", "echo BOOT10 > /var/www/html/rhcsa10-boot.html", "restorecon -v /var/www/html/rhcsa10-boot.html || true"],
                ["# On server:", "systemctl enable --now httpd", "firewall-cmd --permanent --add-service=http", "firewall-cmd --reload"],
                ["curl -fsS http://server/rhcsa10-boot.html > /root/rhcsa10-boot-check.txt"],
            ],
        )

    if lab_id in {
        "lab-19-firewalld-service",
        "lab-22-selinux-port",
        "lab-25-tuned-profile",
        "lab-27-rsyslog-logger",
        "lab-32-cron",
        "lab-33-at-job",
        "lab-43-sticky-directory",
        "lab-44-permission-repair",
    }:
        return _retarget_lab_to_server(block)

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
    lab_block["tasks"] = [_clean_lab_task_wording(task) for task in lab_block.get("tasks", [])]
    lab_block["task_titles"] = [task_title(task) for task in lab_block.get("tasks", [])]
    manifest.setdefault("content", {})["lab"] = normalize_lab_block(lab_block)

    scenario_scripts: dict[str, str] = {}
    if lab_id in client_scripts:
        scenario_scripts["client"] = client_scripts[lab_id]
    if lab_id in server_scripts:
        scenario_scripts["server"] = server_scripts[lab_id]

    manifest["tracks"] = ["rhcsa10"]
    manifest["title"] = normalize_title_capitalization(manifest["title"])
    manifest["description"] = normalize_authored_wording(manifest["description"])
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
    _apply_target_metadata(manifest["content"]["lab"], requires_server=bool(manifest["flags"]["requires_server"]))
    manifest["scope"] = _lab_scope(manifest["content"]["lab"], bool(manifest["flags"]["requires_server"]))

    write_json(manifest_path, manifest)


def _exam_seed_from_id(exam_id: str) -> int:
    match = re.fullmatch(r"rhcsa10-mock-exam-([a-h])", exam_id.strip())
    if not match:
        raise ValueError(f"Unsupported RHCSA10 exam id '{exam_id}'.")
    return ord(match.group(1)) - ord("a")


def _repair_exam_progression(exam_id: str, block: dict[str, Any]) -> dict[str, Any]:
    """Apply RHCSA10 exam compatibility and grading hardening fixes."""
    updated = dict(block)
    tasks = list(updated.get("tasks", []))
    checks = list(updated.get("checks", []))
    commands = [list(command_group) for command_group in updated.get("solution_commands", [])]
    letter = chr(ord("a") + _exam_seed_from_id(exam_id))

    if exam_id == "rhcsa10-mock-exam-g":
        for index, task in enumerate(tasks):
            task_text = str(task)
            if "server:/exports/shareg" in task_text or "Authorized exam-g server" in task_text:
                tasks[index] = "(server) Set the server login message in /etc/motd to Authorized exam-g server."
                if index < len(checks):
                    checks[index] = _ssh_server_check("grep -qx 'Authorized exam-g server' /etc/motd")
                if index < len(commands):
                    commands[index] = [
                        "# On server:",
                        "echo 'Authorized exam-g server' > /etc/motd",
                    ]

            if "create user copy10" in task_text.lower() and "same uid 5010" in task_text.lower():
                if index < len(checks):
                    checks[index] = (
                        "id -u copy10 | grep -qx 5010 && "
                        f"{_ssh_server_check('id -u copy10 | grep -qx 5010')}"
                    )
                if index < len(commands):
                    commands[index] = [
                        "id copy10 >/dev/null 2>&1 || useradd -u 5010 copy10",
                        "echo 'copy10:cinder9' | chpasswd",
                        "# On server:",
                        "id copy10 >/dev/null 2>&1 || useradd -u 5010 copy10",
                        "echo 'copy10:cinder9' | chpasswd",
                    ]

            if "Create group devg10" in task_text and "grant10" in task_text:
                if index < len(commands):
                    commands[index] = [
                        "getent group devg10 >/dev/null || groupadd devg10",
                        "id grant10 >/dev/null 2>&1 || useradd -u 3017 -G devg10 grant10",
                        "id hazel10 >/dev/null 2>&1 || useradd -G devg10 hazel10",
                        "echo 'grant10:cinder9' | chpasswd",
                        "echo 'hazel10:cinder9' | chpasswd",
                    ]

            if "as copy10" in task_text.lower() and "server-hostname" in task_text:
                if index < len(commands):
                    commands[index] = [
                        "# On client:",
                        "su - copy10",
                        "mkdir -p ~/.ssh",
                        "test -f ~/.ssh/id_rsa || ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa",
                        "ssh-copy-id -i ~/.ssh/id_rsa.pub copy10@server",
                        "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa copy10@server:/etc/hostname /home/copy10/server-hostname",
                        "exit",
                    ]

            if "Schedule an at job for user hazel10" in task_text:
                if index < len(commands):
                    commands[index] = [
                        "systemctl enable --now atd",
                        "su - hazel10 -c 'echo \"echo \\\"exam-g task\\\" >> /home/hazel10/at-result.txt\" | at now + 1 minute'",
                        "echo 'exam-g task' >> /home/hazel10/at-result.txt",
                        "chown hazel10:hazel10 /home/hazel10/at-result.txt",
                    ]

            if 'Run the command "sleep 600"' in task_text and "renice" in task_text:
                if index < len(commands):
                    commands[index] = [
                        "nohup nice -n 15 sleep 600 >/dev/null 2>&1 &",
                    ]

            if "gzip-compressed tar archive /root/g-etc.tar.gz" in task_text:
                if index < len(checks):
                    checks[index] = "test -f /root/g-etc.tar.gz && tar -tzf /root/g-etc.tar.gz | awk '$0 ~ /^etc\\// {found=1} END{exit !found}'"

        for field_name in ("hints", "solution_outline"):
            values = [str(value) for value in updated.get(field_name, [])]
            updated[field_name] = [value.replace("NFS and package tasks", "server-side and package tasks") for value in values]

    for index, task in enumerate(tasks):
        task_text = str(task)
        if exam_id == "rhcsa10-mock-exam-b" and task_text.startswith("Set hostname to clientb.exam10.lab"):
            tasks[index] = _prefix_client_task(task_text)

        if exam_id == "rhcsa10-mock-exam-c":
            tasks[index] = _prefix_client_task(str(tasks[index]))
            task_text = str(tasks[index])

        if re.search(r"^Set hostname to client[a-h]\.exam10\.lab\b", task_text, re.I):
            tasks[index] = _prefix_client_task(task_text)
            task_text = str(tasks[index])

        if "server:/exports/direct" in task_text or "server:/exports/autofs" in task_text:
            tasks[index] = _prefix_client_task(task_text)

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
        if any(token in str(task) for token in ("journald.conf", "[Journal]", "Storage=persistent")):
            tasks[index] = (
                "On server, configure systemd-journald so logs are stored persistently across "
                "reboots and restart systemd-journald."
            )
        if index < len(commands):
            commands[index] = list(JOURNALD_PERSISTENT_COMMANDS)
        if index < len(checks):
            checks[index] = _ssh_server_check(JOURNALD_PERSISTENT_CHECK) if re.search(r"\bon server\b|\(server\)", str(tasks[index]), re.I) else JOURNALD_PERSISTENT_CHECK

    flatpak_installed_exams = {"rhcsa10-mock-exam-a", "rhcsa10-mock-exam-c", "rhcsa10-mock-exam-g"}
    for index, task in enumerate(tasks):
        if index >= len(checks):
            continue
        task_text = str(task)
        task_lower = task_text.lower()

        if "baseos" in task_lower and "appstream" in task_lower and "repo" in task_lower:
            checks[index] = _ssh_server_check(STRICT_REPO_CHECK) if re.search(r"\bon server\b|\(server\)", task_text, re.I) else STRICT_REPO_CHECK

        if "httpd_can_network_connect" in task_text:
            checks[index] = SELINUX_HTTPD_BOOLEAN_CHECK

        lvm_vg_match = re.search(r"\bvg([a-h])10\b", task_lower)
        lvm_lv_match = re.search(r"\bdata([a-h])\b", task_lower)
        if lvm_vg_match and lvm_lv_match and "mount" in task_lower and lvm_vg_match.group(1) == lvm_lv_match.group(1):
            checks[index] = _lvm_mount_check(lvm_vg_match.group(1))

        nfs_match = re.search(r"mount\s+server:/exports/direct\s+at\s+(/mnt/[a-z0-9._/-]+)\s+persistently", task_lower)
        if nfs_match:
            checks[index] = _nfs_mount_check(nfs_match.group(1).rstrip("."))

        if "swap" in task_lower and "/dev/sdb" in task_lower and "persist" in task_lower:
            checks[index] = _swap_persistence_check()
            if index < len(commands):
                commands[index] = [
                    "parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 501MiB",
                    "partprobe /dev/sdb || true",
                    "udevadm settle",
                    "mkswap /dev/sdb1",
                    "uuid=$(blkid -s UUID -o value /dev/sdb1)",
                    "echo \"UUID=$uuid swap swap defaults 0 0\" >> /etc/fstab",
                    "swapon /dev/sdb1",
                ]

        if re.search(r"Install\s+org\.rhcsa\.Tools\s+from\s+that\b", task_text, re.I) and exam_id in flatpak_installed_exams:
            remote = f"exam{letter}flatpak"
            add_prefix = "(client) Add" if task_text.lstrip().startswith("(client)") else "On client, add"
            tasks[index] = (
                f"{add_prefix} a system-level Flatpak remote named {remote} pointing to "
                "file:///opt/rhcsa/flatpak/repo with GPG verification disabled. "
                "Install org.rhcsa.Tools from that remote and leave it installed."
            )
            checks[index] = f"{_flatpak_remote_check(remote)} && {_flatpak_installed_check()}"
            if index < len(commands):
                commands[index] = [
                    f"flatpak remote-add --system --if-not-exists --no-gpg-verify {remote} file:///opt/rhcsa/flatpak/repo",
                    f"flatpak install --system -y {remote} org.rhcsa.Tools",
                    "flatpak list --system --app",
                ]
            continue

        combined_flatpak_match = re.search(r"remote named\s+([a-z0-9_-]+)\b", task_text, re.I)
        if combined_flatpak_match and "org.rhcsa.Tools" in task_text and "flatpak" in task_lower:
            remote = combined_flatpak_match.group(1)
            add_prefix = "(client) Add" if task_text.lstrip().startswith("(client)") else "On client, add"
            configure_prefix = "(client) Configure" if task_text.lstrip().startswith("(client)") else "On client, configure"
            if exam_id in flatpak_installed_exams:
                tasks[index] = (
                    f"{add_prefix} a system-level Flatpak remote named {remote} pointing to "
                    "file:///opt/rhcsa/flatpak/repo with GPG verification disabled. "
                    "Install org.rhcsa.Tools from that remote and leave it installed."
                )
                checks[index] = f"{_flatpak_remote_check(remote)} && {_flatpak_installed_check()}"
                if index < len(commands):
                    commands[index] = [
                        f"flatpak remote-add --system --if-not-exists --no-gpg-verify {remote} file:///opt/rhcsa/flatpak/repo",
                        f"flatpak install --system -y {remote} org.rhcsa.Tools",
                        "flatpak list --system --app",
                    ]
            else:
                tasks[index] = (
                    f"{configure_prefix} a system-level Flatpak remote named {remote} pointing to "
                    "file:///opt/rhcsa/flatpak/repo with GPG verification disabled, and ensure org.rhcsa.Tools is not installed."
                )
                checks[index] = f"{_flatpak_remote_check(remote)} && {_flatpak_absent_check()}"
                if index < len(commands):
                    commands[index] = [
                        f"flatpak remote-add --system --if-not-exists --no-gpg-verify {remote} file:///opt/rhcsa/flatpak/repo",
                        "flatpak uninstall --system -y org.rhcsa.Tools >/dev/null 2>&1 || true",
                    ]

        split_flatpak_match = re.search(r"Install\s+org\.rhcsa\.Tools\s+from\s+(?!that\b)([a-z0-9_-]+)", task_text, re.I)
        if split_flatpak_match:
            remote = split_flatpak_match.group(1)
            if exam_id in flatpak_installed_exams:
                tasks[index] = f"Install org.rhcsa.Tools from {remote} and leave it installed."
                checks[index] = _flatpak_installed_check()
                if index < len(commands):
                    commands[index] = [
                        f"flatpak install --system -y {remote} org.rhcsa.Tools",
                        "flatpak list --system --app",
                    ]
            else:
                tasks[index] = f"Ensure org.rhcsa.Tools is not installed after configuring {remote}."
                checks[index] = _flatpak_absent_check()
                if index < len(commands):
                    commands[index] = [
                        "flatpak uninstall --system -y org.rhcsa.Tools >/dev/null 2>&1 || true",
                    ]

    task_points = list(updated.get("task_points", []))
    tasks, checks, commands, task_points = _order_flatpak_prerequisites(tasks, checks, commands, task_points)
    tasks, checks, commands, task_points = _order_user_prerequisites(tasks, checks, commands, task_points)
    if task_points:
        updated["task_points"] = task_points

    _apply_rhcsa10_exam_diversity(exam_id, tasks, checks, commands)
    _apply_rhcsa10_exam_target_balance(exam_id, tasks, checks, commands)
    _ensure_client_root_recovery(tasks, checks, commands)

    for index, task in enumerate(tasks):
        task_text = str(task)
        if exam_id == "rhcsa10-mock-exam-c":
            tasks[index] = _prefix_client_task(task_text)
            task_text = str(tasks[index])
        if re.search(r"^Set hostname to client[a-h]\.exam10\.lab\b", task_text, re.I):
            tasks[index] = _prefix_client_task(task_text)
            task_text = str(tasks[index])
        if "server:/exports/direct" in task_text or "server:/exports/autofs" in task_text:
            tasks[index] = _prefix_client_task(task_text)

    tasks = [_clean_exam_task_wording(task) for task in tasks]
    task_targets = [_task_target(task, commands[index]) for index, task in enumerate(tasks)]
    tasks = [prefix_task_target(task, task_targets[index]) for index, task in enumerate(tasks)]
    updated["tasks"] = tasks
    updated["checks"] = checks
    updated["solution_commands"] = commands
    updated["task_titles"] = [task_title(task) for task in tasks]
    updated["task_points"] = _exam_points(len(tasks))
    _apply_target_metadata(updated, requires_server=True, include_balance=True)
    return updated


def _update_exam_manifest(manifest_path: Path) -> None:
    manifest = _load_manifest(manifest_path)
    scenario_root = manifest_path.parent
    seed = _exam_seed_from_id(str(manifest["id"]))
    client_script, server_script = _exam_scripts(seed)
    exam_block = dict(manifest.get("content", {}).get("exam", {}))

    manifest["tracks"] = ["rhcsa10"]
    manifest["title"] = normalize_title_capitalization(manifest["title"])
    manifest["description"] = normalize_authored_wording(manifest["description"])
    manifest["rhel_major"] = 10
    manifest["supported_modes"] = ["exam"]
    manifest.setdefault("content", {})["exam"] = _repair_exam_progression(str(manifest["id"]), exam_block)
    if str(manifest["id"]) == "rhcsa10-mock-exam-a":
        manifest["description"] = (
            "A 23-task RHCSA 10 mock exam covering boot recovery, networking, Flatpak management, "
            "systemd timers, LVM storage, firewall, SELinux, shell scripting, and chrony time "
            "synchronisation across client and server."
        )
    if str(manifest["id"]) == "rhcsa10-mock-exam-b":
        manifest["description"] = (
            "Software and permissions focus: offline package installation, shared directories, "
            "default ACLs, fixed user identity, storage, NFS, journald, and systemd administration."
        )
    if str(manifest["id"]) == "rhcsa10-mock-exam-c":
        manifest["description"] = (
            "Web service and network focus: httpd service setup, custom service port, SELinux port "
            "labeling, firewalld, Flatpak, client storage, NFS, autofs, users, and scheduling."
        )
    if str(manifest["id"]) == "rhcsa10-mock-exam-d":
        manifest["description"] = (
            "Service and logging focus: custom systemd service, rsyslog routing, firewall service access, "
            "SELinux, journald, chrony, storage, users, and package administration."
        )
    if str(manifest["id"]) == "rhcsa10-mock-exam-e":
        manifest["description"] = (
            "Storage and boot focus: labeled filesystem persistence, kernel arguments, LVM, NFS, "
            "documentation, package administration, users, scheduling, and logging."
        )
    if str(manifest["id"]) == "rhcsa10-mock-exam-g":
        manifest["description"] = (
            "Recovery + server administration focus: root password recovery, server-side login policy, "
            "process management, file search, systemd timers, swap, and LVM storage."
        )
    manifest.setdefault("flags", {})
    manifest["flags"]["requires_server"] = True
    manifest["flags"]["password_recovery"] = True
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
