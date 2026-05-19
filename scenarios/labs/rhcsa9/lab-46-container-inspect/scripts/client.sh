#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

rhcsa_ensure_httpd_base_archive || {
  echo "Failed to prepare /opt/rhcsa/container-assets/rhcsa-httpd-base.tar." >&2
  echo "Rebuild the baseline with .\\RHCSA.ps1 destroy and .\\RHCSA.ps1 up." >&2
  exit 1
}
userdel -r scope46 >/dev/null 2>&1 || true
