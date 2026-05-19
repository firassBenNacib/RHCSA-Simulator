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

## Question 01 - Set hostname to clienta.exam10.lab and map servera.exam10.lab to 192.168 (server) - 5 pts

```bash
hostnamectl set-hostname clienta.exam10.lab
echo '192.168.122.3 servera.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.60/24, gateway 192.1 (server) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.60/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 03 - Create enabled BaseOS and AppStream repository definitions using http:// (server) - 5 pts

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

## Question 04 - Create system Flatpak remote examaflatpak pointing to file:///opt/rhcsa/ (server) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examaflatpak file:///opt/rhcsa/flatpak/repo
```

---

## Question 05 - Install org.rhcsa.Tools from examaflatpak, then remove it after verifica (server) - 5 pts

```bash
flatpak install --system -y examaflatpak org.rhcsa.Tools
flatpak list --system --app
flatpak uninstall --system -y org.rhcsa.Tools
```

---

## Question 06 - Create group teama10, create user usera10, set password cinder9, and add (server) - 5 pts

```bash
groupadd teama10
useradd -G teama10 usera10
passwd usera10
# enter: cinder9
```

---

## Question 07 - Allow %teama10 to run /usr/bin/systemctl without a password by using a s (server) - 5 pts

```bash
echo '%teama10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teama10
chmod 440 /etc/sudoers.d/teama10
```

---

## Question 08 - Set maximum password age for usera10 to 45 days and warning period to 7 (server) - 5 pts

```bash
chage -M 45 -W 7 usera10
```

---

## Question 09 - Create /usr/local/bin/a-who that prints the primary group for the suppli (server) - 5 pts

```bash
cat > /usr/local/bin/a-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/a-who
```

---

## Question 10 - Write users whose shell ends with sh to /root/a-shell-users.txt (server) - 5 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/a-shell-users.txt
```

---

## Question 11 - Create gzip archive /root/a-etc.tar.gz containing /etc/hosts and /etc/fs (server) - 5 pts

```bash
tar -czf /root/a-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/a-etc.tar.gz
```

---

## Question 12 - Create /root/a-original, hard link /root/a-hard, and symlink /root/a-sof (server) - 5 pts

```bash
echo link > /root/a-original
ln /root/a-original /root/a-hard
ln -s /root/a-original /root/a-soft
```

---

## Question 13 - Create and enable examatimer.timer that runs every 10 minutes (server) - 4 pts

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

## Question 14 - Create VG vga10 and LV dataa mounted at /mnt/dataa10 (server) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vga10 /dev/sdb
lvcreate -L 384M -n dataa vga10
mkfs.xfs -f /dev/vga10/dataa
mkdir -p /mnt/dataa10
echo '/dev/vga10/dataa /mnt/dataa10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 15 - Allow TCP port 8100 permanently in firewalld and reload (server) - 4 pts

```bash
firewall-cmd --permanent --add-port=8100/tcp
firewall-cmd --reload
```

---

## Question 16 - Create /var/www/html/a.html and restore its default SELinux context (server) - 4 pts

```bash
echo a > /var/www/html/a.html
chcon -t user_tmp_t /var/www/html/a.html
restorecon -v /var/www/html/a.html
```

---

## Question 17 - Persistently enable httpd_can_network_connect (server) - 4 pts

```bash
setsebool -P httpd_can_network_connect on
```

---

## Question 18 - Create /srv/teama10 owned by root:teama10 with mode 3770 (server) - 4 pts

```bash
mkdir -p /srv/teama10
chown root:teama10 /srv/teama10
chmod 3770 /srv/teama10
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

## Question 21 - Use server as the only chrony source and enable chronyd (server) - 4 pts

```bash
sed -i '/^pool /d;/^server /d' /etc/chrony.conf
echo 'server server iburst' >> /etc/chrony.conf
systemctl enable --now chronyd
```

---

## Question 22 - Create a cron job for usera10 that writes EXAM10 to /home/usera10/exam10 (server) - 4 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/usera10/exam10.log' | crontab -u usera10 -
```
