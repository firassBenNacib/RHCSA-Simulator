# Lab 39: SSH Key Authentication and Rsync Solution

## Task 01 - Create the user mesh39 on both clientvm and (clientvm + servervm) - 10 pts

```bash
useradd -m mesh39
passwd mesh39
# repeat on servervm
```

## Task 02 - generate an ED25519 SSH key pair with no passphrase (clientvm) - 10 pts

```bash
runuser -l mesh39 -c "ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519"
```

## Task 03 - Configure passwordless SSH access for mesh39 from (clientvm + servervm) - 10 pts

```bash
runuser -l mesh39 -c "ssh-copy-id -o StrictHostKeyChecking=no mesh39@192.168.122.3"
```

## Task 04 - Using rsync over SSH, copy the directory (servervm) - 10 pts

```bash
runuser -l mesh39 -c "rsync -av -e ssh /home/mesh39/client-data/ mesh39@192.168.122.3:/home/mesh39/server-data/"
```

## Verification

```bash
ssh -o BatchMode=yes -o StrictHostKeyChecking=no mesh39@192.168.122.3 "test -f /home/mesh39/server-data/file1.txt"
```
