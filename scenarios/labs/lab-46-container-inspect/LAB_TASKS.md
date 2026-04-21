# Lab 46: Container Load And Inspect

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-46-container-inspect` |
| Mode | Lab |
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

Create user scope46 and set the password to cinder9.

---

## Task 02 - load the image archive /opt/rhcsa/container- (client) - 10 pts

As user scope46, load the image archive /opt/rhcsa/container-assets/rhcsa-httpd-base.tar into local storage.

---

## Task 03 - inspect localhost/rhcsa-httpd-base:latest and write (client) - 10 pts

As user scope46, inspect localhost/rhcsa-httpd-base:latest and write the configured working directory to /home/scope46/workdir.txt.

---

## Task 04 - If the image has no explicit configured user, write (client) - 10 pts

If the image has no explicit configured user, write root to /home/scope46/user.txt. Otherwise write the configured user value.
