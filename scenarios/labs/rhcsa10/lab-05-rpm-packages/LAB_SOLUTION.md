# RHCSA 10 Lab 05: RPM Packages

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-05-rpm-packages` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 20 minutes |
| Objectives | software-management |

Install and remove RPM software.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Install the lsof package (client) - 10 pts

```bash
dnf install -y lsof
```

---

## Task 02 - Remove the tcpdump package if it is installed (client) - 10 pts

```bash
dnf remove -y tcpdump
rpm -q tcpdump || true
```

---

## Task 03 - Install the lsof package (server) - 10 pts

```bash
# On server
dnf install -y lsof
```
