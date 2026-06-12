# RHCSA 10 Mock Exam E

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-e` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

Storage and boot focus: labeled filesystem persistence, kernel arguments, LVM, NFS, documentation, package administration, users, scheduling, and logging.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - set hostname to cliente.exam10.lab and map servere.exam10.lab to 192.168 (client) - 5 pts

```bash
hostnamectl set-hostname cliente.exam10.lab
echo '192.168.122.3 servere.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.64/24, gateway 192.1 (client) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.64/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
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

## Question 04 - create a labeled XFS filesystem on /dev/sdc1 and mount it persistently a (client) - 5 pts

```bash
parted -s /dev/sdc -- mklabel gpt mkpart primary xfs 1MiB 513MiB
partprobe /dev/sdc || true
udevadm settle
mkfs.xfs -f -L EXAME10 /dev/sdc1
mkdir -p /mnt/exame-label
sed -i '\#/mnt/exame-label#d' /etc/fstab
echo 'LABEL=EXAME10 /mnt/exame-label xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 05 - add audit_backlog_limit=8192 to all installed kernel entries (client) - 5 pts

```bash
grubby --update-kernel=ALL --args='audit_backlog_limit=8192'
grubby --info=ALL | grep audit_backlog_limit
```

---

## Question 06 - Create group teame10, create user usere10, set password cinder9, and add (client) - 5 pts

```bash
groupadd teame10
useradd -G teame10 usere10
passwd usere10
# enter: cinder9
```

---

## Question 07 - Allow %teame10 to run /usr/bin/systemctl without a password by using a s (client) - 5 pts

```bash
echo '%teame10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teame10
chmod 440 /etc/sudoers.d/teame10
```

---

## Question 08 - Set maximum password age for usere10 to 49 days and warning period to 7 (client) - 5 pts

```bash
chage -M 49 -W 7 usere10
```

---

## Question 09 - Create /usr/local/bin/e-who that prints the primary group for the suppli (client) - 5 pts

```bash
cat > /usr/local/bin/e-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/e-who
```

---

## Question 10 - Write users whose shell ends with sh to /root/e-shell-users.txt (client) - 5 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/e-shell-users.txt
```

---

## Question 11 - Create gzip archive /root/e-etc.tar.gz containing /etc/hosts and /etc/fs (client) - 5 pts

```bash
tar -czf /root/e-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/e-etc.tar.gz
```

---

## Question 12 - Create /root/e-original, hard link /root/e-hard, and symlink /root/e-sof (client) - 5 pts

```bash
echo link > /root/e-original
ln /root/e-original /root/e-hard
ln -s /root/e-original /root/e-soft
```

---

## Question 13 - Create and enable exametimer.timer that runs every 10 minutes (client) - 4 pts

```bash
cat > /usr/local/sbin/exametimer.sh <<'EOF'
#!/bin/bash
echo exametimer >> /var/log/exametimer.log
EOF
chmod +x /usr/local/sbin/exametimer.sh
cat > /etc/systemd/system/exametimer.service <<'EOF'
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/exametimer.sh
EOF
cat > /etc/systemd/system/exametimer.timer <<'EOF'
[Timer]
OnCalendar=*:0/10
Persistent=true
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now exametimer.timer
```

---

## Question 14 - Create VG vge10 and LV datae mounted at /mnt/datae10 (client) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vge10 /dev/sdb
lvcreate -L 384M -n datae vge10
mkfs.xfs -f /dev/vge10/datae
mkdir -p /mnt/datae10
echo '/dev/vge10/datae /mnt/datae10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 15 - Allow TCP port 8104 permanently in firewalld and reload (client) - 4 pts

```bash
firewall-cmd --permanent --add-port=8104/tcp
firewall-cmd --reload
```

---

## Question 16 - Create /var/www/html/e.html and restore its default SELinux context (client) - 4 pts

```bash
echo e > /var/www/html/e.html
chcon -t user_tmp_t /var/www/html/e.html
restorecon -v /var/www/html/e.html
```

---

## Question 17 - Activate the throughput-performance tuned profile (client) - 4 pts

```bash
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

## Question 18 - Create a cron job for usere10 that writes EXAM10 to /home/usere10/exam10 (client) - 4 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/usere10/exam10.log' | crontab -u usere10 -
```

---

## Question 19 - mount server:/exports/direct at /mnt/edirect persistently (client) - 4 pts

```bash
mkdir -p /mnt/edirect
echo 'server:/exports/direct /mnt/edirect nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 20 - save the first useradd help usage line to /root/e-useradd-help.txt (client) - 4 pts

```bash
useradd --help | sed -n '1p' > /root/e-useradd-help.txt
test -s /root/e-useradd-help.txt
```

---

## Question 21 - Install lsof and ensure tcpdump is removed (client) - 4 pts

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

---

## Question 22 - Configure persistent systemd journal storage (client) - 4 pts

```bash
mkdir -p /var/log/journal /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
journalctl --flush
```
