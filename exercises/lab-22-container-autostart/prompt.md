# Lab 22: Container Autostart With Systemd

Time: 35 minutes
Objectives: containers
Systems: clientvm

Run a rootless container as a persistent user service.

## Tasks

## Task 01 - Run The Container (clientvm) - 10 pts

Create user merin22 with password cinder9 if it does not already exist. Then, as that user, run a container named render22 from localhost/fluxpdf22:latest with /opt/inbox22 mounted to /data/input and /opt/outbox22 mounted to /data/output.

## Task 02 - Generate User Service (clientvm) - 10 pts

As user merin22, generate a systemd user unit for that container and enable it.

## Task 03 - Enable Lingering (clientvm) - 10 pts

Enable lingering for merin22 so the user service starts automatically after reboot.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
