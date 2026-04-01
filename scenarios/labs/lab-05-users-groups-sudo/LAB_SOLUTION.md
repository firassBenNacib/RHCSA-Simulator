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

### Task 01 - Create the group opsrune and the users brenor,…
**System:** clientvm

#### Command Flow
```bash
groupadd opsrune
useradd -m brenor
useradd -m lyessa
useradd -m -s /sbin/nologin quillan
usermod -aG opsrune brenor
usermod -aG opsrune lyessa
```

---

### Task 02 - Set the password of all three users to cinder9
**System:** clientvm

#### Command Flow
```bash
passwd brenor
# enter: cinder9
passwd lyessa
# enter: cinder9
passwd quillan
# enter: cinder9
```

---

### Task 03 - Allow members of opsrune to run useradd through sudo,…
**System:** clientvm

#### Command Flow
```bash
visudo -f /etc/sudoers.d/opsrune
%opsrune ALL=(root) /usr/sbin/useradd
visudo -f /etc/sudoers.d/brenor-passwd
brenor ALL=(root) NOPASSWD: /usr/bin/passwd
```

---

### Verification
```bash
id brenor
id lyessa
getent passwd quillan
visudo -cf /etc/sudoers.d/opsrune
visudo -cf /etc/sudoers.d/brenor-passwd
```
