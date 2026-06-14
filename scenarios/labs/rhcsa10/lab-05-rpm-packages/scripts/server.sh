#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

rhcsa_reset_repo_directory /root/.repo-backup-server-lab05 rhcsa-local.repo
cat > /etc/yum.repos.d/rhcsa-local.repo <<'EOF'
[rhcsa-baseos]
name=RHCSA Local BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0

[rhcsa-appstream]
name=RHCSA Local AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf remove -y lsof >/dev/null 2>&1 || true
