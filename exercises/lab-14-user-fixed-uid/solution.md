# Lab 14: User With Fixed UID Solution

## Task 01 - Create user tavric with UID 4111 and set its (clientvm) - 10 pts

```bash
useradd -u 4111 tavric
passwd tavric
# enter: cinder9
id tavric
```

## Verification

```bash
id -u tavric | grep -qx '4111'
```
