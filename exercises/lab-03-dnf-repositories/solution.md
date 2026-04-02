# Lab 03: DNF Repository Configuration Solution

## Task 01 - Client Repositories (clientvm + servervm) - 10 pts

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
:wq
dnf clean all
```

## Task 02 - Server Repositories (servervm) - 10 pts

```bash
# Run on servervm
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
:wq
dnf clean all
```

## Task 03 - Verify Repositories (clientvm) - 10 pts

```bash
dnf repolist
# Run on servervm
dnf repolist
```

## Verification

```bash
dnf repolist | grep -Eq 'rhcsa-baseos|BaseOS' && dnf repolist | grep -Eq 'rhcsa-appstream|AppStream'
ssh admin@servervm sudo dnf repolist | grep -Eq 'rhcsa-baseos|BaseOS' && ssh admin@servervm sudo dnf repolist | grep -Eq 'rhcsa-appstream|AppStream'
```
