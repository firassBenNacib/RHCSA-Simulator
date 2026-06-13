# Mock Exam D

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-d` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, software-management, storage-lvm |

A 22-task RHCSA practice mock exam focused on repository hygiene, account defaults, server service state, and logical volume provisioning.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Client Network (client) - 5 pts

```bash
nmcli device status
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.36/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname client.summit.lab
```

---

## Question 02 - Host Entry (client) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 mirror.summit.lab
```

---

## Question 03 - Client Repositories (client) - 5 pts

```bash
cat > /etc/yum.repos.d/summit.repo <<'EOF'
[summit-baseos]
name=Summit BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[summit-appstream]
name=Summit AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 04 - Server Repositories (server) - 5 pts

```bash
# Run on server
cat > /etc/yum.repos.d/summit.repo <<'EOF'
[summit-baseos]
name=Summit BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[summit-appstream]
name=Summit AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 05 - Useradd Defaults (client) - 5 pts

```bash
useradd -D -f 14
```

---

## Question 06 - No-Home User (client) - 5 pts

```bash
useradd -M trainee54
echo cinder9 | passwd --stdin trainee54
```

---

## Question 07 - Admin User (client) - 5 pts

```bash
useradd kara
echo cinder9 | passwd --stdin kara
```

---

## Question 08 - Delegated Sudo (client) - 5 pts

```bash
visudo -f /etc/sudoers.d/kara-systemctl
kara ALL=(root) NOPASSWD: /usr/bin/systemctl restart rsyslog, /usr/bin/systemctl status sshd
```

---

## Question 09 - Server Login Messages (server) - 5 pts

```bash
# Run on server
echo 'Summit maintenance host' > /etc/issue
echo 'Summit maintenance host' > /etc/motd
```

---

## Question 10 - Server Default Target (server) - 5 pts

```bash
# Run on server
systemctl set-default multi-user.target
systemctl enable --now rsyslog
systemctl disable --now postfix
```

---

## Question 11 - Package Management (server) - 5 pts

```bash
# Run on server
dnf install -y tree
dnf remove -y dos2unix
```

---

## Question 12 - Password Aging Defaults (client) - 5 pts

```bash
vim /etc/login.defs
PASS_MAX_DAYS 60
PASS_MIN_DAYS 2
PASS_WARN_AGE 7
```

---

## Question 13 - Forced Password Change (client) - 4 pts

```bash
useradd miles
echo cinder9 | passwd --stdin miles
chage -d 0 miles
```

---

## Question 14 - Fixed UID User (client) - 4 pts

```bash
useradd -u 4540 cedar540
echo cinder9 | passwd --stdin cedar540
```

---

## Question 15 - User Umask (client) - 4 pts

```bash
echo 'umask 027' >> /home/miles/.bash_profile
```

---

## Question 16 - Audit Directory (client) - 4 pts

```bash
mkdir -p /srv/summit-audit
chown root:root /srv/summit-audit
chmod 0750 /srv/summit-audit
```

---

## Question 17 - Find and Copy (client) - 4 pts

```bash
mkdir -p /root/foragerd-files
find /opt/exam-d/find -user foragerd -mtime -1 -type f -exec cp --parents {} /root/foragerd-files \;
```

---

## Question 18 - Grep Filter (client) - 4 pts

```bash
grep alpha /usr/share/dict/words > /root/alpha-lines
```

---

## Question 19 - Archive (client) - 4 pts

```bash
tar -czf /root/summit-etc.tar.gz /etc
```

---

## Question 20 - Shell Script (client) - 4 pts

```bash
cat > /usr/local/bin/summit-scan <<'SCRIPT'
#!/bin/bash
> /root/summit-units.txt
for unit in $(cat /usr/local/share/exam-d/units.lst); do
  systemctl is-active "$unit" >> /root/summit-units.txt
done
SCRIPT
chmod +x /usr/local/bin/summit-scan
/usr/local/bin/summit-scan
```

---

## Question 21 - Swap Space (client) - 4 pts

```bash
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 513MiB
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
uuid=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
```

---

## Question 22 - Create and Mount LV (client) - 4 pts

```bash
parted -s /dev/sdc -- mklabel gpt mkpart primary 1MiB 100% set 1 lvm on
partprobe /dev/sdc
pvcreate /dev/sdc1
vgcreate -s 16M summitvg /dev/sdc1
lvcreate -n summitlv -l 16 summitvg
mkfs.xfs -f /dev/summitvg/summitlv
mkdir -p /mnt/summitlv
uuid=$(blkid -s UUID -o value /dev/summitvg/summitlv)
echo "UUID=$uuid /mnt/summitlv xfs defaults 0 0" >> /etc/fstab
mount -a
```
