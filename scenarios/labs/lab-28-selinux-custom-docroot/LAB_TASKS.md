# Lab 28: SELinux Custom Document Root

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-28-selinux-custom-docroot` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | selinux-and-default-perms, networking-and-firewall |

Serve an existing custom document root on a non-default port with SELinux enforcing.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Serve the custom document root on port 8088 (clientvm) - 10 pts

Configure Apache on clientvm to serve content from /srv/lab28/site on TCP port 8088.

---

## Task 02 - Apply the required SELinux and firewall changes (clientvm) - 10 pts

Keep SELinux enforcing, configure the correct file context and port label, open the firewall permanently, and enable the service at boot.

---

## Task 03 - Leave the provided content intact (clientvm) - 10 pts

Do not edit or remove /srv/lab28/site/index.html.

## Hints
- This lab needs both a file-context change and a port-label change.
- The provided index file must stay in place.

## Validation Commands
```bash
grep -Rqs 'DocumentRoot /srv/lab28/site' /etc/httpd/conf.d && grep -Rqs '^Listen 8088$' /etc/httpd/conf.d
semanage port -l | grep -Eq '^http_port_t\b.*\b8088\b' && matchpathcon /srv/lab28/site/index.html | grep -Fq httpd_sys_content_t
systemctl is-enabled httpd | grep -qx enabled && firewall-cmd --list-ports | grep -Eq '(^| )8088/tcp($| )'
```
