#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-04-selinux-http-port/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
ss -ltn '( sport = :9082 )' | grep -q ':9082' && systemctl is-enabled httpd | grep -qx enabled && systemctl is-active httpd | grep -qx active

# Check 02 [clientvm]
firewall-cmd --permanent --query-port=9082/tcp

# Check 03 [clientvm]
curl -fsS http://localhost:9082 >/dev/null && semanage port -l | grep -Eq '^http_port_t\b.*\b9082\b'
