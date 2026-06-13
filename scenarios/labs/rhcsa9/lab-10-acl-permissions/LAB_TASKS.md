# Lab 10: ACL and Permissions

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-10-acl-permissions` |
| Mode | Lab |
| Scope | client |
| Time limit | 25 minutes |
| Objectives | selinux-and-default-perms |

Apply fine grained access with POSIX ACLs.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Copy /etc/fstab and set the base ownership and mode (client) - 10 pts

On client, copy /etc/fstab to /var/tmp/fstab-acl. Set the owner and group to root:root and remove all execute bits.

---

## Task 02 - Apply the ACL entries (client) - 10 pts

On client, give natacl read-write access, deny haracl all access, and allow others read only.
