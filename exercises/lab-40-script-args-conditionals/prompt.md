# Lab 40: Script Arguments and Conditionals

Time: 25 minutes
Objectives: shell-scripting, users-sudo-ssh
Systems: clientvm

Create a small shell script that processes arguments and returns the correct exit status.

## Tasks

## Task 01 - Create the executable script (clientvm) - 10 pts

Create the executable script /usr/local/bin/usercheck40 on clientvm.

## Task 02 - The script must accept one username argument (clientvm) - 10 pts

The script must accept one username argument.

## Task 03 - If the user exists, print EXISTS: username to (clientvm) - 10 pts

- **If the user exists, print EXISTS:** username to standard output and exit with status 0.

## Task 04 - If the user does not exist, print MISSING: username (clientvm) - 10 pts

If the user does not exist, print MISSING: username to standard output and exit with status 1.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
