#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

mkdir -p /exports/direct
echo 'nfs direct mount lab 41' > /exports/direct/welcome.txt
chown -R nobody:nobody /exports/direct
cat > /etc/exports.d/lab41.exports <<'EOFX'
/exports/direct 192.168.122.0/24(rw,sync,no_root_squash)
EOFX
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
