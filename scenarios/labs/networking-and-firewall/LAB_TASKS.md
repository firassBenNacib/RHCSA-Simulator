# Networking And Firewall Configuration - Lab Tasks
Scenario ID: networking-and-firewall
Mode: Lab
Time limit: 60 minutes
Objectives: networking-and-firewall

Practice RHCSA v9 hostname management, hostname resolution, persistent routes, service networking, and firewall access control.

## Task 01 - Persistent Hostname (clientvm) - 10 pts
Set the persistent hostname of clientvm to clientvm.lab.example.com.

## Task 02 - Local Name Resolution (clientvm) - 10 pts
Add a persistent hostname-resolution entry so registry.lab.example.com resolves to 192.168.122.3.

## Task 03 - Persistent Static Route (clientvm) - 10 pts
Add a persistent static route for 192.168.50.0/24 via 192.168.122.3 on the active non-NAT connection.

## Task 04 - Apache On Port 8080 (clientvm) - 10 pts
Configure httpd to listen on port 8080 and serve a simple page from /var/www/html/index.html.

## Task 05 - Firewall Access (clientvm) - 10 pts
Open the firewall for TCP port 8080 and verify the service is reachable locally.

Hints
1. Use hostnamectl for the hostname task.
2. Use a persistent local hostname-resolution method that survives reboot.
3. Use nmcli to inspect the active private-network connection before changing routes.
4. For the web task, adjust both the service configuration and the firewall.

Checks
```bash
hostnamectl status --static
getent hosts registry.lab.example.com
ip route show
ss -tlnp | grep 8080
firewall-cmd --list-ports
curl http://localhost:8080/
```
