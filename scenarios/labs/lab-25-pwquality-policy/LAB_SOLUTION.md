# Lab 25: Pwquality Policy

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-25-pwquality-policy` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | users-sudo-ssh |

Configure a persistent local password quality policy without editing PAM service files.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create a persistent password quality policy in (clientvm) - 10 pts

```bash
mkdir -p /etc/security/pwquality.conf.d
vim /etc/security/pwquality.conf.d/lab25.conf
minlen = 12
minclass = 3
```

---

## Task 02 - Do not edit any PAM service file for this task (clientvm) - 10 pts

```bash
grep -R "minlen\|minclass" /etc/security/pwquality.conf.d
```

---

## Verification
```bash
grep -R -Eq '^[[:space:]]*minlen[[:space:]]*=[[:space:]]*12[[:space:]]*$' /etc/security/pwquality.conf.d && grep -R -Eq '^[[:space:]]*minclass[[:space:]]*=[[:space:]]*3[[:space:]]*$' /etc/security/pwquality.conf.d
```
