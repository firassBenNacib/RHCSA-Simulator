# Lab 38: SELinux Boolean

Time: 15 minutes
Objectives: selinux-and-default-perms
Systems: clientvm

Modify a SELinux boolean persistently without changing enforcing mode.

## Tasks

## Task 01 - configure the SELinux boolean (clientvm) - 10 pts

On clientvm, configure the SELinux boolean httpd_can_network_connect so it is enabled persistently.

## Task 02 - SELinux must remain in enforcing mode (clientvm) - 10 pts

SELinux must remain in enforcing mode.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
