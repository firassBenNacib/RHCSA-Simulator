# Filesystems, NFS, And Autofs - Lab Tasks
Scenario ID: filesystems-and-autofs
Mode: Lab
Time limit: 60 minutes
Objectives: filesystems-and-autofs

Practice RHCSA v9 persistent network mounts and indirect automount maps against the reusable server infrastructure.

## Task 01 - Persistent NFS Mount (clientvm) - 15 pts
Create a persistent NFS mount on clientvm for servervm:/exports/direct at /mnt/direct-share.

## Task 02 - Autofs Indirect Map (clientvm) - 15 pts
Configure autofs so /projects/readme resolves to the README file exported from servervm:/exports/autofs/projects.

## Task 03 - Autofs Verification (clientvm) - 10 pts
Ensure autofs starts automatically and verify the indirect map works on demand.

Hints
1. The direct mount belongs in /etc/fstab.
2. The autofs task needs both an auto.master entry and a map file.
3. Use showmount -e servervm if you need to confirm exports.

Checks
```bash
findmnt /mnt/direct-share
systemctl status autofs --no-pager
ls -l /projects/readme
```
