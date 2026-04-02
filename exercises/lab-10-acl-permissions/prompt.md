# Lab 10: ACL And Permissions

Time: 25 minutes
Objectives: selinux-and-default-perms
Systems: clientvm

Apply fine grained access with POSIX ACLs.

## Tasks

## Task 01 - Copy /etc/fstab to /var/tmp/fstab-acl (clientvm) - 10 pts

Copy /etc/fstab to /var/tmp/fstab-acl.

## Task 02 - Set owner and group to root:root, remove all (clientvm) - 10 pts

- **Set owner and group to root:** root, remove all execute bits, give natacl read-write, deny haracl all access, and allow others read only.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
