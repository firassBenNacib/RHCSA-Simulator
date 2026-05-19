#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
hostnamectl set-hostname client >/dev/null 2>&1 || true
rhcsa_remove_matching_lines 'server.ipv6lab.local' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
if [[ -n "${connection_name:-}" ]] && command -v rhcsa_prune_duplicate_connections >/dev/null 2>&1; then
  rhcsa_prune_duplicate_connections "$connection_name"
elif [[ -n "${connection_name:-}" ]]; then
  active_uuid="$(
    nmcli -t -f UUID,NAME connection show --active 2>/dev/null |
      awk -F: -v name="$connection_name" '$2 == name {print $1; exit}'
  )"
  while IFS=: read -r connection_uuid existing_name; do
    [[ "$existing_name" == "$connection_name" ]] || continue
    [[ -n "${active_uuid:-}" && "$connection_uuid" == "$active_uuid" ]] && continue
    nmcli connection delete uuid "$connection_uuid" >/dev/null 2>&1 || true
  done < <(nmcli -t -f UUID,NAME connection show 2>/dev/null)
fi
rhcsa_reset_lab_ipv6_profile "$connection_name"
