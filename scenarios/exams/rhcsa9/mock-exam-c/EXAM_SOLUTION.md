# Mock Exam C

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-c` |
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
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.42/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname client-c.exam9.lab
```

---

## Question 03 - Client RPM Repositories (client) - 5 pts

```bash
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 C BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 C AppStream
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
getent group opsc9 >/dev/null || groupadd opsc9
id anac9 >/dev/null 2>&1 || useradd -m anac9
id devc9 >/dev/null 2>&1 || useradd -m devc9
id auditc9 >/dev/null 2>&1 || useradd -M -s /sbin/nologin auditc9
usermod -s /sbin/nologin auditc9
echo 'anac9:cinder9\ndevc9:cinder9\nauditc9:cinder9' | chpasswd
gpasswd -a anac9 opsc9
gpasswd -a devc9 opsc9
```

---

## Question 06 - Client Password Aging and Sudo (client) - 5 pts

```bash
chage -M 60 -W 7 anac9
echo '%opsc9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/opsc9-systemctl
chmod 0440 /etc/sudoers.d/opsc9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/opsc9-systemctl >/dev/null'
```

---

## Question 07 - Client Shared Directory (client) - 5 pts

```bash
mkdir -p /srv/opsc9
chown root:opsc9 /srv/opsc9
chmod 2770 /srv/opsc9
setfacl -m d:g:opsc9:rwx /srv/opsc9
```

---

## Question 08 - Client Report Script (client) - 5 pts

```bash
cat > /usr/local/bin/report-c9 <<'SCRIPT'
#!/bin/bash
: > /root/report-c9.txt
for service in sshd chronyd firewalld; do
  systemctl is-active "$service" >> /root/report-c9.txt || true
done
SCRIPT
chmod +x /usr/local/bin/report-c9
/usr/local/bin/report-c9
```

---

## Question 09 - Client Swap Persistence (client) - 5 pts

```bash
swapoff /swapc9 >/dev/null 2>&1 || true
sed -i '\#/swapc9#d' /etc/fstab
rm -f /swapc9
dd if=/dev/zero of=/swapc9 bs=1M count=512
chmod 0600 /swapc9
mkswap /swapc9
echo '/swapc9 swap swap defaults 0 0' >> /etc/fstab
swapon /swapc9
```

---

## Question 10 - Client LVM Mount (client) - 5 pts

```bash
umount /mnt/datac9 >/dev/null 2>&1 || true
sed -i '\#/mnt/datac9#d' /etc/fstab
lvremove -ff /dev/vgc9/datac9 >/dev/null 2>&1 || true
vgremove -ff vgc9 >/dev/null 2>&1 || true
pvremove -ff -y /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
parted -s /dev/sdb -- mklabel gpt mkpart primary 1MiB 100%
partprobe /dev/sdb || true
udevadm settle
pvcreate -ff -y /dev/sdb1
vgcreate vgc9 /dev/sdb1
lvcreate -n datac9 -L 320M vgc9
mkfs.xfs -f /dev/vgc9/datac9
mkdir -p /mnt/datac9
uuid=$(blkid -s UUID -o value /dev/vgc9/datac9)
echo "UUID=$uuid /mnt/datac9 xfs defaults 0 0" >> /etc/fstab
mount -a
```

---

## Question 11 - Client Rootless Container (client) - 5 pts

```bash
id podc9 >/dev/null 2>&1 || useradd -m podc9
echo 'podc9:cinder9' | chpasswd
loginctl enable-linger podc9
su - podc9
podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true
podman rm -f webc9 >/dev/null 2>&1 || true
podman run -d --name webc9 localhost/rhcsa-httpd-base:latest
```

---

## Question 12 - Server IPv4 Networking (server) - 5 pts

```bash
# On server:
CONN="System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.3/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname server-c.exam9.lab
```

---

## Question 13 - Server RPM Repositories (server) - 4 pts

```bash
# On server:
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 C BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 C AppStream
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
getent group srvc9 >/dev/null || groupadd srvc9
id svcc9 >/dev/null 2>&1 || useradd -m svcc9
echo 'svcc9:cinder9' | chpasswd
gpasswd -a svcc9 srvc9
echo '%srvc9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/srvc9-systemctl
chmod 0440 /etc/sudoers.d/srvc9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/srvc9-systemctl >/dev/null'
```

---

## Question 15 - Server Web Service (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo RHCSA9-C > /var/www/html/exam-c.html
restorecon -v /var/www/html/exam-c.html || true
cat > /etc/httpd/conf.d/exam-c.conf <<'EOF'
Listen 8302
EOF
semanage port -a -t http_port_t -p tcp 8302 2>/dev/null
firewall-cmd --permanent --add-port=8302/tcp
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
cat > /usr/local/sbin/auditc9.sh <<'EOF'
#!/bin/bash
echo server-c >> /var/log/auditc9.log
EOF
chmod +x /usr/local/sbin/auditc9.sh
cat > /etc/cron.d/auditc9 <<'EOF'
*/7 * * * * root /usr/local/sbin/auditc9.sh
EOF
chmod 644 /etc/cron.d/auditc9
systemctl enable --now crond
```

---

## Question 18 - Server Boot Target and Directory (server) - 4 pts

```bash
# On server:
systemctl set-default multi-user.target
getent group srvc9 >/dev/null || groupadd srvc9
mkdir -p /srv/server-c9
chown root:srvc9 /srv/server-c9
chmod 2770 /srv/server-c9
```

---

## Question 19 - Client Server NFS Mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/rhcsa9-c
echo exam-c > /exports/rhcsa9-c/README
cat > /etc/exports.d/rhcsa9-c.exports <<'EOF'
/exports/rhcsa9-c 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/rhcsa9-c
grep -Eq '^server:/exports/rhcsa9-c[[:space:]]+/mnt/rhcsa9-c[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/rhcsa9-c /mnt/rhcsa9-c nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 20 - Client Server SSH Key (client + server) - 4 pts

```bash
# On server:
id copyc9 >/dev/null 2>&1 || useradd -m copyc9
echo 'copyc9:cinder9' | chpasswd
# On client:
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa9-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub copyc9@server
```

---

## Question 21 - Client Server Secure Copy (client + server) - 4 pts

```bash
echo RHCSA9-C > /root/exam-c-copy.txt
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-c-copy.txt copyc9@server:/home/copyc9/exam-c-copy.txt
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
