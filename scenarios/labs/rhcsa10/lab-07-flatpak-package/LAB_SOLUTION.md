# RHCSA 10 Lab 07: Flatpak Package

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-07-flatpak-package` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 25 minutes |
| Objectives | software-management |

Install and remove Flatpak applications from a configured remote.

### Systems
- server
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Install Flatpak repository tooling and rebuild the metadata under /opt/r (server) - 10 pts

```bash
# On server
dnf install -y flatpak ostree
install -d -m 755 /opt/rhcsa/flatpak/repo
ostree init --repo=/opt/rhcsa/flatpak/repo --mode=archive-z2
flatpak build-update-repo /opt/rhcsa/flatpak/repo
```

---

## Task 02 - Ensure the system Flatpak remote rhcsa10 exists and points to file:///op (client) - 10 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify rhcsa10 file:///opt/rhcsa/flatpak/repo
```

---

## Task 03 - Install Flatpak application org.rhcsa.Tools from rhcsa10 for the system (client) - 10 pts

```bash
flatpak install --system -y rhcsa10 org.rhcsa.Tools
```
