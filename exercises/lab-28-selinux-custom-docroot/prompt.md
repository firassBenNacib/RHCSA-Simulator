# Lab 28: SELinux Custom Document Root

Time: 35 minutes
Objectives: selinux-and-default-perms, networking-and-firewall
Systems: clientvm

Serve a custom document root on a nonstandard HTTP port while keeping SELinux enforcing.

## Tasks

## Task 01 - Configure Apache to serve content from (clientvm) - 10 pts

Configure Apache to serve content from /srv/lab28/site on TCP port 8088.

## Task 02 - Keep SELinux enforcing, configure the correct file (clientvm) - 10 pts

Keep SELinux enforcing, configure the correct file context and port label, open the firewall permanently, and enable the service at boot.

## Task 03 - Do not edit or remove /srv/lab28/site/index.html (clientvm) - 10 pts

Do not edit or remove /srv/lab28/site/index.html.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
