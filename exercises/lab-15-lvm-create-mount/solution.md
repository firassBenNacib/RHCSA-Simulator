# Lab 15: LVM Creation And Mount Solution

## Task 01 - On /dev/sdb, create an LVM partition, then create (clientvm) - 10 pts

```bash
fdisk /dev/sdb
# create a GPT LVM partition for the remaining disk space
partprobe /dev/sdb
pvcreate /dev/sdb1
vgcreate -s 8M wgroupx /dev/sdb1
lvcreate -n wsharex -l 50 wgroupx
```

## Task 02 - Create logical volume wsharex with 50 extents, (clientvm) - 10 pts

```bash
mkfs.ext4 /dev/wgroupx/wsharex
mkdir -p /mnt/wsharex
blkid /dev/wgroupx/wsharex
vim /etc/fstab
UUID=<uuid-of-wsharex> /mnt/wsharex ext4 defaults 0 0
mount -a
findmnt /mnt/wsharex
```

## Verification

```bash
pvs --noheadings -o pv_name,vg_name | awk '$1=="/dev/sdb1" && $2=="wgroupx"{found=1} END{exit !found}'
vgs --noheadings -o vg_name,vg_extent_size --units m --nosuffix | awk '$1=="wgroupx" && int($2)==8{found=1} END{exit !found}'
lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1=="wsharex" && $2=="wgroupx" && $3>=399 && $3<=401{found=1} END{exit !found}'
blkid -o value -s TYPE /dev/wgroupx/wsharex | grep -qx ext4
findmnt -no TARGET,SOURCE,FSTYPE /mnt/wsharex | grep -Eq '^/mnt/wsharex /dev/mapper/wgroupx-wsharex ext4$'
```
