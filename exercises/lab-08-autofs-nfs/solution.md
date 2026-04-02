# Lab 08: Autofs With NFS Solution

## Task 01 - Seed Export And User (servervm) - 10 pts

```bash
# On servervm
mkdir -p /exports/vault8
printf "autofs lab 08\n" > /exports/vault8/welcome.txt
exportfs -arv
# On clientvm
useradd -m vault8
passwd vault8
# enter: cinder9
```

## Task 02 - Configure Autofs Map (clientvm + servervm) - 10 pts

```bash
vim /etc/auto.lab8
vault8 -rw,sync servervm:/exports/vault8
vim /etc/auto.master.d/lab8.autofs
/netdir /etc/auto.lab8
systemctl enable --now autofs
```

## Task 03 - Verify Access (clientvm) - 10 pts

```bash
ls -l /netdir/vault8
cat /netdir/vault8/welcome.txt
```

## Verification

```bash
showmount -e servervm | grep -Eq '(^|[[:space:]])/exports/vault8([[:space:]]|$)'
mount | grep -Eq 'servervm:/exports/vault8 on /netdir/vault8 type nfs'
test -f /netdir/vault8/welcome.txt && grep -Fqx 'autofs lab 08' /netdir/vault8/welcome.txt
```
