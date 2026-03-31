#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null
id student22 >/dev/null 2>&1 || useradd -m student22
runuser -l student22 -c 'podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true'
mkdir -p /opt/file22 /opt/processed22 /tmp/lab22img/site-content
cat > /tmp/lab22img/site-content/index.html <<'EOF'
lab22 image
EOF
cat > /tmp/lab22img/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF
runuser -l student22 -c 'podman build -t localhost/text2pdf22:latest /tmp/lab22img >/dev/null'
runuser -l student22 -c 'podman rm -f mycontainer22 >/dev/null 2>&1 || true'
runuser -l student22 -c 'podman rmi -f localhost/text2pdf22:latest >/dev/null 2>&1 || true'
podman build -t localhost/text2pdf22:latest /tmp/lab22img >/dev/null
rm -rf /home/student22/.config/systemd/user
loginctl disable-linger student22 >/dev/null 2>&1 || true
chown -R student22:student22 /opt/file22 /opt/processed22
