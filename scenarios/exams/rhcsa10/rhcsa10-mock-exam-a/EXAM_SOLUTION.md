# RHCSA 10 Mock Exam A

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-a` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, networking-and-firewall, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

A 23-task RHCSA 10 mock exam covering boot recovery, networking, Flatpak management, systemd timers, LVM storage, firewall, SELinux, shell scripting, and chrony time synchronisation across client and server.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Recover root password (client) - 5 pts

```bash
# Boot into emergency mode: at GRUB, press 'e', append rd.break to the linux line, Ctrl+X
# mount -o remount,rw /sysroot
# chroot /sysroot
# echo cinder9 | passwd --stdin root
# touch /.autorelabel
# exit; exit
```

---

## Question 02 - Set hostname (client) - 5 pts

```bash
hostnamectl set-hostname clienta.exam10.lab
echo '192.168.122.3 servera.exam10.lab' >> /etc/hosts
```

---

## Question 03 - Configure eth1 networking (client) - 5 pts

```bash
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.60/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 04 - Persist kernel boot argument (client) - 5 pts

```bash
grubby --update-kernel=ALL --args='audit_backlog_limit=8192'
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

## Question 06 - Configure the server hostname and persistent IPv4 networking (server) - 5 pts

```bash
# On server:
hostnamectl set-hostname servera.exam10.lab
grep -Eq '^192\.168\.122\.60[[:space:]]+clienta\.exam10\.lab$' /etc/hosts || echo '192.168.122.60 clienta.exam10.lab' >> /etc/hosts
connection_name="System eth1"
nmcli -g NAME connection show "$connection_name" >/dev/null 2>&1 || connection_name="$(private_dev="$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.122\./ {print $2; exit}')"; nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v private_dev="$private_dev" '$2 == private_dev {print $1; exit}')"
nmcli connection modify "$connection_name" ipv4.addresses 192.168.122.3/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "$connection_name"
```

---

## Question 07 - Add a system-level Flatpak remote named examaflatpak (client) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examaflatpak file:///opt/rhcsa/flatpak/repo
flatpak install --system -y examaflatpak org.rhcsa.Tools
flatpak list --system --app
```

---

## Question 08 - Create group opsa10 (client) - 5 pts

```bash
groupadd opsa10
useradd -G opsa10 anna10
useradd -G opsa10 atlas10
echo cinder9 | passwd --stdin anna10
echo cinder9 | passwd --stdin atlas10
```

---

## Question 09 - Allow members of %opsa10 to run /usr/bin/systemctl without a password (client) - 4 pts

```bash
echo '%opsa10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/opsa10
chmod 440 /etc/sudoers.d/opsa10
```

---

## Question 10 - Configure password aging (client) - 4 pts

```bash
chage -M 45 -W 7 anna10
```

---

## Question 11 - Create user lookup script (client) - 4 pts

```bash
cat > /usr/local/bin/a-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/a-who
```

---

## Question 12 - List shell users (client) - 4 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/a-shell-users.txt
```

---

## Question 13 - Copy exam report to server (client + server) - 4 pts

```bash
echo REPORT-A > /root/exam-a-report.txt
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa10-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub root@server
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-a-report.txt root@server:/root/exam-a-report.txt
```

---

## Question 14 - Publish web content (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo RHCSA10-A > /var/www/html/server-a.html
restorecon -v /var/www/html/server-a.html || true
cat > /etc/httpd/conf.d/exam-a-port.conf <<'EOF'
Listen 8200
EOF
semanage port -a -t http_port_t -p tcp 8200 2>/dev/null || semanage port -m -t http_port_t -p tcp 8200
firewall-cmd --permanent --add-port=8200/tcp
firewall-cmd --reload
systemctl enable --now httpd
systemctl restart httpd
```

---

## Question 15 - Configure systemd timer (server) - 4 pts

```bash
# On server:
cat > /usr/local/sbin/serveratimer.sh <<'EOF'
#!/bin/bash
echo SERVER-A >> /var/log/serveratimer.log
EOF
chmod +x /usr/local/sbin/serveratimer.sh
cat > /etc/systemd/system/serveratimer.service <<'EOF'
[Unit]
Description=Server A timer job

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/serveratimer.sh
EOF
cat > /etc/systemd/system/serveratimer.timer <<'EOF'
[Unit]
Description=Run server A timer job

[Timer]
OnCalendar=*:0/10
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now serveratimer.timer
```

---

## Question 16 - Configure LVM storage (client) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vga10 /dev/sdb
lvcreate -L 384M -n dataa vga10
mkfs.xfs /dev/vga10/dataa
mkdir -p /mnt/dataa10
uuid=$(blkid -s UUID -o value /dev/vga10/dataa)
test -n "$uuid" && echo "UUID=$uuid /mnt/dataa10 xfs defaults 0 0" >> /etc/fstab
mount -a
```

---

## Question 17 - Create user and group (server) - 4 pts

```bash
# On server:
getent group servera10 >/dev/null || groupadd servera10
id srva10 >/dev/null 2>&1 || useradd srva10
gpasswd -a srva10 servera10
echo 'srva10:cinder9' | chpasswd
```

---

## Question 18 - Create /srv/servera10 owned by root:servera10 with mode 2770 (server) - 4 pts

```bash
# On server:
getent group servera10 >/dev/null || groupadd servera10
mkdir -p /srv/servera10
chown root:servera10 /srv/servera10
chmod 2770 /srv/servera10
```

---

## Question 19 - Persist SELinux boolean (server) - 4 pts

```bash
# On server:
setsebool -P httpd_can_network_connect on
getsebool httpd_can_network_connect
```

---

## Question 20 - Create the directory /srv/opsa10 owned by root:opsa10 with mode 3770 (client) - 4 pts

```bash
mkdir -p /srv/opsa10
chown root:opsa10 /srv/opsa10
chmod 3770 /srv/opsa10
```

---

## Question 21 - Enable persistent journal (server) - 4 pts

```bash
# On server:
mkdir -p /var/log/journal /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
journalctl --flush
```

---

## Question 22 - Configure chrony time source (client + server) - 4 pts

```bash
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
dnf install -y chrony
systemctl enable --now chronyd
firewall-cmd --permanent --add-service=ntp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
# On client:
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
dnf install -y chrony
cat > /etc/chrony.conf <<'EOF'
server server iburst
makestep 1.0 3
EOF
systemctl enable --now chronyd
```

---

## Question 23 - Configure NFS export and mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/exam-a
echo 'exam a export' > /exports/exam-a/README
cat > /etc/exports.d/exam-a-integrated.exports <<'EOF'
/exports/exam-a 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/aprojects
grep -Eq '^server:/exports/exam-a[[:space:]]+/mnt/aprojects[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/exam-a /mnt/aprojects nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```
