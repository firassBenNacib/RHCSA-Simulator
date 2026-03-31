#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

systemctl disable --now chronyd >/dev/null 2>&1 || true
sed -i '/^server /d;/^pool /d' /etc/chrony.conf

umount /srv/reference >/dev/null 2>&1 || true
automount -u >/dev/null 2>&1 || true
rm -rf /research /srv/reference
mkdir -p /research /srv/reference
rhcsa_remove_matching_lines '/srv/reference' /etc/fstab
rm -f /etc/auto.master.d/rhcsa.research.autofs /etc/auto.research
systemctl disable --now autofs >/dev/null 2>&1 || true

userdel -r orchid >/dev/null 2>&1 || true
groupdel platformops >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/platformops-httpd
rm -rf /home/orchid
rhcsa_remove_matching_lines 'internal-api.edge.lab' /etc/hosts
rm -f /home/orchid/edge-brief.txt

mkdir -p /home/admin/.ssh
if [[ ! -f /home/admin/.ssh/id_rsa ]]; then
  ssh-keygen -q -t rsa -N '' -f /home/admin/.ssh/id_rsa
fi
chown -R admin:admin /home/admin/.ssh
chmod 700 /home/admin/.ssh

hostnamectl set-hostname clientvm
mkdir -p /var/www/html
echo "Edge practice portal" > /var/www/html/index.html
if [[ -f /etc/httpd/conf/httpd.conf ]]; then
  sed -i 's/^Listen .*/Listen 80/' /etc/httpd/conf/httpd.conf
fi
systemctl disable --now httpd >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-port=8088/tcp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true

connection_name="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
if [[ -n "${connection_name:-}" ]]; then
  nmcli connection modify "$connection_name" -ipv4.routes "203.0.113.0/24 192.168.122.3" >/dev/null 2>&1 || true
fi
