# Lab 27: At Job Scheduling

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-27-at-job` |
| Mode | Lab |
| Scope | client |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time |

Schedule a one time task with at and verify that the at daemon is enabled.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the user queue27 and set its password to (client) - 10 pts

On client, create the user queue27 and set its password to cinder9.

---

## Task 02 - Enable and start the atd service (client) - 10 pts

On client, enable and start the atd service.

---

## Task 03 - Schedule a one-time at job that appends the text (client) - 10 pts

On client, as user queue27, schedule a one-time at job that appends the text AT27 OK to /home/queue27/at27.log two minutes from now.
