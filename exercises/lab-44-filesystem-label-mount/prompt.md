# Lab 44: Filesystem By Label

Time: 25 minutes
Objectives: storage-lvm
Systems: clientvm

Create a filesystem, label it, and mount it persistently by label.

## Tasks

## Task 01 - On /dev/sdb, create a GPT partition of 600 MiB for (clientvm) - 10 pts

On /dev/sdb, create a GPT partition of 600 MiB for an ext4 filesystem.

## Task 02 - Format the new partition with the filesystem label (clientvm) - 10 pts

Format the new partition with the filesystem label DATA44 and mount it at /data44.

## Task 03 - Configure the mount persistently in /etc/fstab by (clientvm) - 10 pts

Configure the mount persistently in /etc/fstab by using LABEL=DATA44.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
