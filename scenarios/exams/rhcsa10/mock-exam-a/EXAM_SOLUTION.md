# RHCSA 10 Mock Exam A

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-a` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | essential-tools, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

A RHCSA 10 mock exam focused on RHEL 10 administration, Flatpak, systemd timers, storage, networking, users, security, and services.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Configure hostname and hosts entry (server) - 5 pts

```bash
hostnamectl set-hostname clienta.exam10.lab
echo '192.168.122.3 servera.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure IPv4 profile (server) - 5 pts

```bash
nmcli connection modify 'System eth1' ipv4.addresses 192.168.122.60/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up 'System eth1'
```

---

## Question 03 - Configure RPM repositories (server) - 5 pts

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

## Question 04 - Configure Flatpak remote (server) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examaflatpak file:///opt/rhcsa/flatpak/repo
```

---

## Question 05 - Install and remove Flatpak app (server) - 5 pts

```bash
flatpak install --system -y examaflatpak org.rhcsa.Tools
flatpak list --system --app
flatpak uninstall --system -y org.rhcsa.Tools
```

---

## Question 06 - Create user and group (server) - 5 pts

```bash
groupadd teama10
useradd -G teama10 usera10
passwd usera10
# enter: cinder9
```

---

## Question 07 - Delegate sudo access (server) - 5 pts

```bash
echo '%teama10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teama10
chmod 440 /etc/sudoers.d/teama10
```

---

## Question 08 - Set password aging (server) - 5 pts

```bash
chage -M 45 -W 7 usera10
```

---

## Question 09 - Create argument script (server) - 5 pts

```bash
cat > /usr/local/bin/a-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/a-who
```

---

## Question 10 - Filter shell users (server) - 5 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/a-shell-users.txt
```

---

## Question 11 - Create archive (server) - 5 pts

```bash
tar -czf /root/a-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/a-etc.tar.gz
```

---

## Question 12 - Create links (server) - 5 pts

```bash
echo link > /root/a-original
ln /root/a-original /root/a-hard
ln -s /root/a-original /root/a-soft
```

---

## Question 13 - Create systemd timer (server) - 4 pts

```bash
cat > /usr/local/sbin/examatimer.sh <<'EOF'
#!/bin/bash
echo examatimer >> /var/log/examatimer.log
EOF
chmod +x /usr/local/sbin/examatimer.sh
cat > /etc/systemd/system/examatimer.service <<'EOF'
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/examatimer.sh
EOF
cat > /etc/systemd/system/examatimer.timer <<'EOF'
[Timer]
OnCalendar=*:0/10
Persistent=true
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now examatimer.timer
```

---

## Question 14 - Create LVM mount (server) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vga10 /dev/sdb
lvcreate -L 256M -n dataa vga10
mkfs.xfs -f /dev/vga10/dataa
mkdir -p /mnt/dataa10
echo '/dev/vga10/dataa /mnt/dataa10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 15 - Configure firewalld (server) - 4 pts

```bash
firewall-cmd --permanent --add-port=8100/tcp
firewall-cmd --reload
```

---

## Question 16 - Restore SELinux context (server) - 4 pts

```bash
echo a > /var/www/html/a.html
chcon -t user_tmp_t /var/www/html/a.html
restorecon -v /var/www/html/a.html
```

---

## Question 17 - Set SELinux boolean (server) - 4 pts

```bash
setsebool -P httpd_can_network_connect on
```

---

## Question 18 - Create sticky directory (server) - 4 pts

```bash
mkdir -p /srv/teama10
chown root:teama10 /srv/teama10
chmod 3770 /srv/teama10
```

---

## Question 19 - Set tuned profile (server) - 4 pts

```bash
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

## Question 20 - Preserve journal (server) - 4 pts

```bash
mkdir -p /var/log/journal
sed -i 's/^#\?Storage=.*/Storage=persistent/' /etc/systemd/journald.conf
systemctl restart systemd-journald
```

---

## Question 21 - Configure chrony (server) - 4 pts

```bash
sed -i '/^pool /d;/^server /d' /etc/chrony.conf
echo 'server server iburst' >> /etc/chrony.conf
systemctl enable --now chronyd
```

---

## Question 22 - Create cron job (server) - 4 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/usera10/exam10.log' | crontab -u usera10 -
```
