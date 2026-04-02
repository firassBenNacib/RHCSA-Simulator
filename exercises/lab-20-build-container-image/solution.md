# Lab 20: Build Container Image Solution

## Task 01 - build an image named localhost/text2pdf20:latest (clientvm) - 10 pts

```bash
id builder20 || useradd -m builder20
passwd builder20
# enter: cinder9
su - builder20
cd /opt/rhcsa/workspaces/text2pdf20
podman build -t localhost/text2pdf20:latest .
podman images
exit
```

## Task 02 - Verify that the image exists locally for that user (clientvm) - 10 pts

```bash
runuser -l builder20 -c "podman images"
```

## Verification

```bash
runuser -l builder20 -c 'podman image exists localhost/text2pdf20:latest'
```
