#!/usr/bin/env bash
set -euo pipefail
firewall-cmd --permanent --remove-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept' >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
