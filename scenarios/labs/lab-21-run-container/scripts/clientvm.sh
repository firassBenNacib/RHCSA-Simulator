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
id runner21 >/dev/null 2>&1 || useradd -m runner21
runner21_uid=$(id -u runner21)
runuser -l runner21 -c "export XDG_RUNTIME_DIR=/tmp/podman-run-$runner21_uid; install -d -m 700 \"\$XDG_RUNTIME_DIR\"; podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true"
mkdir -p /opt/file21 /opt/processed21 /tmp/lab21img/site-content
cat > /tmp/lab21img/site-content/index.html <<'EOF'
lab21 image
EOF
cat > /tmp/lab21img/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF
runuser -l runner21 -c "export XDG_RUNTIME_DIR=/tmp/podman-run-$runner21_uid; install -d -m 700 \"\$XDG_RUNTIME_DIR\"; podman build -t localhost/text2pdf21:latest /tmp/lab21img >/dev/null"
runuser -l runner21 -c "export XDG_RUNTIME_DIR=/tmp/podman-run-$runner21_uid; install -d -m 700 \"\$XDG_RUNTIME_DIR\"; podman rm -f mycontainer21 >/dev/null 2>&1 || true"
chown -R runner21:runner21 /opt/file21 /opt/processed21
