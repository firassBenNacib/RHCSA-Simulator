# Lab 39: SSH Key Authentication and Rsync

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-39-ssh-key-rsync` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh, nfs-and-autofs |

Configure key-based SSH access and securely transfer files between systems.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Create the user key39 on both clientvm and servervm.…
**System:** clientvm

#### Command Flow
```bash
useradd -m key39
passwd key39
# repeat on servervm
```

---

### Task 02 — generate an ED25519 SSH key pair with no passphrase
**System:** clientvm

#### Command Flow
```bash
runuser -l key39 -c "ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519"
```

---

### Task 03 — Configure passwordless SSH access for key39 from…
**System:** clientvm

#### Command Flow
```bash
runuser -l key39 -c "ssh-copy-id -o StrictHostKeyChecking=no key39@192.168.122.3"
```

---

### Task 04 — Using rsync over SSH, copy the directory…
**System:** servervm

#### Command Flow
```bash
runuser -l key39 -c "rsync -av -e ssh /home/key39/client-data/ key39@192.168.122.3:/home/key39/server-data/"
```

---

### Verification
```bash
ssh -o BatchMode=yes -o StrictHostKeyChecking=no key39@192.168.122.3 "test -f /home/key39/server-data/file1.txt"
```
