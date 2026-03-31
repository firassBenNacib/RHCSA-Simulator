# Lab 39: SSH Key Authentication and Rsync

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-39-ssh-key-rsync` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh, nfs-and-autofs |

Configure key-based SSH access and securely transfer files between systems.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

Create the user key39 on both clientvm and servervm. Set the password on both systems to redhat.

---

## Task 02 — Part 02
**System:** clientvm

As user key39 on clientvm, generate an ED25519 SSH key pair with no passphrase.

---

## Task 03 — Part 03
**System:** clientvm

Configure passwordless SSH access for key39 from clientvm to servervm using public key authentication.

---

## Task 04 — Part 04
**System:** servervm

Using rsync over SSH, copy the directory /home/key39/client-data/ from clientvm to /home/key39/server-data/ on servervm.

### Hints
- Use the key39 account for the SSH key work.
- Verify the transfer by checking the copied file on servervm through SSH.

### Checks
```bash
ssh -o BatchMode=yes -o StrictHostKeyChecking=no key39@192.168.122.3 "test -f /home/key39/server-data/file1.txt"
```
