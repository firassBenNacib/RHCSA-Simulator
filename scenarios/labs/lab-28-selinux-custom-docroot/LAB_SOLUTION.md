# Lab 28: SELinux Custom Document Root - Lab Solution
Scenario ID: lab-28-selinux-custom-docroot
Mode: Lab
Time limit: 35 minutes
Objectives: selinux-and-default-perms, networking-and-firewall

Serve a custom document root on a nonstandard HTTP port while keeping SELinux enforcing.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
vim /etc/httpd/conf.d/lab28.conf
<VirtualHost *:8088>
    DocumentRoot /srv/lab28/site
    <Directory /srv/lab28/site>
        Require all granted
    </Directory>
</VirtualHost>
```

## Task 02 - Part 02 (clientvm)
```bash
semanage fcontext -a -t httpd_sys_content_t "/srv/lab28/site(/.*)?"
restorecon -Rv /srv/lab28/site
semanage port -a -t http_port_t -p tcp 8088
firewall-cmd --permanent --add-port=8088/tcp
firewall-cmd --reload
systemctl enable --now httpd
```

## Task 03 - Part 03 (clientvm)
```bash
curl -s http://localhost:8088
```

Verification
```bash
curl -s http://localhost:8088
semanage port -l | grep 8088
ls -Zd /srv/lab28/site
```
