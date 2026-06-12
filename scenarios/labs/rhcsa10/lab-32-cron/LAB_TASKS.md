# RHCSA 10 Lab 32: Cron Job

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-32-cron` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time |

Schedule recurring tasks with cron.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - create user cron10 and set password cinder9 (server) - 10 pts

On server, create user cron10 and set password cinder9.

---

## Task 02 - configure a cron job for cron10 that writes CRON10 to /home/cron10/cron1 (server) - 10 pts

On server, configure a cron job for cron10 that writes CRON10 to /home/cron10/cron10.log every 5 minutes.

---

## Task 03 - ensure crond is enabled and running (server) - 10 pts

On server, ensure crond is enabled and running.
