#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null
id runner21 >/dev/null 2>&1 || useradd -m runner21
runuser -l runner21 -c 'podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true'
mkdir -p /opt/file21 /opt/processed21 /tmp/lab21img/site-content
cat > /tmp/lab21img/site-content/index.html <<'EOF'
lab21 image
EOF
cat > /tmp/lab21img/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF
runuser -l runner21 -c 'podman build -t localhost/text2pdf21:latest /tmp/lab21img >/dev/null'
runuser -l runner21 -c 'podman rm -f mycontainer21 >/dev/null 2>&1 || true'
runuser -l runner21 -c 'podman rmi -f localhost/text2pdf21:latest >/dev/null 2>&1 || true'
podman build -t localhost/text2pdf21:latest /tmp/lab21img >/dev/null
chown -R runner21:runner21 /opt/file21 /opt/processed21
