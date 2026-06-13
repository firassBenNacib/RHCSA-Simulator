# Lab 40: Script Arguments and Conditionals

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-40-script-args-conditionals` |
| Mode | Lab |
| Scope | client |
| Time limit | 25 minutes |
| Objectives | shell-scripting, users-sudo-ssh |

Create a small shell script that processes arguments and returns the correct exit status.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the executable script (client) - 10 pts

```bash
/usr/bin/install -m 644 /dev/null /usr/local/bin/usercheck40
test -f /usr/local/bin/usercheck40
```

---

## Task 02 - The script must accept one username argument (client) - 10 pts

```bash
chmod 755 /usr/local/bin/usercheck40
```

---

## Task 03 - If the user exists, print EXISTS: username to (client) - 10 pts

```bash
/usr/bin/printf '%s\n' '#!/bin/bash' 'user_name="$1"' 'if id "$user_name" >/dev/null 2>&1; then' '  echo "EXISTS: $user_name"' '  exit 0' 'fi' 'exit 1' > /usr/local/bin/usercheck40
```

---

## Task 04 - If the user does not exist, print MISSING: username (client) - 10 pts

```bash
/usr/bin/printf '%s\n' '#!/bin/bash' 'user_name="$1"' 'if id "$user_name" >/dev/null 2>&1; then' '  echo "EXISTS: $user_name"' '  exit 0' 'else' '  echo "MISSING: $user_name"' '  exit 1' 'fi' > /usr/local/bin/usercheck40
```
