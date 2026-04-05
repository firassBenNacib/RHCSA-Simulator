#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


mkdir -p /var/www/html
echo 'SELinux port lab' > /var/www/html/index.html
if [[ -f /etc/httpd/conf/httpd.conf ]]; then
  python - <<'EOF'
from pathlib import Path
p = Path('/etc/httpd/conf/httpd.conf')
text = p.read_text()
text = text.replace('Listen 9082', 'Listen 80')
text = text.replace('Listen 8282', 'Listen 80')
p.write_text(text)
EOF
fi
semanage port -d -t http_port_t -p tcp 9082 >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-port=9082/tcp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
systemctl disable --now httpd >/dev/null 2>&1 || true
