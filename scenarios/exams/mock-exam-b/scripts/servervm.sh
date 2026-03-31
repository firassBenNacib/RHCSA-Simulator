#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-server-scripts
rhcsa_reset_repo_directory /root/.repo-backup-server-scripts
mkdir -p /exports/meshb
printf 'exam b mesh
' > /exports/meshb/notes.txt
chown -R nobody:nobody /exports/meshb
cat > /etc/exports.d/exam-b.exports <<'EOF'
/exports/meshb 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
