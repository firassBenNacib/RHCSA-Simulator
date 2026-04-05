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
mkdir -p /root/.repo-backup-client-exam-h
rhcsa_reset_repo_directory /root/.repo-backup-client-exam-h
useradd -D -f -1 >/dev/null 2>&1 || true
hostnamectl set-hostname clientvm
rhcsa_remove_matching_lines 'registry.silverpeak.lab' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"
python - <<'EOF'
from pathlib import Path
p = Path('/etc/httpd/conf/httpd.conf')
text = p.read_text() if p.exists() else ''
text = text.replace('Listen 8181', 'Listen 80')
p.write_text(text)
EOF
systemctl disable --now httpd >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-port=8181/tcp >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept' >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
semanage port -d -t http_port_t -p tcp 8181 >/dev/null 2>&1 || true
for u in iris daren hush agingh silverremote watcherh inspecth; do userdel -r "$u" >/dev/null 2>&1 || true; done
groupdel silverops >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/silverops /etc/sudoers.d/iris-passwd /root/silver-lines /root/usr-local-h.tar.gz
rm -rf /srv/silver /srv/silver-drop /opt/exam-h /root/watcherh-files /silver /home/inspecth/workdir.txt
python - <<'EOF'
from pathlib import Path
try:
    Path('/etc/security/pwquality.conf.d/silverpeak.conf').unlink()
except FileNotFoundError:
    pass
EOF
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
automount -u >/dev/null 2>&1 || true
rm -f /etc/auto.silver /etc/auto.master.d/silver.autofs
systemctl disable --now autofs >/dev/null 2>&1 || true
id watcherh >/dev/null 2>&1 || useradd -m watcherh
mkdir -p /opt/exam-h/find/a /opt/exam-h/find/b/sub
printf 'h1
' > /opt/exam-h/find/a/file1.txt
printf 'h2
' > /opt/exam-h/find/b/sub/file2.txt
chown -R watcherh:watcherh /opt/exam-h/find
mkdir -p /usr/share/dict
cat > /usr/share/dict/words <<'EOF'
silver
silvery
gold
stone
EOF
swapoff /dev/sdb1 >/dev/null 2>&1 || true
sed -i '\#swap#d' /etc/fstab
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
umount /mnt/reviewh >/dev/null 2>&1 || true
sed -i '\#/mnt/reviewh#d' /etc/fstab
lvremove -fy /dev/reviewvgh/reviewh >/dev/null 2>&1 || true
vgremove -fy reviewvgh >/dev/null 2>&1 || true
pvremove -ffy /dev/sdc1 >/dev/null 2>&1 || true
wipefs -a /dev/sdc >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdc >/dev/null 2>&1 || true
printf 'label: gpt
,700M,L
' | sfdisk /dev/sdc >/dev/null 2>&1
partprobe /dev/sdc >/dev/null 2>&1 || true
pvcreate -ff -y /dev/sdc1 >/dev/null 2>&1
vgcreate reviewvgh /dev/sdc1 >/dev/null 2>&1
lvcreate -n reviewh -L 180M reviewvgh >/dev/null 2>&1
mkfs.ext4 -F /dev/reviewvgh/reviewh >/dev/null 2>&1
mkdir -p /mnt/reviewh
mount /dev/reviewvgh/reviewh /mnt/reviewh
printf 'exam h seed data
' > /mnt/reviewh/keep.txt
uuid="$(blkid -s UUID -o value /dev/reviewvgh/reviewh)"
printf 'UUID=%s /mnt/reviewh ext4 defaults 0 0
' "$uuid" >> /etc/fstab
cat > /etc/yum.repos.d/exam-h-local.repo <<'EOF'
[examh-baseos]
name=ExamH BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[examh-appstream]
name=ExamH AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all >/dev/null 2>&1 || true
dnf remove -y tree dos2unix >/dev/null 2>&1 || true
id inspecth >/dev/null 2>&1 || useradd -m inspecth
printf 'inspecth:cinder9
' | chpasswd
runuser -l inspecth -c 'podman rmi -f localhost/rhcsa-httpd-base:latest >/dev/null 2>&1 || true'
rm -f /home/inspecth/workdir.txt
systemctl set-default graphical.target >/dev/null 2>&1 || true
systemctl disable --now rsyslog >/dev/null 2>&1 || true
systemctl enable --now postfix >/dev/null 2>&1 || true
