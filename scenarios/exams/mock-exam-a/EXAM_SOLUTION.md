# Mock Exam A: Access And Service Integration - Exam Solution
Scenario ID: mock-exam-a
Mode: Exam
Time limit: 120 minutes
Objectives: networking-and-firewall, software-scheduling-time, filesystems-and-autofs, users-sudo-ssh

A redesigned RHCSA v9 mock exam focused on time sync, service networking, automounts, remote access, and delegated administration.

## Task 01 - Chrony Client (clientvm) - 20 pts
```bash
sed -i '/^server /d;/^pool /d' /etc/chrony.conf
echo 'server servervm iburst' >> /etc/chrony.conf
systemctl enable --now chronyd
```

## Task 02 - Edge Network And Apache (clientvm) - 20 pts
```bash
hostnamectl set-hostname clientvm.edge.lab
grep -q 'internal-api.edge.lab' /etc/hosts || echo '192.168.122.3 internal-api.edge.lab' >> /etc/hosts
CONN=$(nmcli -t -f NAME,IP4.ADDRESS connection show --active | awk -F: '$2 ~ /^192\.168\.122\./ {print $1; exit}')
nmcli connection modify "$CONN" +ipv4.routes "203.0.113.0/24 192.168.122.3"
nmcli connection up "$CONN"
sed -i 's/^Listen .*/Listen 8088/' /etc/httpd/conf/httpd.conf
systemctl enable --now httpd
firewall-cmd --permanent --add-port=8088/tcp
firewall-cmd --reload
```

## Task 03 - NFS Mount And Autofs Map (clientvm) - 20 pts
```bash
mkdir -p /srv/reference /research
grep -q '^servervm:/exports/direct /srv/reference ' /etc/fstab || echo 'servervm:/exports/direct /srv/reference nfs defaults,_netdev 0 0' >> /etc/fstab
mount /srv/reference
cat > /etc/auto.research <<'EOF'
field-guide -fstype=nfs servervm:/exports/autofs/field-guide
EOF
cat > /etc/auto.master.d/rhcsa.research.autofs <<'EOF'
/research /etc/auto.research
EOF
systemctl enable --now autofs
ls -l /research/field-guide/brief.txt
```

## Task 04 - Orchid Delegated Administration (clientvm) - 20 pts
```bash
groupadd platformops
useradd -m -g platformops orchid
install -d -m 700 -o orchid -g platformops /home/orchid/.ssh
cat /home/admin/.ssh/id_rsa.pub > /home/orchid/.ssh/authorized_keys
chown orchid:platformops /home/orchid/.ssh/authorized_keys
chmod 600 /home/orchid/.ssh/authorized_keys
echo '%platformops ALL=(root) NOPASSWD: /usr/bin/systemctl restart httpd' > /etc/sudoers.d/platformops-httpd
visudo -cf /etc/sudoers.d/platformops-httpd
```

## Task 05 - SSH File Transfer (clientvm) - 20 pts
```bash
# Enter the password redhat when scp prompts.
runuser -l admin -c "scp -o StrictHostKeyChecking=no admin@servervm:/srv/rhcsa/objectives/README.txt /home/admin/edge-brief.txt"
install -o orchid -g platformops -m 0644 /home/admin/edge-brief.txt /home/orchid/edge-brief.txt
rm -f /home/admin/edge-brief.txt
```
