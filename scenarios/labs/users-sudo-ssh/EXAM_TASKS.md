# Users, Sudo, And SSH Access - Exam Tasks
Scenario ID: users-sudo-ssh
Mode: Exam
Time limit: 60 minutes
Objectives: users-sudo-ssh

Practice RHCSA v9 local account management, password policy, privileged access, SSH key-based login, and secure file transfer.

## Task 01 - sysmgrs And analyst (clientvm) - 10 pts
Create sysmgrs and analyst with analyst in sysmgrs as the primary group.

## Task 02 - Password Aging Policy (clientvm) - 10 pts
Set analyst password aging to 30 days with 7 days warning.

## Task 03 - Sudoers Drop-In (clientvm) - 10 pts
Allow sysmgrs to restart httpd via sudo without a password.

## Task 04 - Analyst SSH Key Login (clientvm) - 10 pts
Configure analyst for key-based SSH login using admin's public key.

## Task 05 - SSH File Transfer (clientvm) - 10 pts
Copy /srv/rhcsa/objectives/README.txt from servervm to /home/analyst/servervm-objectives.txt using SSH-based file transfer and leave analyst owning the file.
