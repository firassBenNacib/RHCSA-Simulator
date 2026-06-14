#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

rhcsa_reset_repo_directory /root/.repo-backup-server-flatpak rhcsa-flatpak.repo
