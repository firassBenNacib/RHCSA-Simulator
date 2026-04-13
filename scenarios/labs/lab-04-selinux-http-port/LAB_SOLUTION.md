# Lab 04: SELinux Custom HTTP Port

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-04-selinux-http-port` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | selinux-and-default-perms |

Fix Apache so it listens on a nonstandard port without disabling SELinux.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure Apache on clientvm so it listens on TCP (clientvm) - 10 pts

```bash
vim /etc/httpd/conf/httpd.conf
Listen 9082
systemctl enable httpd
```

---

## Task 02 - Allow TCP port 9082 through the firewall permanently (clientvm) - 10 pts

```bash
firewall-cmd --permanent --add-port=9082/tcp
firewall-cmd --reload
```

---

## Task 03 - Make the SELinux changes needed so Apache serves (clientvm) - 10 pts

```bash
semanage port -a -t http_port_t -p tcp 9082
systemctl restart httpd
```
