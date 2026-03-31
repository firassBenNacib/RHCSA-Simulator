#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

umount /srv/records >/dev/null 2>&1 || true
umount /mnt/archive >/dev/null 2>&1 || true
swapoff /dev/mapper/opsdata_vg-reviewswap >/dev/null 2>&1 || true

sed -i '\#/srv/records#d' /etc/fstab
sed -i '\#/mnt/archive#d' /etc/fstab
sed -i '\#reviewswap#d' /etc/fstab

lvremove -fy /dev/opsdata_vg/records >/dev/null 2>&1 || true
lvremove -fy /dev/opsdata_vg/archive >/dev/null 2>&1 || true
lvremove -fy /dev/opsdata_vg/reviewswap >/dev/null 2>&1 || true
vgremove -fy opsdata_vg >/dev/null 2>&1 || true
pvremove -ffy /dev/sdb /dev/sdc >/dev/null 2>&1 || true

mkdir -p /srv/records /mnt/archive

groupadd -f reviewers
rm -f /root/reports-bundle.tar.gz /root/alerts-only.log
rm -f /etc/profile.d/rhcsa-default-umask.sh /etc/profile.d/review-umask.sh

mkdir -p /srv/reports /srv/rhcsa/review-site /opt/rhcsa/workspaces/review-material
cat > /srv/reports/shift-summary.txt <<'EOF'
Night review summary
EOF
cat > /srv/reports/system-notes.conf <<'EOF'
mode=review
EOF
cat > /srv/rhcsa/review-site/index.html <<'EOF'
Operations review landing page
EOF
cat > /opt/rhcsa/workspaces/review-material/alerts.log <<'EOF'
INFO baseline collected
ALERT storage threshold warning
INFO review package staged
ALERT journal verification pending
EOF

chown root:root /srv/reports
chmod 0755 /srv/reports

chcon -R -t user_home_t /srv/rhcsa/review-site >/dev/null 2>&1 || true
semanage port -d -t http_port_t -p tcp 8089 >/dev/null 2>&1 || true
setsebool -P httpd_can_network_connect off >/dev/null 2>&1 || true
sed -i 's/^Listen .*/Listen 80/' /etc/httpd/conf/httpd.conf
sed -i 's#^DocumentRoot ".*"#DocumentRoot "/var/www/html"#' /etc/httpd/conf/httpd.conf
cat > /etc/httpd/conf.d/rhcsa-review.conf <<'EOF'
<Directory "/var/www/html">
    Require all granted
</Directory>
EOF
systemctl disable --now httpd >/dev/null 2>&1 || true

rm -f /etc/systemd/system/review-stamp.service
cat > /etc/systemd/system/review-stamp.service <<'EOF'
[Unit]
Description=Write the review readiness stamp

[Service]
Type=oneshot
ExecStart=/usr/bin/touch /var/tmp/review-ready.stamp

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl disable --now review-stamp.service >/dev/null 2>&1 || true
rm -f /var/tmp/review-ready.stamp

pkill -f 'yes >/dev/null' >/dev/null 2>&1 || true
nohup bash -c 'yes >/dev/null' >/opt/rhcsa/workspaces/review-material/busy.log 2>&1 &

rm -rf /var/log/journal
sed -i '/^Storage=/d' /etc/systemd/journald.conf
tuned-adm profile balanced >/dev/null 2>&1 || true
