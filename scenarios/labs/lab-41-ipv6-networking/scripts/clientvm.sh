#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
hostnamectl set-hostname clientvm >/dev/null 2>&1 || true
rhcsa_remove_matching_lines 'servervm.ipv6lab.local' /etc/hosts
connection_name="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
if [[ -n "${connection_name:-}" ]]; then
  nmcli connection modify "$connection_name" ipv6.method ignore ipv6.addresses "" ipv6.gateway "" ipv6.dns "" connection.autoconnect yes >/dev/null 2>&1 || true
  nmcli connection down "$connection_name" >/dev/null 2>&1 || true
  nmcli connection up "$connection_name" >/dev/null 2>&1 || true
fi
