# RHCSA 10 Lab 28: Chrony Client

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-28-chrony-client` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time, processes-logs-tuning |

Configure time synchronization.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - install chrony if needed (client) - 10 pts

```bash
dnf install -y chrony
```

---

## Task 02 - configure server as the only NTP source (client) - 10 pts

```bash
sed -i '/^pool /d;/^server /d' /etc/chrony.conf
echo 'server server iburst' >> /etc/chrony.conf
```

---

## Task 03 - enable and start chronyd (client) - 10 pts

```bash
systemctl enable --now chronyd
chronyc sources || true
```
