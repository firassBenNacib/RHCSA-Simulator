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
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the pwquality drop-in (clientvm) - 15 pts

```bash
cat > /etc/security/pwquality.conf.d/lab25.conf <<'EOF'
minlen = 12
minclass = 3
maxrepeat = 2
EOF
```

---

## Task 02 - Leave PAM service files unchanged (clientvm) - 15 pts

```bash
true
```

---

## Verification
```bash
grep -Eq '^minlen[[:space:]]*=[[:space:]]*12$' /etc/security/pwquality.conf.d/lab25.conf && grep -Eq '^minclass[[:space:]]*=[[:space:]]*3$' /etc/security/pwquality.conf.d/lab25.conf && grep -Eq '^maxrepeat[[:space:]]*=[[:space:]]*2$' /etc/security/pwquality.conf.d/lab25.conf
! grep -Rqs 'lab25' /etc/pam.d
```
