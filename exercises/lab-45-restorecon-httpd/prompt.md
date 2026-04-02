# Lab 45: Restore Default SELinux Context

Time: 25 minutes
Objectives: selinux-and-default-perms
Systems: clientvm

Restore the default SELinux context on existing web content without disabling SELinux.

## Tasks

## Task 01 - the file /var/www/html/index45.html has the wrong (clientvm) - 10 pts

On clientvm, the file /var/www/html/index45.html has the wrong SELinux context. Restore the default context.

## Task 02 - Ensure the httpd service is enabled and running (clientvm) - 10 pts

Ensure the httpd service is enabled and running. SELinux must remain enforcing.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
