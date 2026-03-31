#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

workspace="/opt/rhcsa/workspaces/container"
mkdir -p "$workspace/site-content"
podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null

cat > "$workspace/site-content/index.html" <<'EOF'
RHCSA container page
EOF

cat > "$workspace/Containerfile" <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF

podman rm -f rhcsa-web >/dev/null 2>&1 || true
podman rmi -f localhost/rhcsa-web:latest >/dev/null 2>&1 || true
rm -rf /root/.config/systemd/user
