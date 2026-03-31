# Lab 08: Autofs With NFS - Lab Solution
Scenario ID: lab-08-autofs-nfs
Mode: Lab
Time limit: 40 minutes
Objectives: filesystems-and-autofs

Configure an indirect automount from servervm.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
ssh admin@servervm
sudo -i
mkdir -p /exports/netuser8
printf "autofs lab 08
" > /exports/netuser8/welcome.txt
exportfs -arv
exit
exit
useradd -m netuser8
passwd netuser8
# enter: redhat
```

## Task 02 - Part 02 (clientvm)
```bash
vim /etc/auto.lab8
netuser8 -rw,sync servervm:/exports/netuser8
vim /etc/auto.master.d/lab8.autofs
/netdir /etc/auto.lab8
systemctl enable --now autofs
```

## Task 03 - Part 03 (clientvm)
```bash
ls -l /netdir/netuser8
cat /netdir/netuser8/welcome.txt
```

Verification
```bash
showmount -e servervm
ls -l /netdir/netuser8
ls -l /netdir/netuser8/welcome.txt
```
