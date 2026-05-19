#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

mkdir -p /exports/autofs/projects
echo 'autofs lab 42' > /exports/autofs/projects/welcome.txt
chown -R nobody:nobody /exports/autofs/projects
cat > /etc/exports.d/lab42.exports <<'EOFX'
/exports/autofs/projects 192.168.122.0/24(rw,sync,no_root_squash)
EOFX
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
