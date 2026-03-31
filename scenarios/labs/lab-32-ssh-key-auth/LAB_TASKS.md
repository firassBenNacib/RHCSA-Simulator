# Lab 32: SSH Key Authentication

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-32-ssh-key-auth` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | users-sudo-ssh |

Configure passwordless SSH login from clientvm to servervm using a key pair.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm + servervm

Create user ops32 on clientvm and user backup32 on servervm. Set the password of both users to redhat.

---

## Task 02 — Part 02
**System:** clientvm

Configure key-based SSH authentication so that user ops32 on clientvm can log in to backup32@servervm without a password prompt.

---

## Task 03 — Part 03
**System:** clientvm

Do not disable PasswordAuthentication globally for this task.

### Hints
- Generate the key as the source user.
- Populate authorized_keys for the target user.

### Checks
```bash
runuser -l ops32 -c "ssh -o StrictHostKeyChecking=no -o BatchMode=yes backup32@servervm true"
```
