# Lab 45: Restore Default SELinux Context

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-45-restorecon-httpd` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | selinux-and-default-perms |

Restore the default SELinux context on existing web content without disabling SELinux.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - the file /var/www/html/index45.html has the wrong (clientvm) - 10 pts

```bash
restorecon -v /var/www/html/index45.html
```

---

## Task 02 - Ensure the httpd service is enabled and running (clientvm) - 10 pts

```bash
systemctl enable --now httpd
getenforce
ls -Z /var/www/html/index45.html
```

---

## Verification
```bash
getenforce | grep -qx Enforcing
matchpathcon /var/www/html/index45.html | grep -Eq ':httpd_sys_content_t:' && ls -Z /var/www/html/index45.html | grep -Eq ':httpd_sys_content_t:'
systemctl is-enabled httpd | grep -qx enabled && systemctl is-active httpd | grep -qx active
```
