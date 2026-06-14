# RHCSA 10 Lab 26: Persistent Journal

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-26-persistent-journal` |
| Mode | Lab |
| Scope | server |
| Time limit | 20 minutes |
| Objectives | processes-logs-tuning |

Preserve systemd journal logs.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Enable persistent journal (server) - 10 pts

On server, create the persistent systemd journal directory.

---

## Task 02 - Enable persistent journal (server) - 10 pts

On server, configure systemd-journald to store logs persistently and flush current journal data.
