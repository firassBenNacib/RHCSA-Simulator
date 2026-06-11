#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

# --- Reset hostname and network ---
hostnamectl set-hostname client
rhcsa_remove_matching_lines 'serverb.exam10.lab' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"

# --- Reset repos ---
rhcsa_reset_repo_directory /root/.repo-backup-exam-b

# --- Remove flatpak remotes ---
flatpak remote-delete --system exambflatpak >/dev/null 2>&1 || true
flatpak uninstall --system -y org.rhcsa.Tools >/dev/null 2>&1 || true

# --- Remove users, groups, sudoers ---
userdel -r userb10 >/dev/null 2>&1 || true
groupdel teamb10 >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/teamb10-systemctl


# --- SELinux: reset boolean, remove port labels ---
setsebool httpd_can_network_connect 0 2>/dev/null || true
semanage port -d -t http_port_t -p tcp 8101 >/dev/null 2>&1 || true

# --- Firewalld: remove port, reset service ---
firewall-cmd --permanent --remove-port=8101/tcp >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-service=https >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true

# --- SELinux context: mislabel file for restorecon task ---
mkdir -p /var/www/html
echo 'b' > /var/www/html/b.html
chcon -t user_tmp_t /var/www/html/b.html 2>/dev/null || true

# --- Remove sticky directory ---
rm -rf /srv/teamb10
groupdel teamb10 >/dev/null 2>&1 || true

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
rm -f /etc/systemd/system/exambtimer.service /etc/systemd/system/exambtimer.timer
rm -f /usr/local/sbin/exambtimer.sh
systemctl disable --now exambtimer.timer >/dev/null 2>&1 || true

# --- Cron: remove crontab ---
crontab -r -u userb10 >/dev/null 2>&1 || true

# --- Autofs: remove configs ---
systemctl disable --now autofs >/dev/null 2>&1 || true
rm -f /etc/auto.remoteb /etc/auto.master.d/b.autofs
automount -u >/dev/null 2>&1 || true
rm -rf /remoteb

# --- LVM: wipe /dev/sdb ---
umount /mnt/datab10 >/dev/null 2>&1 || true
sed -i '\#/mnt/datab10#d' /etc/fstab
lvremove -fy /dev/vgb10/datab >/dev/null 2>&1 || true
vgremove -fy vgb10 >/dev/null 2>&1 || true
pvremove -ffy /dev/sdb >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true

# --- Default target: reset to graphical ---
systemctl set-default graphical.target >/dev/null 2>&1 || true

# --- Packages: ensure lsof absent, tcpdump present ---
dnf remove -y lsof >/dev/null 2>&1 || true
dnf install -y tcpdump >/dev/null 2>&1 || true

# --- Kernel args: remove audit_backlog_limit ---
grubby --update-kernel=ALL --remove-args="audit_backlog_limit=8192" >/dev/null 2>&1 || true

# --- Scripts: remove leftover custom scripts ---
rm -f /usr/local/bin/b-who /root/b-shell-users.txt /root/b-etc.tar.gz
rm -f /root/b-original /root/b-hard /root/b-soft
