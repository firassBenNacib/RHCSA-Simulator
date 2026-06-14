# RHCSA 10 Lab 33: At Job

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-33-at-job` |
| Mode | Lab |
| Scope | server |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time |

Schedule one-time tasks with at.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create user at10 and set password cinder9 (server) - 10 pts

```bash
useradd at10
passwd at10
# enter: cinder9
```

---

## Task 02 - Enable and start atd (server) - 10 pts

```bash
systemctl enable --now atd
```

---

## Task 03 - As at10, schedule a job that appends AT10 to /home/at10/at10.log two (server) - 10 pts

```bash
su - at10
echo 'echo AT10 >> /home/at10/at10.log' | at now + 2 minutes
atq
```
