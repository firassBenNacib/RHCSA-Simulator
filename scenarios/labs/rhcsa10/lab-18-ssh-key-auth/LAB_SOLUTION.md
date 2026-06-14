# RHCSA 10 Lab 18: SSH Key Authentication

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-18-ssh-key-auth` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh |

Configure key-based SSH authentication.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create user key10 and set password cinder9 (client) - 10 pts

```bash
useradd -m key10
echo 'key10:cinder9' | chpasswd
```

---

## Task 02 - Create user key10 and set password cinder9 (server) - 10 pts

```bash
# On server
useradd -m key10
echo 'key10:cinder9' | chpasswd
```

---

## Task 03 - Generate an ED25519 SSH key pair for key10 with no passphrase (client) - 10 pts

```bash
su - key10
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
```

---

## Task 04 - Configure key-based SSH authentication so key10 can log in to key10@serv (client + server) - 10 pts

```bash
su - key10
ssh-copy-id -i ~/.ssh/id_ed25519.pub key10@server
```
