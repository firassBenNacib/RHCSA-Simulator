#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-server-scripts
rhcsa_reset_repo_directory /root/.repo-backup-server-scripts
mkdir -p /exports/aurorahome
printf 'aurora export
' > /exports/aurorahome/brief.txt
chown -R nobody:nobody /exports/aurorahome
cat > /etc/exports.d/exam-f.exports <<'EOF'
/exports/aurorahome 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
