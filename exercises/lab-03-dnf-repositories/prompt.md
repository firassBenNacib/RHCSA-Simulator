# Lab 03: DNF Repository Configuration

Time: 40 minutes
Objectives: software-scheduling-time
Systems: clientvm + servervm

Configure offline BaseOS and AppStream repositories on both systems.

## Tasks

## Task 01 - Client Repositories (clientvm + servervm) - 10 pts

On clientvm, configure a persistent repository file with the following settings:

- **BaseOS:** http://servervm/repo/BaseOS/
- **AppStream:** http://servervm/repo/AppStream/
- **gpgcheck:** disabled
- **Repositories:** enabled

## Task 02 - Server Repositories (servervm) - 10 pts

On servervm, configure the same repository file with the same settings.

## Task 03 - Verify Repositories (clientvm) - 10 pts

Verify that both repositories are available on both systems.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
