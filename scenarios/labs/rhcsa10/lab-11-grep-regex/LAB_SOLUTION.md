# RHCSA 10 Lab 11: Grep Regex

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-11-grep-regex` |
| Mode | Lab |
| Scope | client |
| Time limit | 15 minutes |
| Objectives | essential-tools |

Filter text with grep and regular expressions.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /root/rhcsa10-shell-users.txt (client) - 10 pts

```bash
: > /root/rhcsa10-shell-users.txt
```

---

## Task 02 - Populate it with account names from /etc/passwd whose shell ends in sh (client) - 10 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/rhcsa10-shell-users.txt
cat /root/rhcsa10-shell-users.txt
```
