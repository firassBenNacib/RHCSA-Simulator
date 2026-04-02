# Lab 36: Persistent NFS Direct Mount

Time: 25 minutes
Objectives: filesystems-and-autofs, storage-lvm
Systems: clientvm + servervm

Mount a remote NFS export persistently using /etc/fstab.

## Tasks

## Task 01 - Persistently mount the NFS export (clientvm) - 10 pts

Persistently mount the NFS export 192.168.122.3:/exports/direct36 on clientvm at /mnt/direct36.

## Task 02 - Use the mount options ro,sync (clientvm) - 10 pts

Use the mount options ro,sync.

## Task 03 - Ensure the mount is available after a reboot and (clientvm) - 10 pts

Ensure the mount is available after a reboot and that the file nfs36.txt can be read from the mount point.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
