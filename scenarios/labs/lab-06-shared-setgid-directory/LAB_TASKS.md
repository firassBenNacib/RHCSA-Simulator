# Lab 06: Shared Setgid Directory

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-06-shared-setgid-directory` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | filesystems-and-autofs, selinux-and-default-perms |

Build a collaborative directory that uses both setgid and sticky semantics.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the shared analysts directory (clientvm) - 10 pts

Create the group analystsx and the directory /shared/analysts with owner root, group analystsx, and access limited to root and members of analystsx.

---

## Task 02 - Enable setgid and sticky behavior on the directory (clientvm) - 10 pts

Configure /shared/analysts so new files inherit the analystsx group and only the file owner, the directory owner, or root can remove entries from it.

---

## Task 03 - Verify the final permission string (clientvm) - 10 pts

Verify the final directory permissions.

## Hints
- A collaborative drop directory often needs both setgid and sticky semantics.
- Use a single chmod invocation to express the final mode cleanly.

## Validation Commands
```bash
getent group analystsx >/dev/null && stat -c '%U:%G %a' /shared/analysts | grep -qx 'root:analystsx 3770'
findmnt -n /shared >/dev/null 2>&1 || test -d /shared
stat -c %A /shared/analysts | grep -qx 'drwxrws--T'
```
