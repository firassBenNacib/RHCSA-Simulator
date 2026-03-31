#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

workspace="/opt/rhcsa/workspaces/essential-tools"
rhcsa_reset_dir "$workspace"
mkdir -p "$workspace/data" "$workspace/logs" "$workspace/secure"

cat > "$workspace/data/report.txt" <<'EOF'
Quarterly operational report
EOF

cat > "$workspace/logs/app.log" <<'EOF'
INFO service started
ERROR disk threshold reached
INFO cleanup complete
ERROR backup failed
EOF

: > "$workspace/data/main.conf"
: > "$workspace/data/extra.conf"
: > "$workspace/data/site.conf"
rm -f /root/essential-tools-backup.tar.gz /root/errors-only.log /root/conf-count.txt
groupadd -f adm
chown -R root:root "$workspace"
