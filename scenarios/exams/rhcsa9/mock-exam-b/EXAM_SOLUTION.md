# Mock Exam B

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-b` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, networking-and-firewall, software-management, users-sudo-ssh, storage-lvm, containers |

A 22-task RHCSA9 mock exam covering persistent networking, repositories, users, services, storage, NFS, SSH, and rootless containers across client and server.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Root recovery (client) - 5 pts

```bash
# At the boot menu, edit the selected kernel entry.
# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.
passwd root
# enter: cinder9
touch /.autorelabel
exec /sbin/init
```

---

## Question 02 - Client IPv4 networking (client) - 5 pts

```bash
CONN="System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.41/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname client-b.exam9.lab
```

---

## Question 03 - Client RPM repositories (client) - 5 pts

```bash
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 B BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 B AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 04 - Client package management (client) - 5 pts

```bash
dnf install -y lsof
dnf remove -y tcpdump || true
```

---

## Question 05 - Client users and group (client) - 5 pts

```bash
getent group opsb9 >/dev/null || groupadd opsb9
id anab9 >/dev/null 2>&1 || useradd -m anab9
id devb9 >/dev/null 2>&1 || useradd -m devb9
id auditb9 >/dev/null 2>&1 || useradd -M -s /sbin/nologin auditb9
usermod -s /sbin/nologin auditb9
echo 'anab9:cinder9\ndevb9:cinder9\nauditb9:cinder9' | chpasswd
gpasswd -a anab9 opsb9
gpasswd -a devb9 opsb9
```

---

## Question 06 - Client password aging and sudo (client) - 5 pts

```bash
chage -M 60 -W 7 anab9
echo '%opsb9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/opsb9-systemctl
chmod 0440 /etc/sudoers.d/opsb9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/opsb9-systemctl >/dev/null'
```

---

## Question 07 - Client shared directory (client) - 5 pts

```bash
mkdir -p /srv/opsb9
chown root:opsb9 /srv/opsb9
chmod 2770 /srv/opsb9
setfacl -m d:g:opsb9:rwx /srv/opsb9
```

---

## Question 08 - Client archive and filter (client) - 5 pts

```bash
rm -rf /root/review-b9 /root/review-b9.tar.bz2 /root/passwd-root-b9.txt
mkdir -p /root/review-b9
cp /etc/passwd /etc/profile /root/review-b9/
tar -cjf /root/review-b9.tar.bz2 -C /root review-b9
grep '^root:' /etc/passwd > /root/passwd-root-b9.txt
echo 'birch beacon report' >> /root/passwd-root-b9.txt
```

---

## Question 09 - Client swap persistence (client) - 5 pts

```bash
swapoff /swapb9 >/dev/null 2>&1 || true
sed -i '\#/swapb9#d' /etc/fstab
rm -f /swapb9
dd if=/dev/zero of=/swapb9 bs=1M count=512
chmod 0600 /swapb9
mkswap /swapb9
echo '/swapb9 swap swap defaults 0 0' >> /etc/fstab
swapon /swapb9
```

---

## Question 10 - Client LVM mount (client) - 5 pts

```bash
umount /mnt/datab9 >/dev/null 2>&1 || true
sed -i '\#/mnt/datab9#d' /etc/fstab
lvremove -ff /dev/vgb9/datab9 >/dev/null 2>&1 || true
vgremove -ff vgb9 >/dev/null 2>&1 || true
pvremove -ff -y /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
parted -s /dev/sdb -- mklabel gpt mkpart primary 1MiB 100%
partprobe /dev/sdb || true
udevadm settle
pvcreate -ff -y /dev/sdb1
vgcreate vgb9 /dev/sdb1
lvcreate -n datab9 -L 320M vgb9
mkfs.xfs -f /dev/vgb9/datab9
mkdir -p /mnt/datab9
uuid=$(blkid -s UUID -o value /dev/vgb9/datab9)
echo "UUID=$uuid /mnt/datab9 xfs defaults 0 0" >> /etc/fstab
mount -a
```

---

## Question 11 - Client rootless container (client) - 5 pts

```bash
id podb9 >/dev/null 2>&1 || useradd -m podb9
echo 'podb9:cinder9' | chpasswd
loginctl enable-linger podb9
su - podb9
podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true
podman rm -f webb9 >/dev/null 2>&1 || true
podman run -d --name webb9 localhost/rhcsa-httpd-base:latest
```

---

## Question 12 - Server IPv4 networking (server) - 5 pts

```bash
# On server:
CONN="System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.3/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname server-b.exam9.lab
```

---

## Question 13 - Server RPM repositories (server) - 4 pts

```bash
# On server:
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 B BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 B AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 14 - Server user and sudo (server) - 4 pts

```bash
# On server:
getent group srvb9 >/dev/null || groupadd srvb9
id svcb9 >/dev/null 2>&1 || useradd -m svcb9
echo 'svcb9:cinder9' | chpasswd
gpasswd -a svcb9 srvb9
echo '%srvb9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/srvb9-systemctl
chmod 0440 /etc/sudoers.d/srvb9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/srvb9-systemctl >/dev/null'
```

---

## Question 15 - Server web service (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo 'birch delta web' > /var/www/html/exam-b.html
restorecon -v /var/www/html/exam-b.html || true
cat > /etc/httpd/conf.d/exam-b.conf <<'EOF'
Listen 8301
EOF
semanage port -a -t http_port_t -p tcp 8301 2>/dev/null
firewall-cmd --permanent --add-port=8301/tcp
firewall-cmd --reload
systemctl enable --now httpd
systemctl restart httpd
```

---

## Question 16 - Server persistent journal (server) - 4 pts

```bash
# On server:
mkdir -p /var/log/journal /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
journalctl --flush
```

---

## Question 17 - Server cron schedule (server) - 4 pts

```bash
# On server:
cat > /usr/local/sbin/auditb9.sh <<'EOF'
#!/bin/bash
echo 'birch relay cron' >> /var/log/auditb9.log
EOF
chmod +x /usr/local/sbin/auditb9.sh
cat > /etc/cron.d/auditb9 <<'EOF'
*/6 * * * * root /usr/local/sbin/auditb9.sh
EOF
chmod 644 /etc/cron.d/auditb9
systemctl enable --now crond
```

---

## Question 18 - Server boot target and directory (server) - 4 pts

```bash
# On server:
systemctl set-default multi-user.target
getent group srvb9 >/dev/null || groupadd srvb9
mkdir -p /srv/server-b9
chown root:srvb9 /srv/server-b9
chmod 2770 /srv/server-b9
```

---

## Question 19 - Client server NFS mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/rhcsa9-b
echo 'birch storage export' > /exports/rhcsa9-b/README
cat > /etc/exports.d/rhcsa9-b.exports <<'EOF'
/exports/rhcsa9-b 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/rhcsa9-b
grep -Eq '^server:/exports/rhcsa9-b[[:space:]]+/mnt/rhcsa9-b[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/rhcsa9-b /mnt/rhcsa9-b nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 20 - Client server SSH key (client + server) - 4 pts

```bash
# On server:
id copyb9 >/dev/null 2>&1 || useradd -m copyb9
echo 'copyb9:cinder9' | chpasswd
# On client:
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa9-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub copyb9@server
```

---

## Question 21 - Client server rsync transfer (client + server) - 4 pts

```bash
dnf install -y rsync >/dev/null 2>&1 || true
echo 'birch archive transfer' > /root/exam-b-rsync.txt
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 copyb9@server 'mkdir -p /home/copyb9/inbox'
rsync -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519' /root/exam-b-rsync.txt copyb9@server:/home/copyb9/inbox/exam-b-rsync.txt
```

---

## Question 22 - Client server time sync (client + server) - 4 pts

```bash
# On server:
systemctl enable --now chronyd
firewall-cmd --permanent --add-service=ntp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
# On client:
cat > /etc/chrony.conf <<'EOF'
server server iburst
makestep 1.0 3
EOF
systemctl enable --now chronyd
```
