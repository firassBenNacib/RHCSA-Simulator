# Lab 11: Time Synchronization

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-11-chrony-client` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time |

Configure clientvm to synchronize time from servervm.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure chrony on clientvm so it synchronizes (clientvm) - 10 pts

Configure chrony on clientvm so it synchronizes only with servervm and starts automatically at boot.

## Hints
- Remove any other server or pool lines.
- Use iburst on the server line.

## Validation Commands
```bash
awk '$1 ~ /^(server|pool)$/ { if ($2 != "servervm") bad=1; if ($1=="server" && $2=="servervm") good=1 } END { exit !(good && !bad) }' /etc/chrony.conf
systemctl is-enabled chronyd | grep -qx enabled && systemctl is-active chronyd | grep -qx active
```
