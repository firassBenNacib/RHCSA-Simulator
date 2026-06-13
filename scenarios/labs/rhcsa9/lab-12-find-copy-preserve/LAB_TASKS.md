# Lab 12: Find and Copy with Structure

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-12-find-copy-preserve` |
| Mode | Lab |
| Scope | client |
| Time limit | 25 minutes |
| Objectives | essential-tools |

Locate recent files owned by a user and copy them while preserving directories.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Copy matching natfind files with structure preserved (client) - 10 pts

On client, find all regular files owned by natfind and modified in the last 24 hours under /opt/lab12/source, then copy them to /root/natfind-files while preserving the original directory structure.
