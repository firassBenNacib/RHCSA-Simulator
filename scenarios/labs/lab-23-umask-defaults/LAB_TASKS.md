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

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

Create the user umask23 and set its password to redhat.

---

## Task 02 — Part 02
**System:** clientvm

Configure the umask for user umask23 so that new regular files are created with mode 0640 and new directories are created with mode 0750 whenever the user logs in.

### Hints
- Use a user login startup file.
- Verify the resulting umask by creating a test file and a test directory as the target user.

### Checks
```bash
id umask23
runuser -l umask23 -c 'rm -rf ~/umask23-check && mkdir ~/umask23-check && touch ~/umask23-check/file && mkdir ~/umask23-check/dir && stat -c %a ~/umask23-check/file ~/umask23-check/dir'
```
