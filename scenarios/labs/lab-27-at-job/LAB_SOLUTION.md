# Lab 27: At Job Scheduling

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-27-at-job` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time |

Schedule a one time task with at and verify that the at daemon is enabled.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the user queue27 and set its password to (clientvm) - 10 pts

```bash
useradd -m queue27
passwd queue27
# enter: cinder9
```

---

## Task 02 - Enable and start the atd service (clientvm) - 10 pts

```bash
systemctl enable --now atd
```

---

## Task 03 - schedule a one-time at job that appends the text (clientvm) - 10 pts

```bash
su - queue27
echo 'echo AT27 OK >> /home/queue27/at27.log' | at now + 2 minutes
atq
```
