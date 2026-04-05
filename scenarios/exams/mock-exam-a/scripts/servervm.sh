#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-server-scripts
rhcsa_reset_repo_directory /root/.repo-backup-server-scripts
rm -rf /var/log/journal
rm -f /etc/systemd/journald.conf.d/persistent.conf
mkdir -p /exports/researcha
echo 'exam a research' > /exports/researcha/brief.txt
chown -R nobody:nobody /exports/researcha
cat > /etc/exports.d/exam-a.exports <<'EOF'
/exports/researcha 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
systemctl restart systemd-journald >/dev/null 2>&1 || true
