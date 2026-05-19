# Lab 12: Find And Copy With Structure

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-12-find-copy-preserve` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | essential-tools |

Locate recent files owned by a user and copy them while preserving directories.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Copy matching natfind files with structure preserved (client) - 10 pts

```bash
mkdir -p /root/natfind-files
cd /opt/lab12/source
find . -type f -user natfind -mtime -1 -exec cp --parents {} /root/natfind-files \;
```
