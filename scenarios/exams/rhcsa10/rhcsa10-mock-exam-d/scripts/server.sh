#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

# --- Reset repos on server ---
mkdir -p /root/.repo-backup-server-exam-d
rhcsa_reset_repo_directory /root/.repo-backup-server-exam-d

# --- NFS exports ---
mkdir -p /exports/direct
echo 'exam d direct' > /exports/direct/welcome.txt
chown -R nobody:nobody /exports/direct

mkdir -p /exports/autofs/projects
echo 'exam d autofs' > /exports/autofs/projects/welcome.txt
chown -R nobody:nobody /exports/autofs/projects

cat > /etc/exports.d/exam-d.exports <<'EOFX'
/exports/direct 192.168.122.0/24(rw,sync,no_root_squash)
/exports/autofs/projects 192.168.122.0/24(rw,sync,no_root_squash)
EOFX
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
