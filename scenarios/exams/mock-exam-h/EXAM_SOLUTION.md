# Mock Exam H

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-h` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, software-management, users-sudo-ssh, processes-logs-tuning, storage-lvm, containers |

A 22 task RHCSA style mock exam covering repositories, SELinux HTTP changes, chrony, package work, and container inspection.

### Systems
- clientvm
- servervm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Client Network (clientvm) - 5 pts

```bash
nmcli device status
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.40/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname clientvm.exam-h.lab
```

---

## Question 02 - Host Entry (clientvm) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 registry.exam-h.lab
```

---

## Question 03 - Client Repositories (clientvm) - 5 pts

```bash
cat > /etc/yum.repos.d/exam-h.repo <<'EOF'
[silver-baseos]
name=RHCSA BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0
[silver-appstream]
name=RHCSA AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 04 - Server Repositories (servervm) - 5 pts

```bash
# Run on servervm
cat > /etc/yum.repos.d/exam-h.repo <<'EOF'
[silver-baseos]
name=RHCSA BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0
[silver-appstream]
name=RHCSA AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 05 - Apache SELinux Port (clientvm) - 5 pts

```bash
dnf install -y httpd
vim /etc/httpd/conf/httpd.conf
Listen 8181
firewall-cmd --permanent --add-port=8181/tcp
firewall-cmd --reload
semanage port -a -t http_port_t -p tcp 8181
systemctl enable --now httpd
```

---

## Question 06 - Pwquality Policy (clientvm) - 5 pts

```bash
mkdir -p /etc/security/pwquality.conf.d
cat > /etc/security/pwquality.conf.d/silverpeak.conf <<'EOF'
minlen = 12
minclass = 3
EOF
```

---

## Question 07 - No-Home User (clientvm) - 5 pts

```bash
useradd -M -s /sbin/nologin agingh
echo cinder9 | passwd --stdin agingh
```

---

## Question 08 - Per-User Password Aging (clientvm) - 5 pts

```bash
chage -m 2 -M 30 -W 7 agingh
chage -d 0 agingh
```

---

## Question 09 - Sticky Directory (clientvm) - 5 pts

```bash
chmod 777 /srv/silver-drop
chmod +t /srv/silver-drop
```

---

## Question 10 - Chrony Server (servervm) - 5 pts

```bash
# Run on servervm
cat > /etc/chrony.conf <<'EOF'
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.122.0/24
local stratum 10
EOF
systemctl enable --now chronyd
```

---

## Question 11 - Chrony Client (clientvm) - 5 pts

```bash
cat > /etc/chrony.conf <<'EOF'
server servervm iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
EOF
systemctl enable --now chronyd
```

---

## Question 12 - Firewalld Rich Rule (clientvm) - 5 pts

```bash
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept'
firewall-cmd --reload
```

---

## Question 13 - Useradd Defaults (clientvm) - 4 pts

```bash
useradd -D -f 10
```

---

## Question 14 - Find And Copy (clientvm) - 4 pts

```bash
mkdir -p /root/watcherh-files
find /opt/exam-h/find -user watcherh -mtime -1 -type f -exec cp --parents {} /root/watcherh-files \;
```

---

## Question 15 - Grep Filter (clientvm) - 4 pts

```bash
grep silver /usr/share/dict/words > /root/silver-lines
```

---

## Question 16 - Archive (clientvm) - 4 pts

```bash
tar -czf /root/usr-local-h.tar.gz /usr/local
```

---

## Question 17 - Swap Space (clientvm) - 4 pts

```bash
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 673MiB
partprobe /dev/sdb
mkswap /dev/sdb1
uuid=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
swapon -a
```

---

## Question 18 - Resize Existing LV (clientvm) - 4 pts

```bash
lvextend -L 320M /dev/reviewvgh/reviewh
resize2fs /dev/reviewvgh/reviewh
```

---

## Question 19 - Boot Target And Services (clientvm) - 4 pts

```bash
systemctl set-default multi-user.target
systemctl enable --now rsyslog
systemctl disable --now postfix
```

---

## Question 20 - Install And Remove Packages (clientvm) - 4 pts

```bash
dnf install -y tree dos2unix
dnf remove -y dos2unix
rpm -q tree
```

---

## Question 21 - Inspect Container Image (clientvm) - 4 pts

```bash
useradd -m inspecth
passwd inspecth
# enter: cinder9
su - inspecth
podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar
podman image inspect localhost/rhcsa-httpd-base:latest --format {{.Config.WorkingDir}} > ~/workdir.txt
```

---

## Question 22 - Recommended Tuned Profile (clientvm) - 4 pts

```bash
tuned-adm profile $(tuned-adm recommend)
tuned-adm active
```
