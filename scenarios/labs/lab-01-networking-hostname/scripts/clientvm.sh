#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


hostnamectl set-hostname clientvm
rhcsa_remove_matching_lines 'repo.netlab.local' /etc/hosts
connection_name="$(rhcsa_get_lab_connection_name || true)"
rhcsa_reset_lab_ipv4_profile "$connection_name"
