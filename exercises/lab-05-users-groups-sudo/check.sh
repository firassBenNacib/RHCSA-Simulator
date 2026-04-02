#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-05-users-groups-sudo/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
id -nG brenor | tr ' ' '\n' | grep -qx opsrune && getent passwd brenor >/dev/null

# Check 02 [clientvm]
id -nG lyessa | tr ' ' '\n' | grep -qx opsrune && getent passwd lyessa >/dev/null

# Check 03 [clientvm]
getent passwd quillan | awk -F: '{exit !($7=="/sbin/nologin")}'

# Check 04 [clientvm]
visudo -cf /etc/sudoers.d/opsrune >/dev/null && grep -Eq '^%opsrune[[:space:]]+ALL=\(root\)[[:space:]]+/usr/sbin/useradd[[:space:]]*$' /etc/sudoers.d/opsrune

# Check 05 [clientvm]
visudo -cf /etc/sudoers.d/brenor-passwd >/dev/null && grep -Eq '^brenor[[:space:]]+ALL=\(root\)[[:space:]]+NOPASSWD:[[:space:]]+/usr/bin/passwd[[:space:]]*$' /etc/sudoers.d/brenor-passwd
