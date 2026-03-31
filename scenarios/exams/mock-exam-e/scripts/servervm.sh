#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-server-scripts
rhcsa_reset_repo_directory /root/.repo-backup-server-scripts
mkdir -p /exports/harborhome
printf 'harbor export
' > /exports/harborhome/brief.txt
chown -R nobody:nobody /exports/harborhome
cat > /etc/exports.d/exam-e.exports <<'EOF'
/exports/harborhome 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
