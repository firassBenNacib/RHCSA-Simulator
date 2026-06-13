#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

# --- Reset repos on server ---
mkdir -p /root/.repo-backup-server-exam-g
rhcsa_reset_repo_directory /root/.repo-backup-server-exam-g

# --- NFS cleanup ---
rm -f /etc/exports.d/exam-g.exports /etc/exports.d/exam-g-integrated.exports
exportfs -ar >/dev/null 2>&1 || true
