#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-25-pwquality-policy/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
grep -R -Eq '^[[:space:]]*minlen[[:space:]]*=[[:space:]]*12[[:space:]]*$' /etc/security/pwquality.conf.d && grep -R -Eq '^[[:space:]]*minclass[[:space:]]*=[[:space:]]*3[[:space:]]*$' /etc/security/pwquality.conf.d
