# Lab 46: Container Load And Inspect

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-46-container-inspect` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | containers |

Load a provided container image into user storage and inspect its metadata with podman.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create user scope46 and set the password (clientvm) - 10 pts

```bash
useradd -m scope46
passwd scope46
# enter: cinder9
```

---

## Task 02 - load the image archive /opt/rhcsa/container- (clientvm) - 10 pts

```bash
su - scope46
podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar
```

---

## Task 03 - inspect localhost/rhcsa-httpd-base:latest and write (clientvm) - 10 pts

```bash
su - scope46
podman image inspect localhost/rhcsa-httpd-base:latest --format {{.Config.WorkingDir}} > ~/workdir.txt
```

---

## Task 04 - If the image has no explicit configured user, write (clientvm) - 10 pts

```bash
su - scope46
u=$(podman image inspect localhost/rhcsa-httpd-base:latest --format {{.Config.User}}); printf %s "${u:-root}" > ~/user.txt
```
