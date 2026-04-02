# Lab 24: Password Aging Defaults Solution

## Task 01 - Configure the system defaults for newly created (clientvm) - 10 pts

```bash
vim /etc/login.defs
PASS_MAX_DAYS   45
PASS_MIN_DAYS   2
PASS_WARN_AGE   10
```

## Task 02 - Create the user drift24, set its password to (clientvm) - 10 pts

```bash
useradd -m drift24
passwd drift24
# enter: cinder9
chage -l drift24
```

## Verification

```bash
grep -Eq '^[[:space:]]*PASS_MAX_DAYS[[:space:]]+45[[:space:]]*$' /etc/login.defs && grep -Eq '^[[:space:]]*PASS_MIN_DAYS[[:space:]]+2[[:space:]]*$' /etc/login.defs && grep -Eq '^[[:space:]]*PASS_WARN_AGE[[:space:]]+10[[:space:]]*$' /etc/login.defs
chage -l drift24 | grep -Eq 'Minimum number of days between password change[^0-9]*2$' && chage -l drift24 | grep -Eq 'Maximum number of days between password change[^0-9]*45$' && chage -l drift24 | grep -Eq 'Number of days of warning before password expires[^0-9]*10$'
```
