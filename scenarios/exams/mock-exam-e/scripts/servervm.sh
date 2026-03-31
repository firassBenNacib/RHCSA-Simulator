#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-server-exam-e
rhcsa_reset_repo_directory /root/.repo-backup-server-exam-e
mkdir -p /exports/harborhome
printf 'harbor export
' > /exports/harborhome/brief.txt
exportfs -arv
