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
grep -ERq '^\[rhcsa-baseos\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://servervm/repo/BaseOS/?$' /etc/yum.repos.d && grep -ERq '^enabled=1$' /etc/yum.repos.d && grep -ERq '^gpgcheck=0$' /etc/yum.repos.d && grep -ERq '^\[rhcsa-appstream\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://servervm/repo/AppStream/?$' /etc/yum.repos.d && curl -fsS http://servervm/repo/BaseOS/repodata/repomd.xml >/dev/null && curl -fsS http://servervm/repo/AppStream/repodata/repomd.xml >/dev/null
ssh admin@servervm sudo grep -ERq '^\[rhcsa-baseos\]$' /etc/yum.repos.d && ssh admin@servervm sudo grep -ERq '^baseurl=http://servervm/repo/BaseOS/?$' /etc/yum.repos.d && ssh admin@servervm sudo grep -ERq '^enabled=1$' /etc/yum.repos.d && ssh admin@servervm sudo grep -ERq '^gpgcheck=0$' /etc/yum.repos.d && ssh admin@servervm sudo grep -ERq '^\[rhcsa-appstream\]$' /etc/yum.repos.d && ssh admin@servervm sudo grep -ERq '^baseurl=http://servervm/repo/AppStream/?$' /etc/yum.repos.d && ssh admin@servervm sudo curl -fsS http://servervm/repo/BaseOS/repodata/repomd.xml >/dev/null && ssh admin@servervm sudo curl -fsS http://servervm/repo/AppStream/repodata/repomd.xml >/dev/null
```
