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

## Task 01 - configure persistent systemd journal storage (server) - 10 pts

```bash
mkdir -p /var/log/journal /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
```

---

## Task 02 - restart systemd-journald and flush current journal data to persistent st (server) - 10 pts

```bash
systemctl restart systemd-journald
journalctl --flush
```
