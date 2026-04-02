# Lab 09: Tar Archive With Bzip2 Solution

## Task 01 - Create /root/myetcbackup.tar.bz2 containing the (clientvm) - 10 pts

```bash
tar -cjf /root/myetcbackup.tar.bz2 /etc
```

## Verification

```bash
tar -tjf /root/myetcbackup.tar.bz2 | grep -Eq '^etc/$|^etc/'
```
