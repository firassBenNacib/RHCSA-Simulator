# Lab 23: Umask Defaults

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-23-umask-defaults` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | selinux-and-default-perms, users-sudo-ssh |

Configure a user specific umask so new files and directories get the required default permissions.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Create the user umask23 and set its password to redhat
**System:** clientvm

#### Command Flow
```bash
useradd -m umask23
passwd umask23
# enter: redhat
```

---

### Task 02 — Configure the umask for user umask23 so that new…
**System:** clientvm

#### Command Flow
```bash
vim /home/umask23/.bashrc
umask 027
chown umask23:umask23 /home/umask23/.bashrc
```

---

### Verification
```bash
id umask23
runuser -l umask23 -c 'rm -rf ~/umask23-check && mkdir ~/umask23-check && touch ~/umask23-check/file && mkdir ~/umask23-check/dir && stat -c %a ~/umask23-check/file ~/umask23-check/dir'
```
