# Mock Exam F

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-f` |
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
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.45/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname client-f.exam9.lab
```

---

## Question 03 - Client RPM repositories (client) - 5 pts

```bash
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 F BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 F AppStream
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
getent group opsf9 >/dev/null || groupadd opsf9
id anaf9 >/dev/null 2>&1 || useradd -m anaf9
id devf9 >/dev/null 2>&1 || useradd -m devf9
id auditf9 >/dev/null 2>&1 || useradd -M -s /sbin/nologin auditf9
usermod -s /sbin/nologin auditf9
echo 'anaf9:cinder9\ndevf9:cinder9\nauditf9:cinder9' | chpasswd
gpasswd -a anaf9 opsf9
gpasswd -a devf9 opsf9
```

---

## Question 06 - Client password aging and sudo (client) - 5 pts

```bash
chage -M 60 -W 7 anaf9
echo '%opsf9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/opsf9-systemctl
chmod 0440 /etc/sudoers.d/opsf9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/opsf9-systemctl >/dev/null'
```

---

## Question 07 - Client shared directory (client) - 5 pts

```bash
mkdir -p /srv/opsf9
chown root:opsf9 /srv/opsf9
chmod 2770 /srv/opsf9
setfacl -m d:g:opsf9:rwx /srv/opsf9
```

---

## Question 08 - Client report script (client) - 5 pts

```bash
cat > /usr/local/bin/report-f9 <<'SCRIPT'
#!/bin/bash
echo 'falcon grove report' > /root/report-f9.txt
for service in sshd chronyd firewalld; do
  systemctl is-active "$service" >> /root/report-f9.txt || true
done
SCRIPT
chmod +x /usr/local/bin/report-f9
/usr/local/bin/report-f9
```

---

## Question 09 - Client swap persistence (client) - 5 pts

```bash
swapoff /swapf9 >/dev/null 2>&1 || true
sed -i '\#/swapf9#d' /etc/fstab
rm -f /swapf9
dd if=/dev/zero of=/swapf9 bs=1M count=512
chmod 0600 /swapf9
mkswap /swapf9
echo '/swapf9 swap swap defaults 0 0' >> /etc/fstab
swapon /swapf9
```

---

## Question 10 - Client LVM mount (client) - 5 pts

```bash
umount /mnt/dataf9 >/dev/null 2>&1 || true
sed -i '\#/mnt/dataf9#d' /etc/fstab
lvremove -ff /dev/vgf9/dataf9 >/dev/null 2>&1 || true
vgremove -ff vgf9 >/dev/null 2>&1 || true
pvremove -ff -y /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
parted -s /dev/sdb -- mklabel gpt mkpart primary 1MiB 100%
partprobe /dev/sdb || true
udevadm settle
pvcreate -ff -y /dev/sdb1
vgcreate vgf9 /dev/sdb1
lvcreate -n dataf9 -L 320M vgf9
mkfs.xfs -f /dev/vgf9/dataf9
mkdir -p /mnt/dataf9
uuid=$(blkid -s UUID -o value /dev/vgf9/dataf9)
echo "UUID=$uuid /mnt/dataf9 xfs defaults 0 0" >> /etc/fstab
mount -a
```

---

## Question 11 - Client rootless container (client) - 5 pts

```bash
id podf9 >/dev/null 2>&1 || useradd -m podf9
echo 'podf9:cinder9' | chpasswd
loginctl enable-linger podf9
su - podf9
podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar >/dev/null 2>&1 || true
podman rm -f webf9 >/dev/null 2>&1 || true
podman run -d --name webf9 localhost/rhcsa-httpd-base:latest
```

---

## Question 12 - Server IPv4 networking (server) - 5 pts

```bash
# On server:
CONN="System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.3/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname server-f.exam9.lab
```

---

## Question 13 - Server RPM repositories (server) - 4 pts

```bash
# On server:
cat > /etc/yum.repos.d/rhcsa9-exam.repo <<'EOF'
[rhcsa9-exam-baseos]
name=RHCSA9 F BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa9-exam-appstream]
name=RHCSA9 F AppStream
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
getent group srvf9 >/dev/null || groupadd srvf9
id svcf9 >/dev/null 2>&1 || useradd -m svcf9
echo 'svcf9:cinder9' | chpasswd
gpasswd -a svcf9 srvf9
echo '%srvf9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/srvf9-systemctl
chmod 0440 /etc/sudoers.d/srvf9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/srvf9-systemctl >/dev/null'
```

---

## Question 15 - Server web service (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo 'falcon console web' > /var/www/html/exam-f.html
restorecon -v /var/www/html/exam-f.html || true
cat > /etc/httpd/conf.d/exam-f.conf <<'EOF'
Listen 8305
EOF
semanage port -a -t http_port_t -p tcp 8305 2>/dev/null
firewall-cmd --permanent --add-port=8305/tcp
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
cat > /usr/local/sbin/auditf9.sh <<'EOF'
#!/bin/bash
echo 'falcon keeper cron' >> /var/log/auditf9.log
EOF
chmod +x /usr/local/sbin/auditf9.sh
cat > /etc/cron.d/auditf9 <<'EOF'
*/10 * * * * root /usr/local/sbin/auditf9.sh
EOF
chmod 644 /etc/cron.d/auditf9
systemctl enable --now crond
```

---

## Question 18 - Server boot target and directory (server) - 4 pts

```bash
# On server:
systemctl set-default multi-user.target
getent group srvf9 >/dev/null || groupadd srvf9
mkdir -p /srv/server-f9
chown root:srvf9 /srv/server-f9
chmod 2770 /srv/server-f9
```

---

## Question 19 - Client server NFS mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/rhcsa9-f
echo 'falcon share export' > /exports/rhcsa9-f/README
cat > /etc/exports.d/rhcsa9-f.exports <<'EOF'
/exports/rhcsa9-f 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/rhcsa9-f
grep -Eq '^server:/exports/rhcsa9-f[[:space:]]+/mnt/rhcsa9-f[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/rhcsa9-f /mnt/rhcsa9-f nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 20 - Client server SSH key (client + server) - 4 pts

```bash
# On server:
id copyf9 >/dev/null 2>&1 || useradd -m copyf9
echo 'copyf9:cinder9' | chpasswd
# On client:
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa9-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub copyf9@server
```

---

## Question 21 - Client server secure copy (client + server) - 4 pts

```bash
echo 'falcon route transfer' > /root/exam-f-copy.txt
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-f-copy.txt copyf9@server:/home/copyf9/exam-f-copy.txt
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
