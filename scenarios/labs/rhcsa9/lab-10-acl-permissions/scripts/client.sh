#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


for u in natacl haracl; do id "$u" >/dev/null 2>&1 || useradd -m "$u"; done
rm -f /var/tmp/fstab-acl
