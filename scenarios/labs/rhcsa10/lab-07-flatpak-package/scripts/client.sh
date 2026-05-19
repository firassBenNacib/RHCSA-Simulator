#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

dnf install -y flatpak >/dev/null 2>&1 || true
flatpak uninstall --system -y org.rhcsa.Tools >/dev/null 2>&1 || true
flatpak remote-delete --system rhcsa10 >/dev/null 2>&1 || true
