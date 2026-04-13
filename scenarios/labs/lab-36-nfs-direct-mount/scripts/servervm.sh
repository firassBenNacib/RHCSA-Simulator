#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /exports/direct36
echo 'nfs36' > /exports/direct36/nfs36.txt
chown -R nobody:nobody /exports/direct36
rhcsa_ensure_packages nfs-utils >/dev/null 2>&1 || true
cat > /etc/exports.d/direct36.exports <<'EOF'
/exports/direct36 192.168.122.0/24(ro,sync,no_root_squash)
EOF
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
firewall-cmd --add-service=nfs >/dev/null 2>&1 || true
firewall-cmd --add-service=rpc-bind >/dev/null 2>&1 || true
firewall-cmd --add-service=mountd >/dev/null 2>&1 || true
