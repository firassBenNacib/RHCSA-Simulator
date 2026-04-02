# Lab 04: SELinux Custom HTTP Port

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-04-selinux-http-port` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | selinux-and-default-perms |

Fix Apache so it listens on a nonstandard port without disabling SELinux.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure Apache on clientvm so it listens on TCP (clientvm) - 10 pts

Configure Apache on clientvm so it listens on TCP port 9082 and starts automatically at boot.

---

## Task 02 - Allow TCP port 9082 through the firewall permanently (clientvm) - 10 pts

Allow TCP port 9082 through the firewall permanently.

---

## Task 03 - Make the SELinux changes needed so Apache serves (clientvm) - 10 pts

Make the SELinux changes needed so Apache serves the existing /var/www/html content on that port.

## Hints
- Do not disable SELinux.
- Do not move the existing document root.

## Validation Commands
```bash
ss -ltn '( sport = :9082 )' | grep -q ':9082' && systemctl is-enabled httpd | grep -qx enabled && systemctl is-active httpd | grep -qx active
firewall-cmd --permanent --query-port=9082/tcp
curl -fsS http://localhost:9082 >/dev/null && semanage port -l | grep -Eq '^http_port_t\b.*\b9082\b'
```
