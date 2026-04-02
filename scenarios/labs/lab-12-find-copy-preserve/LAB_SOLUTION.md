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
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Find all files owned by natfind and modified in the (clientvm) - 10 pts

```bash
find /opt/lab12/source -type f -user natfind -mtime -1 -exec cp --parents {} /root/natfind-files \;
```

---

## Task 02 - Copy them to /root/natfind-files and preserve the (clientvm) - 10 pts

```bash
find /root/natfind-files -type f | sort
```

---

## Verification
```bash
diff -u <(find /opt/lab12/source -type f -user natfind -mtime -1 | sed 's#^/opt/lab12/source#/root/natfind-files#' | sort) <(find /root/natfind-files -type f | sort)
```
