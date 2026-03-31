# Lab 23: Umask Defaults

## Lab Tasks
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

Create the user umask23 and set its password to redhat.

---

### Task 02 — Configure the umask for user umask23 so that new…
**System:** clientvm

Configure the umask for user umask23 so that new regular files are created with mode 0640 and new directories are created with mode 0750 whenever the user logs in.

### Hints
- Use a user login startup file.
- Verify the resulting umask by creating a test file and a test directory as the target user.

### Validation Commands
```bash
id umask23
runuser -l umask23 -c 'rm -rf ~/umask23-check && mkdir ~/umask23-check && touch ~/umask23-check/file && mkdir ~/umask23-check/dir && stat -c %a ~/umask23-check/file ~/umask23-check/dir'
```
