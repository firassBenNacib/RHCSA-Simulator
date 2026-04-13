# Mock Exam C

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-c` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, filesystems-and-autofs, users-sudo-ssh, storage-lvm, containers |

A 22 task RHCSA style mock exam centered on recovery, boot persistence, NFS, ACLs, journald, and rootless containers.

### Systems
- clientvm
- servervm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Root Recovery (clientvm) - 5 pts

```bash
# At the boot menu, edit the selected kernel entry.
# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.
passwd root
# enter: cinder9
touch /.autorelabel
exec /sbin/init
```

---

## Question 02 - Client Network (clientvm) - 5 pts

```bash
nmcli device status
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.28/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname clientvm.exam-c.lab
```

---

## Question 03 - Bootloader Kernel Argument (clientvm) - 5 pts

```bash
grubby --update-kernel=ALL --args="audit_backlog_limit=8192"
```

---

## Question 04 - Host Entry (clientvm) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 vault.exam-c.lab
```

---

## Question 05 - Direct NFS Mount (clientvm) - 5 pts

```bash
mkdir -p /mnt/bluec
vim /etc/fstab
servervm:/exports/bluec /mnt/bluec nfs defaults,_netdev 0 0
mount -a
```

---

## Question 06 - Users And Group (clientvm) - 5 pts

```bash
groupadd infrac
useradd -G infrac talia
useradd -G infrac ren
echo cinder9 | passwd --stdin talia
echo cinder9 | passwd --stdin ren
```

---

## Question 07 - Default ACL Directory (clientvm) - 5 pts

```bash
chmod 770 /srv/infrac
chmod g+s /srv/infrac
```

---

## Question 08 - No-Home User (clientvm) - 5 pts

```bash
useradd -M -s /sbin/nologin remote63
```

---

## Question 09 - At Job (clientvm) - 5 pts

```bash
echo 'echo "exam-c audit" >> /root/exam-c-at.log' | at now + 2 minutes
systemctl enable --now atd
```

---

## Question 10 - Per-User Password Aging (clientvm) - 5 pts

```bash
chage -M 45 -m 5 -W 7 talia
```

---

## Question 11 - Persistent Journal (servervm) - 5 pts

```bash
# Run on servervm
mkdir -p /var/log/journal
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
```

---

## Question 12 - User Umask (clientvm) - 5 pts

```bash
echo 'umask 027' >> /home/ren/.bash_profile
```

---

## Question 13 - Per-User Login Message (clientvm) - 4 pts

```bash
echo 'echo exam-c access' >> /home/ren/.bash_profile
```

---

## Question 14 - Fixed UID User (clientvm) - 4 pts

```bash
useradd -u 4431 kian431
passwd kian431
# enter: cinder9
```

---

## Question 15 - Find And Copy (clientvm) - 4 pts

```bash
find /opt/exam-c/find -type f -user ren -mtime -1 -exec cp --parents {} /root/ren-files \;
```

---

## Question 16 - Grep Filter (clientvm) - 4 pts

```bash
grep orbit /usr/share/dict/words > /root/orbit-lines
```

---

## Question 17 - Archive (clientvm) - 4 pts

```bash
tar -cjf /root/etc-c.tar.bz2 /etc
```

---

## Question 18 - Service Status Script (clientvm) - 4 pts

```bash
vim /usr/local/bin/northcheck
#!/usr/bin/env bash
while read -r svc; do
  systemctl is-active "$svc" >> /root/north-services.txt
done < /usr/local/share/exam-c/check.lst
chmod 755 /usr/local/bin/northcheck
/usr/local/bin/northcheck
```

---

## Question 19 - Swap Space (clientvm) - 4 pts

```bash
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 701MiB
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
uuid=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
```

---

## Question 20 - Resize Existing LV (clientvm) - 4 pts

```bash
lvextend -L 340M /dev/reviewvgc/reviewc
resize2fs /dev/reviewvgc/reviewc
```

---

## Question 21 - Rootless Container (clientvm) - 4 pts

```bash
su - eirac
cd /opt/rhcsa/workspaces/exam-c
podman build -t localhost/northstar-web:latest .
podman run -d --name pdfc -v /opt/inc:/data/input:Z -v /opt/outc:/data/output:Z localhost/northstar-web:latest
exit
```

---

## Question 22 - Container Autostart (clientvm) - 4 pts

```bash
su - eirac
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
podman generate systemd --name pdfc --files --new
systemctl --user daemon-reload
systemctl --user enable --now container-pdfc.service
exit
loginctl enable-linger eirac
```
