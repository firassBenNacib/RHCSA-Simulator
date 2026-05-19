# RHCSA 10 Lab 15: Users Groups And Sudo

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-15-users-groups-sudo` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh |

Create local identities and delegate limited administrative access.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create local group ops10 (client) - 10 pts

```bash
getent group ops10 >/dev/null || groupadd ops10
getent group ops10
```

---

## Task 02 - Create user relay10, set the password to cinder9, and make ops10 the use (client) - 10 pts

```bash
id relay10 >/dev/null 2>&1 || useradd -G ops10 relay10
echo 'relay10:cinder9' | chpasswd
```

---

## Task 03 - Allow members of ops10 to run /usr/bin/systemctl with sudo without a pas (client) - 10 pts

```bash
echo '%ops10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/ops10
chmod 440 /etc/sudoers.d/ops10
```
