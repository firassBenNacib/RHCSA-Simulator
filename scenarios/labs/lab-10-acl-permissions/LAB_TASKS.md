# Lab 10: ACL And Permissions

## Lab Tasks
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

Copy /etc/fstab to /var/tmp/fstab-acl. Set the owner and group to root:root and remove all execute bits.

---

## Task 02 - Apply the ACL entries (clientvm) - 10 pts

Give natacl read-write access, deny haracl all access, and allow others read only.
