# Lab 04: SELinux Custom HTTP Port - Lab Solution
Scenario ID: lab-04-selinux-http-port
Mode: Lab
Time limit: 35 minutes
Objectives: selinux-and-default-perms

Fix Apache so it listens on a nonstandard port without disabling SELinux.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
vim /etc/httpd/conf/httpd.conf
Listen 9082
systemctl enable --now httpd
```

## Task 02 - Part 02 (clientvm)
```bash
firewall-cmd --permanent --add-port=9082/tcp
firewall-cmd --reload
```

## Task 03 - Part 03 (clientvm)
```bash
semanage port -a -t http_port_t -p tcp 9082
systemctl restart httpd
```

Verification
```bash
ss -ltnp | grep 9082
semanage port -l | grep http_port_t | grep 9082
curl -s http://localhost:9082
```
