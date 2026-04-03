# Lab 26: Default ACL Shared Directory

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-26-default-acl-shared-dir` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | filesystems-and-autofs, selinux-and-default-perms |

Use a default ACL for a named user without creating an unnecessary home directory.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the collab26 group and probe26 user (clientvm) - 10 pts

```bash
groupadd collab26
useradd -M probe26
printf 'probe26:cinder9
' | chpasswd
```

---

## Task 02 - Create the shared directory with setgid semantics (clientvm) - 10 pts

```bash
install -d -o root -g collab26 -m 2770 /shared/collab26
```

---

## Task 03 - Create the default ACL for probe26 (clientvm) - 10 pts

```bash
setfacl -m d:u:probe26:rwx /shared/collab26
```

---

## Verification
```bash
getent group collab26 >/dev/null && getent passwd probe26 >/dev/null && ! test -d /home/probe26
stat -c '%U:%G %a' /shared/collab26 | grep -qx 'root:collab26 2770'
getfacl -cp /shared/collab26 | grep -Eq '^default:user:probe26:rwx$'
```
