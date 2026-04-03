#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-server-scripts
rhcsa_reset_repo_directory /root/.repo-backup-server-scripts
: > /etc/issue
: > /etc/motd
systemctl set-default graphical.target >/dev/null 2>&1 || true
systemctl disable --now rsyslog >/dev/null 2>&1 || true
systemctl enable --now postfix >/dev/null 2>&1 || true
dnf remove -y tree >/dev/null 2>&1 || true
rpm -q dos2unix >/dev/null 2>&1 || dnf install -y dos2unix >/dev/null 2>&1 || true
mkdir -p /exports/summit-home
printf 'summit export
' > /exports/summit-home/brief.txt
chown -R nobody:nobody /exports/summit-home
cat > /etc/exports.d/exam-d.exports <<'EOF'
/exports/summit-home 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
