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

## Question 01 - set hostname to clientf.exam10.lab and map serverf.exam10.lab to 192.168 (client) - 5 pts

```bash
hostnamectl set-hostname clientf.exam10.lab
echo '192.168.122.3 serverf.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.65/24, gateway 192.1 (client) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.65/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 03 - copy regular files owned by root from /opt/exam-f/find to /root/examf-ro (client) - 4 pts

```bash
mkdir -p /root/examf-rootfiles
find /opt/exam-f/find -type f -user root -exec cp --parents -t /root/examf-rootfiles {} +
find /root/examf-rootfiles -type f -print
```

---

## Question 04 - create a 500 MiB swap partition on /dev/sdc and make it active and persi (client) - 4 pts

```bash
parted -s /dev/sdc -- mklabel gpt mkpart primary linux-swap 1MiB 501MiB
partprobe /dev/sdc || true
udevadm settle
mkswap /dev/sdc1
uuid=$(blkid -s UUID -o value /dev/sdc1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
swapon /dev/sdc1
```

---

## Question 05 - Activate the throughput-performance tuned profile (client) - 4 pts

```bash
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

## Question 06 - Create system Flatpak remote examfflatpak pointing to file:///opt/rhcsa/ (client) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examfflatpak file:///opt/rhcsa/flatpak/repo
```

---

## Question 07 - Ensure org.rhcsa.Tools is not installed after configuring examfflatpak (client) - 5 pts

```bash
flatpak uninstall --system -y org.rhcsa.Tools >/dev/null 2>&1 || true
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

## Question 09 - Allow %teamf10 to run /usr/bin/systemctl without a password by using a s (client) - 5 pts

```bash
echo '%teamf10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teamf10
chmod 440 /etc/sudoers.d/teamf10
```

---

## Question 10 - Create group teamf10, create user userf10, set password cinder9, and add (client) - 5 pts

```bash
groupadd teamf10
useradd -G teamf10 userf10
passwd userf10
# enter: cinder9
```

---

## Question 11 - Create a cron job for userf10 that writes EXAM10 to /home/userf10/exam10 (client) - 4 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/userf10/exam10.log' | crontab -u userf10 -
```

---

## Question 12 - Create /usr/local/bin/f-who that prints the primary group for the suppli (client) - 5 pts

```bash
cat > /usr/local/bin/f-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/f-who
```

---

## Question 13 - Set the default target to multi-user.target without rebooting (client) - 4 pts

```bash
systemctl set-default multi-user.target
systemctl get-default
```

---

## Question 14 - Create gzip archive /root/f-etc.tar.gz containing /etc/hosts and /etc/fs (client) - 5 pts

```bash
tar -czf /root/f-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/f-etc.tar.gz
```

---

## Question 15 - Install lsof and ensure tcpdump is removed (client) - 4 pts

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

## Question 16 - Create and enable examftimer.timer that runs every 10 minutes (client) - 4 pts

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

## Question 17 - Allow TCP port 8105 permanently in firewalld and reload (client) - 4 pts

```bash
firewall-cmd --permanent --add-port=8105/tcp
firewall-cmd --reload
```

---

## Question 18 - Create enabled BaseOS and AppStream repository definitions using http:// (client) - 5 pts

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

## Question 19 - Set maximum password age for userf10 to 50 days and warning period to 7 (client) - 5 pts

```bash
chage -M 50 -W 7 userf10
```

---

## Question 20 - create and enable examf-cleanup.service so it writes F-CLEANUP to /var/l (client) - 5 pts

```bash
cat > /usr/local/sbin/examf-cleanup.sh <<'EOF'
#!/bin/bash
echo F-CLEANUP >> /var/log/examf-cleanup.log
EOF
chmod +x /usr/local/sbin/examf-cleanup.sh
cat > /etc/systemd/system/examf-cleanup.service <<'EOF'
[Unit]
Description=Exam F cleanup marker

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/examf-cleanup.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now examf-cleanup.service
```

---

## Question 21 - Create /root/f-original, hard link /root/f-hard, and symlink /root/f-sof (client) - 5 pts

```bash
echo link > /root/f-original
ln /root/f-original /root/f-hard
ln -s /root/f-original /root/f-soft
```

---

## Question 22 - Create VG vgf10 and LV dataf mounted at /mnt/dataf10 (client) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vgf10 /dev/sdb
lvcreate -L 384M -n dataf vgf10
mkfs.xfs -f /dev/vgf10/dataf
mkdir -p /mnt/dataf10
echo '/dev/vgf10/dataf /mnt/dataf10 xfs defaults 0 0' >> /etc/fstab
mount -a
```
