# RHCSA 10 Lab 26: Persistent Journal

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-26-persistent-journal` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | processes-logs-tuning |

Preserve systemd journal logs.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - configure persistent systemd journals (server) - 10 pts

```bash
mkdir -p /var/log/journal
install -D -m 0644 /dev/null /etc/systemd/journald.conf
```

---

## Task 02 - restart systemd-journald (server) - 10 pts

```bash
grep -q '^Storage=' /etc/systemd/journald.conf && sed -i 's/^Storage=.*/Storage=persistent/' /etc/systemd/journald.conf || echo 'Storage=persistent' >> /etc/systemd/journald.conf
systemctl restart systemd-journald
journalctl --disk-usage
```
