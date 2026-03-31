# Lab 03: DNF Repository Configuration - Lab Solution
Scenario ID: lab-03-dnf-repositories
Mode: Lab
Time limit: 40 minutes
Objectives: software-scheduling-time

Configure offline BaseOS and AppStream repositories on both systems.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
vim /etc/yum.repos.d/rhcsa.repo
[rhcsa-baseos]
name=RHCSA BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[rhcsa-appstream]
name=RHCSA AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
dnf clean all
```

## Task 02 - Part 02 (clientvm)
```bash
ssh admin@servervm
sudo -i
vim /etc/yum.repos.d/rhcsa.repo
[rhcsa-baseos]
name=RHCSA BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[rhcsa-appstream]
name=RHCSA AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
dnf clean all
exit
exit
```

## Task 03 - Part 03 (clientvm)
```bash
dnf repolist
ssh admin@servervm sudo dnf repolist
```

Verification
```bash
dnf repolist
ssh admin@servervm sudo dnf repolist
```
