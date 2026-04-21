#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
cat > /etc/yum.repos.d/lab43.repo <<'EOF'
[lab43-baseos]
name=Lab43 BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0

[lab43-appstream]
name=Lab43 AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all >/dev/null 2>&1 || true
dnf remove -y tree >/dev/null 2>&1 || true
dnf install -y dos2unix >/dev/null 2>&1 || true
