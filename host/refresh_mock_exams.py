#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

from scenario_solution_normalizer import normalize_command_list

ROOT = Path(__file__).resolve().parents[1]
EXAMS_DIR = ROOT / "scenarios" / "exams"
POINTS = [5] * 12 + [4] * 10


def load_exam(exam_id: str) -> dict:
    return json.loads((EXAMS_DIR / exam_id / "scenario.json").read_text())


def save_exam(exam_id: str, data: dict) -> None:
    (EXAMS_DIR / exam_id / "scenario.json").write_text(json.dumps(data, indent=2) + "\n")


def block(title: str, task: str, commands: list[str]) -> tuple[str, str, list[str]]:
    return (title, task.strip(), commands)


def slice_blocks(exam: dict, start: int, end: int) -> list[tuple[str, str, list[str]]]:
    content = exam["content"]["exam"]
    return list(zip(content["task_titles"][start:end], content["tasks"][start:end], content["solution_commands"][start:end]))


def apply_blocks(exam_id: str, *, title: str, description: str, objective_tags: list[str], password_recovery: bool, blocks: list[tuple[str, str, list[str]]], checks: list[str]) -> None:
    data = load_exam(exam_id)
    exam = data["content"]["exam"]
    data["title"] = title
    data["description"] = description
    data["objective_tags"] = objective_tags
    data["flags"]["password_recovery"] = password_recovery
    exam["task_titles"] = [item[0] for item in blocks]
    exam["tasks"] = [item[1] for item in blocks]
    exam["solution_commands"] = [normalize_command_list(item[2]) for item in blocks]
    exam["task_points"] = POINTS
    exam["checks"] = checks
    save_exam(exam_id, data)


def main() -> int:
    exams = {exam_id: load_exam(exam_id) for exam_id in (
        "mock-exam-a",
        "mock-exam-b",
        "mock-exam-c",
        "mock-exam-d",
        "mock-exam-e",
        "mock-exam-f",
        "mock-exam-g",
        "mock-exam-h",
    )}

    apply_blocks(
        "mock-exam-a",
        title="Mock Exam A",
        description="A 22 task RHCSA style mock exam focused on recovery, repositories, Apache, sudo delegation, storage, and rootless containers.",
        objective_tags=["boot-and-recovery", "networking-and-firewall", "users-sudo-ssh", "storage-lvm", "containers"],
        password_recovery=True,
        blocks=[
            block("Root Recovery", "Recover root access on clientvm from the console.\n\nSet the root password to: cinder9", [
                "# At the boot menu, edit the selected kernel entry.",
                "# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.",
                "passwd root",
                "# enter: cinder9",
                "touch /.autorelabel",
                "exec /sbin/init",
            ]),
            block("Client Network", "Configure networking on clientvm with the following settings:\n\nIP ADDRESS: 192.168.122.26\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: clientvm.exam-a.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.26/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname clientvm.exam-a.lab",
            ]),
            block("Bootloader Kernel Argument", "Configure the bootloader on clientvm so every installed kernel boots with the kernel argument audit_backlog_limit=8192.\n\nRequirements:\n- The change must persist across reboots.\n- Do not rely on a one-time GRUB edit.", [
                "grubby --update-kernel=ALL --args=\"audit_backlog_limit=8192\"",
            ]),
            block("Client Repositories", "Configure a repository file on clientvm with the following settings:\n\nBaseOS: http://servervm/repo/BaseOS/\nAppStream: http://servervm/repo/AppStream/\ngpgcheck: disabled\nRepositories: enabled", [
                "cat > /etc/yum.repos.d/opsa.repo <<'EOF'",
                "[opsa-baseos]",
                "name=OpsA BaseOS",
                "baseurl=http://servervm/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[opsa-appstream]",
                "name=OpsA AppStream",
                "baseurl=http://servervm/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Server Repositories", "Configure the same repository file on servervm.\n\nBaseOS: http://servervm/repo/BaseOS/\nAppStream: http://servervm/repo/AppStream/\ngpgcheck: disabled\nRepositories: enabled", [
                "# Run on servervm",
                "cat > /etc/yum.repos.d/opsa.repo <<'EOF'",
                "[opsa-baseos]",
                "name=OpsA BaseOS",
                "baseurl=http://servervm/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[opsa-appstream]",
                "name=OpsA AppStream",
                "baseurl=http://servervm/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Apache SELinux Port", "Configure Apache on clientvm so it serves the existing site on TCP port 8282.\n\nRequirements:\n- Start the service automatically at boot.\n- Open the port permanently in the firewall.\n- Make the SELinux change required for the new port.\n- Leave the existing document root content in place.", [
                "sed -i 's/^Listen .*/Listen 8282/' /etc/httpd/conf/httpd.conf",
                "systemctl enable --now httpd",
                "firewall-cmd --permanent --add-port=8282/tcp",
                "firewall-cmd --reload",
                "semanage port -a -t http_port_t -p tcp 8282 || semanage port -m -t http_port_t -p tcp 8282",
                "systemctl restart httpd",
            ]),
            block("Users And Group", "Create group sysopsa and users violet and amber with sysopsa as a supplementary group at creation time. Create user frost without a home directory and with login shell /sbin/nologin.", [
                "groupadd sysopsa",
                "useradd -G sysopsa violet",
                "useradd -G sysopsa amber",
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
            block("Host Entry", "Add a persistent hosts entry on clientvm so api.exam-a.lab resolves to 192.168.122.3.", [
                "grep -q 'api.exam-a.lab' /etc/hosts || echo '192.168.122.3 api.exam-a.lab' >> /etc/hosts",
            ]),
            *slice_blocks(exams["mock-exam-a"], 13, 22),
            block("Persistent Journal", "On servervm, enable persistent systemd journal storage and restart systemd-journald.", [
                "# Run on servervm",
                "mkdir -p /var/log/journal",
                "mkdir -p /etc/systemd/journald.conf.d",
                "cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'",
                "[Journal]",
                "Storage=persistent",
                "EOF",
                "systemctl restart systemd-journald",
            ]),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'clientvm.exam-a.lab' && grubby --info=ALL | grep -Eq 'args=.*audit_backlog_limit=8192' && grep -Fqx '192.168.122.3 api.exam-a.lab' /etc/hosts",
            "curl -fsS http://localhost:8282 >/dev/null && semanage port -l | grep -Eq '^http_port_t\\b.*\\b8282\\b' && curl -fsS http://servervm/repo/BaseOS/repodata/repomd.xml >/dev/null && ssh admin@servervm sudo curl -fsS http://servervm/repo/AppStream/repodata/repomd.xml >/dev/null",
            "getent group sysopsa >/dev/null && id -nG violet | tr ' ' '\\n' | grep -qx sysopsa && id -nG amber | tr ' ' '\\n' | grep -qx sysopsa && getent passwd frost | awk -F: '{print $6\":\"$7}' | grep -qx ':/sbin/nologin' && grep -Eq '^%sysopsa .* /usr/sbin/useradd$' /etc/sudoers.d/sysopsa-useradd && grep -Eq '^violet .*NOPASSWD: /usr/bin/passwd$' /etc/sudoers.d/violet-passwd && stat -c '%U:%G %a' /srv/sysopsa | grep -qx 'root:sysopsa 2770' && crontab -l -u amber | grep -Fqx '*/2 * * * * logger \"exam-a tick\"'",
            "getent passwd ash420 | awk -F: '{print $3}' | grep -qx '4420' && test -f /root/amber-files/opt/exam-a/find/a/file1.txt && grep -qx 'delta' /root/delta-lines && test -f /root/etc-opsa.tar.bz2 && /usr/local/bin/opsa-report >/dev/null && test -s /root/opsa-services.txt",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1==\"reviewa\" && $2==\"reviewvga\" && $3>=319 && $3<=321{f=1} END{exit !f}'",
            "runuser -l oriona -c 'podman ps --format {{.Names}}' | grep -qx pdfa && runuser -l oriona -c 'systemctl --user is-enabled container-pdfa.service' | grep -qx enabled && loginctl show-user oriona | grep -Eq '^Linger=yes$' && ssh admin@servervm sudo test -d /var/log/journal",
        ],
    )

    apply_blocks(
        "mock-exam-b",
        title="Mock Exam B",
        description="A 22 task RHCSA style mock exam emphasizing chrony, SSH hardening, user defaults, and storage administration.",
        objective_tags=["networking-and-firewall", "users-sudo-ssh", "processes-logs-tuning", "storage-lvm"],
        password_recovery=False,
        blocks=[
            block("Client Network", "Configure networking on clientvm with the following settings:\n\nIP ADDRESS: 192.168.122.27\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: clientvm.exam-b.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.27/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname clientvm.exam-b.lab",
            ]),
            block("Host Entry", "Add a persistent hosts entry so registry.exam-b.lab resolves to 192.168.122.3.", [
                "grep -q 'registry.exam-b.lab' /etc/hosts || echo '192.168.122.3 registry.exam-b.lab' >> /etc/hosts",
            ]),
            block("Chrony Server", "Configure chronyd on servervm so it serves time to 192.168.122.0/24 and starts automatically at boot.", [
                "# Run on servervm",
                "cat > /etc/chrony.conf <<'EOF'",
                "driftfile /var/lib/chrony/drift",
                "makestep 1.0 3",
                "rtcsync",
                "allow 192.168.122.0/24",
                "local stratum 10",
                "EOF",
                "systemctl enable --now chronyd",
            ]),
            block("Chrony Client", "Configure chronyd on clientvm so it synchronizes only with servervm and starts automatically at boot.", [
                "cat > /etc/chrony.conf <<'EOF'",
                "server servervm iburst",
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
            block("Primary Login User", "Create user mira with a home directory and password cinder9.", [
                "useradd mira",
                "echo cinder9 | passwd --stdin mira",
            ]),
            block("Password Aging", "Create user jonas with a home directory, password cinder9, and password aging of maximum 45 days, minimum 5 days, warning 7 days.", [
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
            block("Delegated Sudo", "Allow mira to restart firewalld on clientvm through sudo without a password prompt. Use a sudoers drop-in.", [
                "visudo -f /etc/sudoers.d/mira-firewalld",
                "mira ALL=(root) NOPASSWD: /usr/bin/systemctl restart firewalld",
            ]),
            block("SSH Port", "On servervm, configure sshd to listen on TCP port 2222 and keep password and public key authentication enabled.", [
                "# Run on servervm",
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
                "systemctl restart sshd",
            ]),
            block("Rich Rule", "On servervm, add a permanent rich firewall rule allowing TCP port 2222 only from 192.168.122.0/24.", [
                "# Run on servervm",
                "firewall-cmd --permanent --add-rich-rule='rule family=\"ipv4\" source address=\"192.168.122.0/24\" port protocol=\"tcp\" port=\"2222\" accept'",
                "firewall-cmd --reload",
            ]),
            block("SSH Key Generation", "As mira on clientvm, generate an ED25519 SSH key pair with no passphrase.", [
                "runuser -l mira -c 'ssh-keygen -t ed25519 -N \"\" -f ~/.ssh/id_ed25519'",
            ]),
            block("Passwordless SSH", "On servervm, create user meshremote with password cinder9 if it does not already exist. Then install mira's public key for meshremote and verify passwordless SSH access on port 2222.", [
                "# Run on servervm",
                "id meshremote >/dev/null 2>&1 || useradd meshremote",
                "echo cinder9 | passwd --stdin meshremote",
                "install -d -m 0755 -o meshremote -g meshremote /home/meshremote/inbox",
                "runuser -l mira -c 'ssh-copy-id -p 2222 meshremote@servervm'",
                "runuser -l mira -c 'ssh -p 2222 -o BatchMode=yes meshremote@servervm true'",
            ]),
            block("Rsync Transfer", "Use rsync over SSH port 2222 to copy /opt/exam-b/report.txt to /home/meshremote/inbox/report.txt on servervm.", [
                "runuser -l mira -c 'rsync -e \"ssh -p 2222\" /opt/exam-b/report.txt meshremote@servervm:/home/meshremote/inbox/report.txt'",
            ]),
            *slice_blocks(exams["mock-exam-b"], 13, 20),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'clientvm.exam-b.lab' && grep -Fqx '192.168.122.3 registry.exam-b.lab' /etc/hosts",
            "grep -Eq '^server servervm iburst$' /etc/chrony.conf && systemctl is-enabled chronyd | grep -qx enabled && ssh admin@servervm sudo grep -Eq '^allow 192\\.168\\.122\\.0/24$' /etc/chrony.conf && ssh admin@servervm sudo systemctl is-enabled chronyd | grep -qx enabled",
            "useradd -D | grep -Eq 'INACTIVE=20' && getent passwd cato421 | awk -F: '{print $3\":\"$6}' | grep -qx '4421:' && chage -l jonas | grep -Eq 'Maximum.*45' && grep -Eq '^minlen\\s*=\\s*12$' /etc/security/pwquality.conf.d/coremesh.conf && grep -Eq '^minclass\\s*=\\s*3$' /etc/security/pwquality.conf.d/coremesh.conf && grep -Eq '^mira .*NOPASSWD: /usr/bin/systemctl restart firewalld$' /etc/sudoers.d/mira-firewalld",
            "ssh admin@servervm sudo grep -Eq '^Port 2222$' /etc/ssh/sshd_config && ssh admin@servervm sudo firewall-cmd --list-rich-rules | grep -Fq 'port port=\"2222\" protocol=\"tcp\" accept' && runuser -l mira -c 'ssh -p 2222 -o BatchMode=yes meshremote@servervm true' && ssh admin@servervm test -f /home/meshremote/inbox/report.txt",
            "test -f /root/mira-files/opt/exam-b/find/a/file1.txt && grep -q 'proto' /root/proto-lines && test -f /root/usr-local-b.tar.bz2 && /usr/local/bin/corecheck >/dev/null && test -s /root/coremesh-units.txt",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1==\"reviewb\" && $2==\"reviewvgb\" && $3>=299 && $3<=301{f=1} END{exit !f}' && tuned-adm active | grep -Eq 'virtual-guest|throughput-performance'",
        ],
    )

    apply_blocks(
        "mock-exam-c",
        title="Mock Exam C",
        description="A 22 task RHCSA style mock exam centered on recovery, boot persistence, NFS, ACLs, journald, and rootless containers.",
        objective_tags=["boot-and-recovery", "filesystems-and-autofs", "users-sudo-ssh", "storage-lvm", "containers"],
        password_recovery=True,
        blocks=[
            block("Root Recovery", "Recover root access on clientvm from the console.\n\nSet the root password to: cinder9", [
                "# At the boot menu, edit the selected kernel entry.",
                "# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.",
                "passwd root",
                "# enter: cinder9",
                "touch /.autorelabel",
                "exec /sbin/init",
            ]),
            block("Client Network", "Configure networking on clientvm with the following settings:\n\nIP ADDRESS: 192.168.122.28\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: clientvm.exam-c.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.28/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname clientvm.exam-c.lab",
            ]),
            block("Bootloader Kernel Argument", "Configure the bootloader on clientvm so every installed kernel boots with the kernel argument audit_backlog_limit=8192.", [
                "grubby --update-kernel=ALL --args=\"audit_backlog_limit=8192\"",
            ]),
            block("Host Entry", "Add a persistent hosts entry so vault.exam-c.lab resolves to 192.168.122.3.", [
                "grep -q 'vault.exam-c.lab' /etc/hosts || echo '192.168.122.3 vault.exam-c.lab' >> /etc/hosts",
            ]),
            block("Direct NFS Mount", "Persistently mount servervm:/exports/bluec on /mnt/bluec using /etc/fstab.", [
                "mkdir -p /mnt/bluec",
                "grep -q '/mnt/bluec' /etc/fstab || echo 'servervm:/exports/bluec /mnt/bluec nfs defaults,_netdev 0 0' >> /etc/fstab",
                "mount -a",
            ]),
            block("Users And Group", "Create group infrac and users talia and ren with infrac as a supplementary group. Set the password of both users to cinder9.", [
                "groupadd infrac",
                "useradd -G infrac talia",
                "useradd -G infrac ren",
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
            block("Persistent Journal", "On servervm, enable persistent systemd journal storage and restart systemd-journald.", [
                "# Run on servervm",
                "mkdir -p /var/log/journal",
                "mkdir -p /etc/systemd/journald.conf.d",
                "cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'",
                "[Journal]",
                "Storage=persistent",
                "EOF",
                "systemctl restart systemd-journald",
            ]),
            block("User Umask", "Set a personal umask of 027 for user ren.", [
                "echo 'umask 027' >> /home/ren/.bash_profile",
            ]),
            block("Per-User Login Message", "Append a login message for ren to ~/.bash_profile that prints \"exam-c access\" when ren logs in.", [
                "echo 'echo exam-c access' >> /home/ren/.bash_profile",
            ]),
            *slice_blocks(exams["mock-exam-c"], 13, 22),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'clientvm.exam-c.lab' && grep -Fqx '192.168.122.3 vault.exam-c.lab' /etc/hosts && grubby --info=ALL | grep -Eq 'args=.*audit_backlog_limit=8192'",
            "mount | grep -Eq 'servervm:/exports/bluec on /mnt/bluec type nfs' && grep -q '/mnt/bluec' /etc/fstab && getent group infrac >/dev/null && id -nG talia | tr ' ' '\\n' | grep -qx infrac && id -nG ren | tr ' ' '\\n' | grep -qx infrac && getfacl -p /srv/infrac | grep -Fq 'default:group:infrac:rwx' && getent passwd remote63 | awk -F: '{print $6\":\"$7}' | grep -qx ':/sbin/nologin'",
            "chage -l talia | grep -Eq 'Maximum.*45' && grep -Fqx 'umask 027' /home/ren/.bash_profile && grep -Fqx 'echo exam-c access' /home/ren/.bash_profile && ssh admin@servervm sudo test -d /var/log/journal",
            "getent passwd kian431 | awk -F: '{print $3}' | grep -qx '4431' && test -f /root/ren-files/opt/exam-c/find/a/file1.txt && grep -q 'orbit' /root/orbit-lines && test -f /root/etc-c.tar.bz2 && /usr/local/bin/northcheck >/dev/null && test -s /root/northstar-services.txt",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1==\"reviewc\" && $2==\"reviewvgc\" && $3>=339 && $3<=341{f=1} END{exit !f}'",
            "runuser -l eirac -c 'podman ps --format {{.Names}}' | grep -qx pdfc && runuser -l eirac -c 'systemctl --user is-enabled container-pdfc.service' | grep -qx enabled && loginctl show-user eirac | grep -Eq '^Linger=yes$'",
        ],
    )

    apply_blocks(
        "mock-exam-d",
        title="Mock Exam D",
        description="A 22 task RHCSA style mock exam focused on repository hygiene, account defaults, server service state, and logical volume provisioning.",
        objective_tags=["networking-and-firewall", "users-sudo-ssh", "software-management", "storage-lvm"],
        password_recovery=False,
        blocks=[
            block("Client Network", "Configure networking on clientvm with the following settings:\n\nIP ADDRESS: 192.168.122.36\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: clientvm.summit.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.36/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname clientvm.summit.lab",
            ]),
            block("Host Entry", "Add a persistent hosts entry so mirror.summit.lab resolves to 192.168.122.3.", [
                "grep -q 'mirror.summit.lab' /etc/hosts || echo '192.168.122.3 mirror.summit.lab' >> /etc/hosts",
            ]),
            block("Client Repositories", "Configure a repository file on clientvm with BaseOS and AppStream served from servervm, enabled, and with gpgcheck disabled.", [
                "cat > /etc/yum.repos.d/summit.repo <<'EOF'",
                "[summit-baseos]",
                "name=Summit BaseOS",
                "baseurl=http://servervm/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[summit-appstream]",
                "name=Summit AppStream",
                "baseurl=http://servervm/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Server Repositories", "Configure the same repository file on servervm.", [
                "# Run on servervm",
                "cat > /etc/yum.repos.d/summit.repo <<'EOF'",
                "[summit-baseos]",
                "name=Summit BaseOS",
                "baseurl=http://servervm/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[summit-appstream]",
                "name=Summit AppStream",
                "baseurl=http://servervm/repo/AppStream/",
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
            block("Server Login Messages", "On servervm, configure both /etc/issue and /etc/motd to contain the line Summit maintenance host.", [
                "# Run on servervm",
                "echo 'Summit maintenance host' > /etc/issue",
                "echo 'Summit maintenance host' > /etc/motd",
            ]),
            block("Server Default Target", "On servervm, set the default target to multi-user.target, ensure rsyslog is enabled, and ensure postfix is disabled.", [
                "# Run on servervm",
                "systemctl set-default multi-user.target",
                "systemctl enable --now rsyslog",
                "systemctl disable --now postfix",
            ]),
            block("Package Management", "On servervm, install tree and remove dos2unix.", [
                "# Run on servervm",
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
            block("Audit Directory", "Create /srv/summit-audit on clientvm with mode 0750 and ownership root:root.", [
                "install -d -m 0750 -o root -g root /srv/summit-audit",
            ]),
            *slice_blocks(exams["mock-exam-d"], 15, 21),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'clientvm.summit.lab' && grep -Fqx '192.168.122.3 mirror.summit.lab' /etc/hosts && curl -fsS http://servervm/repo/BaseOS/repodata/repomd.xml >/dev/null && ssh admin@servervm sudo curl -fsS http://servervm/repo/AppStream/repodata/repomd.xml >/dev/null",
            "useradd -D | grep -Eq 'INACTIVE=14' && getent passwd trainee54 | awk -F: '{print $6}' | grep -qx '' && getent passwd cedar540 | awk -F: '{print $3}' | grep -qx '4540' && grep -Eq '^kara .*NOPASSWD: /usr/bin/systemctl restart rsyslog, /usr/bin/systemctl status sshd$' /etc/sudoers.d/kara-systemctl && grep -Eq '^PASS_MAX_DAYS\\s+60$' /etc/login.defs && grep -Eq '^PASS_MIN_DAYS\\s+2$' /etc/login.defs && grep -Eq '^PASS_WARN_AGE\\s+7$' /etc/login.defs && grep -Fqx 'umask 027' /home/miles/.bash_profile && stat -c '%a %U:%G' /srv/summit-audit | grep -qx '750 root:root'",
            "chage -l miles | grep -Eq 'Last password change.*password must be changed' || chage -l miles | grep -Eq 'Password expires.*password must be changed'",
            "test -f /root/foragerd-files/opt/exam-d/find/a/file1.txt && grep -q 'alpha' /root/alpha-lines && test -f /root/summit-etc.tar.gz && /usr/local/bin/summit-scan >/dev/null && test -s /root/summit-units.txt",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && findmnt /mnt/summitlv >/dev/null && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1==\"summitlv\" && $2==\"summitvg\" && $3>=255 && $3<=257{f=1} END{exit !f}'",
            "ssh admin@servervm sudo grep -Fqx 'Summit maintenance host' /etc/issue && ssh admin@servervm sudo grep -Fqx 'Summit maintenance host' /etc/motd && ssh admin@servervm systemctl get-default | grep -qx multi-user.target && ssh admin@servervm systemctl is-enabled rsyslog | grep -qx enabled && ssh admin@servervm systemctl is-enabled postfix | grep -qx disabled && ssh admin@servervm rpm -q tree >/dev/null && ! ssh admin@servervm rpm -q dos2unix >/dev/null 2>&1",
        ],
    )

    apply_blocks(
        "mock-exam-e",
        title="Mock Exam E",
        description="A 22 task RHCSA style mock exam focused on offline repositories, Apache document roots, ACLs, NFS, and storage maintenance.",
        objective_tags=["networking-and-firewall", "software-management", "filesystems-and-autofs", "users-sudo-ssh", "storage-lvm"],
        password_recovery=False,
        blocks=[
            block("Client Network", "Configure networking on clientvm with the following settings:\n\nIP ADDRESS: 192.168.122.37\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: clientvm.exam-e.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.37/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname clientvm.exam-e.lab",
            ]),
            block("Host Entry", "Add a persistent hosts entry so registry.exam-e.lab resolves to 192.168.122.3.", [
                "grep -q 'registry.exam-e.lab' /etc/hosts || echo '192.168.122.3 registry.exam-e.lab' >> /etc/hosts",
            ]),
            block("Client Repositories", "Configure a repository file on clientvm with BaseOS and AppStream served from servervm, enabled, and with gpgcheck disabled.", [
                "cat > /etc/yum.repos.d/exam-e.repo <<'EOF'",
                "[harbor-baseos]",
                "name=RHCSA BaseOS",
                "baseurl=http://servervm/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[harbor-appstream]",
                "name=RHCSA AppStream",
                "baseurl=http://servervm/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Server Repositories", "Configure the same repository file on servervm.", [
                "# Run on servervm",
                "cat > /etc/yum.repos.d/exam-e.repo <<'EOF'",
                "[harbor-baseos]",
                "name=RHCSA BaseOS",
                "baseurl=http://servervm/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[harbor-appstream]",
                "name=RHCSA AppStream",
                "baseurl=http://servervm/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Apache Custom Docroot", "Configure Apache on clientvm so it serves /srv/harbor-web on TCP port 8181.\n\nRequirements:\n- Start automatically at boot.\n- Open the port permanently in the firewall.\n- Apply the SELinux changes needed for the custom document root and port.", [
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
            block("Direct NFS Mount", "Persistently mount servervm:/exports/harborhome on /mnt/harborhome using /etc/fstab.", [
                "mkdir -p /mnt/harborhome",
                "grep -q '/mnt/harborhome' /etc/fstab || echo 'servervm:/exports/harborhome /mnt/harborhome nfs defaults,_netdev 0 0' >> /etc/fstab",
                "mount -a",
            ]),
            block("Persistent Journal", "On servervm, enable persistent systemd journal storage and restart systemd-journald.", [
                "# Run on servervm",
                "mkdir -p /var/log/journal",
                "mkdir -p /etc/systemd/journald.conf.d",
                "cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'",
                "[Journal]",
                "Storage=persistent",
                "EOF",
                "systemctl restart systemd-journald",
            ]),
            block("Per-User Login Message", "Append a login message for ivor to ~/.bash_profile that prints \"exam-e access\" when ivor logs in.", [
                "echo 'echo exam-e access' >> /home/ivor/.bash_profile",
            ]),
            block("Fixed UID User", "Create user maple551 with UID 4551, no home directory, shell /sbin/nologin, and password cinder9.", [
                "useradd -M -u 4551 -s /sbin/nologin maple551",
                "echo cinder9 | passwd --stdin maple551",
            ]),
            *slice_blocks(exams["mock-exam-e"], 15, 22),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'clientvm.exam-e.lab' && grep -Fqx '192.168.122.3 registry.exam-e.lab' /etc/hosts && curl -fsS http://servervm/repo/BaseOS/repodata/repomd.xml >/dev/null && ssh admin@servervm sudo curl -fsS http://servervm/repo/AppStream/repodata/repomd.xml >/dev/null",
            "curl -fsS http://localhost:8181 | grep -Fq 'exam-e portal' && findmnt -no TARGET,SOURCE /mnt/harborhome | grep -Eq '^/mnt/harborhome servervm:/exports/harborhome$'",
            "getent group harborops >/dev/null && id -nG lena | tr ' ' '\\n' | grep -qx harborops && id -nG ivor | tr ' ' '\\n' | grep -qx harborops && chage -l ivor | grep -Eq 'Maximum.*30' && getfacl -p /srv/harbor-drop | grep -Fq 'default:group:harborops:rwx' && getent passwd harborremote | awk -F: '{print $6\":\"$7}' | grep -qx ':/sbin/nologin' && grep -Eq '^minlen\\s*=\\s*12$' /etc/security/pwquality.conf.d/harborgrid.conf && grep -Eq '^minclass\\s*=\\s*3$' /etc/security/pwquality.conf.d/harborgrid.conf && atq | grep -q ivor && grep -Fqx 'echo exam-e access' /home/ivor/.bash_profile && ssh admin@servervm sudo test -d /var/log/journal",
            "getent passwd maple551 | awk -F: '{print $3\":\"$6\":\"$7}' | grep -qx '4551::/sbin/nologin' && test -f /root/scoutte-files/opt/exam-e/find/a/file1.txt && grep -q 'beacon' /root/beacon-lines && test -f /root/var-tmp-harbor.tar.bz2 && /usr/local/bin/harbor-check >/dev/null && test -s /root/harbor-services.txt",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1==\"reviewe\" && $2==\"reviewvge\" && $3>=359 && $3<=361{f=1} END{exit !f}'",
            "rec=\"$(tuned-adm recommend | awk '{print $1}')\"; act=\"$(tuned-adm active | sed -E 's/.*: ([^ ]+).*/\\1/')\"; test -n \"$rec\" && test \"$act\" = \"$rec\"",
        ],
    )

    apply_blocks(
        "mock-exam-f",
        title="Mock Exam F",
        description="A 22 task RHCSA style mock exam centered on chrony, SSH hardening, account defaults, rsync, and storage administration.",
        objective_tags=["networking-and-firewall", "users-sudo-ssh", "processes-logs-tuning", "storage-lvm"],
        password_recovery=False,
        blocks=[
            block("Client Network", "Configure networking on clientvm with the following settings:\n\nIP ADDRESS: 192.168.122.38\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: clientvm.exam-f.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.38/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname clientvm.exam-f.lab",
            ]),
            block("Host Entry", "Add a persistent hosts entry so db.exam-f.lab resolves to 192.168.122.3.", [
                "grep -q 'db.exam-f.lab' /etc/hosts || echo '192.168.122.3 db.exam-f.lab' >> /etc/hosts",
            ]),
            block("Chrony Server", "Configure chronyd on servervm so it serves time to 192.168.122.0/24 and starts automatically at boot.", [
                "# Run on servervm",
                "cat > /etc/chrony.conf <<'EOF'",
                "driftfile /var/lib/chrony/drift",
                "makestep 1.0 3",
                "rtcsync",
                "allow 192.168.122.0/24",
                "local stratum 10",
                "EOF",
                "systemctl enable --now chronyd",
            ]),
            block("Chrony Client", "Configure chronyd on clientvm so it synchronizes only with servervm and starts automatically at boot.", [
                "cat > /etc/chrony.conf <<'EOF'",
                "server servervm iburst",
                "driftfile /var/lib/chrony/drift",
                "makestep 1.0 3",
                "rtcsync",
                "EOF",
                "systemctl enable --now chronyd",
            ]),
            block("SSH Port", "On servervm, configure sshd to listen on TCP port 2222 and keep both password and public key authentication enabled.", [
                "# Run on servervm",
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
                "systemctl restart sshd",
            ]),
            block("Rich Rule", "On servervm, add a permanent rich firewall rule allowing TCP port 2222 only from 192.168.122.0/24.", [
                "# Run on servervm",
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
            block("Delegated Sudo", "Allow elio to restart firewalld on clientvm through sudo without a password prompt. Use a sudoers drop-in.", [
                "visudo -f /etc/sudoers.d/elio-firewalld",
                "elio ALL=(root) NOPASSWD: /usr/bin/systemctl restart firewalld",
            ]),
            block("SSH Key Generation", "As elio on clientvm, generate an ED25519 SSH key pair with no passphrase.", [
                "runuser -l elio -c 'ssh-keygen -t ed25519 -N \"\" -f ~/.ssh/id_ed25519'",
            ]),
            block("Remote Account", "Create user backupf on servervm with a home directory and password cinder9. Create /home/backupf/inbox and make backupf the owner.", [
                "# Run on servervm",
                "useradd backupf",
                "echo cinder9 | passwd --stdin backupf",
                "install -d -m 0755 -o backupf -g backupf /home/backupf/inbox",
            ]),
            block("Passwordless SSH", "Install elio's public key for backupf on servervm and verify passwordless SSH access on port 2222.", [
                "runuser -l elio -c 'ssh-copy-id -p 2222 backupf@servervm'",
                "runuser -l elio -c 'ssh -p 2222 -o BatchMode=yes backupf@servervm true'",
            ]),
            block("Rsync Transfer", "Use rsync over SSH port 2222 as elio to copy /opt/exam-f/aurora-report.txt to /home/backupf/inbox/report.txt on servervm.", [
                "runuser -l elio -c 'rsync -e \"ssh -p 2222\" /opt/exam-f/aurora-report.txt backupf@servervm:/home/backupf/inbox/report.txt'",
            ]),
            block("User Umask", "Set a personal umask of 027 for elio.", [
                "echo 'umask 027' >> /home/elio/.bash_profile",
            ]),
            *slice_blocks(exams["mock-exam-f"], 15, 21),
            block("Recommended Tuned Profile", "Apply the recommended tuned profile and leave it active.", [
                "tuned-adm profile \"$(tuned-adm recommend)\"",
            ]),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'clientvm.aurora.lab' && grep -Fqx '192.168.122.3 db.aurora.lab' /etc/hosts",
            "grep -Eq '^server servervm iburst$' /etc/chrony.conf && systemctl is-enabled chronyd | grep -qx enabled && ssh admin@servervm sudo grep -Eq '^allow 192\\.168\\.122\\.0/24$' /etc/chrony.conf && ssh admin@servervm sudo systemctl is-enabled chronyd | grep -qx enabled && ssh admin@servervm sudo grep -Eq '^Port 2222$' /etc/ssh/sshd_config && ssh admin@servervm sudo firewall-cmd --list-rich-rules | grep -Fq 'port port=\"2222\" protocol=\"tcp\" accept'",
            "useradd -D | grep -Eq 'INACTIVE=14' && getent passwd pine560 | awk -F: '{print $3\":\"$6\":\"$7}' | grep -qx '4560::/sbin/nologin' && grep -Eq '^elio .*NOPASSWD: /usr/bin/systemctl restart firewalld$' /etc/sudoers.d/elio-firewalld && grep -Fqx 'umask 027' /home/elio/.bash_profile",
            "runuser -l elio -c 'ssh -p 2222 -o BatchMode=yes backupf@servervm true' && ssh admin@servervm test -f /home/backupf/inbox/report.txt",
            "test -f /root/seekerf-files/opt/exam-f/find/a/file1.txt && grep -q 'comet' /root/comet-lines && test -f /root/usr-local-f.tar.gz && /usr/local/bin/aurora-report >/dev/null && test -s /root/aurora-units.txt",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && findmnt -no TARGET,SOURCE,FSTYPE /mnt/auroralv | grep -Eq '^/mnt/auroralv /dev/mapper/auroravg-auroralv xfs$' && rec=\"$(tuned-adm recommend | awk '{print $1}')\"; act=\"$(tuned-adm active | sed -E 's/.*: ([^ ]+).*/\\1/')\"; test -n \"$rec\" && test \"$act\" = \"$rec\"",
        ],
    )

    apply_blocks(
        "mock-exam-g",
        title="Mock Exam G",
        description="A 22 task RHCSA style mock exam combining recovery, NFS, sticky directories, SSH key transfer, process handling, and rootless containers.",
        objective_tags=["boot-and-recovery", "filesystems-and-autofs", "users-sudo-ssh", "storage-lvm", "containers"],
        password_recovery=True,
        blocks=[
            block("Root Recovery", "Recover root access on clientvm from the console.\n\nSet the root password to: cinder9", [
                "# At the boot menu, edit the selected kernel entry.",
                "# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.",
                "passwd root",
                "# enter: cinder9",
                "touch /.autorelabel",
                "exec /sbin/init",
            ]),
            block("Client Network", "Configure networking on clientvm with the following settings:\n\nIP ADDRESS: 192.168.122.39\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: clientvm.deltaforge.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.39/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname clientvm.deltaforge.lab",
            ]),
            block("Bootloader Kernel Argument", "Configure the bootloader on clientvm so every installed kernel boots with the kernel argument audit_backlog_limit=8192.", [
                "grubby --update-kernel=ALL --args=\"audit_backlog_limit=8192\"",
            ]),
            block("Host Entry", "Add a persistent hosts entry so vault.deltaforge.lab resolves to 192.168.122.3.", [
                "grep -q 'vault.deltaforge.lab' /etc/hosts || echo '192.168.122.3 vault.deltaforge.lab' >> /etc/hosts",
            ]),
            block("Direct NFS Mount", "Mount the server export servervm:/exports/delta-home persistently on clientvm at /mnt/delta-home using NFS.", [
                "mkdir -p /mnt/delta-home",
                "grep -q '/mnt/delta-home' /etc/fstab || echo 'servervm:/exports/delta-home /mnt/delta-home nfs defaults,_netdev 0 0' >> /etc/fstab",
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
            block("Password Aging", "Set password aging for pavel to maximum 45 days, minimum 5 days, and warning 7 days.", [
                "chage -M 45 -m 5 -W 7 pavel",
            ]),
            block("User Umask", "Set a personal umask of 027 for pavel.", [
                "echo 'umask 027' >> /home/pavel/.bash_profile",
            ]),
            block("Copy User On Both Systems", "Create user copyg on both systems with password cinder9.", [
                "useradd copyg",
                "echo cinder9 | passwd --stdin copyg",
                "# Run on servervm",
                "useradd copyg",
                "echo cinder9 | passwd --stdin copyg",
                "install -d -m 0755 -o copyg -g copyg /home/copyg/inbox",
            ]),
            block("SSH Key And Secure Copy", "As copyg on clientvm, generate an ED25519 SSH key pair with no passphrase, install it on servervm, and copy /opt/exam-g/copyg-payload.txt to /home/copyg/inbox/payload.txt on servervm.", [
                "runuser -l copyg -c 'ssh-keygen -t ed25519 -N \"\" -f ~/.ssh/id_ed25519'",
                "runuser -l copyg -c 'ssh-copy-id copyg@servervm'",
                "runuser -l copyg -c 'scp /opt/exam-g/copyg-payload.txt copyg@servervm:/home/copyg/inbox/payload.txt'",
            ]),
            block("At Job", "Queue a one-time at job as user pavel that appends the message \"exam-g tick\" to /root/exam-g-at.log in 2 minutes.", [
                "runuser -l pavel -c 'echo \"echo exam-g tick >> /root/exam-g-at.log\" | at now + 2 minutes'",
                "systemctl enable --now atd",
            ]),
            block("Per-User Login Message", "Append a login message for pavel to ~/.bash_profile that prints \"exam-g access\" when pavel logs in.", [
                "echo 'echo exam-g access' >> /home/pavel/.bash_profile",
            ]),
            *slice_blocks(exams["mock-exam-g"], 14, 22),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'clientvm.deltaforge.lab' && grep -Fqx '192.168.122.3 vault.deltaforge.lab' /etc/hosts && grubby --info=ALL | grep -Eq 'args=.*audit_backlog_limit=8192'",
            "mount | grep -Eq 'servervm:/exports/delta-home on /mnt/delta-home type nfs' && getent group deltaops >/dev/null && id -nG pavel | tr ' ' '\\n' | grep -qx deltaops && stat -c '%a %U:%G' /projects/delta-drop | grep -qx '3770 root:deltaops' && getent passwd auditg | awk -F: '{print $6\":\"$7}' | grep -qx ':/sbin/nologin'",
            "chage -l pavel | grep -Eq 'Maximum.*45' && grep -Fqx 'umask 027' /home/pavel/.bash_profile && grep -Fqx 'echo exam-g access' /home/pavel/.bash_profile && atq | grep -q pavel",
            "runuser -l copyg -c 'ssh -o BatchMode=yes copyg@servervm true' && ssh admin@servervm test -f /home/copyg/inbox/payload.txt",
            "test -f /root/trackerg-files/opt/exam-g/find/a/file1.txt && grep -q 'ember' /root/ember-lines && test -f /root/etc-g.tar.bz2 && test -d /var/log/journal && ! ps -p \"$(cat /home/workerg/cpu.pid)\" >/dev/null 2>&1 && ps -o ni= -p \"$(cat /home/workerg/sleep.pid)\" | tr -d ' ' | grep -qx '10'",
            "swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && findmnt -no TARGET,SOURCE,FSTYPE /mnt/deltalv | grep -Eq '^/mnt/deltalv /dev/mapper/deltavg-deltalv ext4$' && runuser -l solg -c 'systemctl --user is-enabled container-pdfg.service' | grep -qx enabled && runuser -l solg -c 'systemctl --user is-active container-pdfg.service' | grep -qx active && loginctl show-user solg | grep -Eq '^Linger=yes$'",
        ],
    )

    apply_blocks(
        "mock-exam-h",
        title="Mock Exam H",
        description="A 22 task RHCSA style mock exam covering repositories, SELinux HTTP changes, chrony, package work, and container inspection.",
        objective_tags=["networking-and-firewall", "software-management", "users-sudo-ssh", "processes-logs-tuning", "storage-lvm", "containers"],
        password_recovery=False,
        blocks=[
            block("Client Network", "Configure networking on clientvm with the following settings:\n\nIP ADDRESS: 192.168.122.40\nNETMASK: 255.255.255.0\nGATEWAY: 192.168.122.1\nDNS SERVER: 192.168.122.3\nHOSTNAME: clientvm.exam-h.lab", [
                "CONN=\"$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != \"\" && $2 != \"lo\" {print $1; exit}')\"",
                "nmcli connection modify \"$CONN\" ipv4.addresses 192.168.122.40/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes",
                "nmcli connection down \"$CONN\"",
                "nmcli connection up \"$CONN\"",
                "hostnamectl set-hostname clientvm.exam-h.lab",
            ]),
            block("Host Entry", "Add a persistent hosts entry so registry.exam-h.lab resolves to 192.168.122.3.", [
                "grep -q 'registry.exam-h.lab' /etc/hosts || echo '192.168.122.3 registry.exam-h.lab' >> /etc/hosts",
            ]),
            block("Client Repositories", "Configure a repository file on clientvm with BaseOS and AppStream served from servervm, enabled, and with gpgcheck disabled.", [
                "cat > /etc/yum.repos.d/exam-h.repo <<'EOF'",
                "[silver-baseos]",
                "name=RHCSA BaseOS",
                "baseurl=http://servervm/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[silver-appstream]",
                "name=RHCSA AppStream",
                "baseurl=http://servervm/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Server Repositories", "Configure the same repository file on servervm.", [
                "# Run on servervm",
                "cat > /etc/yum.repos.d/exam-h.repo <<'EOF'",
                "[silver-baseos]",
                "name=RHCSA BaseOS",
                "baseurl=http://servervm/repo/BaseOS/",
                "enabled=1",
                "gpgcheck=0",
                "",
                "[silver-appstream]",
                "name=RHCSA AppStream",
                "baseurl=http://servervm/repo/AppStream/",
                "enabled=1",
                "gpgcheck=0",
                "EOF",
                "dnf clean all",
            ]),
            block("Apache SELinux Port", "Configure Apache on clientvm so it serves the existing site on TCP port 8181.\n\nRequirements:\n- Start automatically at boot.\n- Open the port permanently in the firewall.\n- Apply the SELinux change required for the new port.", [
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
            block("Chrony Server", "Configure chronyd on servervm so it serves time to 192.168.122.0/24 and starts automatically at boot.", [
                "# Run on servervm",
                "cat > /etc/chrony.conf <<'EOF'",
                "driftfile /var/lib/chrony/drift",
                "makestep 1.0 3",
                "rtcsync",
                "allow 192.168.122.0/24",
                "local stratum 10",
                "EOF",
                "systemctl enable --now chronyd",
            ]),
            block("Chrony Client", "Configure chronyd on clientvm so it synchronizes only with servervm and starts automatically at boot.", [
                "cat > /etc/chrony.conf <<'EOF'",
                "server servervm iburst",
                "driftfile /var/lib/chrony/drift",
                "makestep 1.0 3",
                "rtcsync",
                "EOF",
                "systemctl enable --now chronyd",
            ]),
            block("Firewalld Rich Rule", "On clientvm, add a permanent rich firewall rule allowing TCP port 2222 only from 192.168.122.0/24.", [
                "firewall-cmd --permanent --add-rich-rule='rule family=\"ipv4\" source address=\"192.168.122.0/24\" port protocol=\"tcp\" port=\"2222\" accept'",
                "firewall-cmd --reload",
            ]),
            block("Useradd Defaults", "Set the default inactive period for newly created local users to 10 days.", [
                "useradd -D -f 10",
            ]),
            *slice_blocks(exams["mock-exam-h"], 13, 22),
        ],
        checks=[
            "hostnamectl --static | grep -qx 'clientvm.exam-h.lab' && grep -Fqx '192.168.122.3 registry.exam-h.lab' /etc/hosts && curl -fsS http://servervm/repo/BaseOS/repodata/repomd.xml >/dev/null && ssh admin@servervm sudo curl -fsS http://servervm/repo/AppStream/repodata/repomd.xml >/dev/null",
            "curl -fsS http://localhost:8181 >/dev/null && semanage port -l | grep -Eq '^http_port_t\\b.*\\b8181\\b' && firewall-cmd --list-rich-rules | grep -Fq 'port port=\"2222\" protocol=\"tcp\" accept'",
            "grep -Eq '^minlen\\s*=\\s*12$' /etc/security/pwquality.conf.d/silverpeak.conf && grep -Eq '^minclass\\s*=\\s*3$' /etc/security/pwquality.conf.d/silverpeak.conf && getent passwd agingh | awk -F: '{print $6\":\"$7}' | grep -qx ':/sbin/nologin' && chage -l agingh | grep -Eq 'Minimum.*2' && chage -l agingh | grep -Eq 'Maximum.*30' && chage -l agingh | grep -Eq 'warning.*7' && chage -l agingh | grep -Eq 'password must be changed|must be changed' && useradd -D | grep -Eq 'INACTIVE=10' && stat -c '%a %U:%G' /srv/silver-drop | grep -qx '1777 root:root'",
            "grep -Eq '^server servervm iburst$' /etc/chrony.conf && systemctl is-enabled chronyd | grep -qx enabled && ssh admin@servervm sudo grep -Eq '^allow 192\\.168\\.122\\.0/24$' /etc/chrony.conf && ssh admin@servervm sudo systemctl is-enabled chronyd | grep -qx enabled",
            "test -f /root/watcherh-files/opt/exam-h/find/a/file1.txt && grep -q 'silver' /root/silver-lines && test -f /root/usr-local-h.tar.gz && swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1==\"reviewh\" && $2==\"reviewvgh\" && $3>=319 && $3<=321{f=1} END{exit !f}' && systemctl get-default | grep -qx multi-user.target && systemctl is-enabled rsyslog | grep -qx enabled && systemctl is-enabled postfix | grep -qx disabled && rpm -q tree >/dev/null && ! rpm -q dos2unix >/dev/null 2>&1",
            "runuser -l inspecth -c 'podman image exists localhost/rhcsa-httpd-base:latest' && test -s /home/inspecth/workdir.txt && rec=\"$(tuned-adm recommend | awk '{print $1}')\"; act=\"$(tuned-adm active | sed -E 's/.*: ([^ ]+).*/\\1/')\"; test -n \"$rec\" && test \"$act\" = \"$rec\"",
        ],
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
