# Lab 16: Additional Swap Space Solution

## Task 01 - Create a 400 MiB swap partition on /dev/sdb, enable (clientvm) - 10 pts

```bash
fdisk /dev/sdb
# create a 400M partition and change the type to Linux swap
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
blkid /dev/sdb1
vim /etc/fstab
UUID=<uuid-of-sdb1> swap swap defaults 0 0
swapon --show
```

## Verification

```bash
swapon --noheadings --show=NAME | grep -qx '/dev/sdb1'
blkid -o value -s TYPE /dev/sdb1 | grep -qx swap
uuid="$(blkid -o value -s UUID /dev/sdb1)"; grep -Eq "^UUID=${uuid}[[:space:]]+swap[[:space:]]+swap[[:space:]]+" /etc/fstab
```
