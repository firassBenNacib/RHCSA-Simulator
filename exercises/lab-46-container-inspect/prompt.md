# Lab 46: Container Load And Inspect

Time: 25 minutes
Objectives: containers
Systems: clientvm

Load a provided container image into user storage and inspect its metadata with podman.

## Tasks

## Task 01 - Create user scope46 with password cinder9 if it (clientvm) - 10 pts

Create user scope46 with password cinder9 if it does not already exist.

## Task 02 - load the image archive /opt/rhcsa/container- (clientvm) - 10 pts

As user scope46, load the image archive /opt/rhcsa/container-assets/rhcsa-httpd-base.tar into local storage.

## Task 03 - inspect localhost/rhcsa-httpd-base:latest and write (clientvm) - 10 pts

As user scope46, inspect localhost/rhcsa-httpd-base:latest and write the configured working directory to /home/scope46/workdir.txt.

## Task 04 - If the image has no explicit configured user, write (clientvm) - 10 pts

If the image has no explicit configured user, write root to /home/scope46/user.txt. Otherwise write the configured user value.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
