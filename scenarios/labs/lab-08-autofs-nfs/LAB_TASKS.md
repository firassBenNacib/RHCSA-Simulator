# Lab 08: Autofs With NFS

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-08-autofs-nfs` |
| Mode | Lab |
| Time limit | 40 minutes |
| Objectives | filesystems-and-autofs |

Configure an indirect automount from servervm.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Seed Export And User (clientvm + servervm) - 10 pts

On servervm, export /exports/vault8. On clientvm, create user vault8 with password cinder9.

---

## Task 02 - Configure Autofs Map (clientvm) - 10 pts

Configure autofs on clientvm so /netdir/vault8 is mounted on demand from servervm:/exports/vault8.

---

## Task 03 - Verify Access (clientvm) - 10 pts

Leave the configuration persistent across reboot.
