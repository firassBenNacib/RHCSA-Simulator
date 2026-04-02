# Lab 26: Default ACL Shared Directory

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-26-default-acl-shared-dir` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | filesystems-and-autofs, selinux-and-default-perms |

Create a collaborative directory that combines setgid permissions with a default ACL.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the group collab26 and the user probe26. Set (clientvm) - 10 pts

Create the group collab26 and the user probe26. Set the password of probe26 to cinder9.

---

## Task 02 - Create the directory /shared/collab26 with owner (clientvm) - 10 pts

Create the directory /shared/collab26 with owner root, group collab26, and permissions 2770.

---

## Task 03 - Configure a default ACL so that user probe26 (clientvm) - 10 pts

Configure a default ACL so that user probe26 receives rwx permissions on new files and directories created under /shared/collab26.

## Hints
- Use getfacl to confirm the effective and default entries.

## Validation Commands
```bash
stat -c '%U:%G %a' /shared/collab26 | grep -qx 'root:collab26 2770' && getfacl -cp /shared/collab26 | grep -qx 'default:user:probe26:rwx'
```
