# RHCSA 10 Lab 18: SSH Key Authentication

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-18-ssh-key-auth` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh |

Configure key-based SSH authentication.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create user key10 and set password cinder9 (client) - 10 pts

```bash
useradd -m key10
passwd key10
# enter: cinder9
```

---

## Task 02 - Create /home/key10/.ssh/authorized_keys with the provided public key tex (client) - 10 pts

```bash
install -d -m 700 -o key10 -g key10 /home/key10/.ssh
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIRhcsa10keydemo rhcsa10' > /home/key10/.ssh/authorized_keys
```

---

## Task 03 - Set secure ownership and permissions on the SSH directory and authorized (client) - 10 pts

```bash
chown key10:key10 /home/key10/.ssh/authorized_keys
chmod 600 /home/key10/.ssh/authorized_keys
restorecon -RF /home/key10/.ssh
```
