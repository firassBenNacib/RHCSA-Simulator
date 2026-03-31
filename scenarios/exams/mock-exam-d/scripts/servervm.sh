#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-server-exam-d
rhcsa_reset_repo_directory /root/.repo-backup-server-exam-d
mkdir -p /exports/summit-home
printf 'summit export
' > /exports/summit-home/brief.txt
exportfs -arv
