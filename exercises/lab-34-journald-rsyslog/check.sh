#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-34-journald-rsyslog/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
test -d /var/log/journal && grep -Eq '^[[:space:]]*Storage[[:space:]]*=[[:space:]]*persistent[[:space:]]*$' /etc/systemd/journald.conf

# Check 02 [clientvm]
grep -Eq '^[[:space:]]*authpriv\.warning[[:space:]]+/var/log/auth34\.log[[:space:]]*$' /etc/rsyslog.d/10-auth34.conf

# Check 03 [clientvm]
systemctl is-active rsyslog | grep -qx active
