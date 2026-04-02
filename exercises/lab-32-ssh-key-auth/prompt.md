# Lab 32: SSH Key Authentication

Time: 35 minutes
Objectives: users-sudo-ssh
Systems: clientvm + servervm

Configure passwordless SSH login from clientvm to servervm using a key pair.

## Tasks

## Task 01 - Create user relay32 on clientvm and user vault32 on (servervm) - 10 pts

Create user relay32 on clientvm and user vault32 on servervm. Set the password of both users to cinder9.

## Task 02 - Configure key-based SSH authentication so that user (clientvm + servervm) - 10 pts

Configure key-based SSH authentication so that user relay32 on clientvm can log in to vault32@servervm without a password prompt.

## Task 03 - Do not disable PasswordAuthentication globally for (clientvm) - 10 pts

Do not disable PasswordAuthentication globally for this task.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
