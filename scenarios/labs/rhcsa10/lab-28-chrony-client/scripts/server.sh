#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

dnf install -y chrony >/dev/null 2>&1 || true
cat > /etc/chrony.d/lab28-server.conf <<'EOF'
allow 192.168.122.0/24
local stratum 10
EOF
systemctl enable --now chronyd
