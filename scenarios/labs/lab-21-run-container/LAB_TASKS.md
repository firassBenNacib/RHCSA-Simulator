# Lab 21: Run A Container

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-21-run-container` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | containers |

Run a container from a prepared local image with bind mounts.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - run a container named mycontainer21 from (clientvm) - 10 pts

As user runner21, run a container named mycontainer21 from localhost/text2pdf21:latest.

---

## Task 02 - Bind mount /opt/file21 to /data/input and (clientvm) - 10 pts

Bind mount /opt/file21 to /data/input and /opt/processed21 to /data/output.
