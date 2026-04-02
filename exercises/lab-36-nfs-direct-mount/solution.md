# Lab 36: Persistent NFS Direct Mount Solution

## Task 01 - Persistently mount the NFS export (clientvm) - 10 pts

```bash
mkdir -p /mnt/direct36
vim /etc/fstab
192.168.122.3:/exports/direct36 /mnt/direct36 nfs ro,sync 0 0
:wq
```

## Task 02 - Use the mount options ro,sync (clientvm) - 10 pts

```bash
mount -a
```

## Task 03 - Ensure the mount is available after a reboot and (clientvm) - 10 pts

```bash
ls /mnt/direct36
```

## Verification

```bash
grep -Eq '^[^#].*192\.168\.122\.3:/exports/direct36[[:space:]]+/mnt/direct36[[:space:]]+nfs[[:space:]]+ro,sync' /etc/fstab
mountpoint -q /mnt/direct36
test -f /mnt/direct36/nfs36.txt
```
