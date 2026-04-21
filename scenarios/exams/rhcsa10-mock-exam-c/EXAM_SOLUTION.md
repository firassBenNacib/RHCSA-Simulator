# RHCSA 10 Mock Exam C

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-c` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

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
hostnamectl set-hostname clientc.exam10.lab
echo '192.168.122.3 serverc.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure IPv4 profile (server) - 5 pts

```bash
nmcli connection modify 'System eth1' ipv4.addresses 192.168.122.62/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
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
flatpak remote-add --system --if-not-exists --no-gpg-verify examcflatpak file:///opt/rhcsa/flatpak/repo
```

---

## Question 05 - Install and remove Flatpak app (server) - 5 pts

```bash
flatpak install --system -y examcflatpak org.rhcsa.Tools
flatpak list --system --app
flatpak uninstall --system -y org.rhcsa.Tools
```

---

## Question 06 - Create user and group (server) - 5 pts

```bash
groupadd teamc10
useradd -G teamc10 userc10
passwd userc10
# enter: cinder9
```

---

## Question 07 - Delegate sudo access (server) - 5 pts

```bash
echo '%teamc10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teamc10
chmod 440 /etc/sudoers.d/teamc10
```

---

## Question 08 - Set password aging (server) - 5 pts

```bash
chage -M 47 -W 7 userc10
```

---

## Question 09 - Create argument script (server) - 5 pts

```bash
cat > /usr/local/bin/c-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/c-who
```

---

## Question 10 - Filter shell users (server) - 5 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/c-shell-users.txt
```

---

## Question 11 - Create archive (server) - 5 pts

```bash
tar -czf /root/c-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/c-etc.tar.gz
```

---

## Question 12 - Create links (server) - 5 pts

```bash
echo link > /root/c-original
ln /root/c-original /root/c-hard
ln -s /root/c-original /root/c-soft
```

---

## Question 13 - Create systemd timer (server) - 4 pts

```bash
cat > /usr/local/sbin/examctimer.sh <<'EOF'
#!/bin/bash
echo examctimer >> /var/log/examctimer.log
EOF
chmod +x /usr/local/sbin/examctimer.sh
cat > /etc/systemd/system/examctimer.service <<'EOF'
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/examctimer.sh
EOF
cat > /etc/systemd/system/examctimer.timer <<'EOF'
[Timer]
OnCalendar=*:0/10
Persistent=true
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now examctimer.timer
```

---

## Question 14 - Create LVM mount (server) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vgc10 /dev/sdb
lvcreate -L 256M -n datac vgc10
mkfs.xfs -f /dev/vgc10/datac
mkdir -p /mnt/datac10
echo '/dev/vgc10/datac /mnt/datac10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 15 - Configure firewalld (server) - 4 pts

```bash
firewall-cmd --permanent --add-port=8102/tcp
firewall-cmd --reload
```

---

## Question 16 - Restore SELinux context (server) - 4 pts

```bash
echo c > /var/www/html/c.html
chcon -t user_tmp_t /var/www/html/c.html
restorecon -v /var/www/html/c.html
```

---

## Question 17 - Set tuned profile (server) - 4 pts

```bash
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

## Question 18 - Preserve journal (server) - 4 pts

```bash
mkdir -p /var/log/journal
sed -i 's/^#\?Storage=.*/Storage=persistent/' /etc/systemd/journald.conf
systemctl restart systemd-journald
```

---

## Question 19 - Create cron job (server) - 4 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/userc10/exam10.log' | crontab -u userc10 -
```

---

## Question 20 - Mount NFS export (server) - 4 pts

```bash
mkdir -p /mnt/cdirect
echo 'server:/exports/direct /mnt/cdirect nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 21 - Configure autofs (server) - 4 pts

```bash
mkdir -p /remotec
echo '/remotec /etc/auto.remotec' > /etc/auto.master.d/c.autofs
echo 'projects -ro server:/exports/autofs/projects' > /etc/auto.remotec
systemctl enable --now autofs
```

---

## Question 22 - Set default target (server) - 4 pts

```bash
systemctl set-default multi-user.target
systemctl get-default
```
