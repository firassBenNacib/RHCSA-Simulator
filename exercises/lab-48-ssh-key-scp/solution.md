# Lab 48: SSH Key Authentication And SCP Solution

## Task 01 - Create user bridge48 on both clientvm and servervm (clientvm + servervm) - 10 pts

```bash
# On both systems
useradd -m bridge48
passwd bridge48
# enter: cinder9
```

## Task 02 - generate an ED25519 SSH key pair with no passphrase (clientvm) - 10 pts

```bash
runuser -l bridge48 -c "ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519"
```

## Task 03 - Configure passwordless SSH access for bridge48 from (clientvm + servervm) - 10 pts

```bash
runuser -l bridge48 -c "ssh-copy-id -o StrictHostKeyChecking=no bridge48@192.168.122.3"
```

## Task 04 - Using scp over SSH, copy /home/bridge48/payload.txt (servervm) - 10 pts

```bash
runuser -l bridge48 -c "scp -o StrictHostKeyChecking=no /home/bridge48/payload.txt bridge48@192.168.122.3:/home/bridge48/inbox/"
```

## Verification

```bash
ssh -o BatchMode=yes -o StrictHostKeyChecking=no bridge48@192.168.122.3 "test -f /home/bridge48/inbox/payload.txt"
```
