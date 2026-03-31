# Lab 10: ACL And Permissions - Lab Solution
Scenario ID: lab-10-acl-permissions
Mode: Lab
Time limit: 25 minutes
Objectives: selinux-and-default-perms

Apply fine grained access with POSIX ACLs.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
id natacl || useradd -m natacl
id haracl || useradd -m haracl
cp /etc/fstab /var/tmp/fstab-acl
chown root:root /var/tmp/fstab-acl
chmod 644 /var/tmp/fstab-acl
```

## Task 02 - Part 02 (clientvm)
```bash
setfacl -m u:natacl:rw- /var/tmp/fstab-acl
setfacl -m u:haracl:--- /var/tmp/fstab-acl
```

Verification
```bash
getfacl /var/tmp/fstab-acl
ls -l /var/tmp/fstab-acl
```
