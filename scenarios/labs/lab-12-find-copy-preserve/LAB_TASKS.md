# Lab 12: Find And Copy With Structure

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-12-find-copy-preserve` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | essential-tools |

Locate recent files owned by a user and copy them while preserving directories.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Find the recent natfind-owned files (clientvm) - 10 pts

Find all regular files owned by natfind and modified in the last 24 hours under /opt/lab12/source.

---

## Task 02 - Copy the matching files with structure preserved (clientvm) - 10 pts

Copy the matching files to /root/natfind-files and preserve the original directory structure.
