# Lab 25: Pwquality Policy

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-25-pwquality-policy` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | users-sudo-ssh |

Use a pwquality drop-in to enforce a stronger local password policy.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the pwquality drop-in without editing PAM (clientvm) - 30 pts

```bash
cat > /etc/security/pwquality.conf.d/lab25.conf <<'EOF'
minlen = 12
minclass = 3
maxrepeat = 2
EOF
```
