# Lab 31: Shell Loop Script

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-31-shell-loop-script` |
| Mode | Lab |
| Scope | client |
| Time limit | 25 minutes |
| Objectives | shell-scripting |

Create a simple shell script that uses a loop to filter files by name.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create an executable script (client) - 10 pts

```bash
vim /usr/local/bin/listlogs31
#!/bin/bash
for item in /opt/lab31/*; do
    if [[ "$item" == *.log ]]; then
        echo "$item" >> /root/listlogs31.out
    fi
done
chmod +x /usr/local/bin/listlogs31
```

---

## Task 02 - Run the script once (client) - 10 pts

```bash
/usr/local/bin/listlogs31
```
