#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null
id builder20 >/dev/null 2>&1 || useradd -m builder20
runuser -l builder20 -c 'podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true'
rm -rf /opt/rhcsa/workspaces/text2pdf20
mkdir -p /opt/rhcsa/workspaces/text2pdf20/site-content
cat > /opt/rhcsa/workspaces/text2pdf20/site-content/index.html <<'EOF'
text2pdf20 image
EOF
cat > /opt/rhcsa/workspaces/text2pdf20/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF
chown -R builder20:builder20 /opt/rhcsa/workspaces/text2pdf20
runuser -l builder20 -c 'podman rmi -f localhost/text2pdf20:latest >/dev/null 2>&1 || true'
