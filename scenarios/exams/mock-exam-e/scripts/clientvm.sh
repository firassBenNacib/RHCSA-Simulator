#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
rhcsa_configure_password_recovery disable
rhcsa_configure_password_recovery enable
mkdir -p /root/.repo-backup-client-exam-e
rhcsa_reset_repo_directory /root/.repo-backup-client-exam-e
hostnamectl set-hostname clientvm
rhcsa_remove_matching_lines 'registry.harbor.lab' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"
python - <<'EOF'
from pathlib import Path
p = Path('/etc/httpd/conf/httpd.conf')
text = p.read_text() if p.exists() else ''
if text:
    text = text.replace('Listen 8181', 'Listen 80')
    p.write_text(text)
EOF
systemctl disable --now httpd >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-port=8181/tcp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
semanage port -d -t http_port_t -p tcp 8181 >/dev/null 2>&1 || true
for u in lena ivor hush harborremote maple551 scoutte; do userdel -r "$u" >/dev/null 2>&1 || true; done
groupdel harborops >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/harborops /etc/sudoers.d/lena-httpd
rm -rf /srv/harbor /root/scoutte-files /harbor/home /usr/local/bin/harbor-check /root/harbor-services.txt /root/beacon-lines /root/var-tmp-harbor.tar.bz2 /opt/exam-e
rm -f /etc/security/pwquality.conf.d/exam-e.conf
while read -r job; do atrm "$job"; done < <(atq | awk '{print $1}')
systemctl disable --now atd >/dev/null 2>&1 || true
automount -u >/dev/null 2>&1 || true
rm -f /etc/auto.harbor /etc/auto.master.d/harbor.autofs
systemctl disable --now autofs >/dev/null 2>&1 || true
crontab -r -u ivor >/dev/null 2>&1 || true
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
id scoutte >/dev/null 2>&1 || useradd -m scoutte
mkdir -p /opt/exam-e/find/a /opt/exam-e/find/z/sub
printf 'e1
' > /opt/exam-e/find/a/file1.txt
printf 'e2
' > /opt/exam-e/find/z/sub/file2.txt
chown -R scoutte:scoutte /opt/exam-e/find
mkdir -p /usr/share/dict
cat > /usr/share/dict/words <<'EOF'
beacon
beaconing
harbor
shore
EOF
mkdir -p /usr/local/share/exam-e
cat > /usr/local/share/exam-e/services.lst <<'EOF'
sshd
firewalld
chronyd
EOF
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
umount /mnt/reviewe >/dev/null 2>&1 || true
sed -i '\#/mnt/reviewe#d' /etc/fstab
lvremove -fy /dev/reviewvge/reviewe >/dev/null 2>&1 || true
vgremove -fy reviewvge >/dev/null 2>&1 || true
pvremove -ffy /dev/sdc1 >/dev/null 2>&1 || true
wipefs -a /dev/sdc >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdc >/dev/null 2>&1 || true
printf 'label: gpt
,900M,L
' | sfdisk /dev/sdc >/dev/null 2>&1
partprobe /dev/sdc >/dev/null 2>&1 || true
pvcreate -ff -y /dev/sdc1 >/dev/null 2>&1
vgcreate reviewvge /dev/sdc1 >/dev/null 2>&1
lvcreate -n reviewe -L 180M reviewvge >/dev/null 2>&1
mkfs.ext4 -F /dev/reviewvge/reviewe >/dev/null 2>&1
mkdir -p /mnt/reviewe
mount /dev/reviewvge/reviewe /mnt/reviewe
printf 'exam e seed data
' > /mnt/reviewe/keep.txt
uuid="$(blkid -s UUID -o value /dev/reviewvge/reviewe)"
printf 'UUID=%s /mnt/reviewe ext4 defaults 0 0
' "$uuid" >> /etc/fstab
