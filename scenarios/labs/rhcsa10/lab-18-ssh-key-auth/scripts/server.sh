#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

install -d -m 700 /root/.ssh
ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519_key10 -N '' -C 'key10-test' >/dev/null 2>&1 || true
