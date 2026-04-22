# RHCSA 10 Lab 08: Script Arguments

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-08-shell-script-args` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | shell-scripting |

Create a shell script that processes command-line arguments.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /usr/local/bin/rhcsa10-user-report (client) - 10 pts

```bash
cat > /usr/local/bin/rhcsa10-user-report <<'EOF'
#!/bin/bash
if [ -z "${1:-}" ]; then
  echo 'usage: rhcsa10-user-report USER' >&2
  exit 2
fi
id -gn "$1"
EOF
```

---

## Task 02 - The script must print usage: rhcsa10-user-report USER when no argument i (client) - 10 pts

```bash
chmod +x /usr/local/bin/rhcsa10-user-report
```

---

## Task 03 - When a user name is supplied, print that user's primary group name (client) - 10 pts

```bash
/usr/local/bin/rhcsa10-user-report root
```
