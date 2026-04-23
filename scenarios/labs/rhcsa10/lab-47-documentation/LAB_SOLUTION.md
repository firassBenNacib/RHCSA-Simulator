# RHCSA 10 Lab 47: Local Documentation

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-47-documentation` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | essential-tools |

Locate and use local documentation.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /root/rhcsa10-man.txt (client) - 10 pts

```bash
man useradd | col -b | grep -m1 -A1 '^SYNOPSIS' > /root/rhcsa10-man.txt
```

---

## Task 02 - Write the first SYNOPSIS line from man useradd to the file (client) - 10 pts

```bash
cat /root/rhcsa10-man.txt
```

---

## Task 03 - Ensure the file is not empty (client) - 10 pts

```bash
test -s /root/rhcsa10-man.txt
```
