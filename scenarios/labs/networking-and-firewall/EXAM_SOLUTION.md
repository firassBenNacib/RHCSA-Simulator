# Networking And Firewall Configuration - Exam Solution
Scenario ID: networking-and-firewall
Mode: Exam
Time limit: 60 minutes
Objectives: networking-and-firewall

Practice RHCSA v9 hostname management, hostname resolution, persistent routes, service networking, and firewall access control.

## Task 01 - Persistent Hostname (clientvm) - 10 pts
```bash
hostnamectl set-hostname clientvm.lab.example.com
```

## Task 02 - Local Name Resolution (clientvm) - 10 pts
```bash
grep -q 'registry.lab.example.com' /etc/hosts || echo '192.168.122.3 registry.lab.example.com' >> /etc/hosts
```

## Task 03 - Persistent Static Route (clientvm) - 10 pts
```bash
CONN=$(nmcli -t -f NAME,IP4.ADDRESS connection show --active | awk -F: '$2 ~ /^192\.168\.122\./ {print $1; exit}')
nmcli connection modify "$CONN" +ipv4.routes "192.168.50.0/24 192.168.122.3"
nmcli connection up "$CONN"
```

## Task 04 - Apache On Port 8080 (clientvm) - 10 pts
```bash
sed -i 's/^Listen .*/Listen 8080/' /etc/httpd/conf/httpd.conf
echo 'RHCSA networking lab' > /var/www/html/index.html
systemctl enable --now httpd
```

## Task 05 - Firewall Access (clientvm) - 10 pts
```bash
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload
curl http://localhost:8080/
```
