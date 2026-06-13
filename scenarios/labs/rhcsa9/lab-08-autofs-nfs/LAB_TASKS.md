# Lab 08: Autofs with NFS

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-08-autofs-nfs` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 40 minutes |
| Objectives | filesystems-and-autofs |

Configure an indirect automount from server.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Seed Export and User (client + server) - 10 pts

On server, export /exports/vault8. On client, create user vault8 with password cinder9.

---

## Task 02 - Configure Persistent Autofs Map (client + server) - 20 pts

On client, configure autofs on client so /netdir/vault8 is mounted on demand from server:/exports/vault8 and persists across reboot.
