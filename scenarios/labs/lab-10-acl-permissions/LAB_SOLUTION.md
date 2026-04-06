# Lab 10: ACL And Permissions

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-10-acl-permissions` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | selinux-and-default-perms |

Apply fine grained access with POSIX ACLs.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Copy /etc/fstab and set the base ownership and mode (clientvm) - 10 pts

```bash
cp /etc/fstab /var/tmp/fstab-acl
chown root:root /var/tmp/fstab-acl
chmod 644 /var/tmp/fstab-acl
```

---

## Task 02 - Apply the ACL entries (clientvm) - 10 pts

```bash
setfacl -m u:natacl:rw- /var/tmp/fstab-acl
setfacl -m u:haracl:--- /var/tmp/fstab-acl
getfacl /var/tmp/fstab-acl
```
