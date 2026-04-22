#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-client-exam-f
rhcsa_reset_repo_directory /root/.repo-backup-client-exam-f
useradd -D -f -1 >/dev/null 2>&1 || true
hostnamectl set-hostname client
rhcsa_remove_matching_lines 'db.aurora.lab' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"
mkdir -p /srv/aurora-web
cat > /srv/aurora-web/index.html <<'EOF'
aurora exam page
EOF
rm -f /etc/httpd/conf.d/aurora.conf
systemctl disable --now httpd >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-port=9090/tcp >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept' >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
semanage port -d -t http_port_t -p tcp 9090 >/dev/null 2>&1 || true
restorecon -Rv /srv/aurora-web >/dev/null 2>&1 || true
for u in elio risa nox auditf pine560 seekerf opsf solf; do userdel -r "$u" >/dev/null 2>&1 || true; done
groupdel auroraops >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/elio-firewalld
rm -rf /data/aurora /root/seekerf-files /aurora/home /usr/local/bin/aurora-report /root/aurora-units.txt /root/comet-lines /root/usr-local-f.tar.gz /opt/exam-f
python - <<'EOF'
from pathlib import Path
for p in [Path('/home/risa/.bashrc')]:
    if p.exists():
        text = p.read_text().splitlines()
        text = [line for line in text if 'umask 077' not in line]
        p.write_text('\n'.join(text) + ('\n' if text else ''))
EOF
automount -u >/dev/null 2>&1 || true
rm -f /etc/auto.aurora /etc/auto.master.d/aurora.autofs
systemctl disable --now autofs >/dev/null 2>&1 || true
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
id seekerf >/dev/null 2>&1 || useradd -m seekerf
mkdir -p /opt/exam-f/find/a /opt/exam-f/find/c/sub
echo 'f1' > /opt/exam-f/find/a/file1.txt
echo 'f2' > /opt/exam-f/find/c/sub/file2.txt
echo 'aurora payload' > /opt/exam-f/aurora-report.txt
chown -R seekerf:seekerf /opt/exam-f/find
mkdir -p /usr/share/dict
cat > /usr/share/dict/words <<'EOF'
comet
cometary
star
sky
EOF
mkdir -p /usr/local/share/exam-f
cat > /usr/local/share/exam-f/units.lst <<'EOF'
sshd
firewalld
chronyd
EOF
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
wipefs -a /dev/sdc >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdc >/dev/null 2>&1 || true
sed -i '\#/mnt/auroralv#d' /etc/fstab
umount /mnt/auroralv >/dev/null 2>&1 || true
lvremove -fy /dev/auroravg/auroralv >/dev/null 2>&1 || true
vgremove -fy auroravg >/dev/null 2>&1 || true
pvremove -ffy /dev/sdc1 >/dev/null 2>&1 || true
userdel -r backupf >/dev/null 2>&1 || true
