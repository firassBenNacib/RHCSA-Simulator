# Mock Exam H: SilverPeak Service Review

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
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Client Network (clientvm) - 5 pts

```bash
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.40/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
hostnamectl set-hostname clientvm.silverpeak.lab
```

---

## Question 02 - Host Entry (clientvm) - 5 pts

```bash
grep -q 'registry.silverpeak.lab' /etc/hosts || echo '192.168.122.3 registry.silverpeak.lab' >> /etc/hosts
```

---

## Question 03 - Client Repositories (clientvm) - 5 pts

```bash
cat > /etc/yum.repos.d/silverpeak.repo <<'EOF'
[silver-baseos]
name=SilverPeak BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[silver-appstream]
name=SilverPeak AppStream
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
cat > /etc/yum.repos.d/silverpeak.repo <<'EOF'
[silver-baseos]
name=SilverPeak BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[silver-appstream]
name=SilverPeak AppStream
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
sed -i 's/^Listen .*/Listen 8181/' /etc/httpd/conf/httpd.conf
firewall-cmd --permanent --add-port=8181/tcp
firewall-cmd --reload
semanage port -a -t http_port_t -p tcp 8181 || semanage port -m -t http_port_t -p tcp 8181
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
install -d -m 1777 -o root -g root /srv/silver-drop
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
fdisk /dev/sdb
# g
# n
# <Enter>
# <Enter>
# +672M
# t
# 19
# w
mkswap /dev/sdb1
vim /etc/fstab
blkid /dev/sdb1
vim /etc/fstab
# Add the swap entry with the UUID reported above
:wq
:wq
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
id inspecth || useradd -m inspecth
passwd inspecth
# enter: cinder9
runuser -l inspecth -c "podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar"
runuser -l inspecth -c "podman image inspect localhost/rhcsa-httpd-base:latest --format {{.Config.WorkingDir}} > ~/workdir.txt"
```

---

## Question 22 - Recommended Tuned Profile (clientvm) - 4 pts

```bash
tuned-adm profile $(tuned-adm recommend)
tuned-adm active
```

---

## Verification
```bash
hostnamectl --static | grep -qx 'clientvm.silverpeak.lab' && grep -Fqx '192.168.122.3 registry.silverpeak.lab' /etc/hosts && curl -fsS http://servervm/repo/BaseOS/repodata/repomd.xml >/dev/null && ssh admin@servervm sudo curl -fsS http://servervm/repo/AppStream/repodata/repomd.xml >/dev/null
curl -fsS http://localhost:8181 >/dev/null && semanage port -l | grep -Eq '^http_port_t\b.*\b8181\b' && firewall-cmd --list-rich-rules | grep -Fq 'port port="2222" protocol="tcp" accept'
grep -Eq '^minlen\s*=\s*12$' /etc/security/pwquality.conf.d/silverpeak.conf && grep -Eq '^minclass\s*=\s*3$' /etc/security/pwquality.conf.d/silverpeak.conf && getent passwd agingh | awk -F: '{print $6":"$7}' | grep -qx ':/sbin/nologin' && chage -l agingh | grep -Eq 'Minimum.*2' && chage -l agingh | grep -Eq 'Maximum.*30' && chage -l agingh | grep -Eq 'warning.*7' && chage -l agingh | grep -Eq 'password must be changed|must be changed' && useradd -D | grep -Eq 'INACTIVE=10' && stat -c '%a %U:%G' /srv/silver-drop | grep -qx '1777 root:root'
grep -Eq '^server servervm iburst$' /etc/chrony.conf && systemctl is-enabled chronyd | grep -qx enabled && ssh admin@servervm sudo grep -Eq '^allow 192\.168\.122\.0/24$' /etc/chrony.conf && ssh admin@servervm sudo systemctl is-enabled chronyd | grep -qx enabled
test -f /root/watcherh-files/opt/exam-h/find/a/file1.txt && grep -q 'silver' /root/silver-lines && test -f /root/usr-local-h.tar.gz && swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1=="reviewh" && $2=="reviewvgh" && $3>=319 && $3<=321{f=1} END{exit !f}' && systemctl get-default | grep -qx multi-user.target && systemctl is-enabled rsyslog | grep -qx enabled && systemctl is-enabled postfix | grep -qx disabled && rpm -q tree >/dev/null && ! rpm -q dos2unix >/dev/null 2>&1
runuser -l inspecth -c 'podman image exists localhost/rhcsa-httpd-base:latest' && test -s /home/inspecth/workdir.txt && rec="$(tuned-adm recommend | awk '{print $1}')"; act="$(tuned-adm active | sed -E 's/.*: ([^ ]+).*/\1/')"; test -n "$rec" && test "$act" = "$rec"
```
