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
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.40/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname client.exam-h.lab
```

---

## Question 02 - Host Entry (client) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 registry.exam-h.lab
```

---

## Question 03 - Client Repositories (client) - 5 pts

```bash
cat > /etc/yum.repos.d/exam-h.repo <<'EOF'
[silver-baseos]
name=RHCSA BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[silver-appstream]
name=RHCSA AppStream
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
cat > /etc/yum.repos.d/exam-h.repo <<'EOF'
[silver-baseos]
name=RHCSA BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[silver-appstream]
name=RHCSA AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 05 - Apache SELinux Port (client) - 5 pts

```bash
dnf install -y httpd
grep -Rqs '^Listen 8181$' /etc/httpd/conf /etc/httpd/conf.d || echo 'Listen 8181' > /etc/httpd/conf.d/silverpeak-listen.conf
firewall-cmd --permanent --add-port=8181/tcp
firewall-cmd --reload
semanage port -a -t http_port_t -p tcp 8181 || semanage port -m -t http_port_t -p tcp 8181
mkdir -p /var/www/html
test -s /var/www/html/index.html || echo 'exam-h portal' > /var/www/html/index.html
restorecon -Rv /var/www/html >/dev/null 2>&1 || true
systemctl enable httpd
systemctl restart httpd
```

---

## Question 06 - Pwquality Policy (client) - 5 pts

```bash
mkdir -p /etc/security/pwquality.conf.d
cat > /etc/security/pwquality.conf.d/silverpeak.conf <<'EOF'
minlen = 12
minclass = 3
EOF
```

---

## Question 07 - No-Home User (client) - 5 pts

```bash
id agingh >/dev/null 2>&1 || useradd -M -s /sbin/nologin agingh
usermod -s /sbin/nologin agingh
rm -rf /home/agingh
echo cinder9 | passwd --stdin agingh
```

---

## Question 08 - Per-User Password Aging (client) - 5 pts

```bash
chage -m 2 -M 30 -W 7 agingh
chage -d 0 agingh
```

---

## Question 09 - Sticky Directory (client) - 5 pts

```bash
mkdir -p /srv/silver-drop
chown root:root /srv/silver-drop
chmod 1777 /srv/silver-drop
```

---

## Question 10 - Chrony Server (server) - 5 pts

```bash
# Run on server
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

## Question 11 - Chrony Client (client) - 5 pts

```bash
cat > /etc/chrony.conf <<'EOF'
server server iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
EOF
systemctl enable --now chronyd
```

---

## Question 12 - Firewalld Rich Rule (client) - 5 pts

```bash
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept'
firewall-cmd --reload
```

---

## Question 13 - Useradd Defaults (client) - 4 pts

```bash
useradd -D -f 10
```

---

## Question 14 - Find And Copy (client) - 4 pts

```bash
mkdir -p /root/watcherh-files
find /opt/exam-h/find -user watcherh -mtime -1 -type f -exec cp --parents {} /root/watcherh-files \;
```

---

## Question 15 - Grep Filter (client) - 4 pts

```bash
grep silver /usr/share/dict/words > /root/silver-lines
```

---

## Question 16 - Archive (client) - 4 pts

```bash
tar -czf /root/usr-local-h.tar.gz /usr/local
```

---

## Question 17 - Swap Space (client) - 4 pts

```bash
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 673MiB
blockdev --rereadpt /dev/sdb || true
partprobe /dev/sdb || true
partx -u /dev/sdb || partx -a /dev/sdb || true
udevadm settle
for attempt in 1 2 3 4 5 6 7 8 9 10; do test -b /dev/sdb1 && break; blockdev --rereadpt /dev/sdb || true; partprobe /dev/sdb || true; partx -u /dev/sdb || partx -a /dev/sdb || true; udevadm settle; sleep 1; done
test -b /dev/sdb1
mkswap /dev/sdb1
swapon /dev/sdb1
uuid=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
```

---

## Question 18 - Resize Existing LV (client) - 4 pts

```bash
lvextend -L 320M /dev/reviewvgh/reviewh
resize2fs /dev/reviewvgh/reviewh
```

---

## Question 19 - Boot Target And Services (client) - 4 pts

```bash
systemctl set-default multi-user.target
systemctl enable --now rsyslog
if systemctl list-unit-files postfix.service 2>/dev/null | grep -q '^postfix.service'; then systemctl disable --now postfix; fi
```

---

## Question 20 - Install And Remove Packages (client) - 4 pts

```bash
dnf install -y tree dos2unix
dnf remove -y dos2unix
```

---

## Question 21 - Inspect Container Image (client) - 4 pts

```bash
id inspecth >/dev/null 2>&1 || useradd -m inspecth
echo cinder9 | passwd --stdin inspecth
su - inspecth
podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar
podman image inspect localhost/rhcsa-httpd-base:latest --format {{.Config.WorkingDir}} > ~/workdir.txt
exit
```

---

## Question 22 - Recommended Tuned Profile (client) - 4 pts

```bash
rec="$(tuned-adm recommend | awk 'NF{print $1; exit}')"
test -n "$rec"
tuned-adm profile "$rec"
```
