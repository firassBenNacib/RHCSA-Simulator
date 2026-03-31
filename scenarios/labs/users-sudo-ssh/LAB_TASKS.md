# Users, Sudo, And SSH Access - Lab Tasks
Scenario ID: users-sudo-ssh
Mode: Lab
Time limit: 60 minutes
Objectives: users-sudo-ssh

Practice RHCSA v9 local account management, password policy, privileged access, SSH key-based login, and secure file transfer.

## Task 01 - sysmgrs And analyst (clientvm) - 10 pts
Create a group named sysmgrs and a user named analyst whose primary group is sysmgrs.

## Task 02 - Password Aging Policy (clientvm) - 10 pts
Set password aging so analyst must change the password every 30 days and receives a 7-day warning.

## Task 03 - Sudoers Drop-In (clientvm) - 10 pts
Create a sudoers drop-in that allows members of sysmgrs to restart httpd without a password.

## Task 04 - Analyst SSH Key Login (clientvm) - 10 pts
Generate an SSH key pair for admin if one does not already exist and configure analyst for key-based login using that public key.

## Task 05 - SSH File Transfer (clientvm) - 10 pts
As admin on clientvm, use SSH-based file transfer to copy /srv/rhcsa/objectives/README.txt from servervm to /home/analyst/servervm-objectives.txt and ensure analyst owns the copied file.

Hints
1. Use chage to manage password aging.
2. The sudo rule belongs under /etc/sudoers.d and should be validated with visudo.
3. You only need to authorize the existing admin key for analyst.
4. servervm already accepts the baseline admin account over SSH, so scp is enough for the transfer task.

Checks
```bash
id analyst
chage -l analyst
sudo -l -U analyst
ls -ld /home/analyst/.ssh /home/analyst/.ssh/authorized_keys
ls -l /home/analyst/servervm-objectives.txt
```
