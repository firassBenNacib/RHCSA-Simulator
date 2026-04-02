# Lab 23: Umask Defaults Solution

## Task 01 - Create the user veil23 and set its password to cinder9 (clientvm) - 10 pts

```bash
useradd -m veil23
passwd veil23
# enter: cinder9
```

## Task 02 - Configure the umask for user veil23 so that new (clientvm) - 10 pts

```bash
vim /home/veil23/.bashrc
umask 027
chown veil23:veil23 /home/veil23/.bashrc
```

## Verification

```bash
id veil23
runuser -l veil23 -c 'rm -rf ~/veil23-check && mkdir ~/veil23-check && touch ~/veil23-check/file && mkdir ~/veil23-check/dir && stat -c %a ~/veil23-check/file ~/veil23-check/dir'
```
