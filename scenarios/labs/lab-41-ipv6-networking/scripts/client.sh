#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
hostnamectl set-hostname client >/dev/null 2>&1 || true
rhcsa_remove_matching_lines 'server.ipv6lab.local' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv6_profile "$connection_name"
