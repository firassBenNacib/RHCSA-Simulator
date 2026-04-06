# Lab 06: Shared Setgid Directory

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-06-shared-setgid-directory` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | filesystems-and-autofs, selinux-and-default-perms |

Build a collaborative directory that uses both setgid and sticky semantics.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the shared analysts directory (clientvm) - 10 pts

```bash
groupadd -f analystsx
mkdir -p /shared/analysts
chown root:analystsx /shared/analysts
```

---

## Task 02 - Enable setgid and sticky behavior on the directory (clientvm) - 10 pts

```bash
chmod 770 /shared/analysts
chmod g+s /shared/analysts
chmod +t /shared/analysts
```

---

## Task 03 - Verify the final permission string (clientvm) - 10 pts

```bash
stat -c %A /shared/analysts
```
