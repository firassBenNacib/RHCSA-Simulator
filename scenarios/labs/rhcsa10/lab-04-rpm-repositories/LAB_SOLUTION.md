# RHCSA 10 Lab 04: RPM Repositories

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-04-rpm-repositories` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 35 minutes |
| Objectives | software-management |

Configure BaseOS and AppStream repositories.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure a persistent BaseOS repository. BaseOS URL: http://server/repo (client + server) - 10 pts

```bash
cat > /etc/yum.repos.d/rhcsa10.repo <<'EOF'
[rhcsa10-baseos]
name=RHCSA10 BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=1
EOF
```

---

## Task 02 - Configure a persistent AppStream repository. AppStream URL: http://serve (client + server) - 10 pts

```bash
cat >> /etc/yum.repos.d/rhcsa10.repo <<'EOF'

[rhcsa10-appstream]
name=RHCSA10 AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=1
EOF
```

---

## Task 03 - Disable GPG checks for both RHCSA10 repositories and verify both reposit (client) - 10 pts

```bash
sed -i 's/^gpgcheck=.*/gpgcheck=0/' /etc/yum.repos.d/rhcsa10.repo
dnf clean all
dnf repolist --enabled
```
