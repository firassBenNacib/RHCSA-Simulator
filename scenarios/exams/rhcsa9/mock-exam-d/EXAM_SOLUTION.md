# Mock Exam D

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-d` |
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
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.43/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname client-d.exam9.lab
```

---

## Question 03 - Client RPM Repositories (client) - 5 pts

```bash
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 D BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 D AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 04 - Client Package Management (client) - 5 pts

```bash
dnf install -y tree
dnf remove -y tcpdump || true
```

---

## Question 05 - Client Users and Group (client) - 5 pts

```bash
getent group opsd9 >/dev/null || groupadd opsd9
id anad9 >/dev/null 2>&1 || useradd -m anad9
id devd9 >/dev/null 2>&1 || useradd -m devd9
id auditd9 >/dev/null 2>&1 || useradd -M -s /sbin/nologin auditd9
usermod -s /sbin/nologin auditd9
echo 'anad9:cinder9\ndevd9:cinder9\nauditd9:cinder9' | chpasswd
gpasswd -a anad9 opsd9
gpasswd -a devd9 opsd9
```

---

## Question 06 - Client Password Aging and Sudo (client) - 5 pts

```bash
chage -M 60 -W 7 anad9
echo '%opsd9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/opsd9-systemctl
chmod 0440 /etc/sudoers.d/opsd9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/opsd9-systemctl >/dev/null'
```

---

## Question 07 - Client Shared Directory (client) - 5 pts

```bash
mkdir -p /srv/opsd9
chown root:opsd9 /srv/opsd9
chmod 2770 /srv/opsd9
setfacl -m d:g:opsd9:rwx /srv/opsd9
```

---

## Question 08 - Client Report Script (client) - 5 pts

```bash
cat > /usr/local/bin/report-d9 <<'SCRIPT'
#!/bin/bash
: > /root/report-d9.txt
for service in sshd chronyd firewalld; do
  systemctl is-active "$service" >> /root/report-d9.txt || true
done
SCRIPT
chmod +x /usr/local/bin/report-d9
/usr/local/bin/report-d9
```

---

## Question 09 - Client Swap Persistence (client) - 5 pts

```bash
swapoff /swapd9 >/dev/null 2>&1 || true
sed -i '\#/swapd9#d' /etc/fstab
rm -f /swapd9
dd if=/dev/zero of=/swapd9 bs=1M count=512
chmod 0600 /swapd9
mkswap /swapd9
echo '/swapd9 swap swap defaults 0 0' >> /etc/fstab
swapon /swapd9
```

---

## Question 10 - Client LVM Mount (client) - 5 pts

```bash
umount /mnt/datad9 >/dev/null 2>&1 || true
sed -i '\#/mnt/datad9#d' /etc/fstab
lvremove -ff /dev/vgd9/datad9 >/dev/null 2>&1 || true
vgremove -ff vgd9 >/dev/null 2>&1 || true
pvremove -ff -y /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
parted -s /dev/sdb -- mklabel gpt mkpart primary 1MiB 100%
partprobe /dev/sdb || true
udevadm settle
pvcreate -ff -y /dev/sdb1
vgcreate vgd9 /dev/sdb1
lvcreate -n datad9 -L 320M vgd9
mkfs.xfs -f /dev/vgd9/datad9
mkdir -p /mnt/datad9
uuid=$(blkid -s UUID -o value /dev/vgd9/datad9)
echo "UUID=$uuid /mnt/datad9 xfs defaults 0 0" >> /etc/fstab
mount -a
```

---

## Question 11 - Client Rootless Container (client) - 5 pts

```bash
id podd9 >/dev/null 2>&1 || useradd -m podd9
echo 'podd9:cinder9' | chpasswd
loginctl enable-linger podd9
su - podd9
podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true
podman rm -f webd9 >/dev/null 2>&1 || true
podman run -d --name webd9 localhost/rhcsa-httpd-base:latest
```

---

## Question 12 - Server IPv4 Networking (server) - 5 pts

```bash
# On server:
CONN="System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.3/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname server-d.exam9.lab
```

---

## Question 13 - Server RPM Repositories (server) - 4 pts

```bash
# On server:
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 D BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 D AppStream
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
getent group srvd9 >/dev/null || groupadd srvd9
id svcd9 >/dev/null 2>&1 || useradd -m svcd9
echo 'svcd9:cinder9' | chpasswd
gpasswd -a svcd9 srvd9
echo '%srvd9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/srvd9-systemctl
chmod 0440 /etc/sudoers.d/srvd9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/srvd9-systemctl >/dev/null'
```

---

## Question 15 - Server Web Service (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo RHCSA9-D > /var/www/html/exam-d.html
restorecon -v /var/www/html/exam-d.html || true
cat > /etc/httpd/conf.d/exam-d.conf <<'EOF'
Listen 8303
EOF
semanage port -a -t http_port_t -p tcp 8303 2>/dev/null
firewall-cmd --permanent --add-port=8303/tcp
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

## Question 17 - Server Systemd Timer (server) - 4 pts

```bash
# On server:
cat > /usr/local/sbin/auditd9.sh <<'EOF'
#!/bin/bash
echo server-d >> /var/log/auditd9.log
EOF
chmod +x /usr/local/sbin/auditd9.sh
cat > /etc/systemd/system/auditd9.service <<'EOF'
[Unit]
Description=Server D audit marker
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/auditd9.sh
EOF
cat > /etc/systemd/system/auditd9.timer <<'EOF'
[Unit]
Description=Run server D audit marker
[Timer]
OnCalendar=*:0/8
Persistent=true
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now auditd9.timer
```

---

## Question 18 - Server Boot Target and Directory (server) - 4 pts

```bash
# On server:
systemctl set-default multi-user.target
getent group srvd9 >/dev/null || groupadd srvd9
mkdir -p /srv/server-d9
chown root:srvd9 /srv/server-d9
chmod 2770 /srv/server-d9
```

---

## Question 19 - Client Server NFS Mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/rhcsa9-d
echo exam-d > /exports/rhcsa9-d/README
cat > /etc/exports.d/rhcsa9-d.exports <<'EOF'
/exports/rhcsa9-d 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/rhcsa9-d
grep -Eq '^server:/exports/rhcsa9-d[[:space:]]+/mnt/rhcsa9-d[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/rhcsa9-d /mnt/rhcsa9-d nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 20 - Client Server SSH Key (client + server) - 4 pts

```bash
# On server:
id copyd9 >/dev/null 2>&1 || useradd -m copyd9
echo 'copyd9:cinder9' | chpasswd
# On client:
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa9-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub copyd9@server
```

---

## Question 21 - Client Server Secure Copy (client + server) - 4 pts

```bash
echo RHCSA9-D > /root/exam-d-copy.txt
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-d-copy.txt copyd9@server:/home/copyd9/exam-d-copy.txt
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
