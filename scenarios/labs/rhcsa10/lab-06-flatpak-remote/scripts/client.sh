#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

rhcsa_reset_repo_directory /root/.repo-backup-flatpak rhcsa-flatpak.repo
cat > /etc/yum.repos.d/rhcsa-flatpak.repo <<'EOF'
[rhcsa-flatpak-baseos]
name=RHCSA Flatpak BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0

[rhcsa-flatpak-appstream]
name=RHCSA Flatpak AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF

dnf remove -y flatpak >/dev/null 2>&1 || true
flatpak remote-delete --system rhcsa10 >/dev/null 2>&1 || true
