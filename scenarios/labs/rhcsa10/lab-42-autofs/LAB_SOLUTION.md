# RHCSA 10 Lab 42: Autofs

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-42-autofs` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | filesystems-and-autofs |

Configure automount for NFS exports.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Install autofs if needed (server) - 10 pts

```bash
dnf install -y autofs
```

---

## Task 02 - Configure /remote10/projects to automount server:/exports/autofs/project (server) - 10 pts

```bash
mkdir -p /remote10
echo '/remote10 /etc/auto.remote10' > /etc/auto.master.d/rhcsa10.autofs
echo 'projects -ro server:/exports/autofs/projects' > /etc/auto.remote10
```

---

## Task 03 - Enable and start autofs (server) - 10 pts

```bash
systemctl enable --now autofs
ls /remote10/projects || true
```
