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

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Create the group sysadmx and the users harryx,…
**System:** clientvm

#### Command Flow
```bash
groupadd sysadmx
useradd -m harryx
useradd -m natashax
useradd -m -s /sbin/nologin sarahx
usermod -aG sysadmx harryx
usermod -aG sysadmx natashax
```

---

### Task 02 — Set the password of all three users to redhat
**System:** clientvm

#### Command Flow
```bash
passwd harryx
# enter: redhat
passwd natashax
# enter: redhat
passwd sarahx
# enter: redhat
```

---

### Task 03 — Allow members of sysadmx to run useradd through sudo,…
**System:** clientvm

#### Command Flow
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
