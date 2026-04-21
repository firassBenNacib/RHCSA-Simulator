#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh
if command -v rhcsa_ensure_httpd_base_archive >/dev/null 2>&1; then
  rhcsa_ensure_httpd_base_archive
else
  archive="/opt/rhcsa/container-assets/rhcsa-httpd-base.tar"
  if ! tar -tf "$archive" 2>/dev/null | grep -Eq '^(manifest.json|index.json)$'; then
    podman image exists localhost/rhcsa-httpd-base:latest >/dev/null 2>&1 || \
      podman import --change 'CMD ["/usr/sbin/httpd","-DFOREGROUND"]' --change 'EXPOSE 80' --change 'STOPSIGNAL SIGWINCH' "$archive" localhost/rhcsa-httpd-base:latest >/dev/null 2>&1
    skopeo copy --insecure-policy containers-storage:localhost/rhcsa-httpd-base:latest docker-archive:"$archive":localhost/rhcsa-httpd-base:latest >/dev/null 2>&1
  fi
fi


    mkdir -p /root/.repo-backup-client-exam-b
    rhcsa_reset_repo_directory /root/.repo-backup-client-exam-b
    useradd -D -f -1 >/dev/null 2>&1 || true
    hostnamectl set-hostname client
    rhcsa_remove_matching_lines 'registry.coremesh.lab' /etc/hosts
    connection_name="$(rhcsa_get_lab_connection_name || true)"
    rhcsa_reset_lab_ipv4_profile "$connection_name"
    python - <<'EOF'
from pathlib import Path
p = Path('/etc/httpd/conf/httpd.conf')
text = p.read_text() if p.exists() else ''
if text:
    text = text.replace('Listen 8383', 'Listen 80')
    p.write_text(text)
EOF
    systemctl disable --now httpd >/dev/null 2>&1 || true
    firewall-cmd --permanent --remove-port=8383/tcp >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
    semanage port -d -t http_port_t -p tcp 8383 >/dev/null 2>&1 || true
    for u in mira jonas noel cato421; do userdel -r "$u" >/dev/null 2>&1 || true; done
    groupdel platformb >/dev/null 2>&1 || true
    rm -f /etc/sudoers.d/mira-firewalld
    rm -rf /srv/platformb /root/mira-files /opt/exam-b /meshb
    rm -f /etc/auto.meshb /etc/auto.master.d/meshb.autofs /root/proto-lines /root/usr-local-b.tar.bz2 /usr/local/bin/corecheck
    automount -u >/dev/null 2>&1 || true
    systemctl disable --now autofs >/dev/null 2>&1 || true
    userdel -r meshremote >/dev/null 2>&1 || true
    id mira >/dev/null 2>&1 || useradd -m mira
    mkdir -p /opt/exam-b/find/a /opt/exam-b/find/b/sub
    echo 'b1' > /opt/exam-b/find/a/file1.txt
    echo 'b2' > /opt/exam-b/find/b/sub/file2.txt
    echo 'coremesh report' > /opt/exam-b/report.txt
    chown -R mira:mira /opt/exam-b/find
    mkdir -p /usr/share/dict
    cat > /usr/share/dict/words <<'EOF'
protocol
proton
alpha
prototype
EOF
    mkdir -p /usr/local/share/exam-b
    cat > /usr/local/share/exam-b/units.lst <<'EOF'
sshd.service
firewalld.service
chronyd.service
EOF
    crontab -r -u mira >/dev/null 2>&1 || true
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
umount /mnt/reviewb >/dev/null 2>&1 || true
        sed -i '\#/mnt/reviewb#d' /etc/fstab
        lvremove -fy /dev/reviewvgb/reviewb >/dev/null 2>&1 || true
        vgremove -fy reviewvgb >/dev/null 2>&1 || true
        pvremove -ffy /dev/sdc1 >/dev/null 2>&1 || true
        wipefs -a /dev/sdc >/dev/null 2>&1 || true
        sgdisk --zap-all /dev/sdc >/dev/null 2>&1 || true
        printf 'label: gpt
,700M,L
' | sfdisk /dev/sdc >/dev/null 2>&1
        partprobe /dev/sdc >/dev/null 2>&1 || true
        pvcreate -ff -y /dev/sdc1 >/dev/null 2>&1
        vgcreate reviewvgb /dev/sdc1 >/dev/null 2>&1
        lvcreate -n reviewb -L 160M reviewvgb >/dev/null 2>&1
        mkfs.ext4 -F /dev/reviewvgb/reviewb >/dev/null 2>&1
        mkdir -p /mnt/reviewb
        mount /dev/reviewvgb/reviewb /mnt/reviewb
        echo 'exam-b seed data' > /mnt/reviewb/keep.txt
        uuid="$(blkid -s UUID -o value /dev/reviewvgb/reviewb)"
        printf 'UUID=%s /mnt/reviewb ext4 defaults 0 0
' "$uuid" >> /etc/fstab

    podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null
    id lyrab >/dev/null 2>&1 || useradd -m lyrab
    lyrab_uid="$(id -u lyrab)"
    runuser -l lyrab -c "export XDG_RUNTIME_DIR=/tmp/podman-run-$lyrab_uid; install -d -m 700 \"\$XDG_RUNTIME_DIR\"; podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true"
    mkdir -p /opt/inb /opt/outb /opt/rhcsa/workspaces/exam-b/site-content
    cat > /opt/rhcsa/workspaces/exam-b/site-content/index.html <<'EOF'
exam b container
EOF
    cat > /opt/rhcsa/workspaces/exam-b/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF
    chown -R lyrab:lyrab /opt/rhcsa/workspaces/exam-b /opt/inb /opt/outb
    runuser -l lyrab -c 'podman rm -f pdfb >/dev/null 2>&1 || true'
    runuser -l lyrab -c 'podman rmi -f localhost/coremesh-web:latest >/dev/null 2>&1 || true'
    rm -rf /home/lyrab/.config/systemd/user
    loginctl disable-linger lyrab >/dev/null 2>&1 || true
