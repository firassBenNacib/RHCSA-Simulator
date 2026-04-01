#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null
id merin22 >/dev/null 2>&1 || useradd -m merin22
runuser -l merin22 -c 'podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true'
mkdir -p /opt/inbox22 /opt/outbox22 /tmp/lab22img/site-content
cat > /tmp/lab22img/site-content/index.html <<'EOF'
lab22 image
EOF
cat > /tmp/lab22img/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF
runuser -l merin22 -c 'podman build -t localhost/fluxpdf22:latest /tmp/lab22img >/dev/null'
runuser -l merin22 -c 'podman rm -f render22 >/dev/null 2>&1 || true'
runuser -l merin22 -c 'podman rmi -f localhost/fluxpdf22:latest >/dev/null 2>&1 || true'
podman build -t localhost/fluxpdf22:latest /tmp/lab22img >/dev/null
rm -rf /home/merin22/.config/systemd/user
loginctl disable-linger merin22 >/dev/null 2>&1 || true
chown -R merin22:merin22 /opt/inbox22 /opt/outbox22
