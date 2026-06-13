#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

# --- Reset repos on server ---
mkdir -p /root/.repo-backup-server-exam-a
rhcsa_reset_repo_directory /root/.repo-backup-server-exam-a

# --- NFS cleanup ---
rm -f /etc/exports.d/exam-a.exports /etc/exports.d/exam-a-integrated.exports
exportfs -ar >/dev/null 2>&1 || true
