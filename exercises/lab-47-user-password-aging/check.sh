#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-47-user-password-aging/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
chage -l cycle47 | grep -Eq 'Minimum number of days between password change[^0-9]*2$' && chage -l cycle47 | grep -Eq 'Maximum number of days between password change[^0-9]*30$' && chage -l cycle47 | grep -Eq 'Number of days of warning before password expires[^0-9]*7$' && chage -l cycle47 | grep -Eq 'Last password change[^:]*: password must be changed'
