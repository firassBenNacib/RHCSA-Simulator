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

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
useradd -m key39
passwd key39
# repeat on servervm
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
runuser -l key39 -c "ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519"
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
```bash
runuser -l key39 -c "ssh-copy-id -o StrictHostKeyChecking=no key39@192.168.122.3"
```

---

## Task 04 — Part 04
**System:** servervm

#### Commands
```bash
runuser -l key39 -c "rsync -av -e ssh /home/key39/client-data/ key39@192.168.122.3:/home/key39/server-data/"
```

---

### Verification
```bash
ssh -o BatchMode=yes -o StrictHostKeyChecking=no key39@192.168.122.3 "test -f /home/key39/server-data/file1.txt"
```
