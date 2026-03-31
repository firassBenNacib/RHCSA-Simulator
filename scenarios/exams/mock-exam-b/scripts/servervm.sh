#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


    mkdir -p /root/.repo-backup-server-exam-b
    rhcsa_reset_repo_directory /root/.repo-backup-server-exam-b
    mkdir -p /exports/meshb
    printf 'exam b autofs
' > /exports/meshb/notes.txt
    exportfs -arv
