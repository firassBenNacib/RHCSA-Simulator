# Lab 28: SELinux Custom Document Root - Lab Tasks
Scenario ID: lab-28-selinux-custom-docroot
Mode: Lab
Time limit: 35 minutes
Objectives: selinux-and-default-perms, networking-and-firewall

Serve a custom document root on a nonstandard HTTP port while keeping SELinux enforcing.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Configure Apache to serve content from /srv/lab28/site on TCP port 8088.

## Task 02 - Part 02 (clientvm)
Keep SELinux enforcing, configure the correct file context and port label, open the firewall permanently, and enable the service at boot.

## Task 03 - Part 03 (clientvm)
Do not edit or remove /srv/lab28/site/index.html.

Hints
1. Create a dedicated configuration file in /etc/httpd/conf.d.
2. Use semanage fcontext and semanage port.

Checks
```bash
curl -s http://localhost:8088
semanage port -l | grep 8088
ls -Zd /srv/lab28/site
```
