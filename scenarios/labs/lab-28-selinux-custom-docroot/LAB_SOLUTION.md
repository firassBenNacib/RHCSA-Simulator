# Lab 28: SELinux Custom Document Root

## Lab Solution
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

```bash
vim /etc/httpd/conf.d/lab28.conf
<VirtualHost *:8088>
    DocumentRoot /srv/lab28/site
    <Directory /srv/lab28/site>
        Require all granted
    </Directory>
</VirtualHost>
```

---

## Task 02 - Keep SELinux enforcing, configure the correct file (clientvm) - 10 pts

```bash
semanage fcontext -a -t httpd_sys_content_t "/srv/lab28/site(/.*)?"
restorecon -Rv /srv/lab28/site
semanage port -a -t http_port_t -p tcp 8088
firewall-cmd --permanent --add-port=8088/tcp
firewall-cmd --reload
systemctl enable --now httpd
```

---

## Task 03 - Do not edit or remove /srv/lab28/site/index.html (clientvm) - 10 pts

```bash
curl -s http://localhost:8088
```

---

## Verification
```bash
curl -fsS http://localhost:8088 >/dev/null
semanage port -l | grep -Eq '^http_port_t\b.*\b8088\b' && firewall-cmd --permanent --query-port=8088/tcp && systemctl is-enabled httpd | grep -qx enabled
matchpathcon /srv/lab28/site/index.html | grep -Eq ':httpd_sys_content_t:' && ls -Zd /srv/lab28/site | grep -Eq ':httpd_sys_content_t:'
```
