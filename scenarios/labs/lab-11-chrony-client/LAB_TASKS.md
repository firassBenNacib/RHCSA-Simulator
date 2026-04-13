# Lab 11: Time Synchronization

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-11-chrony-client` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time |

Configure servervm as a simple chrony source and point clientvm at it.

### Systems
- servervm
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure servervm as the chrony source (servervm) - 15 pts

On servervm, configure chronyd so it serves time to the 192.168.122.0/24 lab network and starts automatically at boot.

---

## Task 02 - Configure clientvm to use only servervm for time (clientvm) - 15 pts

On clientvm, configure chronyd so it synchronizes only with servervm and starts automatically at boot.
