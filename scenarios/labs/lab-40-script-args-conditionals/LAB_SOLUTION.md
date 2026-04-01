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

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - Create the executable script…
**System:** clientvm

#### Command Flow
```bash
vim /usr/local/bin/usercheck40
```

---

### Task 02 - The script must accept one username argument
**System:** clientvm

#### Command Flow
```bash
#!/bin/bash
user_name="$1"
```

---

### Task 03 - If the user exists, print EXISTS: username to…
**System:** clientvm

#### Command Flow
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

### Task 04 - If the user does not exist, print MISSING: username…
**System:** clientvm

#### Command Flow
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
