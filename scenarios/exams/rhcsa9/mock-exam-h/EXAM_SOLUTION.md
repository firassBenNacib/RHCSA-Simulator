# Mock Exam H

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-h` |
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
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.47/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname client-h.exam9.lab
```

---

## Question 03 - Client RPM Repositories (client) - 5 pts

```bash
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 H BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 H AppStream
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
dnf remove -y tcpdump || true
```

---

## Question 05 - Client Users and Group (client) - 5 pts

```bash
getent group opsh9 >/dev/null || groupadd opsh9
id anah9 >/dev/null 2>&1 || useradd -m anah9
id devh9 >/dev/null 2>&1 || useradd -m devh9
id audith9 >/dev/null 2>&1 || useradd -M -s /sbin/nologin audith9
usermod -s /sbin/nologin audith9
echo 'anah9:cinder9\ndevh9:cinder9\naudith9:cinder9' | chpasswd
gpasswd -a anah9 opsh9
gpasswd -a devh9 opsh9
```

---

## Question 06 - Client Password Aging and Sudo (client) - 5 pts

```bash
chage -M 60 -W 7 anah9
echo '%opsh9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/opsh9-systemctl
chmod 0440 /etc/sudoers.d/opsh9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/opsh9-systemctl >/dev/null'
```

---

## Question 07 - Client Shared Directory (client) - 5 pts

```bash
mkdir -p /srv/opsh9
chown root:opsh9 /srv/opsh9
chmod 2770 /srv/opsh9
setfacl -m d:g:opsh9:rwx /srv/opsh9
```

---

## Question 08 - Client Report Script (client) - 5 pts

```bash
cat > /usr/local/bin/report-h9 <<'SCRIPT'
#!/bin/bash
: > /root/report-h9.txt
for service in sshd chronyd firewalld; do
  systemctl is-active "$service" >> /root/report-h9.txt || true
done
SCRIPT
chmod +x /usr/local/bin/report-h9
/usr/local/bin/report-h9
```

---

## Question 09 - Client Swap Persistence (client) - 5 pts

```bash
swapoff /swaph9 >/dev/null 2>&1 || true
sed -i '\#/swaph9#d' /etc/fstab
rm -f /swaph9
dd if=/dev/zero of=/swaph9 bs=1M count=512
chmod 0600 /swaph9
mkswap /swaph9
echo '/swaph9 swap swap defaults 0 0' >> /etc/fstab
swapon /swaph9
```

---

## Question 10 - Client LVM Mount (client) - 5 pts

```bash
umount /mnt/datah9 >/dev/null 2>&1 || true
sed -i '\#/mnt/datah9#d' /etc/fstab
lvremove -ff /dev/vgh9/datah9 >/dev/null 2>&1 || true
vgremove -ff vgh9 >/dev/null 2>&1 || true
pvremove -ff -y /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
parted -s /dev/sdb -- mklabel gpt mkpart primary 1MiB 100%
partprobe /dev/sdb || true
udevadm settle
pvcreate -ff -y /dev/sdb1
vgcreate vgh9 /dev/sdb1
lvcreate -n datah9 -L 320M vgh9
mkfs.xfs -f /dev/vgh9/datah9
mkdir -p /mnt/datah9
uuid=$(blkid -s UUID -o value /dev/vgh9/datah9)
echo "UUID=$uuid /mnt/datah9 xfs defaults 0 0" >> /etc/fstab
mount -a
```

---

## Question 11 - Client Rootless Container (client) - 5 pts

```bash
id podh9 >/dev/null 2>&1 || useradd -m podh9
echo 'podh9:cinder9' | chpasswd
loginctl enable-linger podh9
su - podh9
podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true
podman rm -f webh9 >/dev/null 2>&1 || true
podman run -d --name webh9 localhost/rhcsa-httpd-base:latest
```

---

## Question 12 - Server IPv4 Networking (server) - 5 pts

```bash
# On server:
CONN="System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.3/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname server-h.exam9.lab
```

---

## Question 13 - Server RPM Repositories (server) - 4 pts

```bash
# On server:
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 H BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 H AppStream
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
getent group srvh9 >/dev/null || groupadd srvh9
id svch9 >/dev/null 2>&1 || useradd -m svch9
echo 'svch9:cinder9' | chpasswd
gpasswd -a svch9 srvh9
echo '%srvh9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/srvh9-systemctl
chmod 0440 /etc/sudoers.d/srvh9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/srvh9-systemctl >/dev/null'
```

---

## Question 15 - Server Web Service (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo RHCSA9-H > /var/www/html/exam-h.html
restorecon -v /var/www/html/exam-h.html || true
cat > /etc/httpd/conf.d/exam-h.conf <<'EOF'
Listen 8307
EOF
semanage port -a -t http_port_t -p tcp 8307 2>/dev/null
firewall-cmd --permanent --add-port=8307/tcp
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
cat > /usr/local/sbin/audith9.sh <<'EOF'
#!/bin/bash
echo server-h >> /var/log/audith9.log
EOF
chmod +x /usr/local/sbin/audith9.sh
cat > /etc/cron.d/audith9 <<'EOF'
*/12 * * * * root /usr/local/sbin/audith9.sh
EOF
chmod 644 /etc/cron.d/audith9
systemctl enable --now crond
```

---

## Question 18 - Server Boot Target and Directory (server) - 4 pts

```bash
# On server:
systemctl set-default multi-user.target
getent group srvh9 >/dev/null || groupadd srvh9
mkdir -p /srv/server-h9
chown root:srvh9 /srv/server-h9
chmod 2770 /srv/server-h9
```

---

## Question 19 - Client Server NFS Mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/rhcsa9-h
echo exam-h > /exports/rhcsa9-h/README
cat > /etc/exports.d/rhcsa9-h.exports <<'EOF'
/exports/rhcsa9-h 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/rhcsa9-h
grep -Eq '^server:/exports/rhcsa9-h[[:space:]]+/mnt/rhcsa9-h[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/rhcsa9-h /mnt/rhcsa9-h nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 20 - Client Server SSH Key (client + server) - 4 pts

```bash
# On server:
id copyh9 >/dev/null 2>&1 || useradd -m copyh9
echo 'copyh9:cinder9' | chpasswd
# On client:
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa9-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub copyh9@server
```

---

## Question 21 - Client Server Secure Copy (client + server) - 4 pts

```bash
echo RHCSA9-H > /root/exam-h-copy.txt
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-h-copy.txt copyh9@server:/home/copyh9/exam-h-copy.txt
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
