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
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create runner21 and set its password (client) - 10 pts

Create user runner21 if it does not already exist and set its password to cinder9.

---

## Task 02 - Run mycontainer21 with bind mounts (client) - 10 pts

As user runner21, run a container named mycontainer21 from localhost/text2pdf21:latest with /opt/file21 bind mounted to /data/input and /opt/processed21 bind mounted to /data/output.
