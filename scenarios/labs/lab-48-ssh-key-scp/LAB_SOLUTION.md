# Lab 48: SSH Key Authentication And SCP

## Lab Solution
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

#### Command Flow
```bash
# On both systems
useradd -m copy48
passwd copy48
# enter: redhat
```

---

### Task 02 — generate an ED25519 SSH key pair with no passphrase
**System:** clientvm

#### Command Flow
```bash
runuser -l copy48 -c "ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519"
```

---

### Task 03 — Configure passwordless SSH access for copy48 from…
**System:** clientvm

#### Command Flow
```bash
runuser -l copy48 -c "ssh-copy-id -o StrictHostKeyChecking=no copy48@192.168.122.3"
```

---

### Task 04 — Using scp over SSH, copy /home/copy48/payload.txt…
**System:** servervm

#### Command Flow
```bash
runuser -l copy48 -c "scp -o StrictHostKeyChecking=no /home/copy48/payload.txt copy48@192.168.122.3:/home/copy48/inbox/"
```

---

### Verification
```bash
ssh -o BatchMode=yes -o StrictHostKeyChecking=no copy48@192.168.122.3 "test -f /home/copy48/inbox/payload.txt"
```
