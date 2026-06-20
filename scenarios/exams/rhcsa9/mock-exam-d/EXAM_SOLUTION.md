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
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.43/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname client-d.exam9.lab
```

---

## Question 03 - Client RPM repositories (client) - 5 pts

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

## Question 04 - Client package management (client) - 5 pts

```bash
dnf install -y tree
dnf remove -y tcpdump || true
```

---

## Question 05 - Client users and group (client) - 5 pts

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

## Question 06 - Client password aging and sudo (client) - 5 pts

```bash
chage -M 60 -W 7 anad9
echo '%opsd9 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/opsd9-systemctl
chmod 0440 /etc/sudoers.d/opsd9-systemctl
bash -c 'visudo -cf /etc/sudoers.d/opsd9-systemctl >/dev/null'
```

---

## Question 07 - Client shared directory (client) - 5 pts

```bash
mkdir -p /srv/opsd9
chown root:opsd9 /srv/opsd9
chmod 2770 /srv/opsd9
setfacl -m d:g:opsd9:rwx /srv/opsd9
```

---

## Question 08 - Client report script (client) - 5 pts

```bash
cat > /usr/local/bin/report-d9 <<'SCRIPT'
#!/bin/bash
echo 'drift ember report' > /root/report-d9.txt
for service in sshd chronyd firewalld; do
  systemctl is-active "$service" >> /root/report-d9.txt || true
done
SCRIPT
chmod +x /usr/local/bin/report-d9
/usr/local/bin/report-d9
```

---

## Question 09 - Client swap persistence (client) - 5 pts

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

## Question 10 - Client LVM mount (client) - 5 pts

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

## Question 11 - Client rootless container (client) - 5 pts

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

## Question 12 - Server IPv4 networking (server) - 5 pts

```bash
# On server:
CONN="System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.3/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
hostnamectl set-hostname server-d.exam9.lab
```

---

## Question 13 - Server RPM repositories (server) - 4 pts

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

## Question 14 - Server user and sudo (server) - 4 pts

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

## Question 15 - Server web service (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo 'drift portal web' > /var/www/html/exam-d.html
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
cat > /usr/local/sbin/auditd9.sh <<'EOF'
#!/bin/bash
echo 'drift watch cron' >> /var/log/auditd9.log
EOF
chmod +x /usr/local/sbin/auditd9.sh
cat > /etc/cron.d/auditd9 <<'EOF'
*/8 * * * * root /usr/local/sbin/auditd9.sh
EOF
chmod 644 /etc/cron.d/auditd9
systemctl enable --now crond
```

---

## Question 18 - Server boot target and directory (server) - 4 pts

```bash
# On server:
systemctl set-default multi-user.target
getent group srvd9 >/dev/null || groupadd srvd9
mkdir -p /srv/server-d9
chown root:srvd9 /srv/server-d9
chmod 2770 /srv/server-d9
```

---

## Question 19 - Client server NFS mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/rhcsa9-d
echo 'drift team export' > /exports/rhcsa9-d/README
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

## Question 20 - Client server SSH key (client + server) - 4 pts

```bash
# On server:
id copyd9 >/dev/null 2>&1 || useradd -m copyd9
echo 'copyd9:cinder9' | chpasswd
# On client:
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa9-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub copyd9@server
```

---

## Question 21 - Client server secure copy (client + server) - 4 pts

```bash
echo 'drift packet transfer' > /root/exam-d-copy.txt
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-d-copy.txt copyd9@server:/home/copyd9/exam-d-copy.txt
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
