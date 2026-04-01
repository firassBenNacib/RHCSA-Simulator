# Lab 05: Users Groups And Sudo

## Lab Tasks
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

Create the group opsrune and the users brenor, lyessa, and quillan. Put brenor and lyessa in opsrune as a supplementary group. Sarahx must have /sbin/nologin and must not be in opsrune.

---

### Task 02 - Set the password of all three users to cinder9
**System:** clientvm

Set the password of all three users to cinder9.

---

### Task 03 - Allow members of opsrune to run useradd through sudo,…
**System:** clientvm

Allow members of opsrune to run useradd through sudo, and allow brenor to run passwd for other users without a sudo password prompt.

### Hints
- Use useradd and usermod only.
- Create sudo policy files under /etc/sudoers.d and validate them with visudo.

### Validation Commands
```bash
id brenor
id lyessa
getent passwd quillan
visudo -cf /etc/sudoers.d/opsrune
visudo -cf /etc/sudoers.d/brenor-passwd
```
