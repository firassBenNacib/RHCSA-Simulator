# SELinux And Default File Permissions - Exam Tasks
Scenario ID: selinux-and-default-perms
Mode: Exam
Time limit: 60 minutes
Objectives: selinux-and-default-perms

Practice RHCSA v9 SELinux troubleshooting together with default permissions, SELinux port labels, and booleans.

## Task 01 - Default Umask (clientvm) - 15 pts
Set the default shell umask to 027 system-wide.

## Task 02 - Apache Site On 8089 (clientvm) - 30 pts
Serve /srv/rhcsa/selinux-site/index.html with Apache on TCP port 8089 while SELinux remains enforcing.

## Task 03 - Persistent SELinux Labels (clientvm) - 30 pts
Apply persistent SELinux labeling and port labeling so the content continues to work.

## Task 04 - Persistent SELinux Boolean (clientvm) - 25 pts
Set the SELinux boolean httpd_can_network_connect persistently to on.
