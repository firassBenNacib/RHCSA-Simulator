#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

# --- Reset hostname and network ---
hostnamectl set-hostname client
rhcsa_remove_matching_lines 'serverg.exam10.lab' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"

# --- Reset repos ---
rhcsa_reset_repo_directory /root/.repo-backup-exam-g

# --- Remove flatpak remotes ---
flatpak remote-delete --system examgflatpak >/dev/null 2>&1 || true
flatpak uninstall --system -y org.rhcsa.Tools >/dev/null 2>&1 || true

# --- Remove users, groups, sudoers ---
userdel -r userg10 >/dev/null 2>&1 || true
groupdel teamg10 >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/teamg10-systemctl

# --- Exam G find dataset and users ---
while read -r job; do atrm "$job" >/dev/null 2>&1 || true; done < <(atq 2>/dev/null | awk '$NF == "hazel10" {print $1}')
userdel -r grant10 >/dev/null 2>&1 || true
userdel -r hazel10 >/dev/null 2>&1 || true
userdel -r copy10 >/dev/null 2>&1 || true
userdel -r noaccess70 >/dev/null 2>&1 || true
groupdel devg10 >/dev/null 2>&1 || true
rm -rf /srv/devg10 /opt/exam-g/find /home/hazel10 /home/grant10 /home/copy10
mkdir -p /opt/exam-g/find/recent /opt/exam-g/find/archive
echo 'grant recent' > /opt/exam-g/find/recent/grant-a.txt
echo 'grant archive' > /opt/exam-g/find/archive/grant-old.txt
echo 'root recent' > /opt/exam-g/find/recent/root-a.txt
touch -d '2 days ago' /opt/exam-g/find/archive/grant-old.txt
chown 3017:0 /opt/exam-g/find/recent/grant-a.txt /opt/exam-g/find/archive/grant-old.txt
chown root:root /opt/exam-g/find/recent/root-a.txt
mkdir -p /usr/share/dict
cat > /usr/share/dict/words <<'EOFWORDS'
alpha
database
metadata
kernel
EOFWORDS


# --- SELinux: reset boolean, remove port labels ---
setsebool httpd_can_network_connect 0 2>/dev/null || true
semanage port -d -t http_port_t -p tcp 8106 >/dev/null 2>&1 || true

# --- Firewalld: remove port, reset service ---
firewall-cmd --permanent --remove-port=8106/tcp >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-service=https >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true

# --- SELinux context: mislabel file for restorecon task ---
mkdir -p /var/www/html
echo 'g' > /var/www/html/g.html
chcon -t user_tmp_t /var/www/html/g.html 2>/dev/null || true

# --- Remove sticky directory ---
rm -rf /srv/teamg10
groupdel teamg10 >/dev/null 2>&1 || true

# --- Tuned: reset profile, disable tuned ---
systemctl disable --now tuned >/dev/null 2>&1 || true
tuned-adm profile balanced >/dev/null 2>&1 || true

# --- Journal: remove persistent config ---
rm -rf /var/log/journal
rm -f /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf /etc/systemd/journald.conf.d/persistent.conf
sed -i '/^[[:space:]]*Storage[[:space:]]*=.*persistent/d' /etc/systemd/journald.conf >/dev/null 2>&1 || true

# --- Chrony: disable and strip config ---
systemctl disable --now chronyd >/dev/null 2>&1 || true
dnf remove -y chrony >/dev/null 2>&1 || true
rm -f /etc/chrony.conf

# --- Timer: remove any existing timer ---
rm -f /etc/systemd/system/examgtimer.service /etc/systemd/system/examgtimer.timer
rm -f /usr/local/sbin/examgtimer.sh
systemctl disable --now examgtimer.timer >/dev/null 2>&1 || true

# --- Cron: remove crontab ---
crontab -r -u userg10 >/dev/null 2>&1 || true

# --- Autofs: remove configs ---
systemctl disable --now autofs >/dev/null 2>&1 || true
rm -f /etc/auto.remoteg /etc/auto.master.d/g.autofs
automount -u >/dev/null 2>&1 || true
rm -rf /remoteg

# --- LVM: wipe /dev/sdb ---
umount /mnt/datag10 >/dev/null 2>&1 || true
sed -i '\#/mnt/datag10#d' /etc/fstab
lvremove -fy /dev/vgg10/datag >/dev/null 2>&1 || true
vgremove -fy vgg10 >/dev/null 2>&1 || true
pvremove -ffy /dev/sdb >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
partprobe /dev/sdb >/dev/null 2>&1 || true
udevadm settle

# --- Default target: reset to graphical ---
systemctl set-default graphical.target >/dev/null 2>&1 || true

# --- Packages: ensure lsof absent, tcpdump present ---
dnf remove -y lsof >/dev/null 2>&1 || true
dnf install -y tcpdump >/dev/null 2>&1 || true

# --- Kernel args: remove audit_backlog_limit ---
grubby --update-kernel=ALL --remove-args="audit_backlog_limit=8192" >/dev/null 2>&1 || true

# --- Scripts: remove leftover custom scripts ---
rm -f /usr/local/bin/g-who /root/g-shell-users.txt /root/g-etc.tar.gz
rm -f /root/g-original /root/g-hard /root/g-soft
