# RHCSA 10 Mock Exam B

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-b` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

Software and permissions focus: offline package installation, shared directories, default ACLs, fixed user identity, storage, NFS, journald, and systemd administration.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - set hostname to clientb.exam10.lab and map serverb.exam10.lab to 192.168 (client) - 5 pts

```bash
hostnamectl set-hostname clientb.exam10.lab
echo '192.168.122.3 serverb.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.61/24, gateway 192.1 (client) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.61/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 03 - On client and server, create enabled BaseOS and AppStream repository def (client + server) - 5 pts

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

## Question 04 - install the tree package from the configured offline repositories (client) - 5 pts

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
dnf install -y tree
rpm -q tree
```

---

## Question 05 - create /srv/teamb10 as a shared directory for group teamb10 (client) - 5 pts

```bash
getent group teamb10 >/dev/null || groupadd teamb10
mkdir -p /srv/teamb10
chown root:teamb10 /srv/teamb10
chmod 3770 /srv/teamb10
```

---

## Question 06 - Create group teamb10, create user userb10, set password cinder9, and add (client) - 5 pts

```bash
getent group teamb10 >/dev/null || groupadd teamb10
id userb10 >/dev/null 2>&1 || useradd userb10
gpasswd -a userb10 teamb10
echo 'userb10:cinder9' | chpasswd
```

---

## Question 07 - create user auditorb10 with UID 6102 and shell /sbin/nologin (client) - 5 pts

```bash
id auditorb10 >/dev/null 2>&1 || useradd -u 6102 -s /sbin/nologin auditorb10
usermod -u 6102 -s /sbin/nologin auditorb10
```

---

## Question 08 - Set maximum password age for userb10 to 46 days and warning period to 7 (client) - 5 pts

```bash
chage -M 46 -W 7 userb10
```

---

## Question 09 - Create /usr/local/bin/b-who that prints the primary group for the suppli (client) - 5 pts

```bash
cat > /usr/local/bin/b-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/b-who
```

---

## Question 10 - create /root/exam-b-report.txt containing REPORT-B and copy it to server (client) - 5 pts

```bash
echo REPORT-B > /root/exam-b-report.txt
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa10-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub root@server
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-b-report.txt root@server:/root/exam-b-report.txt
```

---

## Question 11 - Create gzip archive /root/b-etc.tar.gz containing /etc/hosts and /etc/fs (client) - 5 pts

```bash
tar -czf /root/b-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/b-etc.tar.gz
```

---

## Question 12 - Create /root/b-original, hard link /root/b-hard, and symlink /root/b-sof (client) - 5 pts

```bash
echo link > /root/b-original
ln /root/b-original /root/b-hard
ln -s /root/b-original /root/b-soft
```

---

## Question 13 - create and enable serverbtimer.timer so it appends SERVER-B to /var/log/ (server) - 4 pts

```bash
# On server:
cat > /usr/local/sbin/serverbtimer.sh <<'EOF'
#!/bin/bash
echo SERVER-B >> /var/log/serverbtimer.log
EOF
chmod +x /usr/local/sbin/serverbtimer.sh
cat > /etc/systemd/system/serverbtimer.service <<'EOF'
[Unit]
Description=Server B timer job

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/serverbtimer.sh
EOF
cat > /etc/systemd/system/serverbtimer.timer <<'EOF'
[Unit]
Description=Run server B timer job

[Timer]
OnCalendar=*:/10
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now serverbtimer.timer
```

---

## Question 14 - Create VG vgb10 and LV datab mounted at /mnt/datab10 (client) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vgb10 /dev/sdb
lvcreate -L 384M -n datab vgb10
mkfs.xfs -f /dev/vgb10/datab
mkdir -p /mnt/datab10
echo '/dev/vgb10/datab /mnt/datab10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 15 - publish /var/www/html/server-b.html containing RHCSA10-B and serve httpd (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo RHCSA10-B > /var/www/html/server-b.html
restorecon -v /var/www/html/server-b.html || true
cat > /etc/httpd/conf.d/exam-b-port.conf <<'EOF'
Listen 8201
EOF
semanage port -a -t http_port_t -p tcp 8201 2>/dev/null || semanage port -m -t http_port_t -p tcp 8201
firewall-cmd --permanent --add-port=8201/tcp
firewall-cmd --reload
systemctl enable --now httpd
systemctl restart httpd
```

---

## Question 16 - create group serverb10 and user srvb10 with password cinder9, then add t (server) - 4 pts

```bash
# On server:
getent group serverb10 >/dev/null || groupadd serverb10
id srvb10 >/dev/null 2>&1 || useradd srvb10
gpasswd -a srvb10 serverb10
echo 'srvb10:cinder9' | chpasswd
```

---

## Question 17 - allow members of serverb10 to run /usr/bin/systemctl with sudo without a (server) - 4 pts

```bash
# On server:
getent group serverb10 >/dev/null || groupadd serverb10
echo '%serverb10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/serverb10-systemctl
chmod 0440 /etc/sudoers.d/serverb10-systemctl
```

---

## Question 18 - enable persistent systemd journal storage (server) - 4 pts

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

## Question 19 - route local5 log messages to /var/log/server-b-local5.log and write a te (server) - 4 pts

```bash
# On server:
cat > /etc/rsyslog.d/server-b-local5.conf <<'EOF'
local5.* /var/log/server-b-local5.log
EOF
systemctl enable --now rsyslog
systemctl restart rsyslog
logger -p local5.info 'server-b-local5'
sleep 1
```

---

## Question 20 - export /exports/exam-b to the 192.168.122.0/24 network. On client, mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/exam-b
echo 'exam b export' > /exports/exam-b/README
cat > /etc/exports.d/exam-b-integrated.exports <<'EOF'
/exports/exam-b 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/bprojects
grep -Eq '^server:/exports/exam-b[[:space:]]+/mnt/bprojects[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/exam-b /mnt/bprojects nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 21 - set the default boot target to multi-user.target without rebooting (server) - 4 pts

```bash
# On server:
systemctl set-default multi-user.target
systemctl get-default
```

---

## Question 22 - Install lsof and ensure tcpdump is removed (client) - 4 pts

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
dnf install -y lsof
dnf remove -y tcpdump
```
