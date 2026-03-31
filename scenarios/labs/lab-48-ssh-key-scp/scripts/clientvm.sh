#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id copy48 >/dev/null 2>&1 || useradd -m copy48
printf 'copy48:redhat
' | chpasswd
rm -rf /home/copy48/.ssh /home/copy48/inbox
printf 'copy48 payload
' > /home/copy48/payload.txt
chown -R copy48:copy48 /home/copy48
