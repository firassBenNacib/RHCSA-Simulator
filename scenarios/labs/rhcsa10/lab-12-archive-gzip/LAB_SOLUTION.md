# RHCSA 10 Lab 12: Archive with Gzip

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-12-archive-gzip` |
| Mode | Lab |
| Scope | client |
| Time limit | 20 minutes |
| Objectives | essential-tools |

Create and inspect compressed archives.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create gzip archive (client) - 10 pts

```bash
tar -czf /root/rhcsa10-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/rhcsa10-etc.tar.gz
```
