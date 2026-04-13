# Lab 40: Script Arguments and Conditionals

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-40-script-args-conditionals` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | shell-scripting, users-sudo-ssh |

Create a small shell script that processes arguments and returns the correct exit status.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the executable script (clientvm) - 10 pts

```bash
vim /usr/local/bin/usercheck40
#!/bin/bash
user_name="$1"
if id "$user_name" >/dev/null 2>&1; then
  echo "EXISTS: $user_name"
  exit 0
else
  echo "MISSING: $user_name"
  exit 1
fi
```

---

## Task 02 - The script must accept one username argument (clientvm) - 10 pts

```bash
# The script reads the first positional parameter as user_name.
```

---

## Task 03 - If the user exists, print EXISTS: username to (clientvm) - 10 pts

```bash
# The script uses id to print EXISTS and exit 0 when the user exists.
```

---

## Task 04 - If the user does not exist, print MISSING: username (clientvm) - 10 pts

```bash
chmod 755 /usr/local/bin/usercheck40
```
