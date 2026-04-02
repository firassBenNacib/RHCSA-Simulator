#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-24-password-aging-defaults/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
grep -Eq '^[[:space:]]*PASS_MAX_DAYS[[:space:]]+45[[:space:]]*$' /etc/login.defs && grep -Eq '^[[:space:]]*PASS_MIN_DAYS[[:space:]]+2[[:space:]]*$' /etc/login.defs && grep -Eq '^[[:space:]]*PASS_WARN_AGE[[:space:]]+10[[:space:]]*$' /etc/login.defs

# Check 02 [clientvm]
chage -l drift24 | grep -Eq 'Minimum number of days between password change[^0-9]*2$' && chage -l drift24 | grep -Eq 'Maximum number of days between password change[^0-9]*45$' && chage -l drift24 | grep -Eq 'Number of days of warning before password expires[^0-9]*10$'
