#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

dnf install -y flatpak >/dev/null 2>&1 || true
rm -rf /opt/rhcsa/flatpak/repo
