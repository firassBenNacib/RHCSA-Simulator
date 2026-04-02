# Lab 32: SSH Key Authentication Solution

## Task 01 - Create user relay32 on clientvm and user vault32 on (servervm) - 10 pts

```bash
useradd -m relay32
passwd relay32
# enter: cinder9
# on servervm
useradd -m vault32
passwd vault32
# enter: cinder9
```

## Task 02 - Configure key-based SSH authentication so that user (clientvm + servervm) - 10 pts

```bash
runuser -l relay32 -c "ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa"
runuser -l relay32 -c "ssh-copy-id vault32@servervm"
```

## Task 03 - Do not disable PasswordAuthentication globally for (clientvm) - 10 pts

```bash
runuser -l relay32 -c "ssh -o StrictHostKeyChecking=no vault32@servervm true"
```

## Verification

```bash
runuser -l relay32 -c 'ssh -o StrictHostKeyChecking=no -o BatchMode=yes vault32@servervm true'
```
