# RHCSA 10 Lab 32: Cron Job

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-32-cron` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time |

Schedule recurring tasks with cron.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create user cron10 and set password cinder9 (client) - 10 pts

```bash
useradd cron10
passwd cron10
# enter: cinder9
```

---

## Task 02 - Configure a cron job for cron10 that writes CRON10 to /home/cron10/cron1 (client) - 10 pts

```bash
echo '*/5 * * * * echo CRON10 >> /home/cron10/cron10.log' | crontab -u cron10 -
```

---

## Task 03 - Ensure crond is enabled and running (client) - 10 pts

```bash
systemctl enable --now crond
```
