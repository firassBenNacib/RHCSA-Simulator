# Lab 26: Default ACL Shared Directory Solution

## Task 01 - Create the group collab26 and the user probe26. Set (clientvm) - 10 pts

```bash
groupadd collab26
useradd -m probe26
passwd probe26
# enter: cinder9
```

## Task 02 - Create the directory /shared/collab26 with owner (clientvm) - 10 pts

```bash
mkdir -p /shared/collab26
chown root:collab26 /shared/collab26
chmod 2770 /shared/collab26
```

## Task 03 - Configure a default ACL so that user probe26 (clientvm) - 10 pts

```bash
setfacl -m d:u:probe26:rwx /shared/collab26
getfacl /shared/collab26
```

## Verification

```bash
stat -c '%U:%G %a' /shared/collab26 | grep -qx 'root:collab26 2770' && getfacl -cp /shared/collab26 | grep -qx 'default:user:probe26:rwx'
```
