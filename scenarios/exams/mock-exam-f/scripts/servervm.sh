#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-server-exam-f
rhcsa_reset_repo_directory /root/.repo-backup-server-exam-f
mkdir -p /exports/aurorahome
printf 'aurora export
' > /exports/aurorahome/brief.txt
exportfs -arv
userdel -r backupf >/dev/null 2>&1 || true
