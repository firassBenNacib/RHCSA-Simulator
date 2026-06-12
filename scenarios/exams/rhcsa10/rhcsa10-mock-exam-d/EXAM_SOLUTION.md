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

## Question 01 - set hostname to clientd.exam10.lab and map serverd.exam10.lab to 192.168 (client) - 5 pts

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

## Question 04 - Create and enable examdtimer.timer that runs every 10 minutes (client) - 4 pts

```bash
cat > /usr/local/sbin/examdtimer.sh <<'EOF'
#!/bin/bash
echo examdtimer >> /var/log/examdtimer.log
EOF
chmod +x /usr/local/sbin/examdtimer.sh
cat > /etc/systemd/system/examdtimer.service <<'EOF'
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/examdtimer.sh
EOF
cat > /etc/systemd/system/examdtimer.timer <<'EOF'
[Timer]
OnCalendar=*:0/10
Persistent=true
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now examdtimer.timer
```

---

## Question 05 - Create VG vgd10 and LV datad mounted at /mnt/datad10 (client) - 4 pts

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

## Question 06 - Create /var/www/html/d.html and restore its default SELinux context (client) - 4 pts

```bash
echo d > /var/www/html/d.html
chcon -t user_tmp_t /var/www/html/d.html
restorecon -v /var/www/html/d.html
```

---

## Question 07 - Persistently enable httpd_can_network_connect (client) - 4 pts

```bash
setsebool -P httpd_can_network_connect on
```

---

## Question 08 - Configure persistent systemd journal storage (client) - 4 pts

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

## Question 09 - Use server as the only chrony source and enable chronyd (client) - 4 pts

```bash
sed -i '/^pool /d;/^server /d' /etc/chrony.conf
echo 'server server iburst' >> /etc/chrony.conf
systemctl enable --now chronyd
```

---

## Question 10 - Create enabled BaseOS and AppStream repository definitions using http:// (client) - 5 pts

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
```

---

## Question 11 - create and enable a custom systemd service named examd-heartbeat.service (client) - 5 pts

```bash
cat > /usr/local/sbin/examd-heartbeat.sh <<'EOF'
#!/bin/bash
echo 'exam-d heartbeat' >> /var/log/examd-heartbeat.log
EOF
chmod +x /usr/local/sbin/examd-heartbeat.sh
cat > /etc/systemd/system/examd-heartbeat.service <<'EOF'
[Unit]
Description=Exam D heartbeat

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/examd-heartbeat.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now examd-heartbeat.service
```

---

## Question 12 - route local5 log messages to /var/log/examd-local5.log and write a test (client) - 5 pts

```bash
cat > /etc/rsyslog.d/examd-local5.conf <<'EOF'
local5.* /var/log/examd-local5.log
EOF
systemctl enable --now rsyslog
systemctl restart rsyslog
logger -p local5.info 'exam-d local5'
sleep 1
```

---

## Question 13 - Create group teamd10, create user userd10, set password cinder9, and add (client) - 5 pts

```bash
groupadd teamd10
useradd -G teamd10 userd10
passwd userd10
# enter: cinder9
```

---

## Question 14 - Allow %teamd10 to run /usr/bin/systemctl without a password by using a s (client) - 5 pts

```bash
echo '%teamd10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teamd10
chmod 440 /etc/sudoers.d/teamd10
```

---

## Question 15 - Set maximum password age for userd10 to 48 days and warning period to 7 (client) - 5 pts

```bash
chage -M 48 -W 7 userd10
```

---

## Question 16 - Create /usr/local/bin/d-who that prints the primary group for the suppli (client) - 5 pts

```bash
cat > /usr/local/bin/d-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/d-who
```

---

## Question 17 - Write users whose shell ends with sh to /root/d-shell-users.txt (client) - 5 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/d-shell-users.txt
```

---

## Question 18 - Create gzip archive /root/d-etc.tar.gz containing /etc/hosts and /etc/fs (client) - 5 pts

```bash
tar -czf /root/d-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/d-etc.tar.gz
```

---

## Question 19 - Create a cron job for userd10 that writes EXAM10 to /home/userd10/exam10 (client) - 4 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/userd10/exam10.log' | crontab -u userd10 -
```

---

## Question 20 - configure autofs so /remoted/projects mounts server:/exports/autofs/proj (client) - 4 pts

```bash
mkdir -p /remoted
echo '/remoted /etc/auto.remoted' > /etc/auto.master.d/d.autofs
echo 'projects -ro server:/exports/autofs/projects' > /etc/auto.remoted
systemctl enable --now autofs
```

---

## Question 21 - allow the http service permanently in firewalld and reload the firewall (client) - 4 pts

```bash
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
firewall-cmd --query-service=http
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
