# Lab 04: SELinux Custom HTTP Port

Time: 35 minutes
Objectives: selinux-and-default-perms
Systems: clientvm

Fix Apache so it listens on a nonstandard port without disabling SELinux.

## Tasks

## Task 01 - Configure Apache on clientvm so it listens on TCP (clientvm) - 10 pts

Configure Apache on clientvm so it listens on TCP port 9082 and starts automatically at boot.

## Task 02 - Allow TCP port 9082 through the firewall permanently (clientvm) - 10 pts

Allow TCP port 9082 through the firewall permanently.

## Task 03 - Make the SELinux changes needed so Apache serves (clientvm) - 10 pts

Make the SELinux changes needed so Apache serves the existing /var/www/html content on that port.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
