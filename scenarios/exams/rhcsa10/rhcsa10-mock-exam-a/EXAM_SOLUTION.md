# RHCSA 10 Mock Exam A

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-a` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, networking-and-firewall, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

A 22-task RHCSA 10 mock exam covering boot recovery, networking, Flatpak management, systemd timers, LVM storage, firewall, SELinux, shell scripting, and chrony time synchronisation across client and server.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Recover root access on client from the console (client) - 5 pts

```bash
# Boot into emergency mode: at GRUB, press 'e', append rd.break to the linux line, Ctrl+X
# mount -o remount,rw /sysroot
# chroot /sysroot
# echo cinder9 | passwd --stdin root
# touch /.autorelabel
# exit; exit
```

---

## Question 02 - Set the hostname on client to clienta.exam10.lab (client) - 5 pts

```bash
hostnamectl set-hostname clienta.exam10.lab
echo '192.168.122.3 servera.exam10.lab' >> /etc/hosts
```

---

## Question 03 - Configure the network connection for eth1 on client with the following s (client) - 5 pts

```bash
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.60/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 04 - Configure the bootloader on client so every installed kernel boots with (client) - 5 pts

```bash
grubby --update-kernel=ALL --args='audit_backlog_limit=8192'
```

---

## Question 05 - Create enabled BaseOS and AppStream repository definitions on client usi (client) - 5 pts

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

## Question 06 - create the same BaseOS and AppStream repository definitions: (server) - 5 pts

```bash
# On server:
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

## Question 07 - add a system-level Flatpak remote named examaflatpak pointing to file:// (client) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examaflatpak file:///opt/rhcsa/flatpak/repo
flatpak install --system -y examaflatpak org.rhcsa.Tools
flatpak list --system --app
```

---

## Question 08 - Create group opsa10 on client (client) - 5 pts

```bash
groupadd opsa10
useradd -G opsa10 anna10
useradd -G opsa10 atlas10
echo cinder9 | passwd --stdin anna10
echo cinder9 | passwd --stdin atlas10
```

---

## Question 09 - allow members of %opsa10 to run /usr/bin/systemctl without a password pr (client) - 5 pts

```bash
echo '%opsa10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/opsa10
chmod 440 /etc/sudoers.d/opsa10
```

---

## Question 10 - set the maximum password age for anna10 to 45 days and the password warn (client) - 5 pts

```bash
chage -M 45 -W 7 anna10
```

---

## Question 11 - Create an executable script /usr/local/bin/a-who on client that accepts (client) - 5 pts

```bash
cat > /usr/local/bin/a-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/a-who
```

---

## Question 12 - write all usernames whose login shell ends with sh to /root/a-shell-user (client) - 5 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/a-shell-users.txt
```

---

## Question 13 - create a gzip-compressed tar archive /root/a-etc.tar.gz containing /etc/ (client) - 4 pts

```bash
tar -czf /root/a-etc.tar.gz /etc/hosts /etc/fstab
```

---

## Question 14 - create a regular file /root/a-original with some content (client) - 4 pts

```bash
echo 'exam-a link test' > /root/a-original
ln /root/a-original /root/a-hard
ln -s /root/a-original /root/a-soft
```

---

## Question 15 - create a systemd timer unit examatimer.timer that triggers an associated (client) - 4 pts

```bash
cat > /usr/local/sbin/examatimer.sh <<'EOF'
#!/bin/bash
echo examatimer ran at $(date) >> /var/log/examatimer.log
EOF
chmod +x /usr/local/sbin/examatimer.sh
cat > /etc/systemd/system/examatimer.service <<'EOF'
[Unit]
Description=Exam A Timer Service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/examatimer.sh
EOF
cat > /etc/systemd/system/examatimer.timer <<'EOF'
[Unit]
Description=Exam A Timer

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

## Question 16 - create volume group vga10 using /dev/sdb (client) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vga10 /dev/sdb
lvcreate -L 384M -n dataa vga10
mkfs.xfs /dev/vga10/dataa
mkdir -p /mnt/dataa10
echo '/dev/vga10/dataa /mnt/dataa10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 17 - permanently allow TCP port 8100 through the firewall and reload firewall (client) - 4 pts

```bash
firewall-cmd --permanent --add-port=8100/tcp
firewall-cmd --reload
```

---

## Question 18 - create the file /var/www/html/a.html and restore its default SELinux con (client) - 4 pts

```bash
mkdir -p /var/www/html
echo 'exam a' > /var/www/html/a.html
restorecon -v /var/www/html/a.html
```

---

## Question 19 - persistently enable the SELinux boolean httpd_can_network_connect (client) - 4 pts

```bash
setsebool -P httpd_can_network_connect on
```

---

## Question 20 - create the directory /srv/opsa10 owned by root:opsa10 with mode 3770 (se (client) - 4 pts

```bash
mkdir -p /srv/opsa10
chown root:opsa10 /srv/opsa10
chmod 3770 /srv/opsa10
```

---

## Question 21 - configure systemd-journald so logs are stored persistently across reboot (server) - 4 pts

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

## Question 22 - configure the server (192.168.122.3) as the only chrony time source (client) - 4 pts

```bash
dnf install -y chrony
sed -i '/^pool /d;/^server /d' /etc/chrony.conf
echo 'server server iburst' >> /etc/chrony.conf
systemctl enable --now chronyd
```
