#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id key39 >/dev/null 2>&1 || useradd -m key39
printf 'key39:redhat\n' | chpasswd
rm -rf /home/key39/.ssh /home/key39/client-data
mkdir -p /home/key39/client-data
printf 'file39\n' > /home/key39/client-data/file1.txt
chown -R key39:key39 /home/key39
