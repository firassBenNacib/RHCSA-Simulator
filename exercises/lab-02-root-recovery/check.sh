#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-02-root-recovery/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
getenforce | grep -qx Enforcing

# Check 02 [clientvm]
ls -Zd /root | grep -Eq '(^| )[^ ]+:object_r:admin_home_t:s0($| )'

# Check 03 [clientvm]
grep -Eq '^[[:space:]]*PasswordAuthentication[[:space:]]+yes[[:space:]]*$' /etc/ssh/sshd_config && grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+yes[[:space:]]*$' /etc/ssh/sshd_config
