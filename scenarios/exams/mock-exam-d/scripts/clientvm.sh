#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

mkdir -p /root/.repo-backup-client-exam-d
rhcsa_reset_repo_directory /root/.repo-backup-client-exam-d
hostnamectl set-hostname clientvm
rhcsa_remove_matching_lines 'mirror.summit.lab' /etc/hosts
connection_name="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
if [[ -n "${connection_name:-}" ]]; then
  nmcli connection modify "$connection_name" ipv4.addresses 192.168.122.2/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes >/dev/null 2>&1 || true
  nmcli connection down "$connection_name" >/dev/null 2>&1 || true
  nmcli connection up "$connection_name" >/dev/null 2>&1 || true
fi
mkdir -p /srv/summit-web
cat > /srv/summit-web/index.html <<'EOF'
summit exam page
EOF
rm -f /etc/httpd/conf.d/summit.conf
systemctl disable --now httpd >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-port=8085/tcp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
semanage port -d -t http_port_t -p tcp 8085 >/dev/null 2>&1 || true
restorecon -Rv /srv/summit-web >/dev/null 2>&1 || true
for u in kara miles zero auditord trainee54 summitremote cedar540 neriad foragerd; do userdel -r "$u" >/dev/null 2>&1 || true; done
groupdel summitops >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/summitops /etc/sudoers.d/kara-passwd
rm -rf /projects/summit /root/miles-files /summit-home /usr/local/bin/summit-scan /root/summit-units.txt /root/alpha-lines /root/summit-etc.tar.gz /opt/exam-d
python - <<'EOF'
from pathlib import Path
for p in [Path('/etc/security/pwquality.conf.d/exam-d.conf')]:
    try:
        p.unlink()
    except FileNotFoundError:
        pass
EOF
python - <<'EOF'
from pathlib import Path
p = Path('/etc/login.defs')
text = p.read_text()
for key, value in [('PASS_MAX_DAYS', '99999'), ('PASS_MIN_DAYS', '0'), ('PASS_WARN_AGE', '7')]:
    lines = []
    done = False
    for line in text.splitlines():
        if line.startswith(key):
            lines.append(f'{key}	{value}')
            done = True
        else:
            lines.append(line)
    if not done:
        lines.append(f'{key}	{value}')
    text = '
'.join(lines) + '
'
p.write_text(text)
EOF
automount -u >/dev/null 2>&1 || true
rm -f /etc/auto.summit /etc/auto.master.d/summit.autofs
systemctl disable --now autofs >/dev/null 2>&1 || true
crontab -r -u miles >/dev/null 2>&1 || true
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
id foragerd >/dev/null 2>&1 || useradd -m foragerd
mkdir -p /opt/exam-d/find/a /opt/exam-d/find/b/sub
printf 'd1
' > /opt/exam-d/find/a/file1.txt
printf 'd2
' > /opt/exam-d/find/b/sub/file2.txt
chown -R foragerd:foragerd /opt/exam-d/find
mkdir -p /usr/share/dict
cat > /usr/share/dict/words <<'EOF'
alpha
alphanumeric
beta
gamma
EOF
mkdir -p /usr/local/share/exam-d
cat > /usr/local/share/exam-d/units.lst <<'EOF'
sshd
firewalld
chronyd
EOF
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
wipefs -a /dev/sdc >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdc >/dev/null 2>&1 || true
sed -i '\#/mnt/summitlv#d' /etc/fstab
umount /mnt/summitlv >/dev/null 2>&1 || true
lvremove -fy /dev/summitvg/summitlv >/dev/null 2>&1 || true
vgremove -fy summitvg >/dev/null 2>&1 || true
pvremove -ffy /dev/sdc1 >/dev/null 2>&1 || true
podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null
id neriad >/dev/null 2>&1 || useradd -m neriad
runuser -l neriad -c 'podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true'
mkdir -p /opt/ind /opt/outd /opt/rhcsa/workspaces/exam-d/site-content
cat > /opt/rhcsa/workspaces/exam-d/site-content/index.html <<'EOF'
exam d container
EOF
cat > /opt/rhcsa/workspaces/exam-d/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF
chown -R neriad:neriad /opt/rhcsa/workspaces/exam-d /opt/ind /opt/outd
runuser -l neriad -c 'podman rm -f pdfd >/dev/null 2>&1 || true'
runuser -l neriad -c 'podman rmi -f localhost/summit-web:latest >/dev/null 2>&1 || true'
rm -rf /home/neriad/.config/systemd/user
loginctl disable-linger neriad >/dev/null 2>&1 || true
