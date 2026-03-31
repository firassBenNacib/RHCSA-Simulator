#!/usr/bin/env bash
            set -euo pipefail
            mkdir -p /srv/lab28/site
            cat > /srv/lab28/site/index.html <<'EOF'
lab28 custom site
EOF
            rm -f /etc/httpd/conf.d/lab28.conf
            systemctl disable --now httpd >/dev/null 2>&1 || true
            firewall-cmd --permanent --remove-port=8088/tcp >/dev/null 2>&1 || true
            firewall-cmd --reload >/dev/null 2>&1 || true
            semanage port -d -t http_port_t -p tcp 8088 >/dev/null 2>&1 || true
            restorecon -Rv /srv/lab28 >/dev/null 2>&1 || true
