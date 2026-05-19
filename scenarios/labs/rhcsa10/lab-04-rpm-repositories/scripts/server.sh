#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

mkdir -p /root/.repo-backup-server-lab04
rhcsa_reset_repo_directory /root/.repo-backup-server-lab04
