#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


    mkdir -p /root/.repo-backup-server-exam-c
    rhcsa_reset_repo_directory /root/.repo-backup-server-exam-c
    mkdir -p /exports/bluec
    printf 'exam c autofs
' > /exports/bluec/info.txt
    exportfs -arv
