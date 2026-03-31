# Lab 26: Default ACL Shared Directory

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-26-default-acl-shared-dir` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | filesystems-and-autofs, selinux-and-default-perms |

Create a collaborative directory that combines setgid permissions with a default ACL.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
groupadd collab26
useradd -m qa26
passwd qa26
# enter: redhat
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
mkdir -p /shared/collab26
chown root:collab26 /shared/collab26
chmod 2770 /shared/collab26
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
```bash
setfacl -m d:u:qa26:rwx /shared/collab26
getfacl /shared/collab26
```

---

### Verification
```bash
getfacl /shared/collab26
```
