#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-28-selinux-custom-docroot/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
curl -fsS http://localhost:8088 >/dev/null

# Check 02 [clientvm]
semanage port -l | grep -Eq '^http_port_t\b.*\b8088\b' && firewall-cmd --permanent --query-port=8088/tcp && systemctl is-enabled httpd | grep -qx enabled

# Check 03 [clientvm]
matchpathcon /srv/lab28/site/index.html | grep -Eq ':httpd_sys_content_t:' && ls -Zd /srv/lab28/site | grep -Eq ':httpd_sys_content_t:'
