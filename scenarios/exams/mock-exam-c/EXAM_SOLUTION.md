# Mock Exam C: NorthStar Recovery Review

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
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

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
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.28/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
hostnamectl set-hostname clientvm.northstar.lab
```

---

## Question 03 - Bootloader Kernel Argument (clientvm) - 5 pts

```bash
grubby --update-kernel=ALL --args="audit_backlog_limit=8192"
```

---

## Question 04 - Host Entry (clientvm) - 5 pts

```bash
grep -q 'vault.northstar.lab' /etc/hosts || echo '192.168.122.3 vault.northstar.lab' >> /etc/hosts
```

---

## Question 05 - Direct NFS Mount (clientvm) - 5 pts

```bash
mkdir -p /mnt/bluec
grep -q '/mnt/bluec' /etc/fstab || echo 'servervm:/exports/bluec /mnt/bluec nfs defaults,_netdev 0 0' >> /etc/fstab
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
install -d -m 2770 -o root -g infrac /srv/infrac
setfacl -d -m g:infrac:rwx /srv/infrac
```

---

## Question 08 - No-Home User (clientvm) - 5 pts

```bash
useradd -M -s /sbin/nologin remote63
```

---

## Question 09 - At Job (clientvm) - 5 pts

```bash
echo 'echo "NorthStar audit" >> /root/northstar-at.log' | at now + 2 minutes
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
echo 'echo NorthStar access' >> /home/ren/.bash_profile
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
fdisk /dev/sdb
# create a 700M GPT partition and set the type to Linux swap
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
blkid /dev/sdb1
vim /etc/fstab
UUID=<uuid-of-sdb1> swap swap defaults 0 0
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

---

## Verification
```bash
hostnamectl --static | grep -qx 'clientvm.northstar.lab' && grep -Fqx '192.168.122.3 vault.northstar.lab' /etc/hosts && grubby --info=ALL | grep -Eq 'args=.*audit_backlog_limit=8192'
mount | grep -Eq 'servervm:/exports/bluec on /mnt/bluec type nfs' && grep -q '/mnt/bluec' /etc/fstab && getent group infrac >/dev/null && id -nG talia | tr ' ' '\n' | grep -qx infrac && id -nG ren | tr ' ' '\n' | grep -qx infrac && getfacl -p /srv/infrac | grep -Fq 'default:group:infrac:rwx' && getent passwd remote63 | awk -F: '{print $6":"$7}' | grep -qx ':/sbin/nologin'
chage -l talia | grep -Eq 'Maximum.*45' && grep -Fqx 'umask 027' /home/ren/.bash_profile && grep -Fqx 'echo NorthStar access' /home/ren/.bash_profile && ssh admin@servervm sudo test -d /var/log/journal
getent passwd kian431 | awk -F: '{print $3}' | grep -qx '4431' && test -f /root/ren-files/opt/exam-c/find/a/file1.txt && grep -q 'orbit' /root/orbit-lines && test -f /root/etc-c.tar.bz2 && /usr/local/bin/northcheck >/dev/null && test -s /root/northstar-services.txt
swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1=="reviewc" && $2=="reviewvgc" && $3>=339 && $3<=341{f=1} END{exit !f}'
runuser -l eirac -c 'podman ps --format {{.Names}}' | grep -qx pdfc && runuser -l eirac -c 'systemctl --user is-enabled container-pdfc.service' | grep -qx enabled && loginctl show-user eirac | grep -Eq '^Linger=yes$'
```
