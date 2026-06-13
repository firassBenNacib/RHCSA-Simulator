#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

# --- Reset repos on server ---
mkdir -p /root/.repo-backup-server-exam-b
rhcsa_reset_repo_directory /root/.repo-backup-server-exam-b

# --- NFS cleanup ---
rm -f /etc/exports.d/exam-b.exports /etc/exports.d/exam-b-integrated.exports
exportfs -ar >/dev/null 2>&1 || true
