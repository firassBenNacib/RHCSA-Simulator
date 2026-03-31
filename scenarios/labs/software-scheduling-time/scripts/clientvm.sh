#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

rm -f /root/at-job.txt /var/log/rhcsa-cron.log
crontab -r >/dev/null 2>&1 || true
atrm $(atq | awk '{print $1}') >/dev/null 2>&1 || true
mkdir -p /var/www/html/schedule
cat > /var/www/html/schedule/index.html <<'EOF'
RHCSA scheduling lab page
EOF

rm -f /etc/systemd/system/schedule-note.service /var/tmp/schedule-note.txt
cat > /etc/systemd/system/schedule-note.service <<'EOF'
[Unit]
Description=Write the RHCSA scheduling note

[Service]
Type=oneshot
ExecStart=/usr/bin/touch /var/tmp/schedule-note.txt

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl disable --now chronyd atd httpd schedule-note.service >/dev/null 2>&1 || true
sed -i '/^server /d;/^pool /d' /etc/chrony.conf
