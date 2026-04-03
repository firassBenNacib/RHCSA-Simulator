# Lab 39: SSH Key Authentication and Rsync

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-39-ssh-key-rsync` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh, essential-tools |

Configure key-based SSH access and securely transfer files between systems.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the user mesh39 on both clientvm and (clientvm) - 10 pts

```bash
useradd -m mesh39
passwd mesh39
# repeat on servervm
```

---

## Task 02 - generate an ED25519 SSH key pair with no passphrase (clientvm) - 10 pts

```bash
runuser -l mesh39 -c "ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519"
```

---

## Task 03 - Configure passwordless SSH access for mesh39 from (clientvm) - 10 pts

```bash
runuser -l mesh39 -c "ssh-copy-id -o StrictHostKeyChecking=no mesh39@192.168.122.3"
```

---

## Task 04 - Using rsync over SSH, copy the directory (servervm) - 10 pts

```bash
runuser -l mesh39 -c "rsync -av -e ssh /home/mesh39/client-data/ mesh39@192.168.122.3:/home/mesh39/server-data/"
```
