#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

rhcsa_configure_password_recovery disable

if command -v atq >/dev/null 2>&1; then
  pending_jobs="$(atq | awk '{print $1}')"
  if [[ -n "${pending_jobs:-}" ]]; then
    atrm ${pending_jobs} >/dev/null 2>&1 || true
  fi
fi

systemctl disable --now atd >/dev/null 2>&1 || true
rm -f /root/automation-at.txt /root/service-audit.txt /var/log/service-audit.log /usr/local/bin/service-audit
crontab -r >/dev/null 2>&1 || true

mkdir -p /opt/rhcsa/workspaces/automation /opt/rhcsa/workspaces/automation-container/site-content
cat > /opt/rhcsa/workspaces/automation/services.lst <<'EOF'
sshd
firewalld
atd
imaginary-agent
EOF

cat > /opt/rhcsa/workspaces/automation-container/site-content/index.html <<'EOF'
Automation exam service page
EOF

cat > /opt/rhcsa/workspaces/automation-container/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF

rm -rf /home/admin/.config/systemd/user /home/admin/.config/containers/systemd
runuser -l admin -c 'podman rm -f briefing-web >/dev/null 2>&1 || true'
runuser -l admin -c 'podman rmi -f localhost/briefing-web:latest >/dev/null 2>&1 || true'
loginctl disable-linger admin >/dev/null 2>&1 || true

chown -R admin:admin /opt/rhcsa/workspaces/automation-container

rhcsa_configure_password_recovery enable
