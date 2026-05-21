# RHCSA 10 Mock Exam D

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-d` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

A RHCSA 10 mock exam focused on RHEL 10 administration, Flatpak, systemd timers, storage, networking, users, security, and services.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Set hostname to clientd.exam10.lab and map serverd.exam10.lab to 192.168 (server) - 5 pts

```bash
hostnamectl set-hostname clientd.exam10.lab
echo '192.168.122.3 serverd.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.63/24, gateway 192.1 (server) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.63/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 03 - Configure persistent systemd journal storage (server) - 4 pts

```bash
mkdir -p /var/log/journal
install -D -m 0644 /dev/null /etc/systemd/journald.conf
grep -q '^Storage=' /etc/systemd/journald.conf && sed -i 's/^Storage=.*/Storage=persistent/' /etc/systemd/journald.conf || echo 'Storage=persistent' >> /etc/systemd/journald.conf
systemctl restart systemd-journald
```

---

## Question 04 - Use server as the only chrony source and enable chronyd (server) - 4 pts

```bash
sed -i '/^pool /d;/^server /d' /etc/chrony.conf
echo 'server server iburst' >> /etc/chrony.conf
systemctl enable --now chronyd
```

---

## Question 05 - Create enabled BaseOS and AppStream repository definitions using http:// (server) - 5 pts

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

## Question 06 - Create system Flatpak remote examdflatpak pointing to file:///opt/rhcsa/ (server) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examdflatpak file:///opt/rhcsa/flatpak/repo
```

---

## Question 07 - Install org.rhcsa.Tools from examdflatpak, then remove it after verifica (server) - 5 pts

```bash
flatpak install --system -y examdflatpak org.rhcsa.Tools
flatpak list --system --app
flatpak uninstall --system -y org.rhcsa.Tools
```

---

## Question 08 - Create group teamd10, create user userd10, set password cinder9, and add (server) - 5 pts

```bash
groupadd teamd10
useradd -G teamd10 userd10
passwd userd10
# enter: cinder9
```

---

## Question 09 - Allow %teamd10 to run /usr/bin/systemctl without a password by using a s (server) - 5 pts

```bash
echo '%teamd10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teamd10
chmod 440 /etc/sudoers.d/teamd10
```

---

## Question 10 - Set maximum password age for userd10 to 48 days and warning period to 7 (server) - 5 pts

```bash
chage -M 48 -W 7 userd10
```

---

## Question 11 - Create /usr/local/bin/d-who that prints the primary group for the suppli (server) - 5 pts

```bash
cat > /usr/local/bin/d-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/d-who
```

---

## Question 12 - Write users whose shell ends with sh to /root/d-shell-users.txt (server) - 5 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/d-shell-users.txt
```

---

## Question 13 - Create gzip archive /root/d-etc.tar.gz containing /etc/hosts and /etc/fs (server) - 5 pts

```bash
tar -czf /root/d-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/d-etc.tar.gz
```

---

## Question 14 - Create /root/d-original, hard link /root/d-hard, and symlink /root/d-sof (server) - 5 pts

```bash
echo link > /root/d-original
ln /root/d-original /root/d-hard
ln -s /root/d-original /root/d-soft
```

---

## Question 15 - Create and enable examdtimer.timer that runs every 10 minutes (server) - 4 pts

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

## Question 16 - Create VG vgd10 and LV datad mounted at /mnt/datad10 (server) - 4 pts

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

## Question 17 - Create /var/www/html/d.html and restore its default SELinux context (server) - 4 pts

```bash
echo d > /var/www/html/d.html
chcon -t user_tmp_t /var/www/html/d.html
restorecon -v /var/www/html/d.html
```

---

## Question 18 - Persistently enable httpd_can_network_connect (server) - 4 pts

```bash
setsebool -P httpd_can_network_connect on
```

---

## Question 19 - Create a cron job for userd10 that writes EXAM10 to /home/userd10/exam10 (server) - 4 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/userd10/exam10.log' | crontab -u userd10 -
```

---

## Question 20 - Configure autofs so /remoted/projects mounts server:/exports/autofs/proj (server) - 4 pts

```bash
mkdir -p /remoted
echo '/remoted /etc/auto.remoted' > /etc/auto.master.d/d.autofs
echo 'projects -ro server:/exports/autofs/projects' > /etc/auto.remoted
systemctl enable --now autofs
```

---

## Question 21 - Set the default target to multi-user.target without rebooting (server) - 4 pts

```bash
systemctl set-default multi-user.target
systemctl get-default
```

---

## Question 22 - Install lsof and ensure tcpdump is removed (server) - 4 pts

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
