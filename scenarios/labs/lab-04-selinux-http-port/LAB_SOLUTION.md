# Lab 04: SELinux Custom HTTP Port

## Lab Solution
### Overview
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

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Configure Apache on clientvm so it listens on TCP…
**System:** clientvm

#### Command Flow
```bash
vim /etc/httpd/conf/httpd.conf
Listen 9082
systemctl enable --now httpd
```

---

### Task 02 — Allow TCP port 9082 through the firewall permanently
**System:** clientvm

#### Command Flow
```bash
firewall-cmd --permanent --add-port=9082/tcp
firewall-cmd --reload
```

---

### Task 03 — Make the SELinux changes needed so Apache serves the…
**System:** clientvm

#### Command Flow
```bash
semanage port -a -t http_port_t -p tcp 9082
systemctl restart httpd
```

---

### Verification
```bash
ss -ltnp | grep 9082
semanage port -l | grep http_port_t | grep 9082
curl -s http://localhost:9082
```
