# Lab 06: Shared Setgid Directory Solution

## Task 01 - Create /shared/analysts with group ownership of (clientvm) - 10 pts

```bash
mkdir -p /shared/analysts
chgrp analystsx /shared/analysts
chmod 2770 /shared/analysts
```

## Task 02 - Set the directory so new files inherit the (clientvm) - 10 pts

```bash
touch /shared/analysts/probe.txt
ls -l /shared/analysts/probe.txt
```

## Task 03 - Verify the final directory permissions (clientvm) - 10 pts

```bash
ls -ld /shared/analysts
```

## Verification

```bash
stat -c '%A %a %G' /shared/analysts | grep -qx 'drwxrws--- 2770 analystsx'
```
