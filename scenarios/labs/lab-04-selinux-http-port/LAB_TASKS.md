# Lab 04: SELinux Custom HTTP Port - Lab Tasks
Scenario ID: lab-04-selinux-http-port
Mode: Lab
Time limit: 35 minutes
Objectives: selinux-and-default-perms

Fix Apache so it listens on a nonstandard port without disabling SELinux.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Configure Apache on clientvm so it listens on TCP port 9082 and starts automatically at boot.

## Task 02 - Part 02 (clientvm)
Allow TCP port 9082 through the firewall permanently.

## Task 03 - Part 03 (clientvm)
Make the SELinux changes needed so Apache serves the existing /var/www/html content on that port.

Hints
1. Do not disable SELinux.
2. Do not move the existing document root.

Checks
```bash
ss -ltnp | grep 9082
semanage port -l | grep http_port_t | grep 9082
curl -s http://localhost:9082
```
