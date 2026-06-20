# Mock Exam E

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-e` |
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

## Question 01 - Root Recovery (client) - 5 pts

```bash
# At the boot menu, edit the selected kernel entry.
# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.
passwd root
# enter: cinder9
touch /.autorelabel
exec /sbin/init
```

---

## Question 02 - Client IPv4 Networking (client) - 5 pts

```bash
CONN="System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.44/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname client-e.exam9.lab
```

---

## Question 03 - Client RPM Repositories (client) - 5 pts

```bash
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 E BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 E AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 04 - Client Package Management (client) - 5 pts

```bash
dnf install -y lsof
dnf remove -y dos2unix || true
```

---

## Question 05 - Client Users and Group (client) - 5 pts

```bash
getent group opse9 >/dev/null || groupadd opse9
id anae9 >/dev/null 2>&1 || useradd -m anae9
id deve9 >/dev/null 2>&1 || useradd -m deve9
id audite9 >/dev/null 2>&1 || useradd -M -s /sbin/nologin audite9
usermod -s /sbin/nologin audite9
echo 'anae9:cinder9\ndeve9:cinder9\naudite9:cinder9' | chpasswd
gpasswd -a anae9 opse9
gpasswd -a deve9 opse9
```

---

## Question 06 - Client Password Aging and Sudo (client) - 5 pts

```bash
chage -M 60 -W 7 anae9
echo '%opse9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/opse9-systemctl
chmod 0440 /etc/sudoers.d/opse9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/opse9-systemctl >/dev/null'
```

---

## Question 07 - Client Shared Directory (client) - 5 pts

```bash
mkdir -p /srv/opse9
chown root:opse9 /srv/opse9
chmod 2770 /srv/opse9
setfacl -m d:g:opse9:rwx /srv/opse9
```

---

## Question 08 - Client Report Script (client) - 5 pts

```bash
cat > /usr/local/bin/report-e9 <<'SCRIPT'
#!/bin/bash
echo 'ember frost report' > /root/report-e9.txt
for service in sshd chronyd firewalld; do
  systemctl is-active "$service" >> /root/report-e9.txt || true
done
SCRIPT
chmod +x /usr/local/bin/report-e9
/usr/local/bin/report-e9
```

---

## Question 09 - Client Swap Persistence (client) - 5 pts

```bash
swapoff /swape9 >/dev/null 2>&1 || true
sed -i '\#/swape9#d' /etc/fstab
rm -f /swape9
dd if=/dev/zero of=/swape9 bs=1M count=512
chmod 0600 /swape9
mkswap /swape9
echo '/swape9 swap swap defaults 0 0' >> /etc/fstab
swapon /swape9
```

---

## Question 10 - Client LVM Mount (client) - 5 pts

```bash
umount /mnt/datae9 >/dev/null 2>&1 || true
sed -i '\#/mnt/datae9#d' /etc/fstab
lvremove -ff /dev/vge9/datae9 >/dev/null 2>&1 || true
vgremove -ff vge9 >/dev/null 2>&1 || true
pvremove -ff -y /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
parted -s /dev/sdb -- mklabel gpt mkpart primary 1MiB 100%
partprobe /dev/sdb || true
udevadm settle
pvcreate -ff -y /dev/sdb1
vgcreate vge9 /dev/sdb1
lvcreate -n datae9 -L 320M vge9
mkfs.xfs -f /dev/vge9/datae9
mkdir -p /mnt/datae9
uuid=$(blkid -s UUID -o value /dev/vge9/datae9)
echo "UUID=$uuid /mnt/datae9 xfs defaults 0 0" >> /etc/fstab
mount -a
```

---

## Question 11 - Client Rootless Container (client) - 5 pts

```bash
id pode9 >/dev/null 2>&1 || useradd -m pode9
echo 'pode9:cinder9' | chpasswd
loginctl enable-linger pode9
su - pode9
podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true
podman rm -f webe9 >/dev/null 2>&1 || true
podman run -d --name webe9 localhost/rhcsa-httpd-base:latest
```

---

## Question 12 - Server IPv4 Networking (server) - 5 pts

```bash
# On server:
CONN="System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.3/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname server-e.exam9.lab
```

---

## Question 13 - Server RPM Repositories (server) - 4 pts

```bash
# On server:
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 E BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 E AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 14 - Server User and Sudo (server) - 4 pts

```bash
# On server:
getent group srve9 >/dev/null || groupadd srve9
id svce9 >/dev/null 2>&1 || useradd -m svce9
echo 'svce9:cinder9' | chpasswd
gpasswd -a svce9 srve9
echo '%srve9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/srve9-systemctl
chmod 0440 /etc/sudoers.d/srve9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/srve9-systemctl >/dev/null'
```

---

## Question 15 - Server Web Service (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo 'ember service web' > /var/www/html/exam-e.html
restorecon -v /var/www/html/exam-e.html || true
cat > /etc/httpd/conf.d/exam-e.conf <<'EOF'
Listen 8304
EOF
semanage port -a -t http_port_t -p tcp 8304 2>/dev/null
firewall-cmd --permanent --add-port=8304/tcp
firewall-cmd --reload
systemctl enable --now httpd
systemctl restart httpd
```

---

## Question 16 - Server Persistent Journal (server) - 4 pts

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

## Question 17 - Server Cron Schedule (server) - 4 pts

```bash
# On server:
cat > /usr/local/sbin/audite9.sh <<'EOF'
#!/bin/bash
echo 'ember audit cron' >> /var/log/audite9.log
EOF
chmod +x /usr/local/sbin/audite9.sh
cat > /etc/cron.d/audite9 <<'EOF'
*/9 * * * * root /usr/local/sbin/audite9.sh
EOF
chmod 644 /etc/cron.d/audite9
systemctl enable --now crond
```

---

## Question 18 - Server Boot Target and Directory (server) - 4 pts

```bash
# On server:
systemctl set-default multi-user.target
getent group srve9 >/dev/null || groupadd srve9
mkdir -p /srv/server-e9
chown root:srve9 /srv/server-e9
chmod 2770 /srv/server-e9
```

---

## Question 19 - Client Server NFS Mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/rhcsa9-e
echo 'ember depot export' > /exports/rhcsa9-e/README
cat > /etc/exports.d/rhcsa9-e.exports <<'EOF'
/exports/rhcsa9-e 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/rhcsa9-e
grep -Eq '^server:/exports/rhcsa9-e[[:space:]]+/mnt/rhcsa9-e[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/rhcsa9-e /mnt/rhcsa9-e nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 20 - Client Server SSH Key (client + server) - 4 pts

```bash
# On server:
id copye9 >/dev/null 2>&1 || useradd -m copye9
echo 'copye9:cinder9' | chpasswd
# On client:
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa9-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub copye9@server
```

---

## Question 21 - Client Server Secure Copy (client + server) - 4 pts

```bash
echo 'ember vault transfer' > /root/exam-e-copy.txt
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-e-copy.txt copye9@server:/home/copye9/exam-e-copy.txt
```

---

## Question 22 - Client Server Time Sync (client + server) - 4 pts

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
