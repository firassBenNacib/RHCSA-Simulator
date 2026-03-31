#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-client-exam-f
rhcsa_reset_repo_directory /root/.repo-backup-client-exam-f
hostnamectl set-hostname clientvm
rhcsa_remove_matching_lines 'db.aurora.lab' /etc/hosts
connection_name="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
if [[ -n "${connection_name:-}" ]]; then
  nmcli connection modify "$connection_name" ipv4.addresses 192.168.122.2/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes >/dev/null 2>&1 || true
  nmcli connection down "$connection_name" >/dev/null 2>&1 || true
  nmcli connection up "$connection_name" >/dev/null 2>&1 || true
fi
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
for u in elio risa nox auditf aurorarem pine560 seekerf opsf solf; do userdel -r "$u" >/dev/null 2>&1 || true; done
groupdel auroraops >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/auroraops /etc/sudoers.d/elio-passwd
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
printf 'f1
' > /opt/exam-f/find/a/file1.txt
printf 'f2
' > /opt/exam-f/find/c/sub/file2.txt
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
podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null
id solf >/dev/null 2>&1 || useradd -m solf
runuser -l solf -c 'podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true'
mkdir -p /opt/inf /opt/outf /opt/rhcsa/workspaces/exam-f/site-content
cat > /opt/rhcsa/workspaces/exam-f/site-content/index.html <<'EOF'
exam f container
EOF
cat > /opt/rhcsa/workspaces/exam-f/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF
chown -R solf:solf /opt/rhcsa/workspaces/exam-f /opt/inf /opt/outf
runuser -l solf -c 'podman rm -f pdff >/dev/null 2>&1 || true'
runuser -l solf -c 'podman rmi -f localhost/aurora-web:latest >/dev/null 2>&1 || true'
rm -rf /home/solf/.config/systemd/user
loginctl disable-linger solf >/dev/null 2>&1 || true
userdel -r backupf >/dev/null 2>&1 || true
