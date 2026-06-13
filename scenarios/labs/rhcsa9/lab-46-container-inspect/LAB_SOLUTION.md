# Lab 46: Container Load and Inspect

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-46-container-inspect` |
| Mode | Lab |
| Scope | client |
| Time limit | 25 minutes |
| Objectives | containers |

Load a provided container image into user storage and inspect its metadata with podman.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create user scope46 and set the password (client) - 10 pts

```bash
id scope46 >/dev/null 2>&1 || useradd -m scope46
echo 'scope46:cinder9' | chpasswd
```

---

## Task 02 - load the image archive /opt/rhcsa/container- (client) - 10 pts

```bash
runuser -l scope46 -c 'podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar'
```

---

## Task 03 - inspect localhost/rhcsa-httpd-base:latest and write (client) - 10 pts

```bash
runuser -l scope46 -c 'podman image inspect localhost/rhcsa-httpd-base:latest --format {{.Config.WorkingDir}} > /home/scope46/workdir.txt'
```

---

## Task 04 - If the image has no explicit configured user, write (client) - 10 pts

```bash
u="$(runuser -l scope46 -c 'podman image inspect localhost/rhcsa-httpd-base:latest --format {{.Config.User}}')"
echo "${u:-root}" > /home/scope46/user.txt
chown scope46:scope46 /home/scope46/user.txt
```
