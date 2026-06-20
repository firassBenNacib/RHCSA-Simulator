# RHCSA 10 Lab 07: Flatpak Package

## Lab Tasks
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

## Task 01 - Install Flatpak repository tooling and rebuild the metadata under (server) - 10 pts

On server, install Flatpak repository tooling and rebuild the metadata under /opt/rhcsa/flatpak/repo.

---

## Task 02 - Configure Flatpak remote rhcsa10 (client) - 10 pts

On client, ensure the system Flatpak remote rhcsa10 exists and points to file:///opt/rhcsa/flatpak/repo.

---

## Task 03 - Install Flatpak application org.RHCSA.tools from rhcsa10 for the system (client) - 10 pts

On client, install Flatpak application org.rhcsa.Tools from rhcsa10 for the system installation.
