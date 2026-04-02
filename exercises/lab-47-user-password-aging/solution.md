# Lab 47: Per-User Password Aging Solution

## Task 01 - Create user cycle47 with password cinder9 if it (clientvm) - 10 pts

```bash
id cycle47 || useradd -m cycle47
passwd cycle47
# enter: cinder9
```

## Task 02 - Configure cycle47 with a maximum password age of 30 (clientvm) - 10 pts

```bash
chage -M 30 -m 2 -W 7 cycle47
```

## Task 03 - Force cycle47 to change the password at the next login (clientvm) - 10 pts

```bash
chage -d 0 cycle47
chage -l cycle47
```

## Verification

```bash
chage -l cycle47 | grep -Eq 'Minimum number of days between password change[^0-9]*2$' && chage -l cycle47 | grep -Eq 'Maximum number of days between password change[^0-9]*30$' && chage -l cycle47 | grep -Eq 'Number of days of warning before password expires[^0-9]*7$' && chage -l cycle47 | grep -Eq 'Last password change[^:]*: password must be changed'
```
