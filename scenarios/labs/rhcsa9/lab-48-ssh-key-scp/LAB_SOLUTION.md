# Lab 48: SSH Key Authentication and SCP

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-48-ssh-key-scp` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 25 minutes |
| Objectives | users-sudo-ssh |

Use a key pair and scp between the two lab hosts.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Ensure bridge48 exists on both systems (client + server) - 10 pts

```bash
# On client
id bridge48 >/dev/null 2>&1 || useradd -m bridge48
echo 'bridge48:cinder9' | chpasswd
# On server
id bridge48 >/dev/null 2>&1 || useradd -m bridge48
echo 'bridge48:cinder9' | chpasswd
```

---

## Task 02 - Generate the ED25519 key pair (client) - 10 pts

```bash
su - bridge48
mkdir -p /home/bridge48/.ssh
chmod 700 /home/bridge48/.ssh
rm -f /home/bridge48/.ssh/id_ed25519 /home/bridge48/.ssh/id_ed25519.pub
ssh-keygen -q -t ed25519 -N "" -f /home/bridge48/.ssh/id_ed25519
chmod 600 /home/bridge48/.ssh/id_ed25519
chmod 644 /home/bridge48/.ssh/id_ed25519.pub
test -f /home/bridge48/.ssh/id_ed25519 && test -f /home/bridge48/.ssh/id_ed25519.pub
exit
```

---

## Task 03 - Enable passwordless SSH from client to server (client + server) - 10 pts

```bash
su - bridge48
ssh-copy-id -i ~/.ssh/id_ed25519.pub bridge48@server
```

---

## Task 04 - Copy the payload with SCP (client + server) - 10 pts

```bash
# On client
su - bridge48
scp /home/bridge48/payload.txt bridge48@server:/home/bridge48/inbox/
```
