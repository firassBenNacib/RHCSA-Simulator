# Lab 40: Script Arguments and Conditionals

## Lab Solution
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

#### Commands
```bash
vim /usr/local/bin/usercheck40
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
#!/bin/bash
user_name="$1"
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
```bash
if id "$user_name" >/dev/null 2>&1; then
  echo "EXISTS: $user_name"
  exit 0
else
  echo "MISSING: $user_name"
  exit 1
fi
```

---

## Task 04 — Part 04
**System:** clientvm

#### Commands
```bash
:wq
chmod 755 /usr/local/bin/usercheck40
```

---

### Verification
```bash
id script40 >/dev/null 2>&1
/usr/local/bin/usercheck40 script40 | grep -qx "EXISTS: script40"
! /usr/local/bin/usercheck40 nosuch40 >/dev/null 2>&1
```
