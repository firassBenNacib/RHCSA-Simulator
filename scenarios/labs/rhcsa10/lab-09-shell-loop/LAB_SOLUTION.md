# RHCSA 10 Lab 09: Loop Script

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-09-shell-loop` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | shell-scripting |

Create a shell script that loops over input.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /usr/local/bin/rhcsa10-lines (client) - 10 pts

```bash
cat > /usr/local/bin/rhcsa10-lines <<'EOF'
#!/bin/bash
: > /root/rhcsa10-lines.txt
while IFS=: read -r name _; do
  case "$name" in
    r*) echo "$name" >> /root/rhcsa10-lines.txt ;;
  esac
done < /etc/passwd
EOF
```

---

## Task 02 - The script must read /etc/passwd and write every account name that start (client) - 10 pts

```bash
chmod +x /usr/local/bin/rhcsa10-lines
```

---

## Task 03 - The script must overwrite the output file each time it runs (client) - 10 pts

```bash
/usr/local/bin/rhcsa10-lines
cat /root/rhcsa10-lines.txt
```
