#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

# --- Reset hostname and network ---
hostnamectl set-hostname client
rhcsa_remove_matching_lines 'serverf.exam10.lab' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"

# --- Reset repos ---
rhcsa_reset_repo_directory /root/.repo-backup-exam-f

# --- Remove flatpak remotes ---
flatpak remote-delete --system examfflatpak >/dev/null 2>&1 || true
flatpak uninstall --system -y org.rhcsa.Tools >/dev/null 2>&1 || true

# --- Remove users, groups, sudoers ---
userdel -r userf10 >/dev/null 2>&1 || true
groupdel teamf10 >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/teamf10-systemctl

# --- Exam F storage and service cleanup ---
swapoff /dev/sdc1 >/dev/null 2>&1 || true
sed -i '/[[:space:]]swap[[:space:]]/d' /etc/fstab
for dev in /dev/sdc[0-9]* /dev/sdc; do
    [ -e "$dev" ] || continue
    wipefs -a "$dev" >/dev/null 2>&1 || true
done
sgdisk --zap-all /dev/sdc >/dev/null 2>&1 || true
partprobe /dev/sdc >/dev/null 2>&1 || true
systemctl disable --now examf-cleanup.service >/dev/null 2>&1 || true
rm -f /etc/systemd/system/examf-cleanup.service /usr/local/sbin/examf-cleanup.sh /var/log/examf-cleanup.log
systemctl daemon-reload >/dev/null 2>&1 || true
rm -rf /opt/exam-f/find /root/examf-rootfiles
mkdir -p /opt/exam-f/find/a /opt/exam-f/find/b
echo FROOT > /opt/exam-f/find/a/root.conf
echo FUSER > /opt/exam-f/find/b/user.conf
chown root:root /opt/exam-f/find/a/root.conf
chown nobody:nobody /opt/exam-f/find/b/user.conf


# --- SELinux: reset boolean, remove port labels ---
setsebool httpd_can_network_connect 0 2>/dev/null || true
semanage port -d -t http_port_t -p tcp 8105 >/dev/null 2>&1 || true

# --- Firewalld: remove port, reset service ---
firewall-cmd --permanent --remove-port=8105/tcp >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-service=https >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true

# --- SELinux context: mislabel file for restorecon task ---
mkdir -p /var/www/html
echo 'f' > /var/www/html/f.html
chcon -t user_tmp_t /var/www/html/f.html 2>/dev/null || true

# --- Remove sticky directory ---
rm -rf /srv/teamf10
groupdel teamf10 >/dev/null 2>&1 || true

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
rm -f /etc/systemd/system/examftimer.service /etc/systemd/system/examftimer.timer
rm -f /usr/local/sbin/examftimer.sh
systemctl disable --now examftimer.timer >/dev/null 2>&1 || true

# --- Cron: remove crontab ---
crontab -r -u userf10 >/dev/null 2>&1 || true

# --- Autofs: remove configs ---
systemctl disable --now autofs >/dev/null 2>&1 || true
rm -f /etc/auto.remotef /etc/auto.master.d/f.autofs
automount -u >/dev/null 2>&1 || true
rm -rf /remotef

# --- LVM: wipe /dev/sdb ---
umount /mnt/dataf10 >/dev/null 2>&1 || true
sed -i '\#/mnt/dataf10#d' /etc/fstab
lvremove -fy /dev/vgf10/dataf >/dev/null 2>&1 || true
vgremove -fy vgf10 >/dev/null 2>&1 || true
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
rm -f /usr/local/bin/f-who /root/f-shell-users.txt /root/f-etc.tar.gz
rm -f /root/f-original /root/f-hard /root/f-soft
