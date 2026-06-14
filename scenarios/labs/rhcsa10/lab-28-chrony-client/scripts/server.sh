#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

dnf install -y chrony >/dev/null 2>&1 || true
cat > /etc/chrony.conf <<'EOF'
driftfile /var/lib/chrony/drift
pool 2.rhel.pool.ntp.org iburst
makestep 1.0 3
logdir /var/log/chrony
EOF
systemctl disable --now chronyd >/dev/null 2>&1 || true
