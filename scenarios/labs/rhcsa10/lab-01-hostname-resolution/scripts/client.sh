#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

hostnamectl set-hostname client
rhcsa_remove_matching_lines 'server10.lab.example' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"
