# Lab 03: DNF Repository Configuration

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-03-dnf-repositories` |
| Mode | Lab |
| Time limit | 40 minutes |
| Objectives | software-scheduling-time |

Configure offline BaseOS and AppStream repositories on both systems.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Client Repositories (clientvm) - 10 pts

```bash
vim /etc/yum.repos.d/rhcsa.repo
[rhcsa-baseos]
name=RHCSA BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa-appstream]
name=RHCSA AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
dnf clean all
```

---

## Task 02 - Server Repositories (servervm) - 10 pts

```bash
# Run on servervm
vim /etc/yum.repos.d/rhcsa.repo
[rhcsa-baseos]
name=RHCSA BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa-appstream]
name=RHCSA AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
dnf clean all
```

---

## Task 03 - Verify Repositories (clientvm) - 10 pts

```bash
dnf repolist
# Run on servervm
dnf repolist
```
