#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /var/www/html
echo 'lab45' > /var/www/html/index45.html
chcon -t user_tmp_t /var/www/html/index45.html >/dev/null 2>&1 || true
systemctl disable --now httpd >/dev/null 2>&1 || true
setenforce 1 >/dev/null 2>&1 || true
