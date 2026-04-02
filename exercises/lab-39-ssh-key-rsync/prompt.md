# Lab 39: SSH Key Authentication and Rsync

Time: 30 minutes
Objectives: users-sudo-ssh, essential-tools
Systems: clientvm + servervm

Configure key-based SSH access and securely transfer files between systems.

## Tasks

## Task 01 - Create the user mesh39 on both clientvm and (clientvm + servervm) - 10 pts

Create the user mesh39 on both clientvm and servervm. Set the password on both systems to cinder9.

## Task 02 - generate an ED25519 SSH key pair with no passphrase (clientvm) - 10 pts

As user mesh39 on clientvm, generate an ED25519 SSH key pair with no passphrase.

## Task 03 - Configure passwordless SSH access for mesh39 from (clientvm + servervm) - 10 pts

Configure passwordless SSH access for mesh39 from clientvm to servervm using public key authentication.

## Task 04 - Using rsync over SSH, copy the directory (servervm) - 10 pts

Using rsync over SSH, copy the directory /home/mesh39/client-data/ from clientvm to /home/mesh39/server-data/ on servervm.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
