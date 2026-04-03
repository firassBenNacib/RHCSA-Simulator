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
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.36/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
hostnamectl set-hostname clientvm.summit.lab
```

---

## Question 02 - Host Entry (clientvm) - 5 pts

```bash
grep -q 'mirror.summit.lab' /etc/hosts || echo '192.168.122.3 mirror.summit.lab' >> /etc/hosts
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
sed -ri 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS	60/; s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS	2/; s/^PASS_WARN_AGE.*/PASS_WARN_AGE	7/' /etc/login.defs
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
install -d -m 0750 -o root -g root /srv/summit-audit
```

---

## Question 17 - Audit Directory (clientvm) - 4 pts

```bash
install -d -m 0750 -o root -g root /srv/summit-audit
```

---

## Question 18 - Audit Directory (clientvm) - 4 pts

```bash
install -d -m 0750 -o root -g root /srv/summit-audit
```

---

## Question 19 - Audit Directory (clientvm) - 4 pts

```bash
install -d -m 0750 -o root -g root /srv/summit-audit
```

---

## Question 20 - Find And Copy (clientvm) - 4 pts

```bash
mkdir -p /root/miles-files
find /opt/exam-d/find -user foragerd -mtime -1 -type f -exec cp --parents {} /root/miles-files \;
```

---

## Question 21 - Grep Filter (clientvm) - 4 pts

```bash
grep alpha /usr/share/dict/words > /root/alpha-lines
```

---

## Question 22 - Archive (clientvm) - 4 pts

```bash
tar -czf /root/summit-etc.tar.gz /etc
```

---

## Verification
```bash
hostnamectl --static | grep -qx 'clientvm.summit.lab' && grep -Fqx '192.168.122.3 mirror.summit.lab' /etc/hosts && curl -fsS http://servervm/repo/BaseOS/repodata/repomd.xml >/dev/null && ssh admin@servervm sudo curl -fsS http://servervm/repo/AppStream/repodata/repomd.xml >/dev/null
useradd -D | grep -Eq 'INACTIVE=14' && getent passwd trainee54 | awk -F: '{print $6}' | grep -qx '' && getent passwd cedar540 | awk -F: '{print $3}' | grep -qx '4540' && grep -Eq '^kara .*NOPASSWD: /usr/bin/systemctl restart rsyslog, /usr/bin/systemctl status sshd$' /etc/sudoers.d/kara-systemctl && grep -Eq '^PASS_MAX_DAYS\s+60$' /etc/login.defs && grep -Eq '^PASS_MIN_DAYS\s+2$' /etc/login.defs && grep -Eq '^PASS_WARN_AGE\s+7$' /etc/login.defs && grep -Fqx 'umask 027' /home/miles/.bash_profile && stat -c '%a %U:%G' /srv/summit-audit | grep -qx '750 root:root'
chage -l miles | grep -Eq 'Last password change.*password must be changed' || chage -l miles | grep -Eq 'Password expires.*password must be changed'
test -f /root/foragerd-files/opt/exam-d/find/a/file1.txt && grep -q 'alpha' /root/alpha-lines && test -f /root/summit-etc.tar.gz && /usr/local/bin/summit-scan >/dev/null && test -s /root/summit-units.txt
swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && findmnt /mnt/summitlv >/dev/null && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1=="summitlv" && $2=="summitvg" && $3>=255 && $3<=257{f=1} END{exit !f}'
ssh admin@servervm sudo grep -Fqx 'Summit maintenance host' /etc/issue && ssh admin@servervm sudo grep -Fqx 'Summit maintenance host' /etc/motd && ssh admin@servervm systemctl get-default | grep -qx multi-user.target && ssh admin@servervm systemctl is-enabled rsyslog | grep -qx enabled && ssh admin@servervm systemctl is-enabled postfix | grep -qx disabled && ssh admin@servervm rpm -q tree >/dev/null && ! ssh admin@servervm rpm -q dos2unix >/dev/null 2>&1
```
