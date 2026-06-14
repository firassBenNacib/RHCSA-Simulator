# RHCSA 10 Lab 06: Flatpak Remote

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-06-flatpak-remote` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 20 minutes |
| Objectives | software-management |

Configure system Flatpak repository access.

### Systems
- server
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure BaseOS and AppStream repositories for Flatpak package access w (server) - 10 pts

On server, configure BaseOS and AppStream repositories for Flatpak package access with GPG checks disabled.

---

## Task 02 - Install the flatpak package if it is not already installed (client) - 10 pts

On client, install the flatpak package if it is not already installed.

---

## Task 03 - Configure a system Flatpak remote named rhcsa10 that points to file:///o (client) - 10 pts

On client, configure a system Flatpak remote named rhcsa10 that points to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.
