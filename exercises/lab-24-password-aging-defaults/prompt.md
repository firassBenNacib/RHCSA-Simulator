# Lab 24: Password Aging Defaults

Time: 30 minutes
Objectives: users-sudo-ssh
Systems: clientvm

Configure default password aging for newly created local users through login.defs.

## Tasks

## Task 01 - Configure the system defaults for newly created (clientvm) - 10 pts

Configure the system defaults for newly created local users with the following values:

- **Pass_Max_Days:** 45
- **Pass_Min_Days:** 2
- **Pass_Warn_Age:** 10

## Task 02 - Create the user drift24, set its password to (clientvm) - 10 pts

Create the user drift24, set its password to cinder9, and ensure the user inherits the default password aging policy.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
