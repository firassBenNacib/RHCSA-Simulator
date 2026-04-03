#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-client-exam-g
rhcsa_reset_repo_directory /root/.repo-backup-client-exam-g
rhcsa_configure_password_recovery disable
rhcsa_configure_password_recovery enable
hostnamectl set-hostname clientvm
rhcsa_remove_matching_lines 'vault.deltaforge.lab' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"
if command -v grubby >/dev/null 2>&1; then
  grubby --update-kernel=ALL --remove-args="audit_backlog_limit=8192" >/dev/null 2>&1 || true
fi
mkdir -p /srv/delta-web
printf 'delta forge page
' > /srv/delta-web/index.html
rm -f /etc/httpd/conf.d/delta.conf
systemctl disable --now httpd >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-port=8086/tcp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
semanage port -d -t http_port_t -p tcp 8086 >/dev/null 2>&1 || true
restorecon -Rv /srv/delta-web >/dev/null 2>&1 || true
for u in gwen pavel sable auditg trackerg workerg copyg solg; do userdel -r "$u" >/dev/null 2>&1 || true; done
groupdel deltaops >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/deltaops /etc/sudoers.d/gwen-passwd /root/ember-lines /root/etc-g.tar.bz2
rm -rf /projects/delta /projects/delta-drop /opt/exam-g /root/trackerg-files /mnt/delta-home /mnt/deltalv /opt/ing /opt/outg /opt/rhcsa/workspaces/exam-g
python - <<'EOF'
from pathlib import Path
p = Path('/home/pavel/.bashrc')
if p.exists():
    lines = [line for line in p.read_text().splitlines() if line.strip() != 'umask 027']
    p.write_text('\n'.join(lines) + ('\n' if lines else ''))
EOF
atrm $(atq | awk '{print $1}') >/dev/null 2>&1 || true
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
umount /mnt/delta-home >/dev/null 2>&1 || true
sed -i '\#/mnt/delta-home#d' /etc/fstab
rm -f /root/.ssh/known_hosts >/dev/null 2>&1 || true
userdel -r copyg >/dev/null 2>&1 || true
mkdir -p /opt/exam-g
printf 'copy g payload\n' > /opt/exam-g/copyg-payload.txt
id trackerg >/dev/null 2>&1 || useradd -m trackerg
mkdir -p /opt/exam-g/find/a /opt/exam-g/find/b/sub
printf 'g1
' > /opt/exam-g/find/a/file1.txt
printf 'g2
' > /opt/exam-g/find/b/sub/file2.txt
chown -R trackerg:trackerg /opt/exam-g/find
mkdir -p /usr/share/dict
cat > /usr/share/dict/words <<'EOF'
ember
embers
ash
coal
EOF
rm -rf /var/log/journal
python - <<'EOF'
from pathlib import Path
p = Path('/etc/systemd/journald.conf')
text = p.read_text()
if 'Storage=persistent' in text:
    text = text.replace('Storage=persistent', 'Storage=auto')
p.write_text(text)
EOF
systemctl restart systemd-journald >/dev/null 2>&1 || true
id workerg >/dev/null 2>&1 || useradd -m workerg
pkill -u workerg -f 'while :; do :; done' >/dev/null 2>&1 || true
pkill -u workerg -f 'sleep 7200' >/dev/null 2>&1 || true
runuser -l workerg -c 'nohup bash -c "while :; do :; done" >/dev/null 2>&1 & echo $! > ~/cpu.pid'
runuser -l workerg -c 'nohup sleep 7200 >/dev/null 2>&1 & echo $! > ~/sleep.pid'
swapoff /dev/sdb1 >/dev/null 2>&1 || true
sed -i '\#swap#d' /etc/fstab
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
umount /mnt/deltalv >/dev/null 2>&1 || true
sed -i '\#/mnt/deltalv#d' /etc/fstab
lvremove -fy /dev/deltavg/deltalv >/dev/null 2>&1 || true
vgremove -fy deltavg >/dev/null 2>&1 || true
pvremove -ffy /dev/sdc1 >/dev/null 2>&1 || true
wipefs -a /dev/sdc >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdc >/dev/null 2>&1 || true
podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null
id solg >/dev/null 2>&1 || useradd -m solg
runuser -l solg -c 'podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true'
mkdir -p /opt/ing /opt/outg /opt/rhcsa/workspaces/exam-g/site-content
cat > /opt/rhcsa/workspaces/exam-g/site-content/index.html <<'EOF'
exam g container
EOF
cat > /opt/rhcsa/workspaces/exam-g/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF
chown -R solg:solg /opt/rhcsa/workspaces/exam-g /opt/ing /opt/outg
runuser -l solg -c 'podman rm -f pdfg >/dev/null 2>&1 || true'
runuser -l solg -c 'podman rmi -f localhost/delta-web:latest >/dev/null 2>&1 || true'
rm -rf /home/solg/.config/systemd/user
loginctl disable-linger solg >/dev/null 2>&1 || true
