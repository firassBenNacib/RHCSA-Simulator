# RHCSA 10 Lab 47: Local Documentation

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-47-documentation` |
| Mode | Lab |
| Scope | client |
| Time limit | 15 minutes |
| Objectives | essential-tools |

Locate and use local documentation.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Write the first usage summary for useradd to /root/rhcsa10-man.txt (client) - 10 pts

```bash
if man useradd 2>/dev/null | col -b | awk 'BEGIN{found=0} /^SYNOPSIS/{found=1} found{print; count++} count>=2{exit}' > /root/rhcsa10-man.txt && test -s /root/rhcsa10-man.txt; then :; else useradd --help | grep -m1 -A1 '^Usage' > /root/rhcsa10-man.txt; fi
cat /root/rhcsa10-man.txt
```
