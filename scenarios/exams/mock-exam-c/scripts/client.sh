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

    grubby --update-kernel=ALL --remove-args="audit_backlog_limit=8192" >/dev/null 2>&1 || true

    rhcsa_configure_password_recovery disable
    rhcsa_configure_password_recovery enable
    mkdir -p /root/.repo-backup-client-exam-c
    rhcsa_reset_repo_directory /root/.repo-backup-client-exam-c
    hostnamectl set-hostname client
    rhcsa_remove_matching_lines 'vault.northstar.lab' /etc/hosts
    connection_name="$(rhcsa_get_lab_connection_name || true)"
    rhcsa_reset_lab_ipv4_profile "$connection_name"
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
    echo 'c1' > /opt/exam-c/find/a/file1.txt
    echo 'c2' > /opt/exam-c/find/b/sub/file2.txt
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
p.write_text('\n'.join(lines) + '\n')
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
        echo 'exam-c seed data' > /mnt/reviewc/keep.txt
        uuid="$(blkid -s UUID -o value /dev/reviewvgc/reviewc)"
        printf 'UUID=%s /mnt/reviewc ext4 defaults 0 0
' "$uuid" >> /etc/fstab

    podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null
    id eirac >/dev/null 2>&1 || useradd -m eirac
    eirac_uid="$(id -u eirac)"
    runuser -l eirac -c "export XDG_RUNTIME_DIR=/tmp/podman-run-$eirac_uid; install -d -m 700 \"\$XDG_RUNTIME_DIR\"; podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true"
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
