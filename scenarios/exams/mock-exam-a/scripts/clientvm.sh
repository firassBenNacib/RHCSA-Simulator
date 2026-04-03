#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

    grubby --update-kernel=ALL --remove-args="audit_backlog_limit=8192" >/dev/null 2>&1 || true

    rhcsa_configure_password_recovery disable
    rhcsa_configure_password_recovery enable
    mkdir -p /root/.repo-backup-client-exam-a
    rhcsa_reset_repo_directory /root/.repo-backup-client-exam-a
    hostnamectl set-hostname clientvm
    rhcsa_remove_matching_lines 'api.opsedge.lab' /etc/hosts
    connection_name="$(rhcsa_get_lab_connection_name || true)"
    rhcsa_reset_lab_ipv4_profile "$connection_name"
    python - <<'EOF'
from pathlib import Path
p = Path('/etc/httpd/conf/httpd.conf')
text = p.read_text() if p.exists() else ''
for old in ['Listen 8282','Listen 80']:
    pass
if text:
    text = text.replace('Listen 8282', 'Listen 80')
    p.write_text(text)
EOF
    systemctl disable --now httpd >/dev/null 2>&1 || true
    firewall-cmd --permanent --remove-port=8282/tcp >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
    semanage port -d -t http_port_t -p tcp 8282 >/dev/null 2>&1 || true
    for u in violet amber frost ash420; do userdel -r "$u" >/dev/null 2>&1 || true; done
    groupdel sysopsa >/dev/null 2>&1 || true
    rm -f /etc/sudoers.d/sysopsa-useradd /etc/sudoers.d/violet-passwd
    rm -rf /srv/sysopsa /root/amber-files /opt/exam-a /researcha
    rm -f /etc/auto.opsa /etc/auto.master.d/opsa.autofs /root/delta-lines /root/etc-opsa.tar.bz2 /usr/local/bin/opsa-report
    automount -u >/dev/null 2>&1 || true
    systemctl disable --now autofs >/dev/null 2>&1 || true
    userdel -r netopsa >/dev/null 2>&1 || true
    id amber >/dev/null 2>&1 || useradd -m amber
    id violet >/dev/null 2>&1 || useradd -m violet
    id frost >/dev/null 2>&1 || useradd -m -s /sbin/nologin frost
    mkdir -p /opt/exam-a/find/a /opt/exam-a/find/b/sub
    printf 'a1
' > /opt/exam-a/find/a/file1.txt
    printf 'a2
' > /opt/exam-a/find/b/sub/file2.txt
    chown -R amber:amber /opt/exam-a/find
    mkdir -p /usr/share/dict
    cat > /usr/share/dict/words <<'EOF'
which
richter
delta
redlich
EOF
    rm -f /root/delta-lines
    mkdir -p /usr/local/share/exam-a
    cat > /usr/local/share/exam-a/services.lst <<'EOF'
sshd
firewalld
chronyd
EOF
    rm -f /usr/local/bin/opsa-report /root/opsa-services.txt
    crontab -r -u amber >/dev/null 2>&1 || true
    systemctl disable --now chronyd >/dev/null 2>&1 || true
    python - <<'EOF'
from pathlib import Path
p = Path('/etc/chrony.conf')
lines = []
for line in p.read_text().splitlines():
    if line.strip().startswith('server ') or line.strip().startswith('pool '):
        continue
    lines.append(line)
p.write_text('\n'.join(lines) + '\n')
EOF
    wipefs -a /dev/sdb >/dev/null 2>&1 || true
    sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
umount /mnt/reviewa >/dev/null 2>&1 || true
        sed -i '\#/mnt/reviewa#d' /etc/fstab
        lvremove -fy /dev/reviewvga/reviewa >/dev/null 2>&1 || true
        vgremove -fy reviewvga >/dev/null 2>&1 || true
        pvremove -ffy /dev/sdc1 >/dev/null 2>&1 || true
        wipefs -a /dev/sdc >/dev/null 2>&1 || true
        sgdisk --zap-all /dev/sdc >/dev/null 2>&1 || true
        printf 'label: gpt
,700M,L
' | sfdisk /dev/sdc >/dev/null 2>&1
        partprobe /dev/sdc >/dev/null 2>&1 || true
        pvcreate -ff -y /dev/sdc1 >/dev/null 2>&1
        vgcreate reviewvga /dev/sdc1 >/dev/null 2>&1
        lvcreate -n reviewa -L 160M reviewvga >/dev/null 2>&1
        mkfs.ext4 -F /dev/reviewvga/reviewa >/dev/null 2>&1
        mkdir -p /mnt/reviewa
        mount /dev/reviewvga/reviewa /mnt/reviewa
        printf 'exam-a seed data
' > /mnt/reviewa/keep.txt
        uuid="$(blkid -s UUID -o value /dev/reviewvga/reviewa)"
        printf 'UUID=%s /mnt/reviewa ext4 defaults 0 0
' "$uuid" >> /etc/fstab

    podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null
    id oriona >/dev/null 2>&1 || useradd -m oriona
runuser -l oriona -c 'podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true'
    mkdir -p /opt/ina /opt/outa /opt/rhcsa/workspaces/exam-a/site-content
    cat > /opt/rhcsa/workspaces/exam-a/site-content/index.html <<'EOF'
exam a container
EOF
    cat > /opt/rhcsa/workspaces/exam-a/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF
    chown -R oriona:oriona /opt/rhcsa/workspaces/exam-a /opt/ina /opt/outa
    runuser -l oriona -c 'podman rm -f pdfa >/dev/null 2>&1 || true'
    runuser -l oriona -c 'podman rmi -f localhost/opsa-web:latest >/dev/null 2>&1 || true'
    rm -rf /home/oriona/.config/systemd/user
    loginctl disable-linger oriona >/dev/null 2>&1 || true
