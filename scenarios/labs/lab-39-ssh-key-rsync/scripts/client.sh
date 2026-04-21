#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id mesh39 >/dev/null 2>&1 || useradd -m mesh39
passwd -l mesh39 >/dev/null 2>&1 || true
rm -rf /home/mesh39/.ssh /home/mesh39/client-data
mkdir -p /home/mesh39/client-data
echo 'file39' > /home/mesh39/client-data/file1.txt
chown -R mesh39:mesh39 /home/mesh39
