# Local Storage And LVM - Lab Solution
Scenario ID: storage-lvm
Mode: Lab
Time limit: 60 minutes
Objectives: storage-lvm

Practice RHCSA v9 partitioning, LVM creation, swap, and persistent filesystem mounts on the attached data disks.

## Task 01 - Volume Group And labdata LV (clientvm) - 10 pts
```bash
pvcreate /dev/sdb /dev/sdc
vgcreate rhcsa_vg /dev/sdb /dev/sdc
lvcreate -L 512M -n labdata rhcsa_vg
```

## Task 02 - XFS Data Mount (clientvm) - 15 pts
```bash
mkfs.xfs /dev/rhcsa_vg/labdata
mkdir -p /srv/labdata
echo '/dev/rhcsa_vg/labdata /srv/labdata xfs defaults 0 0' >> /etc/fstab
mount /srv/labdata
```

## Task 03 - Swap Logical Volume (clientvm) - 10 pts
```bash
lvcreate -L 256M -n labswap rhcsa_vg
mkswap /dev/rhcsa_vg/labswap
echo '/dev/rhcsa_vg/labswap none swap defaults 0 0' >> /etc/fstab
swapon -a
```

## Task 04 - ext4 Filesystem Mount (clientvm) - 10 pts
```bash
lvcreate -L 300M -n labext4 rhcsa_vg
mkfs.ext4 /dev/rhcsa_vg/labext4
mkdir -p /mnt/labext4
echo '/dev/rhcsa_vg/labext4 /mnt/labext4 ext4 defaults 0 0' >> /etc/fstab
mount /mnt/labext4
```

## Task 05 - Reboot Persistence Check (clientvm) - 5 pts
```bash
findmnt /srv/labdata
findmnt /mnt/labext4
swapon --show
```

Verification
```bash
pvs
vgs
lvs
findmnt /srv/labdata
findmnt /mnt/labext4
swapon --show
```
