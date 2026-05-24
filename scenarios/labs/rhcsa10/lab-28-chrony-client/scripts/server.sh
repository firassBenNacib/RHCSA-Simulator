#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

dnf install -y chrony >/dev/null 2>&1 || true
install -d -m 755 /etc/chrony.d
cat > /etc/chrony.conf <<'EOF'
driftfile /var/lib/chrony/drift
makestep 1.0 3
allow 192.168.122.0/24
local stratum 10
logdir /var/log/chrony
EOF
systemctl enable --now chronyd
