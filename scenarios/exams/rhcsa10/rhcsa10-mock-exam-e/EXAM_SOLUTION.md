# RHCSA 10 Mock Exam E

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-e` |
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

## Question 01 - Set hostname to cliente.exam10.lab and map servere.exam10.lab to 192.168 (server) - 5 pts

```bash
hostnamectl set-hostname cliente.exam10.lab
echo '192.168.122.3 servere.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.64/24, gateway 192.1 (server) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.64/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
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

## Question 04 - Create system Flatpak remote exameflatpak pointing to file:///opt/rhcsa/ (server) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify exameflatpak file:///opt/rhcsa/flatpak/repo
```

---

## Question 05 - Install org.rhcsa.Tools from exameflatpak, then remove it after verifica (server) - 5 pts

```bash
flatpak install --system -y exameflatpak org.rhcsa.Tools
flatpak list --system --app
flatpak uninstall --system -y org.rhcsa.Tools
```

---

## Question 06 - Create group teame10, create user usere10, set password cinder9, and add (server) - 5 pts

```bash
groupadd teame10
useradd -G teame10 usere10
passwd usere10
# enter: cinder9
```

---

## Question 07 - Allow %teame10 to run /usr/bin/systemctl without a password by using a s (server) - 5 pts

```bash
echo '%teame10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teame10
chmod 440 /etc/sudoers.d/teame10
```

---

## Question 08 - Set maximum password age for usere10 to 49 days and warning period to 7 (server) - 5 pts

```bash
chage -M 49 -W 7 usere10
```

---

## Question 09 - Create /usr/local/bin/e-who that prints the primary group for the suppli (server) - 5 pts

```bash
cat > /usr/local/bin/e-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/e-who
```

---

## Question 10 - Write users whose shell ends with sh to /root/e-shell-users.txt (server) - 5 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/e-shell-users.txt
```

---

## Question 11 - Create gzip archive /root/e-etc.tar.gz containing /etc/hosts and /etc/fs (server) - 5 pts

```bash
tar -czf /root/e-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/e-etc.tar.gz
```

---

## Question 12 - Create /root/e-original, hard link /root/e-hard, and symlink /root/e-sof (server) - 5 pts

```bash
echo link > /root/e-original
ln /root/e-original /root/e-hard
ln -s /root/e-original /root/e-soft
```

---

## Question 13 - Create and enable exametimer.timer that runs every 10 minutes (server) - 4 pts

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

## Question 14 - Create VG vge10 and LV datae mounted at /mnt/datae10 (server) - 4 pts

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

## Question 15 - Allow TCP port 8104 permanently in firewalld and reload (server) - 4 pts

```bash
firewall-cmd --permanent --add-port=8104/tcp
firewall-cmd --reload
```

---

## Question 16 - Create /var/www/html/e.html and restore its default SELinux context (server) - 4 pts

```bash
echo e > /var/www/html/e.html
chcon -t user_tmp_t /var/www/html/e.html
restorecon -v /var/www/html/e.html
```

---

## Question 17 - Activate the throughput-performance tuned profile (server) - 4 pts

```bash
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

## Question 18 - Create a cron job for usere10 that writes EXAM10 to /home/usere10/exam10 (server) - 4 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/usere10/exam10.log' | crontab -u usere10 -
```

---

## Question 19 - Mount server:/exports/direct at /mnt/edirect persistently (server) - 4 pts

```bash
mkdir -p /mnt/edirect
echo 'server:/exports/direct /mnt/edirect nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 20 - Set the default target to multi-user.target without rebooting (server) - 4 pts

```bash
systemctl set-default multi-user.target
systemctl get-default
```

---

## Question 21 - Install lsof and ensure tcpdump is removed (server) - 4 pts

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

## Question 22 - Configure persistent systemd journal storage (server) - 4 pts

```bash
mkdir -p /var/log/journal
install -D -m 0644 /dev/null /etc/systemd/journald.conf
grep -q '^Storage=' /etc/systemd/journald.conf && sed -i 's/^Storage=.*/Storage=persistent/' /etc/systemd/journald.conf || echo 'Storage=persistent' >> /etc/systemd/journald.conf
systemctl restart systemd-journald
```
