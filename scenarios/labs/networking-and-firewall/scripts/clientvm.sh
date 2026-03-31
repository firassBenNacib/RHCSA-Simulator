#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

hostnamectl set-hostname clientvm
rhcsa_remove_matching_lines 'registry.lab.example.com' /etc/hosts
sed -i 's/^Listen .*/Listen 80/' /etc/httpd/conf/httpd.conf
echo "RHCSA networking lab" > /var/www/html/index.html
systemctl disable --now httpd >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-port=8080/tcp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
