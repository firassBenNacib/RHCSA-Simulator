# Lab 39: SSH Key Authentication and Rsync

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-39-ssh-key-rsync` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh, essential-tools |

Configure key-based SSH access and securely transfer files between systems.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Ensure mesh39 exists on both systems (client + server) - 10 pts

```bash
id mesh39 >/dev/null 2>&1 || useradd -m mesh39
echo 'mesh39:cinder9' | chpasswd
# Run on server
id mesh39 >/dev/null 2>&1 || useradd -m mesh39
echo 'mesh39:cinder9' | chpasswd
```

---

## Task 02 - Generate an ED25519 SSH key pair with no passphrase (client) - 10 pts

```bash
su - mesh39
mkdir -p /home/mesh39/.ssh
chmod 700 /home/mesh39/.ssh
rm -f /home/mesh39/.ssh/id_ed25519 /home/mesh39/.ssh/id_ed25519.pub
ssh-keygen -q -t ed25519 -N "" -f /home/mesh39/.ssh/id_ed25519
chmod 600 /home/mesh39/.ssh/id_ed25519
chmod 644 /home/mesh39/.ssh/id_ed25519.pub
test -f /home/mesh39/.ssh/id_ed25519 && test -f /home/mesh39/.ssh/id_ed25519.pub
exit
```

---

## Task 03 - Configure passwordless SSH access for mesh39 from (client + server) - 10 pts

```bash
su - mesh39
ssh-copy-id -o StrictHostKeyChecking=no mesh39@192.168.122.3
```

---

## Task 04 - Using rsync over SSH, copy the directory (client + server) - 10 pts

```bash
# On client
su - mesh39
rsync -av -e ssh /home/mesh39/client-data/ mesh39@192.168.122.3:/home/mesh39/server-data/
```
