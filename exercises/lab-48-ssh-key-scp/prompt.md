# Lab 48: SSH Key Authentication And SCP

Time: 25 minutes
Objectives: users-sudo-ssh
Systems: clientvm + servervm

Configure key-based SSH access and securely copy a file to the second system.

## Tasks

## Task 01 - Create user bridge48 on both clientvm and servervm (clientvm + servervm) - 10 pts

Create user bridge48 on both clientvm and servervm. Set the password on both systems to cinder9.

## Task 02 - generate an ED25519 SSH key pair with no passphrase (clientvm) - 10 pts

As user bridge48 on clientvm, generate an ED25519 SSH key pair with no passphrase.

## Task 03 - Configure passwordless SSH access for bridge48 from (clientvm + servervm) - 10 pts

Configure passwordless SSH access for bridge48 from clientvm to servervm using the public key.

## Task 04 - Using scp over SSH, copy /home/bridge48/payload.txt (servervm) - 10 pts

Using scp over SSH, copy /home/bridge48/payload.txt from clientvm to /home/bridge48/inbox/ on servervm.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
