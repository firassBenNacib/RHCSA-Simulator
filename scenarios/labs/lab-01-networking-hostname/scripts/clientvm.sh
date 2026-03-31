#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


hostnamectl set-hostname clientvm
rhcsa_remove_matching_lines 'repo.netlab.local' /etc/hosts
connection_name="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
if [[ -n "${connection_name:-}" ]]; then
  nmcli connection modify "$connection_name" ipv4.addresses 192.168.122.2/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes >/dev/null 2>&1 || true
  nmcli connection down "$connection_name" >/dev/null 2>&1 || true
  nmcli connection up "$connection_name" >/dev/null 2>&1 || true
fi
