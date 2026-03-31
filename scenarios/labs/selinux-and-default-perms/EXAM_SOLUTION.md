# SELinux And Default File Permissions - Exam Solution
Scenario ID: selinux-and-default-perms
Mode: Exam
Time limit: 60 minutes
Objectives: selinux-and-default-perms

Practice RHCSA v9 SELinux troubleshooting together with default permissions, SELinux port labels, and booleans.

## Task 01 - Default Umask (clientvm) - 15 pts
```bash
cat > /etc/profile.d/rhcsa-default-umask.sh <<'EOF'
umask 027
EOF
chmod 644 /etc/profile.d/rhcsa-default-umask.sh
```

## Task 02 - Apache Site On 8089 (clientvm) - 30 pts
```bash
sed -i 's/^Listen .*/Listen 8089/' /etc/httpd/conf/httpd.conf
sed -i 's#^DocumentRoot ".*"#DocumentRoot "/srv/rhcsa/selinux-site"#' /etc/httpd/conf/httpd.conf
cat > /etc/httpd/conf.d/rhcsa-selinux-site.conf <<'EOF'
<Directory "/srv/rhcsa/selinux-site">
    Require all granted
</Directory>
EOF
systemctl enable --now httpd
```

## Task 03 - Persistent SELinux Labels (clientvm) - 30 pts
```bash
semanage fcontext -a -t httpd_sys_content_t '/srv/rhcsa/selinux-site(/.*)?'
restorecon -Rv /srv/rhcsa/selinux-site
semanage port -a -t http_port_t -p tcp 8089
systemctl restart httpd
```

## Task 04 - Persistent SELinux Boolean (clientvm) - 25 pts
```bash
setsebool -P httpd_can_network_connect on
```
