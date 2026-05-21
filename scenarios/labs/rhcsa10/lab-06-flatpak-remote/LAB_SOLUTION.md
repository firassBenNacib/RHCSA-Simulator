# RHCSA 10 Lab 06: Flatpak Remote

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-06-flatpak-remote` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-management |

Configure system Flatpak repository access.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Install the flatpak package if it is not already installed (client) - 10 pts

```bash
dnf install -y flatpak
```

---

## Task 02 - Configure a system Flatpak remote named rhcsa10 that points to file:///o (client) - 20 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify rhcsa10 file:///opt/rhcsa/flatpak/repo
flatpak remotes --system --columns=name,url
```
