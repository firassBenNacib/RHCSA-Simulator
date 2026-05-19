#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

mkdir -p /var/www/html
echo RHCSA10 > /var/www/html/rhcsa10.html
chcon -t user_tmp_t /var/www/html/rhcsa10.html 2>/dev/null || true
