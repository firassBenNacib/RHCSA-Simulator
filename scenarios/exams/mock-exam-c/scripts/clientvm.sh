#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

    grubby --update-kernel=ALL --remove-args="audit=1" >/dev/null 2>&1 || true

    rhcsa_configure_password_recovery disable
    rhcsa_configure_password_recovery enable
    mkdir -p /root/.repo-backup-client-exam-c
    rhcsa_reset_repo_directory /root/.repo-backup-client-exam-c
    hostnamectl set-hostname clientvm
    rhcsa_remove_matching_lines 'vault.northstar.lab' /etc/hosts
    connection_name="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
    if [[ -n "${connection_name:-}" ]]; then
      nmcli connection modify "$connection_name" ipv4.addresses 192.168.122.28/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes >/dev/null 2>&1 || true
      nmcli connection down "$connection_name" >/dev/null 2>&1 || true
      nmcli connection up "$connection_name" >/dev/null 2>&1 || true
    fi
    python - <<'EOF'
from pathlib import Path
p = Path('/etc/httpd/conf/httpd.conf')
text = p.read_text() if p.exists() else ''
if text:
    text = text.replace('Listen 8484', 'Listen 80')
    p.write_text(text)
EOF
    systemctl disable --now httpd >/dev/null 2>&1 || true
    firewall-cmd --permanent --remove-port=8484/tcp >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
    semanage port -d -t http_port_t -p tcp 8484 >/dev/null 2>&1 || true
    for u in talia ren sage kian431; do userdel -r "$u" >/dev/null 2>&1 || true; done
    groupdel infrac >/dev/null 2>&1 || true
    rm -f /etc/sudoers.d/infrac /etc/sudoers.d/talia-passwd
    rm -rf /srv/infrac /root/ren-files /opt/exam-c /bluec
    rm -f /etc/auto.bluec /etc/auto.master.d/bluec.autofs /root/orbit-lines /root/etc-c.tar.bz2 /usr/local/bin/northcheck
    automount -u >/dev/null 2>&1 || true
    systemctl disable --now autofs >/dev/null 2>&1 || true
    userdel -r remote63 >/dev/null 2>&1 || true
    id ren >/dev/null 2>&1 || useradd -m ren
    mkdir -p /opt/exam-c/find/a /opt/exam-c/find/b/sub
    printf 'c1
' > /opt/exam-c/find/a/file1.txt
    printf 'c2
' > /opt/exam-c/find/b/sub/file2.txt
    chown -R ren:ren /opt/exam-c/find
    mkdir -p /usr/share/dict
    cat > /usr/share/dict/words <<'EOF'
orbit
orbital
hello
suborbit
EOF
    mkdir -p /usr/local/share/exam-c
    cat > /usr/local/share/exam-c/check.lst <<'EOF'
sshd
firewalld
httpd
EOF
    crontab -r -u ren >/dev/null 2>&1 || true
    systemctl disable --now chronyd >/dev/null 2>&1 || true
    python - <<'EOF'
from pathlib import Path
p = Path('/etc/chrony.conf')
lines = []
for line in p.read_text().splitlines():
    if line.strip().startswith('server ') or line.strip().startswith('pool '):
        continue
    lines.append(line)
p.write_text('
'.join(lines) + '
')
EOF
    wipefs -a /dev/sdb >/dev/null 2>&1 || true
    sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
umount /mnt/reviewc >/dev/null 2>&1 || true
        sed -i '\#/mnt/reviewc#d' /etc/fstab
        lvremove -fy /dev/reviewvgc/reviewc >/dev/null 2>&1 || true
        vgremove -fy reviewvgc >/dev/null 2>&1 || true
        pvremove -ffy /dev/sdc1 >/dev/null 2>&1 || true
        wipefs -a /dev/sdc >/dev/null 2>&1 || true
        sgdisk --zap-all /dev/sdc >/dev/null 2>&1 || true
        printf 'label: gpt
,700M,L
' | sfdisk /dev/sdc >/dev/null 2>&1
        partprobe /dev/sdc >/dev/null 2>&1 || true
        pvcreate -ff -y /dev/sdc1 >/dev/null 2>&1
        vgcreate reviewvgc /dev/sdc1 >/dev/null 2>&1
        lvcreate -n reviewc -L 160M reviewvgc >/dev/null 2>&1
        mkfs.ext4 -F /dev/reviewvgc/reviewc >/dev/null 2>&1
        mkdir -p /mnt/reviewc
        mount /dev/reviewvgc/reviewc /mnt/reviewc
        printf 'exam-c seed data
' > /mnt/reviewc/keep.txt
        uuid="$(blkid -s UUID -o value /dev/reviewvgc/reviewc)"
        printf 'UUID=%s /mnt/reviewc ext4 defaults 0 0
' "$uuid" >> /etc/fstab

    podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null
    id eirac >/dev/null 2>&1 || useradd -m eirac
runuser -l eirac -c 'podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true'
    mkdir -p /opt/inc /opt/outc /opt/rhcsa/workspaces/exam-c/site-content
    cat > /opt/rhcsa/workspaces/exam-c/site-content/index.html <<'EOF'
exam c container
EOF
    cat > /opt/rhcsa/workspaces/exam-c/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF
    chown -R eirac:eirac /opt/rhcsa/workspaces/exam-c /opt/inc /opt/outc
    runuser -l eirac -c 'podman rm -f pdfc >/dev/null 2>&1 || true'
    runuser -l eirac -c 'podman rmi -f localhost/northstar-web:latest >/dev/null 2>&1 || true'
    rm -rf /home/eirac/.config/systemd/user
    loginctl disable-linger eirac >/dev/null 2>&1 || true
