# RHCSA 10 Lab 26: Persistent Journal

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-26-persistent-journal` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | processes-logs-tuning |

Preserve systemd journal logs.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure persistent systemd journals (client) - 10 pts

```bash
mkdir -p /var/log/journal
```

---

## Task 02 - Restart systemd-journald (client) - 10 pts

```bash
sed -i 's/^#\?Storage=.*/Storage=persistent/' /etc/systemd/journald.conf
```

---

## Task 03 - Verify that /var/log/journal exists (client) - 10 pts

```bash
systemctl restart systemd-journald
journalctl --disk-usage
```
