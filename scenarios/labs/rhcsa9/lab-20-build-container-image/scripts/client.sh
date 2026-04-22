#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh
if command -v rhcsa_ensure_httpd_base_archive >/dev/null 2>&1; then
  rhcsa_ensure_httpd_base_archive
else
  archive="/opt/rhcsa/container-assets/rhcsa-httpd-base.tar"
  if ! tar -tf "$archive" 2>/dev/null | grep -Eq '^(manifest.json|index.json)$'; then
    podman image exists localhost/rhcsa-httpd-base:latest >/dev/null 2>&1 || \
      podman import --change 'CMD ["/usr/sbin/httpd","-DFOREGROUND"]' --change 'EXPOSE 80' --change 'STOPSIGNAL SIGWINCH' "$archive" localhost/rhcsa-httpd-base:latest >/dev/null 2>&1
    skopeo copy --insecure-policy containers-storage:localhost/rhcsa-httpd-base:latest docker-archive:"$archive":localhost/rhcsa-httpd-base:latest >/dev/null 2>&1
  fi
fi


podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null
id builder20 >/dev/null 2>&1 || useradd -m builder20
builder20_uid="$(id -u builder20)"
runuser -l builder20 -c "export XDG_RUNTIME_DIR=/tmp/podman-run-$builder20_uid; install -d -m 700 \"\$XDG_RUNTIME_DIR\"; podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true"
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
