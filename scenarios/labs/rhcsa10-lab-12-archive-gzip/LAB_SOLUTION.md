# RHCSA 10 Lab 12: Archive With Gzip

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-12-archive-gzip` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | essential-tools |

Create and inspect compressed archives.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /root/rhcsa10-etc.tar.gz containing /etc/hosts and /etc/fstab (client) - 10 pts

```bash
tar -czf /root/rhcsa10-etc.tar.gz /etc/hosts /etc/fstab
```

---

## Task 02 - Ensure the archive uses gzip compression (client) - 10 pts

```bash
file /root/rhcsa10-etc.tar.gz
```

---

## Task 03 - List the archive contents without extracting it (client) - 10 pts

```bash
tar -tzf /root/rhcsa10-etc.tar.gz
```
