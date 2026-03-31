#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

mkdir -p /srv/rhcsa/selinux-site
cat > /srv/rhcsa/selinux-site/index.html <<'EOF'
RHCSA SELinux lab page
EOF

rm -f /etc/profile.d/rhcsa-default-umask.sh
chcon -R -t user_home_t /srv/rhcsa/selinux-site >/dev/null 2>&1 || true
semanage port -d -t http_port_t -p tcp 8089 >/dev/null 2>&1 || true
setsebool -P httpd_can_network_connect off >/dev/null 2>&1 || true
sed -i 's/^Listen .*/Listen 80/' /etc/httpd/conf/httpd.conf
sed -i 's#^DocumentRoot \".*\"#DocumentRoot \"/var/www/html\"#' /etc/httpd/conf/httpd.conf
cat > /etc/httpd/conf.d/rhcsa-default.conf <<'EOF'
<Directory "/var/www/html">
    Require all granted
</Directory>
EOF
systemctl disable --now httpd >/dev/null 2>&1 || true
