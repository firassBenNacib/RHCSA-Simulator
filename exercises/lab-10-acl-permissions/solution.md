# Lab 10: ACL And Permissions Solution

## Task 01 - Copy /etc/fstab to /var/tmp/fstab-acl (clientvm) - 10 pts

```bash
id natacl || useradd -m natacl
id haracl || useradd -m haracl
cp /etc/fstab /var/tmp/fstab-acl
chown root:root /var/tmp/fstab-acl
chmod 644 /var/tmp/fstab-acl
```

## Task 02 - Set owner and group to root:root, remove all (clientvm) - 10 pts

```bash
setfacl -m u:natacl:rw- /var/tmp/fstab-acl
setfacl -m u:haracl:--- /var/tmp/fstab-acl
getfacl /var/tmp/fstab-acl
```

## Verification

```bash
stat -c '%U:%G %a' /var/tmp/fstab-acl | grep -qx 'root:root 644'
getfacl -cp /var/tmp/fstab-acl | grep -qx 'user:natacl:rw-' && getfacl -cp /var/tmp/fstab-acl | grep -qx 'user:haracl:---' && getfacl -cp /var/tmp/fstab-acl | grep -qx 'other::r--'
```
