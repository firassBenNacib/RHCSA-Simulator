# Lab 25: Pwquality Policy

Time: 20 minutes
Objectives: users-sudo-ssh
Systems: clientvm

Configure a persistent local password quality policy without editing PAM service files.

## Tasks

## Task 01 - Create a persistent password quality policy in (clientvm) - 10 pts

Create a persistent password quality policy in /etc/security/pwquality.conf.d so that local passwords must meet the following requirements:

- **Minimum Length:** 12
- **Minimum Character Classes:** 3

## Task 02 - Do not edit any PAM service file for this task (clientvm) - 10 pts

Do not edit any PAM service file for this task.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
