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

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Create the group collab26 and the user qa26. Set the…
**System:** clientvm

#### Command Flow
```bash
groupadd collab26
useradd -m qa26
passwd qa26
# enter: redhat
```

---

### Task 02 — Create the directory /shared/collab26 with owner…
**System:** clientvm

#### Command Flow
```bash
mkdir -p /shared/collab26
chown root:collab26 /shared/collab26
chmod 2770 /shared/collab26
```

---

### Task 03 — Configure a default ACL so that user qa26 receives…
**System:** clientvm

#### Command Flow
```bash
setfacl -m d:u:qa26:rwx /shared/collab26
getfacl /shared/collab26
```

---

### Verification
```bash
getfacl /shared/collab26
```
