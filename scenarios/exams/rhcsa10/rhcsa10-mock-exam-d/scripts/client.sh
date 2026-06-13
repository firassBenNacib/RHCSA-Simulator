#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

# --- Reset hostname and network ---
hostnamectl set-hostname client
rhcsa_remove_matching_lines 'serverd.exam10.lab' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"

# --- Reset repos ---
rhcsa_reset_repo_directory /root/.repo-backup-exam-d

# --- Remove flatpak remotes ---
flatpak remote-delete --system examdflatpak >/dev/null 2>&1 || true
flatpak uninstall --system -y org.rhcsa.Tools >/dev/null 2>&1 || true

# --- Remove users, groups, sudoers ---
userdel -r userd10 >/dev/null 2>&1 || true
groupdel teamd10 >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/teamd10-systemctl

# --- Exam D service and logging cleanup ---
systemctl disable --now examd-heartbeat.service >/dev/null 2>&1 || true
rm -f /etc/systemd/system/examd-heartbeat.service /usr/local/sbin/examd-heartbeat.sh /var/log/examd-heartbeat.log
rm -f /etc/rsyslog.d/examd-local5.conf /var/log/examd-local5.log
systemctl daemon-reload >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-service=http >/dev/null 2>&1 || true
firewall-cmd --remove-service=http >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true


# --- SELinux: reset boolean, remove port labels ---
setsebool httpd_can_network_connect 0 2>/dev/null || true
semanage port -d -t http_port_t -p tcp 8103 >/dev/null 2>&1 || true

# --- Firewalld: remove port, reset service ---
firewall-cmd --permanent --remove-port=8103/tcp >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-service=https >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true

# --- SELinux context: mislabel file for restorecon task ---
mkdir -p /var/www/html
echo 'd' > /var/www/html/d.html
chcon -t user_tmp_t /var/www/html/d.html 2>/dev/null || true

# --- Remove sticky directory ---
rm -rf /srv/teamd10
groupdel teamd10 >/dev/null 2>&1 || true

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
rm -f /etc/systemd/system/examdtimer.service /etc/systemd/system/examdtimer.timer
rm -f /usr/local/sbin/examdtimer.sh
systemctl disable --now examdtimer.timer >/dev/null 2>&1 || true

# --- Cron: remove crontab ---
crontab -r -u userd10 >/dev/null 2>&1 || true

# --- Autofs: remove configs ---
systemctl disable --now autofs >/dev/null 2>&1 || true
rm -f /etc/auto.remoted /etc/auto.master.d/d.autofs
automount -u >/dev/null 2>&1 || true
rm -rf /remoted

# --- LVM: wipe /dev/sdb ---
umount /mnt/datad10 >/dev/null 2>&1 || true
sed -i '\#/mnt/datad10#d' /etc/fstab
lvremove -fy /dev/vgd10/datad >/dev/null 2>&1 || true
vgremove -fy vgd10 >/dev/null 2>&1 || true
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
rm -f /usr/local/bin/d-who /root/d-shell-users.txt /root/d-etc.tar.gz
rm -f /root/d-original /root/d-hard /root/d-soft
