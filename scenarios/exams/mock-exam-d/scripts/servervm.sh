#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-server-scripts
rhcsa_reset_repo_directory /root/.repo-backup-server-scripts
mkdir -p /exports/summit-home
printf 'summit export
' > /exports/summit-home/brief.txt
chown -R nobody:nobody /exports/summit-home
cat > /etc/exports.d/exam-d.exports <<'EOF'
/exports/summit-home 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
