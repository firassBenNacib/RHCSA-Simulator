#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

workspace="/opt/rhcsa/workspaces/shell-scripting"
rhcsa_reset_dir "$workspace"

cat > "$workspace/users.csv" <<'EOF'
training1
training2
training3
EOF

cat > "$workspace/services.txt" <<'EOF'
sshd
firewalld
chronyd
EOF

userdel -r training1 >/dev/null 2>&1 || true
userdel -r training2 >/dev/null 2>&1 || true
userdel -r training3 >/dev/null 2>&1 || true
rm -f /usr/local/bin/rhcsa-user-summary /usr/local/bin/rhcsa-service-check /root/user-summary.txt /root/service-status.txt
