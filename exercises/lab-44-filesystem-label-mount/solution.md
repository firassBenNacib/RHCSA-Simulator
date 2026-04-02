# Lab 44: Filesystem By Label Solution

## Task 01 - On /dev/sdb, create a GPT partition of 600 MiB for (clientvm) - 10 pts

```bash
fdisk /dev/sdb
# g
# n
# <Enter>
# <Enter>
# +600M
# w
```

## Task 02 - Format the new partition with the filesystem label (clientvm) - 10 pts

```bash
mkfs.ext4 -L DATA44 /dev/sdb1
mkdir -p /data44
```

## Task 03 - Configure the mount persistently in /etc/fstab by (clientvm) - 10 pts

```bash
vim /etc/fstab
LABEL=DATA44 /data44 ext4 defaults 0 0
:wq
mount -a
findmnt /data44
```

## Verification

```bash
blkid -o value -s LABEL /dev/sdb1 | grep -qx DATA44
findmnt -no TARGET,SOURCE /data44 | grep -Eq '^/data44 /dev/sdb1$|^/data44 /dev/mapper/.+$' && grep -Eq '^[^#]*LABEL=DATA44[[:space:]]+/data44[[:space:]]+ext4' /etc/fstab
```
