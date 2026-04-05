# Lab 28: SELinux Custom Document Root

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-28-selinux-custom-docroot` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | selinux-and-default-perms, networking-and-firewall |

Serve an existing custom document root on a non-default port with SELinux enforcing.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Serve the custom document root on port 8088 (clientvm) - 10 pts

```bash
cat > /etc/httpd/conf.d/lab28.conf <<'EOF'
Listen 8088
<VirtualHost *:8088>
    DocumentRoot /srv/lab28/site
</VirtualHost>
EOF
```

---

## Task 02 - Apply the required SELinux and firewall changes (clientvm) - 10 pts

```bash
semanage fcontext -a -t httpd_sys_content_t '/srv/lab28/site(/.*)?'
restorecon -RF /srv/lab28/site
semanage port -a -t http_port_t -p tcp 8088
firewall-cmd --permanent --add-port=8088/tcp
firewall-cmd --reload
```

---

## Task 03 - Leave the provided content intact (clientvm) - 10 pts

```bash
systemctl enable --now httpd
```
