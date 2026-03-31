#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

rm -f /etc/systemd/system/rhcsa-note.service
cat > /etc/systemd/system/rhcsa-note.service <<'EOF'
[Unit]
Description=RHCSA note writer

[Service]
Type=oneshot
ExecStart=/usr/bin/touch /var/tmp/rhcsa-note.stamp

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl disable --now rhcsa-note.service >/dev/null 2>&1 || true
rm -f /var/tmp/rhcsa-note.stamp

mkdir -p /opt/rhcsa/workspaces/processes
pkill -f 'yes >/dev/null' >/dev/null 2>&1 || true
nohup bash -c 'yes >/dev/null' >/opt/rhcsa/workspaces/processes/busy.log 2>&1 &

mkdir -p /var/log/journal
sed -i '/^Storage=/d' /etc/systemd/journald.conf
tuned-adm profile balanced >/dev/null 2>&1 || true
systemctl set-default graphical.target >/dev/null 2>&1 || true
