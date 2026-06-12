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

## Question 03 - Create enabled BaseOS and AppStream repository definitions using http:// (client) - 5 pts

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

## Question 10 - Write users whose shell ends with sh to /root/b-shell-users.txt (client) - 5 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/b-shell-users.txt
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

## Question 13 - Create and enable exambtimer.timer that runs every 10 minutes (client) - 4 pts

```bash
cat > /usr/local/sbin/exambtimer.sh <<'EOF'
#!/bin/bash
echo exambtimer >> /var/log/exambtimer.log
EOF
chmod +x /usr/local/sbin/exambtimer.sh
cat > /etc/systemd/system/exambtimer.service <<'EOF'
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/exambtimer.sh
EOF
cat > /etc/systemd/system/exambtimer.timer <<'EOF'
[Timer]
OnCalendar=*:0/10
Persistent=true
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now exambtimer.timer
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

## Question 15 - Create /var/www/html/b.html and restore its default SELinux context (client) - 4 pts

```bash
echo b > /var/www/html/b.html
chcon -t user_tmp_t /var/www/html/b.html
restorecon -v /var/www/html/b.html
```

---

## Question 16 - Persistently enable httpd_can_network_connect (client) - 4 pts

```bash
setsebool -P httpd_can_network_connect on
```

---

## Question 17 - Activate the throughput-performance tuned profile (client) - 4 pts

```bash
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

## Question 18 - Configure persistent systemd journal storage (client) - 4 pts

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

## Question 19 - set a default ACL on /srv/teamb10 that gives group teamb10 full access t (client) - 4 pts

```bash
setfacl -m g:teamb10:rwx,d:g:teamb10:rwx /srv/teamb10
getfacl -p /srv/teamb10
```

---

## Question 20 - mount server:/exports/direct at /mnt/bdirect persistently (client) - 4 pts

```bash
mkdir -p /mnt/bdirect
echo 'server:/exports/direct /mnt/bdirect nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 21 - Set the default target to multi-user.target without rebooting (client) - 4 pts

```bash
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
