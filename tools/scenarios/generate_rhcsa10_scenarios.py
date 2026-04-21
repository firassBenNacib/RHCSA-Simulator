#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
LABS_ROOT = ROOT / "scenarios" / "labs"
EXAMS_ROOT = ROOT / "scenarios" / "exams"


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def clean_generated() -> None:
    for root, prefix in ((LABS_ROOT, "rhcsa10-lab-"), (EXAMS_ROOT, "rhcsa10-mock-exam-")):
        for child in root.glob(f"{prefix}*"):
            if child.is_dir():
                shutil.rmtree(child)
    for legacy in (LABS_ROOT / "lab-49-flatpak-remote", LABS_ROOT / "lab-50-systemd-timer"):
        if legacy.exists():
            shutil.rmtree(legacy)


def scenario(kind: str, sid: str, title: str, description: str, tags: list[str], minutes: int, block: dict[str, Any], requires_server: bool = False, password_recovery: bool = False) -> dict[str, Any]:
    return {
        "id": sid,
        "title": title,
        "description": description,
        "objective_tags": tags,
        "supported_modes": [kind],
        "time_limit_minutes": minutes,
        "tracks": ["rhcsa10"],
        "rhel_major": 10,
        "flags": {
            "password_recovery": password_recovery,
            "requires_server": requires_server,
        },
        "content": {kind: block},
    }


def lab(sid: str, title: str, description: str, tags: list[str], minutes: int, tasks: list[str], hints: list[str], checks: list[str], commands: list[list[str]], requires_server: bool = False, points: list[int] | None = None) -> dict[str, Any]:
    return scenario(
        "lab",
        sid,
        title,
        description,
        tags,
        minutes,
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
    )


def task_title(task: str) -> str:
    line = task.splitlines()[0].strip().rstrip(".")
    for prefix in ("On client, ", "On server, ", "As root, "):
        if line.startswith(prefix):
            line = line[len(prefix):]
    return line[:72]


def user_lab(n: int, user: str, group: str) -> dict[str, Any]:
    sid = f"rhcsa10-lab-{n:02d}-users-groups-sudo"
    return lab(
        sid,
        f"RHCSA 10 Lab {n:02d}: Users Groups And Sudo",
        "Create local identities and delegate limited administrative access",
        ["users-sudo-ssh"],
        30,
        [
            f"Create local group {group}.",
            f"Create user {user}, set the password to cinder9, and make {group} the user's supplementary group.",
            f"Allow members of {group} to run /usr/bin/systemctl with sudo without a password by using a sudoers drop-in.",
        ],
        ["Use a file under /etc/sudoers.d.", "Validate sudoers syntax with visudo -cf."],
        [
            f"getent group {group} >/dev/null",
            f"id -nG {user} | tr ' ' '\\n' | grep -qx {group} && getent shadow {user} | awk -F: 'length($2)>0 && $2 !~ /^(!!?|\\*|LK|NP)$/ {{ok=1}} END {{exit !ok}}'",
            f"grep -ERq '^%{group}[[:space:]]+ALL=\\(ALL\\)[[:space:]]+NOPASSWD:[[:space:]]*/usr/bin/systemctl$' /etc/sudoers.d && visudo -cf /etc/sudoers >/dev/null",
        ],
        [
            [f"groupadd {group}"],
            [f"useradd -G {group} {user}", f"passwd {user}", "# enter: cinder9"],
            [f"echo '%{group} ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/{group}", f"chmod 440 /etc/sudoers.d/{group}"],
        ],
    )


def flatpak_remote_lab(n: int, remote: str) -> dict[str, Any]:
    sid = f"rhcsa10-lab-{n:02d}-flatpak-remote"
    return lab(
        sid,
        f"RHCSA 10 Lab {n:02d}: Flatpak Remote",
        "Configure system Flatpak repository access",
        ["software-management"],
        20,
        [
            "Install the flatpak package if it is not already installed.",
            f"Configure a system Flatpak remote named {remote} that points to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.",
            "Verify that the system remote is available.",
        ],
        ["Use flatpak remote-add --system.", "Use --if-not-exists for idempotent configuration."],
        [
            "rpm -q flatpak >/dev/null",
            f"flatpak remotes --system --columns=name,url 2>/dev/null | awk '$1 == \"{remote}\" && $2 == \"file:///opt/rhcsa/flatpak/repo\" {{found=1}} END {{exit !found}}'",
            f"flatpak remotes --system --columns=name 2>/dev/null | grep -qx {remote}",
        ],
        [
            ["dnf install -y flatpak"],
            [f"flatpak remote-add --system --if-not-exists --no-gpg-verify {remote} file:///opt/rhcsa/flatpak/repo"],
            ["flatpak remotes --system --columns=name,url"],
        ],
    )


def flatpak_package_lab(n: int, remote: str, app: str) -> dict[str, Any]:
    sid = f"rhcsa10-lab-{n:02d}-flatpak-package"
    return lab(
        sid,
        f"RHCSA 10 Lab {n:02d}: Flatpak Package",
        "Install and remove Flatpak applications from a configured remote",
        ["software-management"],
        25,
        [
            f"Ensure the system Flatpak remote {remote} exists and points to file:///opt/rhcsa/flatpak/repo.",
            f"Install Flatpak application {app} from {remote} for the system installation.",
            f"Remove {app} and verify that it is no longer installed.",
        ],
        ["Flatpak installs can be scoped with --system.", "Use flatpak list --app to verify installed applications."],
        [
            f"flatpak remotes --system --columns=name,url 2>/dev/null | awk '$1 == \"{remote}\" && $2 == \"file:///opt/rhcsa/flatpak/repo\" {{found=1}} END {{exit !found}}'",
            f"flatpak list --system --app --columns=application 2>/dev/null | grep -qx {app} || test -f /root/{app}.removed",
            f"! flatpak list --system --app --columns=application 2>/dev/null | grep -qx {app}",
        ],
        [
            [f"flatpak remote-add --system --if-not-exists --no-gpg-verify {remote} file:///opt/rhcsa/flatpak/repo"],
            [f"flatpak install --system -y {remote} {app}"],
            [f"flatpak uninstall --system -y {app}", f"touch /root/{app}.removed"],
        ],
    )


def timer_lab(n: int, name: str, minutes: int) -> dict[str, Any]:
    sid = f"rhcsa10-lab-{n:02d}-systemd-timer"
    script = f"/usr/local/sbin/{name}.sh"
    service = f"{name}.service"
    timer = f"{name}.timer"
    logfile = f"/var/log/{name}.log"
    return lab(
        sid,
        f"RHCSA 10 Lab {n:02d}: Systemd Timer",
        "Create and enable a persistent systemd timer",
        ["software-scheduling-time"],
        25,
        [
            f"Create {script} so it appends TIMER OK to {logfile}.",
            f"Create a oneshot service named {service} that runs {script}.",
            f"Create {timer} so it runs every {minutes} minutes, is persistent, and starts automatically at boot.",
        ],
        ["Enable the timer unit, not the service unit.", "Use OnCalendar and Persistent in the timer unit."],
        [
            f"test -x {script} && grep -Fqx 'echo TIMER OK >> {logfile}' {script}",
            f"systemctl cat {service} | grep -Fqx 'ExecStart={script}' && systemctl cat {service} | grep -Fqx 'Type=oneshot'",
            f"systemctl cat {timer} | grep -Fqx 'OnCalendar=*:0/{minutes}' && systemctl cat {timer} | grep -Fqx 'Persistent=true' && systemctl is-enabled {timer} | grep -qx enabled",
        ],
        [
            [f"cat > {script} <<'EOF'", "#!/bin/bash", f"echo TIMER OK >> {logfile}", "EOF", f"chmod +x {script}"],
            [f"cat > /etc/systemd/system/{service} <<'EOF'", "[Unit]", f"Description={name} service", "", "[Service]", "Type=oneshot", f"ExecStart={script}", "EOF"],
            [f"cat > /etc/systemd/system/{timer} <<'EOF'", "[Unit]", f"Description=Run {name}", "", "[Timer]", f"OnCalendar=*:0/{minutes}", "Persistent=true", "", "[Install]", "WantedBy=timers.target", "EOF", "systemctl daemon-reload", f"systemctl enable --now {timer}"],
        ],
    )


def simple_labs() -> list[dict[str, Any]]:
    return [
        lab("rhcsa10-lab-01-hostname-resolution", "RHCSA 10 Lab 01: Hostname Resolution", "Configure persistent hostname and local name resolution", ["networking-and-firewall"], 25, ["Set the persistent hostname to client10.lab.example.", "Add a persistent hosts entry mapping server10.lab.example to 192.168.122.3.", "Verify local hostname and name resolution."], ["Use hostnamectl for the static hostname.", "Edit /etc/hosts for local host resolution."], ["hostnamectl --static | grep -qx client10.lab.example", "grep -Eq '^192\\.168\\.122\\.3[[:space:]]+server10\\.lab\\.example$' /etc/hosts", "getent hosts server10.lab.example | grep -q '192.168.122.3'"], [["hostnamectl set-hostname client10.lab.example"], ["echo '192.168.122.3 server10.lab.example' >> /etc/hosts"], ["hostnamectl --static", "getent hosts server10.lab.example"]]),
        lab("rhcsa10-lab-02-ipv4-nmcli", "RHCSA 10 Lab 02: IPv4 Networking", "Configure persistent IPv4 networking with NetworkManager", ["networking-and-firewall"], 35, ["Configure the active client connection with IPv4 address 192.168.122.45/24.", "Set gateway 192.168.122.1 and DNS server 192.168.122.3.", "Ensure the connection uses manual IPv4 configuration and autoconnects."], ["Use nmcli connection show --active to find the connection.", "Modify the connection profile, then bring it up."], ["nmcli -g ipv4.addresses connection show 'System eth1' | grep -qx '192.168.122.45/24'", "nmcli -g ipv4.gateway connection show 'System eth1' | grep -qx '192.168.122.1' && nmcli -g ipv4.dns connection show 'System eth1' | grep -qx '192.168.122.3'", "nmcli -g ipv4.method,connection.autoconnect connection show 'System eth1' | grep -qx manual && nmcli -g connection.autoconnect connection show 'System eth1' | grep -qx yes"], [["nmcli connection modify 'System eth1' ipv4.addresses 192.168.122.45/24"], ["nmcli connection modify 'System eth1' ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3"], ["nmcli connection modify 'System eth1' ipv4.method manual connection.autoconnect yes", "nmcli connection up 'System eth1'"]]),
        lab("rhcsa10-lab-03-ipv6-nmcli", "RHCSA 10 Lab 03: IPv6 Networking", "Configure persistent IPv6 networking with NetworkManager", ["networking-and-firewall"], 30, ["Configure the active client connection with IPv6 address fd00:10::45/64.", "Set IPv6 gateway fd00:10::1.", "Ensure IPv6 method is manual and the profile autoconnects."], ["Modify the connection profile rather than using ip addr add.", "Use nmcli -g to verify persistent profile values."], ["nmcli -g ipv6.addresses connection show 'System eth1' | grep -qx 'fd00:10::45/64'", "nmcli -g ipv6.gateway connection show 'System eth1' | grep -qx 'fd00:10::1'", "nmcli -g ipv6.method,connection.autoconnect connection show 'System eth1' | grep -qx manual && nmcli -g connection.autoconnect connection show 'System eth1' | grep -qx yes"], [["nmcli connection modify 'System eth1' ipv6.addresses fd00:10::45/64"], ["nmcli connection modify 'System eth1' ipv6.gateway fd00:10::1"], ["nmcli connection modify 'System eth1' ipv6.method manual connection.autoconnect yes", "nmcli connection up 'System eth1'"]]),
        lab("rhcsa10-lab-04-rpm-repositories", "RHCSA 10 Lab 04: RPM Repositories", "Configure BaseOS and AppStream repositories", ["software-management"], 35, ["Configure a persistent BaseOS repository using http://server/repo/BaseOS/.", "Configure a persistent AppStream repository using http://server/repo/AppStream/.", "Disable GPG checks and verify both repositories are enabled."], ["Use one file under /etc/yum.repos.d.", "Use dnf repolist to verify both repositories."], ["grep -ERq '^\\[rhcsa10-baseos\\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://server/repo/BaseOS/?$' /etc/yum.repos.d", "grep -ERq '^\\[rhcsa10-appstream\\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://server/repo/AppStream/?$' /etc/yum.repos.d", "grep -ERq '^gpgcheck=0$' /etc/yum.repos.d && dnf repolist --enabled | grep -Eq 'rhcsa10-baseos|rhcsa10-appstream'"], [["cat > /etc/yum.repos.d/rhcsa10.repo <<'EOF'", "[rhcsa10-baseos]", "name=RHCSA10 BaseOS", "baseurl=http://server/repo/BaseOS/", "enabled=1", "gpgcheck=0", "", "[rhcsa10-appstream]", "name=RHCSA10 AppStream", "baseurl=http://server/repo/AppStream/", "enabled=1", "gpgcheck=0", "EOF"], ["dnf clean all"], ["dnf repolist --enabled"]], requires_server=True),
        lab("rhcsa10-lab-05-rpm-packages", "RHCSA 10 Lab 05: RPM Packages", "Install and remove RPM software", ["software-management"], 20, ["Install the lsof package.", "Remove the tcpdump package if it is installed.", "Verify package state with rpm."], ["Use dnf for package changes.", "Use rpm -q for final verification."], ["rpm -q lsof >/dev/null", "! rpm -q tcpdump >/dev/null 2>&1", "rpm -q lsof >/dev/null && ! rpm -q tcpdump >/dev/null 2>&1"], [["dnf install -y lsof"], ["dnf remove -y tcpdump"], ["rpm -q lsof", "rpm -q tcpdump || true"]]),
        flatpak_remote_lab(6, "rhcsa10"),
        flatpak_package_lab(7, "rhcsa10", "org.rhcsa.Tools"),
        lab("rhcsa10-lab-08-shell-script-args", "RHCSA 10 Lab 08: Script Arguments", "Create a shell script that processes command-line arguments", ["shell-scripting"], 25, ["Create /usr/local/bin/rhcsa10-user-report.", "The script must print usage: rhcsa10-user-report USER when no argument is supplied.", "When a user name is supplied, print that user's primary group name."], ["Use id -gn USER.", "Test for an empty first positional parameter."], ["test -x /usr/local/bin/rhcsa10-user-report", "/usr/local/bin/rhcsa10-user-report 2>&1 | grep -qx 'usage: rhcsa10-user-report USER'", "/usr/local/bin/rhcsa10-user-report root | grep -qx root"], [["cat > /usr/local/bin/rhcsa10-user-report <<'EOF'", "#!/bin/bash", "if [ -z \"${1:-}\" ]; then", "  echo 'usage: rhcsa10-user-report USER' >&2", "  exit 2", "fi", "id -gn \"$1\"", "EOF"], ["chmod +x /usr/local/bin/rhcsa10-user-report"], ["/usr/local/bin/rhcsa10-user-report root"]]),
        lab("rhcsa10-lab-09-shell-loop", "RHCSA 10 Lab 09: Loop Script", "Create a shell script that loops over input", ["shell-scripting"], 25, ["Create /usr/local/bin/rhcsa10-lines.", "The script must read /etc/passwd and write every account name that starts with r to /root/rhcsa10-lines.txt.", "The script must overwrite the output file each time it runs."], ["Use a while read loop or awk.", "Account names are the first colon-separated field."], ["test -x /usr/local/bin/rhcsa10-lines", "/usr/local/bin/rhcsa10-lines && test -s /root/rhcsa10-lines.txt", "grep -Ev '^r' /root/rhcsa10-lines.txt >/dev/null 2>&1 && exit 1 || true"], [["cat > /usr/local/bin/rhcsa10-lines <<'EOF'", "#!/bin/bash", ": > /root/rhcsa10-lines.txt", "while IFS=: read -r name _; do", "  case \"$name\" in", "    r*) echo \"$name\" >> /root/rhcsa10-lines.txt ;;", "  esac", "done < /etc/passwd", "EOF"], ["chmod +x /usr/local/bin/rhcsa10-lines"], ["/usr/local/bin/rhcsa10-lines", "cat /root/rhcsa10-lines.txt"]]),
        lab("rhcsa10-lab-10-find-copy", "RHCSA 10 Lab 10: Find And Copy", "Find files and preserve metadata", ["essential-tools"], 20, ["Create /root/rhcsa10-found.", "Copy every file smaller than 1 KiB from /etc/skel to /root/rhcsa10-found while preserving mode and timestamps.", "Verify that at least one copied file exists."], ["Use find -size -1k.", "Use cp -a or install -p to preserve metadata."], ["test -d /root/rhcsa10-found", "find /root/rhcsa10-found -type f | grep -q .", "find /etc/skel -type f -size -1k | wc -l | awk '{exit !($1 >= 1)}'"], [["mkdir -p /root/rhcsa10-found"], ["find /etc/skel -type f -size -1k -exec cp -a {} /root/rhcsa10-found/ \\;"], ["find /root/rhcsa10-found -type f -ls"]]),
        lab("rhcsa10-lab-11-grep-regex", "RHCSA 10 Lab 11: Grep Regex", "Filter text with grep and regular expressions", ["essential-tools"], 15, ["Create /root/rhcsa10-shell-users.txt.", "Populate it with account names from /etc/passwd whose shell ends in sh.", "Sort the output alphabetically."], ["Use grep or awk.", "The login shell is the last colon-separated field."], ["test -s /root/rhcsa10-shell-users.txt", "diff -u <(awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort) /root/rhcsa10-shell-users.txt", "grep -q '^root$' /root/rhcsa10-shell-users.txt"], [["awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/rhcsa10-shell-users.txt"], ["cat /root/rhcsa10-shell-users.txt"], ["grep '^root$' /root/rhcsa10-shell-users.txt"]]),
        lab("rhcsa10-lab-12-archive-gzip", "RHCSA 10 Lab 12: Archive With Gzip", "Create and inspect compressed archives", ["essential-tools"], 20, ["Create /root/rhcsa10-etc.tar.gz containing /etc/hosts and /etc/fstab.", "Ensure the archive uses gzip compression.", "List the archive contents without extracting it."], ["Use tar -czf.", "Use tar -tzf to inspect gzip archives."], ["test -f /root/rhcsa10-etc.tar.gz", "file /root/rhcsa10-etc.tar.gz | grep -qi gzip", "tar -tzf /root/rhcsa10-etc.tar.gz | grep -Eq 'etc/(hosts|fstab)'"], [["tar -czf /root/rhcsa10-etc.tar.gz /etc/hosts /etc/fstab"], ["file /root/rhcsa10-etc.tar.gz"], ["tar -tzf /root/rhcsa10-etc.tar.gz"]]),
        lab("rhcsa10-lab-13-links", "RHCSA 10 Lab 13: Hard And Soft Links", "Create hard and symbolic links", ["essential-tools"], 15, ["Create /root/rhcsa10-original with the text link source.", "Create hard link /root/rhcsa10-hard pointing to the original file.", "Create symbolic link /root/rhcsa10-soft pointing to /root/rhcsa10-original."], ["Hard links share an inode.", "Symbolic links store a path."], ["test \"$(cat /root/rhcsa10-original)\" = 'link source'", "test \"$(stat -c %i /root/rhcsa10-original)\" = \"$(stat -c %i /root/rhcsa10-hard)\"", "test -L /root/rhcsa10-soft && test \"$(readlink /root/rhcsa10-soft)\" = '/root/rhcsa10-original'"], [["echo 'link source' > /root/rhcsa10-original"], ["ln /root/rhcsa10-original /root/rhcsa10-hard"], ["ln -s /root/rhcsa10-original /root/rhcsa10-soft"]]),
        lab("rhcsa10-lab-14-permissions-umask", "RHCSA 10 Lab 14: Permissions And Umask", "Manage default permissions", ["selinux-and-default-perms"], 20, ["Set root's shell umask to 027 using /root/.bashrc.", "Create /srv/rhcsa10-private with owner root and group root.", "Set directory permissions to 750."], ["Use umask 027 in the shell startup file.", "Use chmod with octal permissions."], ["grep -Eq '^umask 027$' /root/.bashrc", "stat -c '%U:%G' /srv/rhcsa10-private | grep -qx root:root", "stat -c '%a' /srv/rhcsa10-private | grep -qx 750"], [["grep -qx 'umask 027' /root/.bashrc || echo 'umask 027' >> /root/.bashrc"], ["mkdir -p /srv/rhcsa10-private", "chown root:root /srv/rhcsa10-private"], ["chmod 750 /srv/rhcsa10-private"]]),
        user_lab(15, "relay10", "ops10"),
        lab("rhcsa10-lab-16-password-aging", "RHCSA 10 Lab 16: Password Aging", "Adjust password aging for a local user", ["users-sudo-ssh"], 20, ["Create user aging10 and set password cinder9.", "Set maximum password age to 60 days.", "Set password warning period to 7 days."], ["Use chage.", "Verify with chage -l or /etc/shadow fields."], ["getent passwd aging10 >/dev/null", "chage -l aging10 | grep -Eq 'Maximum.*60'", "chage -l aging10 | grep -Eq 'warning.*7|Warning.*7'"], [["useradd aging10", "passwd aging10", "# enter: cinder9"], ["chage -M 60 aging10"], ["chage -W 7 aging10"]]),
        lab("rhcsa10-lab-17-user-defaults", "RHCSA 10 Lab 17: User Defaults", "Configure default useradd settings", ["users-sudo-ssh"], 20, ["Set default inactive password period for new users to 14 days.", "Set default account expiration date to 2030-12-31.", "Verify the new useradd defaults."], ["Use useradd -D.", "Defaults must persist in /etc/default/useradd."], ["useradd -D | grep -qx 'INACTIVE=14'", "useradd -D | grep -qx 'EXPIRE=2030-12-31'", "grep -Eq '^INACTIVE=14$' /etc/default/useradd && grep -Eq '^EXPIRE=2030-12-31$' /etc/default/useradd"], [["useradd -D -f 14"], ["useradd -D -e 2030-12-31"], ["useradd -D"]]),
        lab("rhcsa10-lab-18-ssh-key-auth", "RHCSA 10 Lab 18: SSH Key Authentication", "Configure key-based SSH authentication", ["users-sudo-ssh"], 30, ["Create user key10 and set password cinder9.", "Create /home/key10/.ssh/authorized_keys with the provided public key text ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIRhcsa10keydemo rhcsa10.", "Set secure ownership and permissions on the SSH directory and authorized_keys file."], ["The .ssh directory should be 700.", "authorized_keys should be 600 and owned by the user."], ["getent passwd key10 >/dev/null", "grep -Fqx 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIRhcsa10keydemo rhcsa10' /home/key10/.ssh/authorized_keys", "stat -c '%U:%a' /home/key10/.ssh /home/key10/.ssh/authorized_keys | grep -qx 'key10:700' && stat -c '%U:%a' /home/key10/.ssh/authorized_keys | grep -qx 'key10:600'"], [["useradd -m key10", "passwd key10", "# enter: cinder9"], ["install -d -m 700 -o key10 -g key10 /home/key10/.ssh", "echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIRhcsa10keydemo rhcsa10' > /home/key10/.ssh/authorized_keys"], ["chown key10:key10 /home/key10/.ssh/authorized_keys", "chmod 600 /home/key10/.ssh/authorized_keys", "restorecon -RF /home/key10/.ssh"]]),
        lab("rhcsa10-lab-19-firewalld-service", "RHCSA 10 Lab 19: Firewalld Service", "Manage persistent firewalld service rules", ["networking-and-firewall", "selinux-and-default-perms"], 20, ["Ensure firewalld is enabled and running.", "Permanently allow the https service in the public zone.", "Reload firewalld and verify the service is allowed."], ["Use --permanent for persistent rules.", "Reload after changing permanent configuration."], ["systemctl is-enabled firewalld | grep -qx enabled && systemctl is-active firewalld | grep -qx active", "firewall-cmd --permanent --zone=public --query-service=https", "firewall-cmd --zone=public --query-service=https"], [["systemctl enable --now firewalld"], ["firewall-cmd --permanent --zone=public --add-service=https"], ["firewall-cmd --reload", "firewall-cmd --zone=public --list-services"]]),
        lab("rhcsa10-lab-20-selinux-mode", "RHCSA 10 Lab 20: SELinux Mode", "Set SELinux enforcing mode persistently", ["selinux-and-default-perms"], 20, ["Set SELinux to enforcing mode immediately.", "Configure SELinux to boot in enforcing mode.", "Verify current and persistent SELinux mode."], ["Use setenforce for runtime state.", "Edit /etc/selinux/config for persistence."], ["getenforce | grep -qx Enforcing", "grep -Eq '^SELINUX=enforcing$' /etc/selinux/config", "sestatus | grep -q 'Current mode'"], [["setenforce 1"], ["sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config"], ["getenforce", "grep '^SELINUX=' /etc/selinux/config"]]),
        lab("rhcsa10-lab-21-selinux-restorecon", "RHCSA 10 Lab 21: Restore SELinux Context", "Restore default SELinux file contexts", ["selinux-and-default-perms"], 20, ["Create /var/www/html/rhcsa10.html containing RHCSA10.", "Set an incorrect context on the file.", "Restore the default context with restorecon."], ["Use chcon to simulate a bad label.", "Use restorecon to repair the default label."], ["test \"$(cat /var/www/html/rhcsa10.html)\" = RHCSA10", "matchpathcon /var/www/html/rhcsa10.html | grep -q httpd_sys_content_t", "ls -Z /var/www/html/rhcsa10.html | grep -q httpd_sys_content_t"], [["echo RHCSA10 > /var/www/html/rhcsa10.html"], ["chcon -t user_tmp_t /var/www/html/rhcsa10.html"], ["restorecon -v /var/www/html/rhcsa10.html"]]),
        lab("rhcsa10-lab-22-selinux-port", "RHCSA 10 Lab 22: SELinux HTTP Port", "Manage SELinux port labels", ["selinux-and-default-perms", "networking-and-firewall"], 25, ["Add TCP port 8010 as an http_port_t SELinux port.", "Configure firewalld to allow TCP port 8010 permanently.", "Verify SELinux and firewall configuration."], ["Use semanage port.", "Use firewall-cmd --add-port for the firewall."], ["semanage port -l | awk '$1 == \"http_port_t\" {print}' | grep -Eq '(^|[, ])8010(,|$)'", "firewall-cmd --permanent --query-port=8010/tcp", "firewall-cmd --query-port=8010/tcp"], [["semanage port -a -t http_port_t -p tcp 8010 || semanage port -m -t http_port_t -p tcp 8010"], ["firewall-cmd --permanent --add-port=8010/tcp"], ["firewall-cmd --reload", "semanage port -l | grep http_port_t"]]),
        lab("rhcsa10-lab-23-selinux-boolean", "RHCSA 10 Lab 23: SELinux Boolean", "Set SELinux booleans persistently", ["selinux-and-default-perms"], 15, ["Enable the httpd_can_network_connect SELinux boolean.", "Make the boolean persistent.", "Verify the boolean state."], ["Use setsebool -P.", "Use getsebool for verification."], ["getsebool httpd_can_network_connect | grep -Eq -- '--> on$'", "semanage boolean -l | grep -E '^httpd_can_network_connect\\s' | grep -q on", "getsebool httpd_can_network_connect >/dev/null"], [["setsebool -P httpd_can_network_connect on"], ["getsebool httpd_can_network_connect"], ["semanage boolean -l | grep httpd_can_network_connect"]]),
        lab("rhcsa10-lab-24-process-priority", "RHCSA 10 Lab 24: Process Priority", "Identify and adjust process scheduling", ["processes-logs-tuning"], 20, ["Start a background sleep process and save its PID in /run/rhcsa10-sleep.pid.", "Change the process nice value to 8.", "Verify the process priority."], ["Use nohup or shell backgrounding.", "Use renice against the PID."], ["test -s /run/rhcsa10-sleep.pid && kill -0 $(cat /run/rhcsa10-sleep.pid)", "ps -o ni= -p $(cat /run/rhcsa10-sleep.pid) | awk '{exit !($1 == 8)}'", "kill -0 $(cat /run/rhcsa10-sleep.pid)"], [["sleep 3600 & echo $! > /run/rhcsa10-sleep.pid"], ["renice -n 8 -p $(cat /run/rhcsa10-sleep.pid)"], ["ps -o pid,ni,comm -p $(cat /run/rhcsa10-sleep.pid)"]]),
        lab("rhcsa10-lab-25-tuned-profile", "RHCSA 10 Lab 25: Tuned Profile", "Manage tuned profiles", ["processes-logs-tuning"], 15, ["Ensure tuned is enabled and running.", "Activate the throughput-performance tuned profile.", "Verify the active profile."], ["Use tuned-adm profile.", "Use tuned-adm active to verify."], ["systemctl is-enabled tuned | grep -qx enabled && systemctl is-active tuned | grep -qx active", "tuned-adm active | grep -q throughput-performance", "tuned-adm active >/dev/null"], [["systemctl enable --now tuned"], ["tuned-adm profile throughput-performance"], ["tuned-adm active"]]),
        lab("rhcsa10-lab-26-persistent-journal", "RHCSA 10 Lab 26: Persistent Journal", "Preserve systemd journal logs", ["processes-logs-tuning"], 20, ["Configure persistent systemd journals.", "Restart systemd-journald.", "Verify that /var/log/journal exists."], ["Create /var/log/journal.", "Restart systemd-journald after changing storage."], ["test -d /var/log/journal", "grep -Eq '^Storage=persistent$' /etc/systemd/journald.conf", "systemctl is-active systemd-journald | grep -qx active"], [["mkdir -p /var/log/journal"], ["sed -i 's/^#\\?Storage=.*/Storage=persistent/' /etc/systemd/journald.conf"], ["systemctl restart systemd-journald", "journalctl --disk-usage"]]),
        lab("rhcsa10-lab-27-rsyslog-logger", "RHCSA 10 Lab 27: Rsyslog Logger", "Create and route log messages", ["processes-logs-tuning"], 20, ["Ensure rsyslog is installed and running.", "Configure local7.* messages to log to /var/log/rhcsa10-local7.log.", "Send a logger test message with facility local7 and verify it is written."], ["Use a file under /etc/rsyslog.d.", "Use logger -p local7.info."], ["systemctl is-active rsyslog | grep -qx active", "grep -Rqx 'local7.* /var/log/rhcsa10-local7.log' /etc/rsyslog.d", "grep -q 'RHCSA10 local7 test' /var/log/rhcsa10-local7.log"], [["dnf install -y rsyslog", "systemctl enable --now rsyslog"], ["echo 'local7.* /var/log/rhcsa10-local7.log' > /etc/rsyslog.d/rhcsa10.conf", "systemctl restart rsyslog"], ["logger -p local7.info 'RHCSA10 local7 test'", "sleep 1", "grep 'RHCSA10 local7 test' /var/log/rhcsa10-local7.log"]]),
        lab("rhcsa10-lab-28-chrony-client", "RHCSA 10 Lab 28: Chrony Client", "Configure time synchronization", ["software-scheduling-time", "processes-logs-tuning"], 20, ["Install chrony if needed.", "Configure server as the only NTP source.", "Enable and start chronyd."], ["Use /etc/chrony.conf.", "Use server server iburst."], ["rpm -q chrony >/dev/null", "grep -Eq '^server server iburst$' /etc/chrony.conf", "systemctl is-enabled chronyd | grep -qx enabled && systemctl is-active chronyd | grep -qx active"], [["dnf install -y chrony"], ["sed -i '/^pool /d;/^server /d' /etc/chrony.conf", "echo 'server server iburst' >> /etc/chrony.conf"], ["systemctl enable --now chronyd", "chronyc sources || true"]], requires_server=True),
        lab("rhcsa10-lab-29-default-target", "RHCSA 10 Lab 29: Default Target", "Configure system boot target", ["boot-and-recovery"], 15, ["Set the default systemd target to multi-user.target.", "Verify the default target.", "Do not reboot the system."], ["Use systemctl set-default.", "Use systemctl get-default to verify."], ["systemctl get-default | grep -qx multi-user.target", "test -L /etc/systemd/system/default.target", "readlink /etc/systemd/system/default.target | grep -q multi-user.target"], [["systemctl set-default multi-user.target"], ["systemctl get-default"], ["readlink /etc/systemd/system/default.target"]]),
        lab("rhcsa10-lab-30-systemd-service", "RHCSA 10 Lab 30: Custom Service", "Create and enable a custom systemd service", ["software-scheduling-time"], 25, ["Create /usr/local/sbin/rhcsa10-service.sh that writes SERVICE10 to /var/tmp/rhcsa10-service.out.", "Create a oneshot service named rhcsa10-service.service that runs the script.", "Enable and start the service."], ["Use Type=oneshot.", "Reload systemd before enabling a new unit."], ["test -x /usr/local/sbin/rhcsa10-service.sh", "systemctl is-enabled rhcsa10-service.service | grep -qx enabled", "grep -qx SERVICE10 /var/tmp/rhcsa10-service.out"], [["cat > /usr/local/sbin/rhcsa10-service.sh <<'EOF'", "#!/bin/bash", "echo SERVICE10 > /var/tmp/rhcsa10-service.out", "EOF", "chmod +x /usr/local/sbin/rhcsa10-service.sh"], ["cat > /etc/systemd/system/rhcsa10-service.service <<'EOF'", "[Unit]", "Description=RHCSA10 oneshot service", "", "[Service]", "Type=oneshot", "ExecStart=/usr/local/sbin/rhcsa10-service.sh", "", "[Install]", "WantedBy=multi-user.target", "EOF"], ["systemctl daemon-reload", "systemctl enable --now rhcsa10-service.service"]]),
        timer_lab(31, "rhcsa10-timer", 5),
        lab("rhcsa10-lab-32-cron", "RHCSA 10 Lab 32: Cron Job", "Schedule recurring tasks with cron", ["software-scheduling-time"], 20, ["Create user cron10 and set password cinder9.", "Configure a cron job for cron10 that writes CRON10 to /home/cron10/cron10.log every 5 minutes.", "Ensure crond is enabled and running."], ["Use crontab -u cron10 -e.", "Use */5 for every five minutes."], ["getent passwd cron10 >/dev/null", "crontab -l -u cron10 2>/dev/null | grep -Fqx '*/5 * * * * echo CRON10 >> /home/cron10/cron10.log'", "systemctl is-enabled crond | grep -qx enabled && systemctl is-active crond | grep -qx active"], [["useradd cron10", "passwd cron10", "# enter: cinder9"], ["echo '*/5 * * * * echo CRON10 >> /home/cron10/cron10.log' | crontab -u cron10 -"], ["systemctl enable --now crond"]]),
        lab("rhcsa10-lab-33-at-job", "RHCSA 10 Lab 33: At Job", "Schedule one-time tasks with at", ["software-scheduling-time"], 20, ["Create user at10 and set password cinder9.", "Enable and start atd.", "As at10, schedule a job that appends AT10 to /home/at10/at10.log two minutes from now."], ["Use standard input to submit the at job.", "Use atq to verify a queued job."], ["getent passwd at10 >/dev/null", "systemctl is-enabled atd | grep -qx enabled && systemctl is-active atd | grep -qx active", "atq | grep -q at10"], [["useradd at10", "passwd at10", "# enter: cinder9"], ["systemctl enable --now atd"], ["su - at10", "echo 'echo AT10 >> /home/at10/at10.log' | at now + 2 minutes", "atq"]]),
        lab("rhcsa10-lab-34-grub-argument", "RHCSA 10 Lab 34: Kernel Argument", "Persistently modify bootloader kernel arguments", ["boot-and-recovery"], 20, ["Add kernel argument audit_backlog_limit=8192 persistently.", "Regenerate the GRUB configuration.", "Verify the argument is present in /etc/default/grub or grubby output."], ["Use grubby --update-kernel=ALL.", "Do not rely on a one-time GRUB edit."], ["grubby --info=ALL | grep -q 'audit_backlog_limit=8192'", "grep -q 'audit_backlog_limit=8192' /etc/default/grub || grubby --info=ALL | grep -q 'audit_backlog_limit=8192'", "grubby --default-kernel >/dev/null"], [["grubby --update-kernel=ALL --args='audit_backlog_limit=8192'"], ["grub2-mkconfig -o /boot/grub2/grub.cfg"], ["grubby --info=ALL | grep audit_backlog_limit"]]),
        lab("rhcsa10-lab-35-root-recovery", "RHCSA 10 Lab 35: Root Recovery", "Practice the root password recovery workflow", ["boot-and-recovery"], 20, ["From the console, interrupt boot and enter emergency recovery mode.", "Set the root password to cinder9.", "Relabel the system if SELinux requires it."], ["This is a console workflow.", "Use rd.break or emergency target practice in a real VM console."], ["echo 'console-only password recovery workflow is skipped in SSH replay mode'"], [["# console task: interrupt GRUB and boot with rd.break"], ["passwd root", "# enter: cinder9"], ["touch /.autorelabel", "reboot"]], points=[10, 10, 10]),
        lab("rhcsa10-lab-36-xfs-label-mount", "RHCSA 10 Lab 36: XFS Label Mount", "Create a labeled filesystem and mount persistently", ["storage-lvm"], 35, ["Create an XFS filesystem on /dev/sdb1 labeled RHCSA10DATA.", "Create mount point /mnt/rhcsa10data.", "Mount it persistently by label with default options."], ["Use mkfs.xfs -L.", "Use LABEL= in /etc/fstab."], ["blkid /dev/sdb1 | grep -q 'LABEL=\"RHCSA10DATA\"'", "findmnt -no TARGET /mnt/rhcsa10data | grep -qx /mnt/rhcsa10data", "grep -Eq '^LABEL=RHCSA10DATA[[:space:]]+/mnt/rhcsa10data[[:space:]]+xfs[[:space:]]+defaults' /etc/fstab"], [["parted -s /dev/sdb mklabel gpt mkpart primary xfs 1MiB 512MiB", "mkfs.xfs -f -L RHCSA10DATA /dev/sdb1"], ["mkdir -p /mnt/rhcsa10data"], ["echo 'LABEL=RHCSA10DATA /mnt/rhcsa10data xfs defaults 0 0' >> /etc/fstab", "mount -a"]]),
        lab("rhcsa10-lab-37-swap", "RHCSA 10 Lab 37: Swap Space", "Add persistent swap space", ["storage-lvm"], 25, ["Create a 512 MiB swap partition on /dev/sdb.", "Enable the swap immediately.", "Make the swap persistent across reboots."], ["Use mkswap.", "Use UUID or device path in /etc/fstab."], ["swapon --show=NAME --noheadings | grep -qx /dev/sdb1", "blkid /dev/sdb1 | grep -q TYPE=\\\"swap\\\"", "grep -Eq '^/dev/sdb1[[:space:]]+swap[[:space:]]+swap[[:space:]]+defaults' /etc/fstab"], [["parted -s /dev/sdb mklabel gpt mkpart primary linux-swap 1MiB 513MiB", "mkswap /dev/sdb1"], ["swapon /dev/sdb1"], ["echo '/dev/sdb1 swap swap defaults 0 0' >> /etc/fstab"]]),
        lab("rhcsa10-lab-38-lvm-create", "RHCSA 10 Lab 38: LVM Create", "Create and mount a logical volume", ["storage-lvm"], 40, ["Create physical volume /dev/sdb.", "Create volume group vg10.", "Create a 256 MiB logical volume lvdata formatted with XFS and mounted at /mnt/lvdata10 persistently."], ["Use pvcreate, vgcreate, and lvcreate.", "Add the logical volume to /etc/fstab."], ["pvs /dev/sdb >/dev/null", "vgs vg10 >/dev/null && lvs /dev/vg10/lvdata >/dev/null", "findmnt -no TARGET /mnt/lvdata10 | grep -qx /mnt/lvdata10 && grep -Eq '/dev/vg10/lvdata[[:space:]]+/mnt/lvdata10' /etc/fstab"], [["pvcreate /dev/sdb"], ["vgcreate vg10 /dev/sdb"], ["lvcreate -L 256M -n lvdata vg10", "mkfs.xfs -f /dev/vg10/lvdata", "mkdir -p /mnt/lvdata10", "echo '/dev/vg10/lvdata /mnt/lvdata10 xfs defaults 0 0' >> /etc/fstab", "mount -a"]]),
        lab("rhcsa10-lab-39-lvm-extend", "RHCSA 10 Lab 39: LVM Extend", "Extend an existing logical volume and filesystem", ["storage-lvm"], 30, ["Create volume group grow10 on /dev/sdb.", "Create logical volume growlv with size 256 MiB and XFS filesystem mounted at /mnt/grow10.", "Extend the logical volume and filesystem to at least 384 MiB."], ["Use lvextend -r to resize the filesystem with the LV.", "Verify with lvs and findmnt."], ["lvs /dev/grow10/growlv >/dev/null", "findmnt -no TARGET /mnt/grow10 | grep -qx /mnt/grow10", "test $(lvs --noheadings -o LV_SIZE --units m --nosuffix /dev/grow10/growlv | awk '{printf \"%d\", $1}') -ge 384"], [["pvcreate /dev/sdb", "vgcreate grow10 /dev/sdb"], ["lvcreate -L 256M -n growlv grow10", "mkfs.xfs -f /dev/grow10/growlv", "mkdir -p /mnt/grow10", "mount /dev/grow10/growlv /mnt/grow10"], ["lvextend -L 384M -r /dev/grow10/growlv"]]),
        lab("rhcsa10-lab-40-vfat-filesystem", "RHCSA 10 Lab 40: VFAT Filesystem", "Create and mount a VFAT filesystem", ["storage-lvm"], 25, ["Create a 256 MiB partition on /dev/sdb.", "Format it as VFAT with label RHCSA10VFAT.", "Mount it persistently at /mnt/vfat10."], ["Use mkfs.vfat -n.", "Use vfat in /etc/fstab."], ["blkid /dev/sdb1 | grep -q 'TYPE=\"vfat\"'", "blkid /dev/sdb1 | grep -q 'LABEL_FATBOOT=\"RHCSA10VFAT\"\\|LABEL=\"RHCSA10VFAT\"'", "findmnt -no TARGET /mnt/vfat10 | grep -qx /mnt/vfat10"], [["parted -s /dev/sdb mklabel gpt mkpart primary fat32 1MiB 257MiB"], ["mkfs.vfat -n RHCSA10VFAT /dev/sdb1"], ["mkdir -p /mnt/vfat10", "echo 'LABEL=RHCSA10VFAT /mnt/vfat10 vfat defaults 0 0' >> /etc/fstab", "mount -a"]]),
        lab("rhcsa10-lab-41-nfs-mount", "RHCSA 10 Lab 41: NFS Direct Mount", "Mount a network filesystem persistently", ["filesystems-and-autofs"], 30, ["Create mount point /mnt/serverdirect10.", "Mount server:/exports/direct at /mnt/serverdirect10.", "Make the mount persistent across reboots."], ["Use nfs as the filesystem type.", "Use _netdev for network mounts."], ["test -d /mnt/serverdirect10", "findmnt -no SOURCE,TARGET /mnt/serverdirect10 | grep -qx 'server:/exports/direct /mnt/serverdirect10'", "grep -Eq '^server:/exports/direct[[:space:]]+/mnt/serverdirect10[[:space:]]+nfs' /etc/fstab"], [["mkdir -p /mnt/serverdirect10"], ["mount -t nfs server:/exports/direct /mnt/serverdirect10"], ["echo 'server:/exports/direct /mnt/serverdirect10 nfs defaults,_netdev 0 0' >> /etc/fstab"]], requires_server=True),
        lab("rhcsa10-lab-42-autofs", "RHCSA 10 Lab 42: Autofs", "Configure automount for NFS exports", ["filesystems-and-autofs"], 35, ["Install autofs if needed.", "Configure /remote10/projects to automount server:/exports/autofs/projects.", "Enable and start autofs."], ["Use a direct map or an indirect map.", "Access the path once to trigger mounting."], ["rpm -q autofs >/dev/null", "grep -Eq '^/remote10[[:space:]]+/etc/auto.remote10' /etc/auto.master.d/rhcsa10.autofs", "systemctl is-enabled autofs | grep -qx enabled && systemctl is-active autofs | grep -qx active"], [["dnf install -y autofs"], ["mkdir -p /remote10", "echo '/remote10 /etc/auto.remote10' > /etc/auto.master.d/rhcsa10.autofs", "echo 'projects -ro server:/exports/autofs/projects' > /etc/auto.remote10"], ["systemctl enable --now autofs", "ls /remote10/projects || true"]], requires_server=True),
        lab("rhcsa10-lab-43-sticky-directory", "RHCSA 10 Lab 43: Sticky Directory", "Configure shared directory permissions", ["selinux-and-default-perms"], 20, ["Create group share10.", "Create /srv/share10 owned by root:share10.", "Set permissions so group members can write and only owners can delete their own files."], ["Use chmod 3770 for setgid plus sticky.", "Use chgrp or chown to set the group."], ["getent group share10 >/dev/null", "stat -c '%U:%G' /srv/share10 | grep -qx root:share10", "stat -c '%a' /srv/share10 | grep -qx 3770"], [["groupadd share10"], ["mkdir -p /srv/share10", "chown root:share10 /srv/share10"], ["chmod 3770 /srv/share10"]]),
        lab("rhcsa10-lab-44-permission-repair", "RHCSA 10 Lab 44: Permission Repair", "Diagnose and repair file permission problems", ["selinux-and-default-perms"], 20, ["Create /srv/repair10/report.txt.", "Make the file readable and writable by owner and group, and unreadable by others.", "Ensure the parent directory allows group traversal."], ["Use chmod 660 for the file.", "Use chmod 770 for the directory."], ["test -f /srv/repair10/report.txt", "stat -c '%a' /srv/repair10/report.txt | grep -qx 660", "stat -c '%a' /srv/repair10 | grep -qx 770"], [["mkdir -p /srv/repair10", "touch /srv/repair10/report.txt"], ["chmod 660 /srv/repair10/report.txt"], ["chmod 770 /srv/repair10"]]),
        lab("rhcsa10-lab-45-secure-copy", "RHCSA 10 Lab 45: Secure Copy", "Securely transfer files between systems", ["users-sudo-ssh"], 25, ["Create /root/rhcsa10-transfer.txt containing TRANSFER10.", "Copy the file to server:/root/rhcsa10-transfer.txt.", "Verify the file exists on server."], ["Use scp or rsync over SSH.", "Use the server hostname from /etc/hosts."], ["test -f /root/rhcsa10-transfer.txt", "# server test \"$(cat /root/rhcsa10-transfer.txt)\" = TRANSFER10", "# server test -f /root/rhcsa10-transfer.txt"], [["echo TRANSFER10 > /root/rhcsa10-transfer.txt"], ["scp /root/rhcsa10-transfer.txt root@server:/root/rhcsa10-transfer.txt"], ["ssh root@server 'cat /root/rhcsa10-transfer.txt'"]], requires_server=True),
        lab("rhcsa10-lab-46-package-file-install", "RHCSA 10 Lab 46: Local RPM Install", "Install software from a local RPM file", ["software-management"], 20, ["Find an RPM named tree under /var/www/html/repo or the mounted ISO.", "Install the local RPM file without enabling external repositories.", "Verify that tree is installed."], ["Use find to locate tree*.rpm.", "Use dnf install /path/to/package.rpm."], ["rpm -q tree >/dev/null", "command -v tree >/dev/null", "rpm -q tree >/dev/null"], [["rpm_path=$(find /var/www/html/repo /mnt/rhcsa-bootstrap-iso -name 'tree-*.rpm' 2>/dev/null | head -n1)", "test -n \"$rpm_path\""], ["dnf install -y \"$rpm_path\""], ["rpm -q tree"]], requires_server=True),
        lab("rhcsa10-lab-47-documentation", "RHCSA 10 Lab 47: Local Documentation", "Locate and use local documentation", ["essential-tools"], 15, ["Create /root/rhcsa10-man.txt.", "Write the first SYNOPSIS line from man useradd to the file.", "Ensure the file is not empty."], ["Use man useradd.", "Use grep to find SYNOPSIS."], ["test -s /root/rhcsa10-man.txt", "grep -qi SYNOPSIS /root/rhcsa10-man.txt", "wc -l /root/rhcsa10-man.txt | awk '{exit !($1 >= 1)}'"], [["man useradd | col -b | grep -m1 -A1 '^SYNOPSIS' > /root/rhcsa10-man.txt"], ["cat /root/rhcsa10-man.txt"], ["test -s /root/rhcsa10-man.txt"]]),
        lab("rhcsa10-lab-48-service-network-boot", "RHCSA 10 Lab 48: Network Service Boot", "Configure network services to start at boot", ["networking-and-firewall"], 20, ["Install httpd if needed.", "Enable and start httpd.", "Allow the http service permanently in firewalld."], ["Use systemctl enable --now.", "Use firewall-cmd --permanent and reload."], ["rpm -q httpd >/dev/null", "systemctl is-enabled httpd | grep -qx enabled && systemctl is-active httpd | grep -qx active", "firewall-cmd --permanent --query-service=http && firewall-cmd --query-service=http"], [["dnf install -y httpd"], ["systemctl enable --now httpd"], ["firewall-cmd --permanent --add-service=http", "firewall-cmd --reload"]]),
    ]


def exam_task_pool(seed: int) -> list[dict[str, Any]]:
    letter = chr(ord("a") + seed)
    user = f"user{letter}10"
    group = f"team{letter}10"
    remote = f"exam{letter}flatpak"
    timer = f"exam{letter}timer"
    return [
        q("Configure hostname and hosts entry", f"Set hostname to client{letter}.exam10.lab and map server{letter}.exam10.lab to 192.168.122.3.", "networking-and-firewall", [f"hostnamectl --static | grep -qx client{letter}.exam10.lab", f"grep -Eq '^192\\.168\\.122\\.3[[:space:]]+server{letter}\\.exam10\\.lab$' /etc/hosts"], [[f"hostnamectl set-hostname client{letter}.exam10.lab", f"echo '192.168.122.3 server{letter}.exam10.lab' >> /etc/hosts"]]),
        q("Configure IPv4 profile", f"Set System eth1 to 192.168.122.{60+seed}/24 with gateway 192.168.122.1 and DNS 192.168.122.3.", "networking-and-firewall", [f"nmcli -g ipv4.addresses connection show 'System eth1' | grep -qx '192.168.122.{60+seed}/24'"], [[f"nmcli connection modify 'System eth1' ipv4.addresses 192.168.122.{60+seed}/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes", "nmcli connection up 'System eth1'"]]),
        q("Configure RPM repositories", "Create enabled BaseOS and AppStream repository definitions using http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.", "software-management", ["grep -ERq '^baseurl=http://server/repo/BaseOS/?$' /etc/yum.repos.d", "grep -ERq '^baseurl=http://server/repo/AppStream/?$' /etc/yum.repos.d"], [["cat > /etc/yum.repos.d/rhcsa10-exam.repo <<'EOF'", "[rhcsa10-exam-baseos]", "name=RHCSA10 Exam BaseOS", "baseurl=http://server/repo/BaseOS/", "enabled=1", "gpgcheck=0", "", "[rhcsa10-exam-appstream]", "name=RHCSA10 Exam AppStream", "baseurl=http://server/repo/AppStream/", "enabled=1", "gpgcheck=0", "EOF"]]),
        q("Configure Flatpak remote", f"Create system Flatpak remote {remote} pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.", "software-management", [f"flatpak remotes --system --columns=name,url 2>/dev/null | awk '$1 == \"{remote}\" && $2 == \"file:///opt/rhcsa/flatpak/repo\" {{found=1}} END {{exit !found}}'"], [[f"flatpak remote-add --system --if-not-exists --no-gpg-verify {remote} file:///opt/rhcsa/flatpak/repo"]]),
        q("Install and remove Flatpak app", f"Install org.rhcsa.Tools from {remote}, then remove it after verification.", "software-management", ["! flatpak list --system --app --columns=application 2>/dev/null | grep -qx org.rhcsa.Tools"], [[f"flatpak install --system -y {remote} org.rhcsa.Tools", "flatpak list --system --app", "flatpak uninstall --system -y org.rhcsa.Tools"]]),
        q("Create user and group", f"Create group {group}, create user {user}, set password cinder9, and add the user to {group}.", "users-sudo-ssh", [f"getent group {group} >/dev/null", f"id -nG {user} | tr ' ' '\\n' | grep -qx {group}"], [[f"groupadd {group}", f"useradd -G {group} {user}", f"passwd {user}", "# enter: cinder9"]]),
        q("Delegate sudo access", f"Allow %{group} to run /usr/bin/systemctl without a password by using a sudoers drop-in.", "users-sudo-ssh", [f"grep -ERq '^%{group}[[:space:]]+ALL=\\(ALL\\)[[:space:]]+NOPASSWD:[[:space:]]*/usr/bin/systemctl$' /etc/sudoers.d"], [[f"echo '%{group} ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/{group}", f"chmod 440 /etc/sudoers.d/{group}"]]),
        q("Set password aging", f"Set maximum password age for {user} to {45+seed} days and warning period to 7 days.", "users-sudo-ssh", [f"chage -l {user} | grep -Eq 'Maximum.*{45+seed}'"], [[f"chage -M {45+seed} -W 7 {user}"]]),
        q("Create argument script", f"Create /usr/local/bin/{letter}-who that prints the primary group for the supplied user argument.", "shell-scripting", [f"test -x /usr/local/bin/{letter}-who", f"/usr/local/bin/{letter}-who root | grep -qx root"], [[f"cat > /usr/local/bin/{letter}-who <<'EOF'", "#!/bin/bash", "test -n \"${1:-}\" || exit 2", "id -gn \"$1\"", "EOF", f"chmod +x /usr/local/bin/{letter}-who"]]),
        q("Filter shell users", f"Write users whose shell ends with sh to /root/{letter}-shell-users.txt.", "essential-tools", [f"test -s /root/{letter}-shell-users.txt", f"grep -q '^root$' /root/{letter}-shell-users.txt"], [[f"awk -F: '$7 ~ /sh$/ {{print $1}}' /etc/passwd | sort > /root/{letter}-shell-users.txt"]]),
        q("Create archive", f"Create gzip archive /root/{letter}-etc.tar.gz containing /etc/hosts and /etc/fstab.", "essential-tools", [f"test -f /root/{letter}-etc.tar.gz", f"tar -tzf /root/{letter}-etc.tar.gz | grep -Eq 'etc/(hosts|fstab)'"], [[f"tar -czf /root/{letter}-etc.tar.gz /etc/hosts /etc/fstab", f"tar -tzf /root/{letter}-etc.tar.gz"]]),
        q("Create links", f"Create /root/{letter}-original, hard link /root/{letter}-hard, and symlink /root/{letter}-soft.", "essential-tools", [f"test \"$(stat -c %i /root/{letter}-original)\" = \"$(stat -c %i /root/{letter}-hard)\"", f"test -L /root/{letter}-soft"], [[f"echo link > /root/{letter}-original", f"ln /root/{letter}-original /root/{letter}-hard", f"ln -s /root/{letter}-original /root/{letter}-soft"]]),
        q("Configure firewalld", f"Allow TCP port {8100+seed} permanently in firewalld and reload.", "networking-and-firewall", [f"firewall-cmd --permanent --query-port={8100+seed}/tcp", f"firewall-cmd --query-port={8100+seed}/tcp"], [[f"firewall-cmd --permanent --add-port={8100+seed}/tcp", "firewall-cmd --reload"]]),
        q("Restore SELinux context", f"Create /var/www/html/{letter}.html and restore its default SELinux context.", "selinux-and-default-perms", [f"ls -Z /var/www/html/{letter}.html | grep -q httpd_sys_content_t"], [[f"echo {letter} > /var/www/html/{letter}.html", f"chcon -t user_tmp_t /var/www/html/{letter}.html", f"restorecon -v /var/www/html/{letter}.html"]]),
        q("Set SELinux boolean", "Persistently enable httpd_can_network_connect.", "selinux-and-default-perms", ["getsebool httpd_can_network_connect | grep -Eq -- '--> on$'"], [["setsebool -P httpd_can_network_connect on"]]),
        q("Create sticky directory", f"Create /srv/{group} owned by root:{group} with mode 3770.", "selinux-and-default-perms", [f"stat -c '%G:%a' /srv/{group} | grep -qx {group}:3770"], [[f"mkdir -p /srv/{group}", f"chown root:{group} /srv/{group}", f"chmod 3770 /srv/{group}"]]),
        q("Set tuned profile", "Activate the throughput-performance tuned profile.", "processes-logs-tuning", ["tuned-adm active | grep -q throughput-performance"], [["systemctl enable --now tuned", "tuned-adm profile throughput-performance"]]),
        q("Preserve journal", "Configure persistent systemd journal storage.", "processes-logs-tuning", ["test -d /var/log/journal", "grep -Eq '^Storage=persistent$' /etc/systemd/journald.conf"], [["mkdir -p /var/log/journal", "sed -i 's/^#\\?Storage=.*/Storage=persistent/' /etc/systemd/journald.conf", "systemctl restart systemd-journald"]]),
        q("Configure chrony", "Use server as the only chrony source and enable chronyd.", "processes-logs-tuning", ["grep -Eq '^server server iburst$' /etc/chrony.conf", "systemctl is-enabled chronyd | grep -qx enabled"], [["sed -i '/^pool /d;/^server /d' /etc/chrony.conf", "echo 'server server iburst' >> /etc/chrony.conf", "systemctl enable --now chronyd"]]),
        q("Create systemd timer", f"Create and enable {timer}.timer that runs every 10 minutes.", "software-scheduling-time", [f"systemctl cat {timer}.timer | grep -Fqx 'OnCalendar=*:0/10'", f"systemctl is-enabled {timer}.timer | grep -qx enabled"], [[f"cat > /usr/local/sbin/{timer}.sh <<'EOF'", "#!/bin/bash", f"echo {timer} >> /var/log/{timer}.log", "EOF", f"chmod +x /usr/local/sbin/{timer}.sh", f"cat > /etc/systemd/system/{timer}.service <<'EOF'", "[Service]", "Type=oneshot", f"ExecStart=/usr/local/sbin/{timer}.sh", "EOF", f"cat > /etc/systemd/system/{timer}.timer <<'EOF'", "[Timer]", "OnCalendar=*:0/10", "Persistent=true", "[Install]", "WantedBy=timers.target", "EOF", "systemctl daemon-reload", f"systemctl enable --now {timer}.timer"]]),
        q("Create cron job", f"Create a cron job for {user} that writes EXAM10 to /home/{user}/exam10.log every 15 minutes.", "software-scheduling-time", [f"crontab -l -u {user} 2>/dev/null | grep -Fqx '*/15 * * * * echo EXAM10 >> /home/{user}/exam10.log'"], [[f"echo '*/15 * * * * echo EXAM10 >> /home/{user}/exam10.log' | crontab -u {user} -"]]),
        q("Mount NFS export", f"Mount server:/exports/direct at /mnt/{letter}direct persistently.", "filesystems-and-autofs", [f"findmnt -no SOURCE,TARGET /mnt/{letter}direct | grep -qx 'server:/exports/direct /mnt/{letter}direct'"], [[f"mkdir -p /mnt/{letter}direct", f"echo 'server:/exports/direct /mnt/{letter}direct nfs defaults,_netdev 0 0' >> /etc/fstab", "mount -a"]]),
        q("Configure autofs", f"Configure autofs so /remote{letter}/projects mounts server:/exports/autofs/projects.", "filesystems-and-autofs", [f"grep -Eq '^/remote{letter}[[:space:]]+/etc/auto.remote{letter}' /etc/auto.master.d/{letter}.autofs", "systemctl is-enabled autofs | grep -qx enabled"], [[f"mkdir -p /remote{letter}", f"echo '/remote{letter} /etc/auto.remote{letter}' > /etc/auto.master.d/{letter}.autofs", f"echo 'projects -ro server:/exports/autofs/projects' > /etc/auto.remote{letter}", "systemctl enable --now autofs"]]),
        q("Create LVM mount", f"Create VG vg{letter}10 and LV data{letter} mounted at /mnt/data{letter}10.", "storage-lvm", [f"lvs /dev/vg{letter}10/data{letter} >/dev/null", f"findmnt -no TARGET /mnt/data{letter}10 | grep -qx /mnt/data{letter}10"], [[f"pvcreate /dev/sdb", f"vgcreate vg{letter}10 /dev/sdb", f"lvcreate -L 256M -n data{letter} vg{letter}10", f"mkfs.xfs -f /dev/vg{letter}10/data{letter}", f"mkdir -p /mnt/data{letter}10", f"echo '/dev/vg{letter}10/data{letter} /mnt/data{letter}10 xfs defaults 0 0' >> /etc/fstab", "mount -a"]]),
        q("Set default target", "Set the default target to multi-user.target without rebooting.", "boot-and-recovery", ["systemctl get-default | grep -qx multi-user.target"], [["systemctl set-default multi-user.target", "systemctl get-default"]]),
        q("Install local RPM package", "Install lsof and ensure tcpdump is removed.", "software-management", ["rpm -q lsof >/dev/null", "! rpm -q tcpdump >/dev/null 2>&1"], [["dnf install -y lsof", "dnf remove -y tcpdump"]]),
    ]


def q(title: str, task: str, tag: str, checks: list[str], commands: list[list[str]]) -> dict[str, Any]:
    return {
        "title": title,
        "task": task,
        "tag": tag,
        "checks": checks,
        "commands": commands,
    }


def make_exam(seed: int) -> dict[str, Any]:
    by_title = {item["title"]: item for item in exam_task_pool(seed)}
    foundation = [
        "Configure hostname and hosts entry",
        "Configure IPv4 profile",
        "Configure RPM repositories",
        "Configure Flatpak remote",
        "Install and remove Flatpak app",
        "Create user and group",
        "Delegate sudo access",
        "Set password aging",
        "Create argument script",
        "Filter shell users",
        "Create archive",
        "Create links",
        "Create systemd timer",
        "Create LVM mount",
    ]
    optional_by_seed = [
        ["Configure firewalld", "Restore SELinux context", "Set SELinux boolean", "Create sticky directory", "Set tuned profile", "Preserve journal", "Configure chrony", "Create cron job"],
        ["Restore SELinux context", "Set SELinux boolean", "Set tuned profile", "Preserve journal", "Create cron job", "Mount NFS export", "Set default target", "Install local RPM package"],
        ["Configure firewalld", "Restore SELinux context", "Set tuned profile", "Preserve journal", "Create cron job", "Mount NFS export", "Configure autofs", "Set default target"],
        ["Restore SELinux context", "Set SELinux boolean", "Preserve journal", "Configure chrony", "Create cron job", "Configure autofs", "Set default target", "Install local RPM package"],
        ["Configure firewalld", "Restore SELinux context", "Set tuned profile", "Create cron job", "Mount NFS export", "Set default target", "Install local RPM package", "Preserve journal"],
        ["Set SELinux boolean", "Restore SELinux context", "Set tuned profile", "Preserve journal", "Create cron job", "Set default target", "Install local RPM package", "Configure firewalld"],
        ["Configure firewalld", "Restore SELinux context", "Set SELinux boolean", "Set tuned profile", "Preserve journal", "Create cron job", "Set default target", "Install local RPM package"],
        ["Set SELinux boolean", "Set tuned profile", "Preserve journal", "Configure chrony", "Create cron job", "Set default target", "Install local RPM package", "Configure firewalld"],
    ]
    selected = foundation + optional_by_seed[seed % len(optional_by_seed)]
    pool = [by_title[title] for title in selected]
    tasks = [item["task"] for item in pool]
    titles = [item["title"] for item in pool]
    checks = [" && ".join(item["checks"]) for item in pool]
    commands = [sum(item["commands"], []) for item in pool]
    points = [5] * 12 + [4] * 10
    sid = f"rhcsa10-mock-exam-{chr(ord('a') + seed)}"
    tags = sorted({item["tag"] for item in pool})
    return scenario(
        "exam",
        sid,
        f"RHCSA 10 Mock Exam {chr(ord('A') + seed)}",
        "A RHCSA 10 mock exam focused on RHEL 10 administration, Flatpak, systemd timers, storage, networking, users, security, and services.",
        tags,
        180,
        {
            "tasks": tasks,
            "hints": [
                "Make changes persistent unless a question says otherwise.",
                "Use local repositories and local documentation; do not depend on internet access.",
                "Flatpak and systemd timer tasks belong to the RHCSA 10 track.",
            ],
            "checks": checks,
            "solution_outline": ["Work through each question independently and verify before moving on."],
            "task_titles": titles,
            "task_points": points,
            "solution_commands": commands,
        },
        requires_server=True,
    )


def main() -> int:
    clean_generated()
    for item in simple_labs():
        write_json(LABS_ROOT / item["id"] / "scenario.json", item)
    for seed in range(8):
        item = make_exam(seed)
        write_json(EXAMS_ROOT / item["id"] / "scenario.json", item)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
