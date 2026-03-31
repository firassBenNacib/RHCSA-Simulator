# Lab 40: Script Arguments and Conditionals

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-40-script-args-conditionals` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | shell-scripting, users-sudo-ssh |

Create a small shell script that processes arguments and returns the correct exit status.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

Create the executable script /usr/local/bin/usercheck40 on clientvm.

---

## Task 02 — Part 02
**System:** clientvm

The script must accept one username argument.

---

## Task 03 — Part 03
**System:** clientvm

If the user exists, print EXISTS: username to standard output and exit with status 0.

---

## Task 04 — Part 04
**System:** clientvm

If the user does not exist, print MISSING: username to standard output and exit with status 1.

### Hints
- Use an if test against the passwd database or the id command.
- Make the script executable.

### Checks
```bash
id script40 >/dev/null 2>&1
/usr/local/bin/usercheck40 script40 | grep -qx "EXISTS: script40"
! /usr/local/bin/usercheck40 nosuch40 >/dev/null 2>&1
```
