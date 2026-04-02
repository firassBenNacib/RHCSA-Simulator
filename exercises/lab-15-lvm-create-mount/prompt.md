# Lab 15: LVM Creation And Mount

Time: 40 minutes
Objectives: storage-lvm
Systems: clientvm

Create a new volume group and logical volume and mount it persistently.

## Tasks

## Task 01 - On /dev/sdb, create an LVM partition, then create (clientvm) - 10 pts

On /dev/sdb, create an LVM partition, then create volume group wgroupx with physical extent size 8 MiB.

## Task 02 - Create logical volume wsharex with 50 extents, (clientvm) - 10 pts

Create logical volume wsharex with 50 extents, format it as ext4, and mount it persistently on /mnt/wsharex.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
