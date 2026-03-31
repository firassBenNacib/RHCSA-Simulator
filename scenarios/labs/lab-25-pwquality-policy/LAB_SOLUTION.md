# Lab 25: Pwquality Policy

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-25-pwquality-policy` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | users-sudo-ssh |

Configure a persistent local password quality policy without editing PAM service files.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
mkdir -p /etc/security/pwquality.conf.d
vim /etc/security/pwquality.conf.d/lab25.conf
minlen = 12
minclass = 3
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
grep -R "minlen\|minclass" /etc/security/pwquality.conf.d
```

---

### Verification
```bash
grep -R "minlen\|minclass" /etc/security/pwquality.conf.d
```
