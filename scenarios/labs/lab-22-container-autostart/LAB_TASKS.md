# Lab 22: Container Autostart With Systemd

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-22-container-autostart` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | containers |

Run a rootless container as a persistent user service.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Ensure merin22 exists and run the container (client) - 10 pts

Ensure user merin22 exists, set the password to cinder9, and then, as that user, run a container named render22 from localhost/fluxpdf22:latest with /opt/inbox22 mounted to /data/input and /opt/outbox22 mounted to /data/output.

---

## Task 02 - Enable lingering for merin22 (client) - 10 pts

Enable lingering for merin22 so the user service can start automatically after reboot.

---

## Task 03 - Generate and enable the user service (client) - 10 pts

As user merin22, generate a systemd user unit for that container and enable it.
