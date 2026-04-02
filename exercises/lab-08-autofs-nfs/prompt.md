# Lab 08: Autofs With NFS

Time: 40 minutes
Objectives: filesystems-and-autofs
Systems: clientvm + servervm

Configure an indirect automount from servervm.

## Tasks

## Task 01 - Seed Export And User (servervm) - 10 pts

On servervm, export /exports/vault8. On clientvm, create user vault8 with password cinder9.

## Task 02 - Configure Autofs Map (clientvm + servervm) - 10 pts

Configure autofs on clientvm so /netdir/vault8 is mounted on demand from servervm:/exports/vault8.

## Task 03 - Verify Access (clientvm) - 10 pts

Leave the configuration persistent across reboot.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
