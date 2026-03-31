# Lab 05: Users Groups And Sudo

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-05-users-groups-sudo` |
| Mode | Lab |
| Time limit | 40 minutes |
| Objectives | users-sudo-ssh |

Create local users, a delegated admin group, and passwordless privileged access.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
groupadd sysadmx
useradd -m harryx
useradd -m natashax
useradd -m -s /sbin/nologin sarahx
usermod -aG sysadmx harryx
usermod -aG sysadmx natashax
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
passwd harryx
# enter: redhat
passwd natashax
# enter: redhat
passwd sarahx
# enter: redhat
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
```bash
visudo -f /etc/sudoers.d/sysadmx
%sysadmx ALL=(root) /usr/sbin/useradd
visudo -f /etc/sudoers.d/harryx-passwd
harryx ALL=(root) NOPASSWD: /usr/bin/passwd
```

---

### Verification
```bash
id harryx
id natashax
getent passwd sarahx
visudo -cf /etc/sudoers.d/sysadmx
visudo -cf /etc/sudoers.d/harryx-passwd
```
