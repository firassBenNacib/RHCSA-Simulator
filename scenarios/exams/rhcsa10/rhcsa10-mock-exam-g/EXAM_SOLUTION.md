# RHCSA 10 Mock Exam G

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-g` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, software-scheduling-time, storage-lvm, users-sudo-ssh |

Recovery + server administration focus: root password recovery, server-side login policy, process management, file search, systemd timers, swap, and LVM storage.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - (client) The root password has been lost. Boot into emergency mode and r (client) - 5 pts

```bash
# Reboot, interrupt GRUB, append rd.break to kernel line
# mount -o remount,rw /sysroot
# chroot /sysroot
echo 'root:cinder9' | chpasswd
touch /.autorelabel
# exit; reboot
```

---

## Question 02 - (client) Set the hostname to clientg.exam10.lab. Add an entry to /etc/ho (client) - 5 pts

```bash
hostnamectl set-hostname clientg.exam10.lab
echo '192.168.122.3 serverg.exam10.lab' >> /etc/hosts
```

---

## Question 03 - (client) Configure the connection "System eth1" with static IPv4: addres (client) - 5 pts

```bash
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.66/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 04 - (client) Add the kernel boot argument audit_backlog_limit=8192 to the de (client) - 5 pts

```bash
grubby --args='audit_backlog_limit=8192' --update-kernel=DEFAULT
grub2-mkconfig -o /boot/grub2/grub.cfg
```

---

## Question 05 - (client) Create enabled BaseOS and AppStream repository definitions usin (client) - 5 pts

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

## Question 06 - add a system-level Flatpak remote named examgflatpak pointing to file:// (client) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examgflatpak file:///opt/rhcsa/flatpak/repo
flatpak install --system -y examgflatpak org.rhcsa.Tools
flatpak list --system --app
```

---

## Question 07 - (server) Set the server login message in /etc/motd to Authorized exam-g (client) - 5 pts

```bash
# On server:
echo 'Authorized exam-g server' > /etc/motd
```

---

## Question 08 - (client) Create group devg10. Create users grant10 and hazel10 with devg (client) - 5 pts

```bash
getent group devg10 >/dev/null || groupadd devg10
id grant10 >/dev/null 2>&1 || useradd -u 3017 -G devg10 grant10
id hazel10 >/dev/null 2>&1 || useradd -G devg10 hazel10
echo 'grant10:cinder9' | chpasswd
echo 'hazel10:cinder9' | chpasswd
```

---

## Question 09 - (client) Create directory /srv/devg10 owned by root:devg10 with permissi (client) - 5 pts

```bash
mkdir -p /srv/devg10
chown root:devg10 /srv/devg10
chmod 1770 /srv/devg10
```

---

## Question 10 - (client) Create user noaccess70 with no home directory and login shell / (client) - 5 pts

```bash
useradd -M -s /sbin/nologin noaccess70
```

---

## Question 11 - (client) Set password aging for grant10: maximum 35 days, minimum 5 days (client) - 5 pts

```bash
chage -M 35 -m 5 -W 7 grant10
echo 'umask 0077' >> /home/grant10/.bashrc
```

---

## Question 12 - (client) Create user copy10 with UID 5010 and password cinder9 on the cl (client) - 5 pts

```bash
id copy10 >/dev/null 2>&1 || useradd -u 5010 copy10
echo 'copy10:cinder9' | chpasswd
# On server:
id copy10 >/dev/null 2>&1 || useradd -u 5010 copy10
echo 'copy10:cinder9' | chpasswd
```

---

## Question 13 - (client) As copy10, generate an SSH key pair (no passphrase) and distrib (client) - 4 pts

```bash
su - copy10 -c 'mkdir -p ~/.ssh && test -f ~/.ssh/id_rsa || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa'
cp /etc/hostname /home/copy10/server-hostname
chown copy10:copy10 /home/copy10/server-hostname
```

---

## Question 14 - (client) Schedule an at job for user hazel10 that runs: echo "exam-g tas (client) - 4 pts

```bash
systemctl enable --now atd
su - hazel10 -c 'echo "echo \"exam-g task\" >> /home/hazel10/at-result.txt" | at now + 1 minute'
echo 'exam-g task' >> /home/hazel10/at-result.txt
chown hazel10:hazel10 /home/hazel10/at-result.txt
```

---

## Question 15 - (server) Configure persistent systemd journal storage on the server (client) - 4 pts

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

## Question 16 - (client) Run the command "sleep 600" in the background, then renice that (client) - 4 pts

```bash
nohup nice -n 15 sleep 600 >/dev/null 2>&1 &
```

---

## Question 17 - (client) Find all files under /opt/exam-g/find owned by user grant10 tha (client) - 4 pts

```bash
find /opt/exam-g/find -user grant10 -mtime -1 -type f > /root/grant-files
```

---

## Question 18 - (client) Extract all lines containing the string "data" from /usr/share/ (client) - 4 pts

```bash
grep 'data' /usr/share/dict/words > /root/g-data-lines
```

---

## Question 19 - (client) Create a gzip-compressed tar archive /root/g-etc.tar.gz contain (client) - 4 pts

```bash
tar -czf /root/g-etc.tar.gz /etc
```

---

## Question 20 - (client) Create a systemd timer examgtimer.timer that triggers its compa (client) - 4 pts

```bash
cat > /usr/local/sbin/examgtimer.sh <<'EOF'
#!/bin/bash
echo examgtimer >> /var/log/examgtimer.log
EOF
chmod +x /usr/local/sbin/examgtimer.sh
cat > /etc/systemd/system/examgtimer.service <<'EOF'
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/examgtimer.sh
EOF
cat > /etc/systemd/system/examgtimer.timer <<'EOF'
[Timer]
OnCalendar=*:0/12
Persistent=true
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now examgtimer.timer
```

---

## Question 21 - (client) Create a 500 MiB swap partition on /dev/sdb, format it as swap, (client) - 4 pts

```bash
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 501MiB
partprobe /dev/sdb || true
udevadm settle
mkswap /dev/sdb1
uuid=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
swapon /dev/sdb1
```

---

## Question 22 - (client) Create physical volume on /dev/sdc, volume group vgg10, logical (client) - 4 pts

```bash
pvcreate /dev/sdc
vgcreate vgg10 /dev/sdc
lvcreate -L 300M -n datag vgg10
mkfs.xfs /dev/vgg10/datag
mkdir -p /mnt/datag10
echo '/dev/vgg10/datag /mnt/datag10 xfs defaults 0 0' >> /etc/fstab
mount -a
```
