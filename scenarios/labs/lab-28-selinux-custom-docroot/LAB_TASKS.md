# Lab 28: SELinux Custom Document Root

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-28-selinux-custom-docroot` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | selinux-and-default-perms, networking-and-firewall |

Serve a custom document root on a nonstandard HTTP port while keeping SELinux enforcing.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure Apache to serve content from (clientvm) - 10 pts

Configure Apache to serve content from /srv/lab28/site on TCP port 8088.

---

## Task 02 - Keep SELinux enforcing, configure the correct file (clientvm) - 10 pts

Keep SELinux enforcing, configure the correct file context and port label, open the firewall permanently, and enable the service at boot.

---

## Task 03 - Do not edit or remove /srv/lab28/site/index.html (clientvm) - 10 pts

Do not edit or remove /srv/lab28/site/index.html.

## Hints
- Create a dedicated configuration file in /etc/httpd/conf.d.
- Use semanage fcontext and semanage port.

## Validation Commands
```bash
curl -fsS http://localhost:8088 >/dev/null
semanage port -l | grep -Eq '^http_port_t\b.*\b8088\b' && firewall-cmd --permanent --query-port=8088/tcp && systemctl is-enabled httpd | grep -qx enabled
matchpathcon /srv/lab28/site/index.html | grep -Eq ':httpd_sys_content_t:' && ls -Zd /srv/lab28/site | grep -Eq ':httpd_sys_content_t:'
```
