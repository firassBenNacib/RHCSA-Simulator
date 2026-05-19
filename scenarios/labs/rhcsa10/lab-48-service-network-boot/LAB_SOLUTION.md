# RHCSA 10 Lab 48: Network Service Boot

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-48-service-network-boot` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | networking-and-firewall |

Configure network services to start at boot.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /var/www/html/rhcsa10-boot.html containing BOOT10 (client) - 10 pts

```bash
mkdir -p /var/www/html
echo BOOT10 > /var/www/html/rhcsa10-boot.html
restorecon -v /var/www/html/rhcsa10-boot.html || true
```

---

## Task 02 - Enable and start httpd (client) - 10 pts

```bash
systemctl enable --now httpd
```

---

## Task 03 - Allow the http service permanently in firewalld (client) - 10 pts

```bash
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
```
