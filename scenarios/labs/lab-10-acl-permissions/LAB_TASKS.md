# Lab 10: ACL And Permissions - Lab Tasks
Scenario ID: lab-10-acl-permissions
Mode: Lab
Time limit: 25 minutes
Objectives: selinux-and-default-perms

Apply fine grained access with POSIX ACLs.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Copy /etc/fstab to /var/tmp/fstab-acl.

## Task 02 - Part 02 (clientvm)
Set owner and group to root:root, remove all execute bits, give natacl read-write, deny haracl all access, and allow others read only.

Hints
1. Create the users natacl and haracl if they are missing.
2. Use setfacl for the named user entries.

Checks
```bash
getfacl /var/tmp/fstab-acl
ls -l /var/tmp/fstab-acl
```
