# RHCSA 10 Mock Exam D

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-d` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

Service and logging focus: custom systemd service, rsyslog routing, firewall service access, SELinux, journald, chrony, storage, users, and package administration.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Set hostname to clientd.exam10.lab and map serverd.exam10.lab to 192.168 (client) - 5 pts

```bash
hostnamectl set-hostname clientd.exam10.lab
echo '192.168.122.3 serverd.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.63/24, gateway 192.1 (client) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.63/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 03 - Create /root/d-original, hard link /root/d-hard, and symlink /root/d-sof (client) - 5 pts

```bash
echo link > /root/d-original
ln /root/d-original /root/d-hard
ln -s /root/d-original /root/d-soft
```

---

## Question 04 - Create and enable serverdtimer.timer so it appends SERVER-D to /var/log/ (server) - 5 pts

```bash
# On server:
cat > /usr/local/sbin/serverdtimer.sh <<'EOF'
#!/bin/bash
echo SERVER-D >> /var/log/serverdtimer.log
EOF
chmod +x /usr/local/sbin/serverdtimer.sh
cat > /etc/systemd/system/serverdtimer.service <<'EOF'
[Unit]
Description=Server D timer job

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/serverdtimer.sh
EOF
cat > /etc/systemd/system/serverdtimer.timer <<'EOF'
[Unit]
Description=Run server D timer job

[Timer]
OnCalendar=*:0/10
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now serverdtimer.timer
```

---

## Question 05 - Create VG vgd10 and LV datad mounted at /mnt/datad10 (client) - 5 pts

```bash
pvcreate /dev/sdb
vgcreate vgd10 /dev/sdb
lvcreate -L 384M -n datad vgd10
mkfs.xfs -f /dev/vgd10/datad
mkdir -p /mnt/datad10
echo '/dev/vgd10/datad /mnt/datad10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 06 - Create /var/www/html/d.html and restore its default SELinux context (client) - 5 pts

```bash
echo d > /var/www/html/d.html
chcon -t user_tmp_t /var/www/html/d.html
restorecon -v /var/www/html/d.html
```

---

## Question 07 - Persistently enable httpd_can_network_connect (client) - 5 pts

```bash
setsebool -P httpd_can_network_connect on
```

---

## Question 08 - Enable persistent systemd journal storage (server) - 5 pts

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

## Question 09 - Make chronyd available as the lab time source. on client, configure chro (client + server) - 5 pts

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

---

## Question 10 - Create enabled BaseOS and AppStream repository definitions with BaseOS a (client + server) - 5 pts

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

## Question 11 - Publish /var/www/html/server-d.html containing RHCSA10-D and serve httpd (server) - 5 pts

```bash
# On server:
mkdir -p /var/www/html
echo RHCSA10-D > /var/www/html/server-d.html
restorecon -v /var/www/html/server-d.html || true
cat > /etc/httpd/conf.d/exam-d-port.conf <<'EOF'
Listen 8203
EOF
semanage port -a -t http_port_t -p tcp 8203 2>/dev/null || semanage port -m -t http_port_t -p tcp 8203
firewall-cmd --permanent --add-port=8203/tcp
firewall-cmd --reload
systemctl enable --now httpd
systemctl restart httpd
```

---

## Question 12 - Route local5 log messages to /var/log/server-d-local5.log and write a te (server) - 5 pts

```bash
# On server:
cat > /etc/rsyslog.d/server-d-local5.conf <<'EOF'
local5.* /var/log/server-d-local5.log
EOF
systemctl enable --now rsyslog
systemctl restart rsyslog
logger -p local5.info 'server-d-local5'
sleep 1
```

---

## Question 13 - Create group teamd10, create user userd10, set password cinder9, and add (client) - 4 pts

```bash
groupadd teamd10
useradd -G teamd10 userd10
passwd userd10
# enter: cinder9
```

---

## Question 14 - Allow members of serverd10 to run /usr/bin/systemctl with sudo without a (server) - 4 pts

```bash
# On server:
getent group serverd10 >/dev/null || groupadd serverd10
echo '%serverd10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/serverd10-systemctl
chmod 0440 /etc/sudoers.d/serverd10-systemctl
```

---

## Question 15 - Create group serverd10 and user srvd10 with password cinder9, then add t (server) - 4 pts

```bash
# On server:
getent group serverd10 >/dev/null || groupadd serverd10
id srvd10 >/dev/null 2>&1 || useradd srvd10
gpasswd -a srvd10 serverd10
echo 'srvd10:cinder9' | chpasswd
```

---

## Question 16 - Create /usr/local/bin/d-who that prints the primary group for the suppli (client) - 4 pts

```bash
cat > /usr/local/bin/d-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/d-who
```

---

## Question 17 - Write users whose shell ends with sh to /root/d-shell-users.txt (client) - 4 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/d-shell-users.txt
```

---

## Question 18 - Create /root/exam-d-report.txt containing REPORT-D and copy it to server (client + server) - 4 pts

```bash
echo REPORT-D > /root/exam-d-report.txt
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa10-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub root@server
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-d-report.txt root@server:/root/exam-d-report.txt
```

---

## Question 19 - Create a cron job for userd10 that writes EXAM10 to /home/userd10/exam10 (client) - 4 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/userd10/exam10.log' | crontab -u userd10 -
```

---

## Question 20 - Export /exports/exam-d to the 192.168.122.0/24 network. on client, mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/exam-d
echo 'exam d export' > /exports/exam-d/README
cat > /etc/exports.d/exam-d-integrated.exports <<'EOF'
/exports/exam-d 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/dprojects
grep -Eq '^server:/exports/exam-d[[:space:]]+/mnt/dprojects[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/exam-d /mnt/dprojects nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 21 - Set the default boot target to multi-user.target without rebooting (server) - 4 pts

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
