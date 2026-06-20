# Mock Exam G

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-g` |
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
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.46/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname client-g.exam9.lab
```

---

## Question 03 - Client RPM repositories (client) - 5 pts

```bash
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 G BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 G AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 04 - Client package management (client) - 5 pts

```bash
dnf install -y tree
dnf remove -y dos2unix || true
```

---

## Question 05 - Client users and group (client) - 5 pts

```bash
getent group opsg9 >/dev/null || groupadd opsg9
id anag9 >/dev/null 2>&1 || useradd -m anag9
id devg9 >/dev/null 2>&1 || useradd -m devg9
id auditg9 >/dev/null 2>&1 || useradd -M -s /sbin/nologin auditg9
usermod -s /sbin/nologin auditg9
echo 'anag9:cinder9\ndevg9:cinder9\nauditg9:cinder9' | chpasswd
gpasswd -a anag9 opsg9
gpasswd -a devg9 opsg9
```

---

## Question 06 - Client password aging and sudo (client) - 5 pts

```bash
chage -M 60 -W 7 anag9
echo '%opsg9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/opsg9-systemctl
chmod 0440 /etc/sudoers.d/opsg9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/opsg9-systemctl >/dev/null'
```

---

## Question 07 - Client shared directory (client) - 5 pts

```bash
mkdir -p /srv/opsg9
chown root:opsg9 /srv/opsg9
chmod 2770 /srv/opsg9
setfacl -m d:g:opsg9:rwx /srv/opsg9
```

---

## Question 08 - Client report script (client) - 5 pts

```bash
cat > /usr/local/bin/report-g9 <<'SCRIPT'
#!/bin/bash
echo 'glacier iris report' > /root/report-g9.txt
for service in sshd chronyd firewalld; do
  systemctl is-active "$service" >> /root/report-g9.txt || true
done
SCRIPT
chmod +x /usr/local/bin/report-g9
/usr/local/bin/report-g9
```

---

## Question 09 - Client swap persistence (client) - 5 pts

```bash
swapoff /swapg9 >/dev/null 2>&1 || true
sed -i '\#/swapg9#d' /etc/fstab
rm -f /swapg9
dd if=/dev/zero of=/swapg9 bs=1M count=512
chmod 0600 /swapg9
mkswap /swapg9
echo '/swapg9 swap swap defaults 0 0' >> /etc/fstab
swapon /swapg9
```

---

## Question 10 - Client LVM mount (client) - 5 pts

```bash
umount /mnt/datag9 >/dev/null 2>&1 || true
sed -i '\#/mnt/datag9#d' /etc/fstab
lvremove -ff /dev/vgg9/datag9 >/dev/null 2>&1 || true
vgremove -ff vgg9 >/dev/null 2>&1 || true
pvremove -ff -y /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
parted -s /dev/sdb -- mklabel gpt mkpart primary 1MiB 100%
partprobe /dev/sdb || true
udevadm settle
pvcreate -ff -y /dev/sdb1
vgcreate vgg9 /dev/sdb1
lvcreate -n datag9 -L 320M vgg9
mkfs.xfs -f /dev/vgg9/datag9
mkdir -p /mnt/datag9
uuid=$(blkid -s UUID -o value /dev/vgg9/datag9)
echo "UUID=$uuid /mnt/datag9 xfs defaults 0 0" >> /etc/fstab
mount -a
```

---

## Question 11 - Client rootless container (client) - 5 pts

```bash
id podg9 >/dev/null 2>&1 || useradd -m podg9
echo 'podg9:cinder9' | chpasswd
loginctl enable-linger podg9
su - podg9
podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true
podman rm -f webg9 >/dev/null 2>&1 || true
podman run -d --name webg9 localhost/rhcsa-httpd-base:latest
```

---

## Question 12 - Server IPv4 networking (server) - 5 pts

```bash
# On server:
CONN="System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.3/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname server-g.exam9.lab
```

---

## Question 13 - Server RPM repositories (server) - 4 pts

```bash
# On server:
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 G BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 G AppStream
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
getent group srvg9 >/dev/null || groupadd srvg9
id svcg9 >/dev/null 2>&1 || useradd -m svcg9
echo 'svcg9:cinder9' | chpasswd
gpasswd -a svcg9 srvg9
echo '%srvg9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/srvg9-systemctl
chmod 0440 /etc/sudoers.d/srvg9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/srvg9-systemctl >/dev/null'
```

---

## Question 15 - Server web service (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo 'glacier status web' > /var/www/html/exam-g.html
restorecon -v /var/www/html/exam-g.html || true
cat > /etc/httpd/conf.d/exam-g.conf <<'EOF'
Listen 8306
EOF
semanage port -a -t http_port_t -p tcp 8306 2>/dev/null
firewall-cmd --permanent --add-port=8306/tcp
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
cat > /usr/local/sbin/auditg9.sh <<'EOF'
#!/bin/bash
echo 'glacier monitor cron' >> /var/log/auditg9.log
EOF
chmod +x /usr/local/sbin/auditg9.sh
cat > /etc/cron.d/auditg9 <<'EOF'
*/11 * * * * root /usr/local/sbin/auditg9.sh
EOF
chmod 644 /etc/cron.d/auditg9
systemctl enable --now crond
```

---

## Question 18 - Server boot target and directory (server) - 4 pts

```bash
# On server:
systemctl set-default multi-user.target
getent group srvg9 >/dev/null || groupadd srvg9
mkdir -p /srv/server-g9
chown root:srvg9 /srv/server-g9
chmod 2770 /srv/server-g9
```

---

## Question 19 - Client server NFS mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/rhcsa9-g
echo 'glacier project export' > /exports/rhcsa9-g/README
cat > /etc/exports.d/rhcsa9-g.exports <<'EOF'
/exports/rhcsa9-g 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/rhcsa9-g
grep -Eq '^server:/exports/rhcsa9-g[[:space:]]+/mnt/rhcsa9-g[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/rhcsa9-g /mnt/rhcsa9-g nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 20 - Client server SSH key (client + server) - 4 pts

```bash
# On server:
id copyg9 >/dev/null 2>&1 || useradd -m copyg9
echo 'copyg9:cinder9' | chpasswd
# On client:
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa9-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub copyg9@server
```

---

## Question 21 - Client server secure copy (client + server) - 4 pts

```bash
echo 'glacier courier transfer' > /root/exam-g-copy.txt
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-g-copy.txt copyg9@server:/home/copyg9/exam-g-copy.txt
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
