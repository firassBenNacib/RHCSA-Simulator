# Lab 05: Users Groups And Sudo Solution

## Task 01 - Create the group opsrune and the users brenor, (clientvm) - 10 pts

```bash
groupadd opsrune
useradd -m brenor
useradd -m lyessa
useradd -m -s /sbin/nologin quillan
usermod -aG opsrune brenor
usermod -aG opsrune lyessa
```

## Task 02 - Set the password of all three users to cinder9 (clientvm) - 10 pts

```bash
passwd brenor
# enter: cinder9
passwd lyessa
# enter: cinder9
passwd quillan
# enter: cinder9
```

## Task 03 - Allow members of opsrune to run useradd through (clientvm) - 10 pts

```bash
visudo -f /etc/sudoers.d/opsrune
%opsrune ALL=(root) /usr/sbin/useradd
visudo -f /etc/sudoers.d/brenor-passwd
brenor ALL=(root) NOPASSWD: /usr/bin/passwd
```

## Verification

```bash
id -nG brenor | tr ' ' '\n' | grep -qx opsrune && getent passwd brenor >/dev/null
id -nG lyessa | tr ' ' '\n' | grep -qx opsrune && getent passwd lyessa >/dev/null
getent passwd quillan | awk -F: '{exit !($7=="/sbin/nologin")}'
visudo -cf /etc/sudoers.d/opsrune >/dev/null && grep -Eq '^%opsrune[[:space:]]+ALL=\(root\)[[:space:]]+/usr/sbin/useradd[[:space:]]*$' /etc/sudoers.d/opsrune
visudo -cf /etc/sudoers.d/brenor-passwd >/dev/null && grep -Eq '^brenor[[:space:]]+ALL=\(root\)[[:space:]]+NOPASSWD:[[:space:]]+/usr/bin/passwd[[:space:]]*$' /etc/sudoers.d/brenor-passwd
```
