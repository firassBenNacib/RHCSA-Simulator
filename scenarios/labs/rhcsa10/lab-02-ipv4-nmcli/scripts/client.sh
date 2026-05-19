#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"
if [[ -n "${connection_name:-}" ]]; then
  nmcli connection modify "$connection_name" ipv4.gateway "" ipv4.dns "" connection.autoconnect no >/dev/null 2>&1 || true
fi
