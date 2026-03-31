# SELinux And Default File Permissions - Lab Solution
Scenario ID: selinux-and-default-perms
Mode: Lab
Time limit: 60 minutes
Objectives: selinux-and-default-perms

Practice RHCSA v9 SELinux troubleshooting together with default permissions, SELinux port labels, and booleans.

## Task 01 - Default Umask (clientvm) - 10 pts
```bash
cat > /etc/profile.d/rhcsa-default-umask.sh <<'EOF'
umask 027
EOF
chmod 644 /etc/profile.d/rhcsa-default-umask.sh
```

## Task 02 - Apache Site On 8089 (clientvm) - 15 pts
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

## Task 03 - Persistent SELinux Labels (clientvm) - 15 pts
```bash
semanage fcontext -a -t httpd_sys_content_t '/srv/rhcsa/selinux-site(/.*)?'
restorecon -Rv /srv/rhcsa/selinux-site
semanage port -a -t http_port_t -p tcp 8089
systemctl restart httpd
```

## Task 04 - Persistent SELinux Boolean (clientvm) - 10 pts
```bash
setsebool -P httpd_can_network_connect on
```

## Task 05 - Enforcing Mode (clientvm) - 5 pts
```bash
getenforce
curl http://localhost:8089/
```

Verification
```bash
grep -R '^umask 027' /etc/profile /etc/profile.d 2>/dev/null
getenforce
ls -Zd /srv/rhcsa/selinux-site /srv/rhcsa/selinux-site/index.html
semanage port -l | grep http_port_t | grep 8089
getsebool httpd_can_network_connect
curl http://localhost:8089/
```
