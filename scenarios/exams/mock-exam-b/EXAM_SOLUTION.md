# Mock Exam B

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-b` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, processes-logs-tuning, storage-lvm |

A 22 task RHCSA style mock exam emphasizing chrony, SSH hardening, user defaults, and storage administration.

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
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.27/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname client.exam-b.lab
```

---

## Question 02 - Host Entry (client) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 registry.exam-b.lab
```

---

## Question 03 - Chrony Server (server) - 5 pts

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

## Question 04 - Chrony Client (client) - 5 pts

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

## Question 05 - Useradd Defaults (client) - 5 pts

```bash
useradd -D -f 20
```

---

## Question 06 - No-Home UID User (client) - 5 pts

```bash
useradd -M -u 4421 cato421
echo cinder9 | passwd --stdin cato421
```

---

## Question 07 - Primary Login User (client) - 5 pts

```bash
useradd mira
echo cinder9 | passwd --stdin mira
```

---

## Question 08 - Password Aging (client) - 5 pts

```bash
useradd jonas
echo cinder9 | passwd --stdin jonas
chage -M 45 -m 5 -W 7 jonas
```

---

## Question 09 - Pwquality Policy (client) - 5 pts

```bash
mkdir -p /etc/security/pwquality.conf.d
cat > /etc/security/pwquality.conf.d/coremesh.conf <<'EOF'
minlen = 12
minclass = 3
EOF
```

---

## Question 10 - Delegated Sudo (client) - 5 pts

```bash
visudo -f /etc/sudoers.d/mira-firewalld
mira ALL=(root) NOPASSWD: /usr/bin/systemctl restart firewalld
```

---

## Question 11 - SSH Port (server) - 5 pts

```bash
# Run on server
vim /etc/ssh/sshd_config
Port 2222
PasswordAuthentication yes
PubkeyAuthentication yes
systemctl restart sshd
```

---

## Question 12 - Rich Rule (server) - 5 pts

```bash
# Run on server
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept'
firewall-cmd --reload
```

---

## Question 13 - SSH Key Generation (client) - 4 pts

```bash
su - mira
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
```

---

## Question 14 - Passwordless SSH (server) - 4 pts

```bash
# Run on server
id meshremote >/dev/null 2>&1 || useradd meshremote
echo cinder9 | passwd --stdin meshremote
mkdir -p /home/meshremote/inbox
chown meshremote:meshremote /home/meshremote/inbox
chmod 0755 /home/meshremote/inbox
su - mira
ssh-copy-id -p 2222 meshremote@server
ssh -p 2222 -o BatchMode=yes meshremote@server true
```

---

## Question 15 - Rsync Transfer (server) - 4 pts

```bash
su - mira
rsync -e "ssh -p 2222" /opt/exam-b/report.txt meshremote@server:/home/meshremote/inbox/report.txt
```

---

## Question 16 - Passwordless SSH (server) - 4 pts

```bash
# Run on server
id meshremote >/dev/null 2>&1 || useradd meshremote
echo cinder9 | passwd --stdin meshremote
mkdir -p /home/meshremote/inbox
chown meshremote:meshremote /home/meshremote/inbox
chmod 0755 /home/meshremote/inbox
su - mira
ssh-copy-id -p 2222 meshremote@server
ssh -p 2222 -o BatchMode=yes meshremote@server true
```

---

## Question 17 - Rsync Transfer (server) - 4 pts

```bash
su - mira
rsync -e "ssh -p 2222" /opt/exam-b/report.txt meshremote@server:/home/meshremote/inbox/report.txt
```

---

## Question 18 - Passwordless SSH (server) - 4 pts

```bash
# Run on server
id meshremote >/dev/null 2>&1 || useradd meshremote
echo cinder9 | passwd --stdin meshremote
mkdir -p /home/meshremote/inbox
chown meshremote:meshremote /home/meshremote/inbox
chmod 0755 /home/meshremote/inbox
su - mira
ssh-copy-id -p 2222 meshremote@server
ssh -p 2222 -o BatchMode=yes meshremote@server true
```

---

## Question 19 - Rsync Transfer (server) - 4 pts

```bash
su - mira
rsync -e "ssh -p 2222" /opt/exam-b/report.txt meshremote@server:/home/meshremote/inbox/report.txt
```

---

## Question 20 - Passwordless SSH (server) - 4 pts

```bash
# Run on server
id meshremote >/dev/null 2>&1 || useradd meshremote
echo cinder9 | passwd --stdin meshremote
mkdir -p /home/meshremote/inbox
chown meshremote:meshremote /home/meshremote/inbox
chmod 0755 /home/meshremote/inbox
su - mira
ssh-copy-id -p 2222 meshremote@server
ssh -p 2222 -o BatchMode=yes meshremote@server true
```

---

## Question 21 - Rsync Transfer (server) - 4 pts

```bash
su - mira
rsync -e "ssh -p 2222" /opt/exam-b/report.txt meshremote@server:/home/meshremote/inbox/report.txt
```

---

## Question 22 - Passwordless SSH (server) - 4 pts

```bash
# Run on server
id meshremote >/dev/null 2>&1 || useradd -m meshremote
echo cinder9 | passwd --stdin meshremote
mkdir -p /home/meshremote/inbox
chown meshremote:meshremote /home/meshremote/inbox
chmod 0755 /home/meshremote/inbox
# Run on client
su - mira
ssh-copy-id -p 2222 meshremote@server
ssh -p 2222 -o BatchMode=yes meshremote@server true
```
