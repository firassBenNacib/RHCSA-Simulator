#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

systemctl disable --now httpd >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-service=http >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
rm -f /var/www/html/rhcsa10-boot.html
