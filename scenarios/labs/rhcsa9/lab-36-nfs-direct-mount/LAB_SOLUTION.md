# Lab 36: Persistent NFS Direct Mount

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-36-nfs-direct-mount` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 25 minutes |
| Objectives | filesystems-and-autofs, storage-lvm |

Mount a remote NFS export persistently using /etc/fstab.

### Systems
- server
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Server NFS export (server) - 10 pts

```bash
mkdir -p /exports/direct36
echo 'direct36' > /exports/direct36/nfs36.txt
cat > /etc/exports.d/lab36.exports <<'EOF'
/exports/direct36 192.168.122.0/24(ro,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs || true
firewall-cmd --permanent --add-service=mountd || true
firewall-cmd --permanent --add-service=rpc-bind || true
firewall-cmd --reload || true
exportfs -arv
```

---

## Task 02 - Client persistent NFS mount (client) - 10 pts

```bash
dnf install -y nfs-utils
mkdir -p /mnt/direct36
grep -Fqx '192.168.122.3:/exports/direct36 /mnt/direct36 nfs ro,sync 0 0' /etc/fstab || echo '192.168.122.3:/exports/direct36 /mnt/direct36 nfs ro,sync 0 0' >> /etc/fstab
systemctl enable --now nfs-client.target || true
mount /mnt/direct36 || mount -a
for attempt in 1 2 3 4 5; do mountpoint -q /mnt/direct36 && test -f /mnt/direct36/nfs36.txt && break; sleep 2; done
ls /mnt/direct36
```
