#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-03-dnf-repositories/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
grep -ERq '^\[rhcsa-baseos\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://servervm/repo/BaseOS/?$' /etc/yum.repos.d && grep -ERq '^enabled=1$' /etc/yum.repos.d && grep -ERq '^gpgcheck=0$' /etc/yum.repos.d && grep -ERq '^\[rhcsa-appstream\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://servervm/repo/AppStream/?$' /etc/yum.repos.d && curl -fsS http://servervm/repo/BaseOS/repodata/repomd.xml >/dev/null && curl -fsS http://servervm/repo/AppStream/repodata/repomd.xml >/dev/null

# Check 02 [servervm]
# Source: ssh admin@servervm sudo grep -ERq '^\[rhcsa-baseos\]$' /etc/yum.repos.d && ssh admin@servervm sudo grep -ERq '^baseurl=http://servervm/repo/BaseOS/?$' /etc/yum.repos.d && ssh admin@servervm sudo grep -ERq '^enabled=1$' /etc/yum.repos.d && ssh admin@servervm sudo grep -ERq '^gpgcheck=0$' /etc/yum.repos.d && ssh admin@servervm sudo grep -ERq '^\[rhcsa-appstream\]$' /etc/yum.repos.d && ssh admin@servervm sudo grep -ERq '^baseurl=http://servervm/repo/AppStream/?$' /etc/yum.repos.d && ssh admin@servervm sudo curl -fsS http://servervm/repo/BaseOS/repodata/repomd.xml >/dev/null && ssh admin@servervm sudo curl -fsS http://servervm/repo/AppStream/repodata/repomd.xml >/dev/null
grep -ERq '^\[rhcsa-baseos\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://servervm/repo/BaseOS/?$' /etc/yum.repos.d && grep -ERq '^enabled=1$' /etc/yum.repos.d && grep -ERq '^gpgcheck=0$' /etc/yum.repos.d && grep -ERq '^\[rhcsa-appstream\]$' /etc/yum.repos.d && grep -ERq '^baseurl=http://servervm/repo/AppStream/?$' /etc/yum.repos.d && curl -fsS http://servervm/repo/BaseOS/repodata/repomd.xml >/dev/null && curl -fsS http://servervm/repo/AppStream/repodata/repomd.xml >/dev/null
