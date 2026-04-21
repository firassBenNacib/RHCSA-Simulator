# Lab 32: SSH Key Authentication

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-32-ssh-key-auth` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | users-sudo-ssh |

Configure passwordless SSH login from client to server using a key pair.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create user relay32 on client and user vault32 on (client + server) - 10 pts

```bash
id relay32 >/dev/null 2>&1 || useradd -m relay32
passwd relay32
# enter: cinder9
# on server
id vault32 >/dev/null 2>&1 || useradd -m vault32
passwd vault32
# enter: cinder9
```

---

## Task 02 - Configure key-based SSH authentication so that user (client) - 10 pts

```bash
su - relay32
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
ssh-copy-id -o StrictHostKeyChecking=no vault32@server
```

---

## Task 03 - Do not disable PasswordAuthentication globally for (client) - 10 pts

```bash
su - relay32
ssh -o StrictHostKeyChecking=no vault32@server true
```
