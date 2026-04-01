#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id mesh39 >/dev/null 2>&1 || useradd -m mesh39
printf 'mesh39:cinder9\n' | chpasswd
rm -rf /home/mesh39/.ssh /home/mesh39/client-data
mkdir -p /home/mesh39/client-data
printf 'file39\n' > /home/mesh39/client-data/file1.txt
chown -R mesh39:mesh39 /home/mesh39
