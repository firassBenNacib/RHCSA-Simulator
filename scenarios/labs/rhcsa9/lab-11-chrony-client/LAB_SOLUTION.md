# Lab 11: Time Synchronization

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-11-chrony-client` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time |

Configure server as a simple chrony source and point client at it.

### Systems
- server
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure server as the chrony source (server) - 15 pts

```bash
vim /etc/chrony.conf
allow 192.168.122.0/24
systemctl enable --now chronyd
```

---

## Task 02 - Configure client to use only server for time (client) - 15 pts

```bash
vim /etc/chrony.conf
server server iburst
systemctl enable --now chronyd
```
