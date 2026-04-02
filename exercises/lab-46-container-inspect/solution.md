# Lab 46: Container Load And Inspect Solution

## Task 01 - Create user scope46 with password cinder9 if it (clientvm) - 10 pts

```bash
id scope46 || useradd -m scope46
passwd scope46
# enter: cinder9
```

## Task 02 - load the image archive /opt/rhcsa/container- (clientvm) - 10 pts

```bash
runuser -l scope46 -c "podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar"
```

## Task 03 - inspect localhost/rhcsa-httpd-base:latest and write (clientvm) - 10 pts

```bash
runuser -l scope46 -c "podman image inspect localhost/rhcsa-httpd-base:latest --format {{.Config.WorkingDir}} > ~/workdir.txt"
```

## Task 04 - If the image has no explicit configured user, write (clientvm) - 10 pts

```bash
runuser -l scope46 -c "sh -c 'u=$(podman image inspect localhost/rhcsa-httpd-base:latest --format {{.Config.User}}); printf %s \"${u:-root}\" > ~/user.txt'"
```

## Verification

```bash
runuser -l scope46 -c "test -s ~/workdir.txt && test -s ~/user.txt"
```
