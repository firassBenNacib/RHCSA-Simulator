# RHCSA 10 Mock Exam F

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-f` |
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

## Question 01 - Set hostname to clientf.exam10.lab and map serverf.exam10.lab to 192.168 (server) - 5 pts

```bash
hostnamectl set-hostname clientf.exam10.lab
echo '192.168.122.3 serverf.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.65/24, gateway 192.1 (server) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.65/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 03 - Install lsof and ensure tcpdump is removed (server) - 4 pts

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

## Question 04 - Create and enable examftimer.timer that runs every 10 minutes (server) - 4 pts

```bash
cat > /usr/local/sbin/examftimer.sh <<'EOF'
#!/bin/bash
echo examftimer >> /var/log/examftimer.log
EOF
chmod +x /usr/local/sbin/examftimer.sh
cat > /etc/systemd/system/examftimer.service <<'EOF'
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/examftimer.sh
EOF
cat > /etc/systemd/system/examftimer.timer <<'EOF'
[Timer]
OnCalendar=*:0/10
Persistent=true
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now examftimer.timer
```

---

## Question 05 - Allow TCP port 8105 permanently in firewalld and reload (server) - 4 pts

```bash
firewall-cmd --permanent --add-port=8105/tcp
firewall-cmd --reload
```

---

## Question 06 - Persistently enable httpd_can_network_connect (server) - 4 pts

```bash
setsebool -P httpd_can_network_connect on
```

---

## Question 07 - Create enabled BaseOS and AppStream repository definitions using http:// (server) - 5 pts

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

## Question 08 - Create system Flatpak remote examfflatpak pointing to file:///opt/rhcsa/ (server) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examfflatpak file:///opt/rhcsa/flatpak/repo
```

---

## Question 09 - Install org.rhcsa.Tools from examfflatpak, then remove it after verifica (server) - 5 pts

```bash
flatpak install --system -y examfflatpak org.rhcsa.Tools
flatpak list --system --app
flatpak uninstall --system -y org.rhcsa.Tools
```

---

## Question 10 - Create group teamf10, create user userf10, set password cinder9, and add (server) - 5 pts

```bash
groupadd teamf10
useradd -G teamf10 userf10
passwd userf10
# enter: cinder9
```

---

## Question 11 - Allow %teamf10 to run /usr/bin/systemctl without a password by using a s (server) - 5 pts

```bash
echo '%teamf10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teamf10
chmod 440 /etc/sudoers.d/teamf10
```

---

## Question 12 - Set maximum password age for userf10 to 50 days and warning period to 7 (server) - 5 pts

```bash
chage -M 50 -W 7 userf10
```

---

## Question 13 - Create /usr/local/bin/f-who that prints the primary group for the suppli (server) - 5 pts

```bash
cat > /usr/local/bin/f-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/f-who
```

---

## Question 14 - Write users whose shell ends with sh to /root/f-shell-users.txt (server) - 5 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/f-shell-users.txt
```

---

## Question 15 - Create gzip archive /root/f-etc.tar.gz containing /etc/hosts and /etc/fs (server) - 5 pts

```bash
tar -czf /root/f-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/f-etc.tar.gz
```

---

## Question 16 - Create /root/f-original, hard link /root/f-hard, and symlink /root/f-sof (server) - 5 pts

```bash
echo link > /root/f-original
ln /root/f-original /root/f-hard
ln -s /root/f-original /root/f-soft
```

---

## Question 17 - Create VG vgf10 and LV dataf mounted at /mnt/dataf10 (server) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vgf10 /dev/sdb
lvcreate -L 384M -n dataf vgf10
mkfs.xfs -f /dev/vgf10/dataf
mkdir -p /mnt/dataf10
echo '/dev/vgf10/dataf /mnt/dataf10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 18 - Create /var/www/html/f.html and restore its default SELinux context (server) - 4 pts

```bash
echo f > /var/www/html/f.html
chcon -t user_tmp_t /var/www/html/f.html
restorecon -v /var/www/html/f.html
```

---

## Question 19 - Activate the throughput-performance tuned profile (server) - 4 pts

```bash
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

## Question 20 - Configure persistent systemd journal storage (server) - 4 pts

```bash
mkdir -p /var/log/journal
install -D -m 0644 /dev/null /etc/systemd/journald.conf
grep -q '^Storage=' /etc/systemd/journald.conf && sed -i 's/^Storage=.*/Storage=persistent/' /etc/systemd/journald.conf || echo 'Storage=persistent' >> /etc/systemd/journald.conf
systemctl restart systemd-journald
```

---

## Question 21 - Create a cron job for userf10 that writes EXAM10 to /home/userf10/exam10 (server) - 4 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/userf10/exam10.log' | crontab -u userf10 -
```

---

## Question 22 - Set the default target to multi-user.target without rebooting (server) - 4 pts

```bash
systemctl set-default multi-user.target
systemctl get-default
```
