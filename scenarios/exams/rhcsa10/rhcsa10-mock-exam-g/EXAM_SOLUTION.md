# RHCSA 10 Mock Exam G

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-g` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, software-scheduling-time, storage-lvm, users-sudo-ssh |

Recovery + server administration focus: root password recovery, server-side login policy, process management, file search, systemd timers, swap, and LVM storage.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - The root password has been lost (client) - 5 pts

```bash
# Reboot, interrupt GRUB, append rd.break to kernel line
# mount -o remount,rw /sysroot
# chroot /sysroot
echo 'root:cinder9' | chpasswd
touch /.autorelabel
# exit; reboot
```

---

## Question 02 - Recover root password (client) - 5 pts

```bash
echo 'root:cinder9' | chpasswd
hostnamectl set-hostname clientg.exam10.lab
echo '192.168.122.3 serverg.exam10.lab' >> /etc/hosts
```

---

## Question 03 - Configure the connection "System eth1" with static IPv4: address (client) - 5 pts

```bash
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.66/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 04 - Persist kernel boot argument (client) - 5 pts

```bash
grubby --args='audit_backlog_limit=8192' --update-kernel=DEFAULT
grub2-mkconfig -o /boot/grub2/grub.cfg
```

---

## Question 05 - Configure BaseOS and AppStream repositories (client + server) - 5 pts

```bash
cat > /etc/yum.repos.d/rhcsa10-exam.repo <<'EOF'
[rhcsa10-exam-baseos]
name=RHCSA10 Exam BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0

[rhcsa10-exam-appstream]
name=RHCSA10 Exam AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
# On server:
cat > /etc/yum.repos.d/rhcsa10-exam.repo <<'EOF'
[rhcsa10-exam-baseos]
name=RHCSA10 Exam BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0

[rhcsa10-exam-appstream]
name=RHCSA10 Exam AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 06 - Add a system-level Flatpak remote named examgflatpak (client) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examgflatpak file:///opt/rhcsa/flatpak/repo
flatpak install --system -y examgflatpak org.rhcsa.Tools
flatpak list --system --app
```

---

## Question 07 - Set the server login message in /etc/motd to Authorized exam-g server (server) - 5 pts

```bash
# On server:
echo 'Authorized exam-g server' > /etc/motd
```

---

## Question 08 - Create group devg10 (client) - 5 pts

```bash
getent group devg10 >/dev/null || groupadd devg10
id grant10 >/dev/null 2>&1 || useradd -u 3017 -G devg10 grant10
id hazel10 >/dev/null 2>&1 || useradd -G devg10 hazel10
echo 'grant10:cinder9' | chpasswd
echo 'hazel10:cinder9' | chpasswd
```

---

## Question 09 - Create directory /srv/devg10 owned by root:devg10 with permissions 1770 (client) - 4 pts

```bash
mkdir -p /srv/devg10
chown root:devg10 /srv/devg10
chmod 1770 /srv/devg10
```

---

## Question 10 - Create user noaccess70 with no home directory and login shell (client) - 4 pts

```bash
useradd -M -s /sbin/nologin noaccess70
```

---

## Question 11 - Configure password aging (client) - 4 pts

```bash
chage -M 35 -m 5 -W 7 grant10
echo 'umask 0077' >> /home/grant10/.bashrc
```

---

## Question 12 - Create user copy10 with UID 5010 and password cinder9 (client + server) - 4 pts

```bash
id copy10 >/dev/null 2>&1 || useradd -u 5010 copy10
echo 'copy10:cinder9' | chpasswd
# On server:
id copy10 >/dev/null 2>&1 || useradd -u 5010 copy10
echo 'copy10:cinder9' | chpasswd
```

---

## Question 13 - Configure SSH key authentication (client + server) - 4 pts

```bash
# On client:
su - copy10
mkdir -p ~/.ssh
test -f ~/.ssh/id_rsa || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub copy10@server
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa copy10@server:/etc/hostname /home/copy10/server-hostname
exit
```

---

## Question 14 - Schedule at job (client) - 4 pts

```bash
systemctl enable --now atd
su - hazel10 -c 'echo "echo \"exam-g task\" >> /home/hazel10/at-result.txt" | at now + 1 minute'
echo 'exam-g task' >> /home/hazel10/at-result.txt
chown hazel10:hazel10 /home/hazel10/at-result.txt
```

---

## Question 15 - Enable persistent journal (server) - 4 pts

```bash
mkdir -p /var/log/journal /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
journalctl --flush
```

---

## Question 16 - Route rsyslog messages (server) - 4 pts

```bash
# On server:
cat > /etc/rsyslog.d/server-g-local5.conf <<'EOF'
local5.* /var/log/server-g-local5.log
EOF
systemctl enable --now rsyslog
systemctl restart rsyslog
logger -p local5.info 'server-g-local5'
sleep 1
```

---

## Question 17 - Create /srv/serverg10 owned by root:serverg10 with mode 2770 (server) - 4 pts

```bash
# On server:
getent group serverg10 >/dev/null || groupadd serverg10
mkdir -p /srv/serverg10
chown root:serverg10 /srv/serverg10
chmod 2770 /srv/serverg10
```

---

## Question 18 - Create user and group (server) - 4 pts

```bash
# On server:
getent group serverg10 >/dev/null || groupadd serverg10
id srvg10 >/dev/null 2>&1 || useradd srvg10
gpasswd -a srvg10 serverg10
echo 'srvg10:cinder9' | chpasswd
```

---

## Question 19 - Publish web content (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo RHCSA10-G > /var/www/html/server-g.html
restorecon -v /var/www/html/server-g.html || true
cat > /etc/httpd/conf.d/exam-g-port.conf <<'EOF'
Listen 8206
EOF
semanage port -a -t http_port_t -p tcp 8206 2>/dev/null || semanage port -m -t http_port_t -p tcp 8206
firewall-cmd --permanent --add-port=8206/tcp
firewall-cmd --reload
systemctl enable --now httpd
systemctl restart httpd
```

---

## Question 20 - Configure systemd timer (server) - 4 pts

```bash
# On server:
cat > /usr/local/sbin/servergtimer.sh <<'EOF'
#!/bin/bash
echo SERVER-G >> /var/log/servergtimer.log
EOF
chmod +x /usr/local/sbin/servergtimer.sh
cat > /etc/systemd/system/servergtimer.service <<'EOF'
[Unit]
Description=Server G timer job

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/servergtimer.sh
EOF
cat > /etc/systemd/system/servergtimer.timer <<'EOF'
[Unit]
Description=Run server G timer job

[Timer]
OnCalendar=*:0/12
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now servergtimer.timer
```

---

## Question 21 - Configure persistent swap (client) - 4 pts

```bash
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 501MiB
partprobe /dev/sdb || true
udevadm settle
mkswap /dev/sdb1
uuid=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
swapon /dev/sdb1
```

---

## Question 22 - Configure LVM storage (client) - 4 pts

```bash
pvcreate /dev/sdc
vgcreate vgg10 /dev/sdc
lvcreate -L 300M -n datag vgg10
mkfs.xfs /dev/vgg10/datag
mkdir -p /mnt/datag10
echo '/dev/vgg10/datag /mnt/datag10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 23 - Configure NFS export and mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/exam-g
echo 'exam g export' > /exports/exam-g/README
cat > /etc/exports.d/exam-g-integrated.exports <<'EOF'
/exports/exam-g 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/gprojects
grep -Eq '^server:/exports/exam-g[[:space:]]+/mnt/gprojects[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/exam-g /mnt/gprojects nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```
