#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-45-restorecon-httpd/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
getenforce | grep -qx Enforcing

# Check 02 [clientvm]
matchpathcon /var/www/html/index45.html | grep -Eq ':httpd_sys_content_t:' && ls -Z /var/www/html/index45.html | grep -Eq ':httpd_sys_content_t:'

# Check 03 [clientvm]
systemctl is-enabled httpd | grep -qx enabled && systemctl is-active httpd | grep -qx active
