# Lab 48: SSH Key Authentication And SCP

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-48-ssh-key-scp` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | users-sudo-ssh |

Configure key-based SSH access and securely copy a file to the second system.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Create user copy48 on both clientvm and servervm. Set…
**System:** clientvm

Create user copy48 on both clientvm and servervm. Set the password on both systems to redhat.

---

### Task 02 — generate an ED25519 SSH key pair with no passphrase
**System:** clientvm

As user copy48 on clientvm, generate an ED25519 SSH key pair with no passphrase.

---

### Task 03 — Configure passwordless SSH access for copy48 from…
**System:** clientvm

Configure passwordless SSH access for copy48 from clientvm to servervm using the public key.

---

### Task 04 — Using scp over SSH, copy /home/copy48/payload.txt…
**System:** servervm

Using scp over SSH, copy /home/copy48/payload.txt from clientvm to /home/copy48/inbox/ on servervm.

### Hints
- Use ssh-keygen, ssh-copy-id, and scp as the target user.

### Validation Commands
```bash
ssh -o BatchMode=yes -o StrictHostKeyChecking=no copy48@192.168.122.3 "test -f /home/copy48/inbox/payload.txt"
```
