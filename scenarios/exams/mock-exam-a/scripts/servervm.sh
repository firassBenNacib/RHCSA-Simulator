#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


    mkdir -p /root/.repo-backup-server-exam-a
    rhcsa_reset_repo_directory /root/.repo-backup-server-exam-a
    mkdir -p /exports/researcha
    printf 'exam a research
' > /exports/researcha/brief.txt
    exportfs -arv
