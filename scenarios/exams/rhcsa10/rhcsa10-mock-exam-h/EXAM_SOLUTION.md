# RHCSA 10 Mock Exam H

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-h` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

A RHCSA 10 mock exam focused on RHEL 10 administration, Flatpak, systemd timers, storage, networking, users, security, and services.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Set hostname to clienth.exam10.lab and map serverh.exam10.lab to 192.168 (server) - 5 pts

```bash
hostnamectl set-hostname clienth.exam10.lab
echo '192.168.122.3 serverh.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.67/24, gateway 192.1 (server) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.67/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 03 - Create system Flatpak remote examhflatpak pointing to file:///opt/rhcsa/ (server) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examhflatpak file:///opt/rhcsa/flatpak/repo
```

---

## Question 04 - Install org.rhcsa.Tools from examhflatpak, then remove it after verifica (server) - 5 pts

```bash
flatpak install --system -y examhflatpak org.rhcsa.Tools
flatpak list --system --app
flatpak uninstall --system -y org.rhcsa.Tools
```

---

## Question 05 - Create and enable examhtimer.timer that runs every 10 minutes (server) - 4 pts

```bash
cat > /usr/local/sbin/examhtimer.sh <<'EOF'
#!/bin/bash
echo examhtimer >> /var/log/examhtimer.log
EOF
chmod +x /usr/local/sbin/examhtimer.sh
cat > /etc/systemd/system/examhtimer.service <<'EOF'
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/examhtimer.sh
EOF
cat > /etc/systemd/system/examhtimer.timer <<'EOF'
[Timer]
OnCalendar=*:0/10
Persistent=true
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now examhtimer.timer
```

---

## Question 06 - Create group teamh10, create user userh10, set password cinder9, and add (server) - 5 pts

```bash
groupadd teamh10
useradd -G teamh10 userh10
passwd userh10
# enter: cinder9
```

---

## Question 07 - Set maximum password age for userh10 to 52 days and warning period to 7 (server) - 5 pts

```bash
chage -M 52 -W 7 userh10
```

---

## Question 08 - Persistently enable httpd_can_network_connect (server) - 4 pts

```bash
setsebool -P httpd_can_network_connect on
```

---

## Question 09 - Write users whose shell ends with sh to /root/h-shell-users.txt (server) - 5 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/h-shell-users.txt
```

---

## Question 10 - Configure persistent systemd journal storage (server) - 4 pts

```bash
mkdir -p /var/log/journal
install -D -m 0644 /dev/null /etc/systemd/journald.conf
grep -q '^Storage=' /etc/systemd/journald.conf && sed -i 's/^Storage=.*/Storage=persistent/' /etc/systemd/journald.conf || echo 'Storage=persistent' >> /etc/systemd/journald.conf
systemctl restart systemd-journald
```

---

## Question 11 - Create /root/h-original, hard link /root/h-hard, and symlink /root/h-sof (server) - 5 pts

```bash
echo link > /root/h-original
ln /root/h-original /root/h-hard
ln -s /root/h-original /root/h-soft
```

---

## Question 12 - Create a cron job for userh10 that writes EXAM10 to /home/userh10/exam10 (server) - 4 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/userh10/exam10.log' | crontab -u userh10 -
```

---

## Question 13 - Create VG vgh10 and LV datah mounted at /mnt/datah10 (server) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vgh10 /dev/sdb
lvcreate -L 384M -n datah vgh10
mkfs.xfs -f /dev/vgh10/datah
mkdir -p /mnt/datah10
echo '/dev/vgh10/datah /mnt/datah10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 14 - Set the default target to multi-user.target without rebooting (server) - 4 pts

```bash
systemctl set-default multi-user.target
systemctl get-default
```

---

## Question 15 - Activate the throughput-performance tuned profile (server) - 4 pts

```bash
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

## Question 16 - Install lsof and ensure tcpdump is removed (server) - 4 pts

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

## Question 17 - Use server as the only chrony source and enable chronyd (server) - 4 pts

```bash
sed -i '/^pool /d;/^server /d' /etc/chrony.conf
echo 'server server iburst' >> /etc/chrony.conf
systemctl enable --now chronyd
```

---

## Question 18 - Allow TCP port 8107 permanently in firewalld and reload (server) - 4 pts

```bash
firewall-cmd --permanent --add-port=8107/tcp
firewall-cmd --reload
```

---

## Question 19 - Create enabled BaseOS and AppStream repository definitions using http:// (server) - 5 pts

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

## Question 20 - Allow %teamh10 to run /usr/bin/systemctl without a password by using a s (server) - 5 pts

```bash
echo '%teamh10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teamh10
chmod 440 /etc/sudoers.d/teamh10
```

---

## Question 21 - Create /usr/local/bin/h-who that prints the primary group for the suppli (server) - 5 pts

```bash
cat > /usr/local/bin/h-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/h-who
```

---

## Question 22 - Create gzip archive /root/h-etc.tar.gz containing /etc/hosts and /etc/fs (server) - 5 pts

```bash
tar -czf /root/h-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/h-etc.tar.gz
```
