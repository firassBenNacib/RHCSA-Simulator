# RHCSA 10 Lab 24: Process Priority

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-24-process-priority` |
| Mode | Lab |
| Scope | server |
| Time limit | 20 minutes |
| Objectives | processes-logs-tuning |

Identify and adjust process scheduling.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Start a detached background sleep process and save its PID in (server) - 10 pts

On server, start a detached background sleep process and save its PID in /run/rhcsa10-sleep.pid.

---

## Task 02 - Change the process nice value to 8 (server) - 10 pts

On server, change the process nice value to 8.
