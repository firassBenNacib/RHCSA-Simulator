# Lab 05: Users Groups And Sudo

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-05-users-groups-sudo` |
| Mode | Lab |
| Time limit | 40 minutes |
| Objectives | users-sudo-ssh |

Create local users on servervm with minimal useradd usage and delegated sudo rules.

### Systems
- servervm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create opsrune and the required users (servervm) - 10 pts

```bash
groupadd opsrune
useradd -G opsrune brenor
useradd -G opsrune lyessa
useradd quillan
useradd -M -s /sbin/nologin sarahx
```

---

## Task 02 - Set the interactive user passwords to cinder9 (servervm) - 10 pts

```bash
passwd brenor
passwd lyessa
passwd quillan
```

---

## Task 03 - Create the required sudo rules (servervm) - 10 pts

```bash
visudo
%opsrune ALL=(ALL) /usr/sbin/useradd
brenor ALL=(ALL) NOPASSWD: /usr/bin/passwd
```
