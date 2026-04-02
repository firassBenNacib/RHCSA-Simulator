#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-30-links-hard-soft/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
test "$(stat -c '%i' /root/linksource30)" = "$(stat -c '%i' /root/linkhard30)" && test "$(stat -c '%h' /root/linksource30)" -ge 2

# Check 02 [clientvm]
test "$(readlink -f /root/linksoft30)" = '/root/linksource30' && grep -Fqx 'link-test' /root/linksource30
