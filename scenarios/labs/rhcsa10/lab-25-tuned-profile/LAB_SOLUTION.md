# RHCSA 10 Lab 25: Tuned Profile

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-25-tuned-profile` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | processes-logs-tuning |

Manage tuned profiles.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Ensure tuned is enabled and running (client) - 10 pts

```bash
systemctl enable --now tuned
```

---

## Task 02 - Activate the throughput-performance tuned profile (client) - 20 pts

```bash
tuned-adm profile throughput-performance
tuned-adm active
```
