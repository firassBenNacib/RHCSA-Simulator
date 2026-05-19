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

    mkdir -p /root/.repo-backup-client-exam-a
    rhcsa_reset_repo_directory /root/.repo-backup-client-exam-a
    hostnamectl set-hostname client
    rhcsa_remove_matching_lines 'api.opsedge.lab' /etc/hosts
    connection_name="$(rhcsa_get_lab_connection_name || true)"
    rhcsa_reset_lab_ipv4_profile "$connection_name"
    python - <<'EOF'
from pathlib import Path
p = Path('/etc/httpd/conf/httpd.conf')
if p.exists():
    text = p.read_text()
    text = text.replace('Listen 8282', 'Listen 80')
    p.write_text(text)
EOF
    mkdir -p /var/www/html
    echo 'exam-a portal' > /var/www/html/index.html
    restorecon -Rv /var/www/html >/dev/null 2>&1 || true
    systemctl disable --now httpd >/dev/null 2>&1 || true
    rm -f /etc/httpd/conf.d/opsa-listen.conf
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
    id frost >/dev/null 2>&1 || useradd -M -s /sbin/nologin frost
    usermod -s /sbin/nologin frost >/dev/null 2>&1 || true
    rm -rf /home/frost
    mkdir -p /opt/exam-a/find/a /opt/exam-a/find/b/sub
    echo 'a1' > /opt/exam-a/find/a/file1.txt
    echo 'a2' > /opt/exam-a/find/b/sub/file2.txt
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
    for dev in /dev/sdb[0-9]*; do
        [ -e "$dev" ] || continue
        swapoff "$dev" >/dev/null 2>&1 || true
        findmnt -nr -S "$dev" -o TARGET 2>/dev/null | sort -r | xargs -r umount >/dev/null 2>&1 || true
    done
    for vg in $(pvs --noheadings -o vg_name /dev/sdb[0-9]* 2>/dev/null | awk 'NF{print $1}' | sort -u); do
        vgchange -an "$vg" >/dev/null 2>&1 || true
    done
    for dev in /dev/sdb[0-9]*; do
        [ -e "$dev" ] || continue
        pvremove -ffy "$dev" >/dev/null 2>&1 || true
        wipefs -a "$dev" >/dev/null 2>&1 || true
    done
    sed -i '/[[:space:]]swap[[:space:]]swap[[:space:]]/d' /etc/fstab
    partx -d /dev/sdb >/dev/null 2>&1 || true
    wipefs -a /dev/sdb >/dev/null 2>&1 || true
    dd if=/dev/zero of=/dev/sdb bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
    blockdev --rereadpt /dev/sdb >/dev/null 2>&1 || true
    partprobe /dev/sdb >/dev/null 2>&1 || true
umount /mnt/reviewa >/dev/null 2>&1 || true
        sed -i '\#/mnt/reviewa#d' /etc/fstab
        lvremove -fy /dev/reviewvga/reviewa >/dev/null 2>&1 || true
        vgremove -fy reviewvga >/dev/null 2>&1 || true
        pvremove -ffy /dev/sdc1 >/dev/null 2>&1 || true
        wipefs -a /dev/sdc >/dev/null 2>&1 || true
        dd if=/dev/zero of=/dev/sdc bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
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
        echo 'exam-a seed data' > /mnt/reviewa/keep.txt
        uuid="$(blkid -s UUID -o value /dev/reviewvga/reviewa)"
        printf 'UUID=%s /mnt/reviewa ext4 defaults 0 0
' "$uuid" >> /etc/fstab

    podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null
    id oriona >/dev/null 2>&1 || useradd -m oriona
    oriona_uid="$(id -u oriona)"
    runuser -l oriona -c "export XDG_RUNTIME_DIR=/tmp/podman-run-$oriona_uid; install -d -m 700 \"\$XDG_RUNTIME_DIR\"; podman rmi -f localhost/rhcsa-httpd-base:latest >/dev/null 2>&1 || true; podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null"
    mkdir -p /opt/inc /opt/outa /opt/rhcsa/workspaces/exam-a/site-content
    cat > /opt/rhcsa/workspaces/exam-a/site-content/index.html <<'EOF'
exam a container
EOF
cat > /opt/rhcsa/workspaces/exam-a/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
CMD ["/usr/bin/bash", "-lc", "while true; do sleep 300; done"]
EOF
    chown -R oriona:oriona /opt/rhcsa/workspaces/exam-a /opt/inc /opt/outa
    runuser -l oriona -c 'podman rm -f pdfa >/dev/null 2>&1 || true'
    runuser -l oriona -c 'podman rmi -f localhost/opsa-web:latest >/dev/null 2>&1 || true'
    rm -rf /home/oriona/.config/systemd/user
    loginctl disable-linger oriona >/dev/null 2>&1 || true
