# Lab 02: Root Password Recovery Solution

## Task 01 - Recover root access on clientvm from the console (clientvm) - 10 pts

```bash
# At the boot menu, edit the selected kernel entry.
# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.
passwd root
# enter: cinder9
touch /.autorelabel
exec /sbin/init
```

## Task 02 - After the system boots normally, confirm that (clientvm) - 10 pts

```bash
getenforce
ls -Z /root | head
```

## Task 03 - Leave SSH password authentication working for root (clientvm) - 10 pts

```bash
vim /etc/ssh/sshd_config
PasswordAuthentication yes
PermitRootLogin yes
systemctl restart sshd
```

## Verification

```bash
getenforce | grep -qx Enforcing
ls -Zd /root | grep -Eq '(^| )[^ ]+:object_r:admin_home_t:s0($| )'
grep -Eq '^[[:space:]]*PasswordAuthentication[[:space:]]+yes[[:space:]]*$' /etc/ssh/sshd_config && grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+yes[[:space:]]*$' /etc/ssh/sshd_config
```
