# Lab 20: Build Container Image

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-20-build-container-image` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | containers |

Build and tag a local container image from a provided Containerfile.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Build the text2pdf20 image as builder20 (client) - 10 pts

As user builder20, build an image named localhost/text2pdf20:latest from /opt/rhcsa/workspaces/text2pdf20/Containerfile.
