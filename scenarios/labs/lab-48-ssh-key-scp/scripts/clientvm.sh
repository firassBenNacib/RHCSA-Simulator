#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id bridge48 >/dev/null 2>&1 || useradd -m bridge48
printf 'bridge48:cinder9
' | chpasswd
rm -rf /home/bridge48/.ssh /home/bridge48/inbox
printf 'bridge48 payload
' > /home/bridge48/payload.txt
chown -R bridge48:bridge48 /home/bridge48
