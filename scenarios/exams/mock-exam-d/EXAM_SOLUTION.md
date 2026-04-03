# Mock Exam D

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-d` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, software-management, storage-lvm |

A 22 task RHCSA style mock exam focused on repository hygiene, account defaults, server service state, and logical volume provisioning.

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
nmcli device status
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.36/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname clientvm.summit.lab
```

---

## Question 02 - Host Entry (clientvm) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 mirror.summit.lab
```

---

## Question 03 - Client Repositories (clientvm) - 5 pts

```bash
cat > /etc/yum.repos.d/summit.repo <<'EOF'
[summit-baseos]
name=Summit BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0
[summit-appstream]
name=Summit AppStream
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
cat > /etc/yum.repos.d/summit.repo <<'EOF'
[summit-baseos]
name=Summit BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0
[summit-appstream]
name=Summit AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 05 - Useradd Defaults (clientvm) - 5 pts

```bash
useradd -D -f 14
```

---

## Question 06 - No-Home User (clientvm) - 5 pts

```bash
useradd -M trainee54
echo cinder9 | passwd --stdin trainee54
```

---

## Question 07 - Admin User (clientvm) - 5 pts

```bash
useradd kara
echo cinder9 | passwd --stdin kara
```

---

## Question 08 - Delegated Sudo (clientvm) - 5 pts

```bash
visudo -f /etc/sudoers.d/kara-systemctl
kara ALL=(root) NOPASSWD: /usr/bin/systemctl restart rsyslog, /usr/bin/systemctl status sshd
```

---

## Question 09 - Server Login Messages (servervm) - 5 pts

```bash
# Run on servervm
echo 'Summit maintenance host' > /etc/issue
echo 'Summit maintenance host' > /etc/motd
```

---

## Question 10 - Server Default Target (servervm) - 5 pts

```bash
# Run on servervm
systemctl set-default multi-user.target
systemctl enable --now rsyslog
systemctl disable --now postfix
```

---

## Question 11 - Package Management (servervm) - 5 pts

```bash
# Run on servervm
dnf install -y tree
dnf remove -y dos2unix
```

---

## Question 12 - Password Aging Defaults (clientvm) - 5 pts

```bash
vim /etc/login.defs
PASS_MAX_DAYS 60
PASS_MIN_DAYS 2
PASS_WARN_AGE 7
```

---

## Question 13 - Forced Password Change (clientvm) - 4 pts

```bash
useradd miles
echo cinder9 | passwd --stdin miles
chage -d 0 miles
```

---

## Question 14 - Fixed UID User (clientvm) - 4 pts

```bash
useradd -u 4540 cedar540
echo cinder9 | passwd --stdin cedar540
```

---

## Question 15 - User Umask (clientvm) - 4 pts

```bash
echo 'umask 027' >> /home/miles/.bash_profile
```

---

## Question 16 - Audit Directory (clientvm) - 4 pts

```bash
mkdir -p /srv/summit-audit
chown root:root /srv/summit-audit
chmod 0750 /srv/summit-audit
```

---

## Question 17 - Audit Directory (clientvm) - 4 pts

```bash
mkdir -p /srv/summit-audit
chown root:root /srv/summit-audit
chmod 0750 /srv/summit-audit
```

---

## Question 18 - Audit Directory (clientvm) - 4 pts

```bash
mkdir -p /srv/summit-audit
chown root:root /srv/summit-audit
chmod 0750 /srv/summit-audit
```

---

## Question 19 - Audit Directory (clientvm) - 4 pts

```bash
mkdir -p /srv/summit-audit
chown root:root /srv/summit-audit
chmod 0750 /srv/summit-audit
```

---

## Question 20 - Audit Directory (clientvm) - 4 pts

```bash
mkdir -p /srv/summit-audit
chown root:root /srv/summit-audit
chmod 0750 /srv/summit-audit
```

---

## Question 21 - Audit Directory (clientvm) - 4 pts

```bash
mkdir -p /srv/summit-audit
chown root:root /srv/summit-audit
chmod 0750 /srv/summit-audit
```

---

## Question 22 - Find And Copy (clientvm) - 4 pts

```bash
mkdir -p /root/miles-files
find /opt/exam-d/find -user foragerd -mtime -1 -type f -exec cp --parents {} /root/miles-files \;
```
