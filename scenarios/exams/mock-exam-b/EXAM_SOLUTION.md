# Mock Exam B: System Review And Hardening - Exam Solution
Scenario ID: mock-exam-b
Mode: Exam
Time limit: 120 minutes
Objectives: storage-lvm, processes-logs-tuning, selinux-and-default-perms, essential-tools

A redesigned RHCSA v9 mock exam focused on local storage, default permissions, SELinux labeling and port control, process tuning, logging, and file workflows.

## Task 01 - LVM Storage Layout (clientvm) - 20 pts
```bash
pvcreate /dev/sdb /dev/sdc
vgcreate opsdata_vg /dev/sdb /dev/sdc
lvcreate -L 700M -n records opsdata_vg
mkfs.xfs /dev/opsdata_vg/records
mkdir -p /srv/records
echo '/dev/opsdata_vg/records /srv/records xfs defaults 0 0' >> /etc/fstab
mount /srv/records
lvcreate -L 300M -n archive opsdata_vg
mkfs.ext4 /dev/opsdata_vg/archive
mkdir -p /mnt/archive
echo '/dev/opsdata_vg/archive /mnt/archive ext4 defaults 0 0' >> /etc/fstab
mount /mnt/archive
lvcreate -L 256M -n reviewswap opsdata_vg
mkswap /dev/opsdata_vg/reviewswap
echo '/dev/opsdata_vg/reviewswap none swap defaults 0 0' >> /etc/fstab
swapon -a
```

## Task 02 - Default Permissions (clientvm) - 20 pts
```bash
cat > /etc/profile.d/review-umask.sh <<'EOF'
umask 027
EOF
chmod 644 /etc/profile.d/review-umask.sh
chown root:reviewers /srv/reports
chmod 2770 /srv/reports
```

## Task 03 - Apache With SELinux (clientvm) - 20 pts
```bash
sed -i 's/^Listen .*/Listen 8089/' /etc/httpd/conf/httpd.conf
sed -i 's#^DocumentRoot ".*"#DocumentRoot "/srv/rhcsa/review-site"#' /etc/httpd/conf/httpd.conf
cat > /etc/httpd/conf.d/rhcsa-review.conf <<'EOF'
<Directory "/srv/rhcsa/review-site">
    Require all granted
</Directory>
EOF
semanage fcontext -a -t httpd_sys_content_t '/srv/rhcsa/review-site(/.*)?'
restorecon -Rv /srv/rhcsa/review-site
semanage port -a -t http_port_t -p tcp 8089
setsebool -P httpd_can_network_connect on
systemctl enable --now httpd
```

## Task 04 - Processes Logs And Tuning (clientvm) - 20 pts
```bash
PID=$(pgrep -n -f 'yes >/dev/null')
renice 10 -p "$PID"
mkdir -p /var/log/journal
sed -i '/^Storage=/d' /etc/systemd/journald.conf
echo 'Storage=persistent' >> /etc/systemd/journald.conf
systemctl restart systemd-journald
tuned-adm profile throughput-performance
systemctl enable --now review-stamp.service
```

## Task 05 - Archive And Log Filtering (clientvm) - 20 pts
```bash
tar -czf /root/reports-bundle.tar.gz -C /srv reports
grep 'ALERT' /opt/rhcsa/workspaces/review-material/alerts.log > /root/alerts-only.log
```
