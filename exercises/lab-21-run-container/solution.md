# Lab 21: Run A Container Solution

## Task 01 - run a container named mycontainer21 from (clientvm) - 10 pts

```bash
id runner21 || useradd -m runner21
passwd runner21
# enter: cinder9
su - runner21
```

## Task 02 - Bind mount /opt/file21 to /data/input and (clientvm) - 10 pts

```bash
podman run -d --name mycontainer21 -v /opt/file21:/data/input:Z -v /opt/processed21:/data/output:Z localhost/text2pdf21:latest
podman ps
exit
```

## Verification

```bash
runuser -l runner21 -c 'podman ps --format {{.Names}}' | grep -qx mycontainer21
```
