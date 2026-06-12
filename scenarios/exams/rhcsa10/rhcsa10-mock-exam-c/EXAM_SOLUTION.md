# RHCSA 10 Mock Exam C

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-c` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

Web service and network focus: httpd service setup, custom service port, SELinux port labeling, firewalld, Flatpak, client storage, NFS, autofs, users, and scheduling.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - set hostname to clientc.exam10.lab and map serverc.exam10.lab to 192.168 (client) - 5 pts

```bash
hostnamectl set-hostname clientc.exam10.lab
echo '192.168.122.3 serverc.exam10.lab' >> /etc/hosts
```

---

## Question 02 - configure System eth1 with IPv4 address 192.168.122.62/24, gateway 192.1 (client) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.62/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 03 - publish a web page /var/www/html/examc.html containing EXAMC and enable (client) - 5 pts

```bash
mkdir -p /var/www/html
echo EXAMC > /var/www/html/examc.html
restorecon -v /var/www/html/examc.html || true
systemctl enable --now httpd
```

---

## Question 04 - configure httpd to listen on TCP port 8102 and make the port usable by t (client) - 5 pts

```bash
cat > /etc/httpd/conf.d/examc-port.conf <<'EOF'
Listen 8102
EOF
semanage port -a -t http_port_t -p tcp 8102 2>/dev/null || semanage port -m -t http_port_t -p tcp 8102
systemctl restart httpd
```

---

## Question 05 - set the login message to RHCSA10-C authorized access only (client) - 5 pts

```bash
echo 'RHCSA10-C authorized access only' > /etc/motd
```

---

## Question 06 - create /root/c-original, hard link /root/c-hard, and symlink /root/c-sof (client) - 5 pts

```bash
echo link > /root/c-original
ln /root/c-original /root/c-hard
ln -s /root/c-original /root/c-soft
```

---

## Question 07 - create and enable examctimer.timer that runs every 10 minutes (client) - 4 pts

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

## Question 08 - create VG vgc10 and LV datac mounted at /mnt/datac10 (client) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vgc10 /dev/sdb
lvcreate -L 384M -n datac vgc10
mkfs.xfs -f /dev/vgc10/datac
mkdir -p /mnt/datac10
echo '/dev/vgc10/datac /mnt/datac10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 09 - allow TCP port 8102 permanently in firewalld and reload (client) - 4 pts

```bash
firewall-cmd --permanent --add-port=8102/tcp
firewall-cmd --reload
```

---

## Question 10 - create enabled BaseOS and AppStream repository definitions using http:// (client) - 5 pts

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

## Question 11 - create system Flatpak remote examcflatpak pointing to file:///opt/rhcsa/ (client) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examcflatpak file:///opt/rhcsa/flatpak/repo
```

---

## Question 12 - install org.rhcsa.Tools from examcflatpak and leave it installed (client) - 5 pts

```bash
flatpak install --system -y examcflatpak org.rhcsa.Tools
flatpak list --system --app
```

---

## Question 13 - create group teamc10, create user userc10, set password cinder9, and add (client) - 5 pts

```bash
groupadd teamc10
useradd -G teamc10 userc10
passwd userc10
# enter: cinder9
```

---

## Question 14 - allow %teamc10 to run /usr/bin/systemctl without a password by using a s (client) - 5 pts

```bash
echo '%teamc10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teamc10
chmod 440 /etc/sudoers.d/teamc10
```

---

## Question 15 - set maximum password age for userc10 to 47 days and warning period to 7 (client) - 5 pts

```bash
chage -M 47 -W 7 userc10
```

---

## Question 16 - create /var/www/html/c.html and restore its default SELinux context (client) - 4 pts

```bash
echo c > /var/www/html/c.html
chcon -t user_tmp_t /var/www/html/c.html
restorecon -v /var/www/html/c.html
```

---

## Question 17 - activate the throughput-performance tuned profile (client) - 4 pts

```bash
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

## Question 18 - configure persistent systemd journal storage (client) - 4 pts

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

## Question 19 - create a cron job for userc10 that writes EXAM10 to /home/userc10/exam10 (client) - 4 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/userc10/exam10.log' | crontab -u userc10 -
```

---

## Question 20 - mount server:/exports/direct at /mnt/cdirect persistently (client) - 4 pts

```bash
mkdir -p /mnt/cdirect
echo 'server:/exports/direct /mnt/cdirect nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 21 - configure autofs so /remotec/projects mounts server:/exports/autofs/proj (client) - 4 pts

```bash
mkdir -p /remotec
echo '/remotec /etc/auto.remotec' > /etc/auto.master.d/c.autofs
echo 'projects -ro server:/exports/autofs/projects' > /etc/auto.remotec
systemctl enable --now autofs
```

---

## Question 22 - set the default target to multi-user.target without rebooting (client) - 4 pts

```bash
systemctl set-default multi-user.target
systemctl get-default
```
