# Lab 22: Container Autostart With Systemd Solution

## Task 01 - Run The Container (clientvm) - 10 pts

```bash
id merin22 || useradd -m merin22
passwd merin22
# enter: cinder9
runuser -l merin22 -c "podman run -d --name render22 -v /opt/inbox22:/data/input:Z -v /opt/outbox22:/data/output:Z localhost/fluxpdf22:latest"
```

## Task 02 - Generate User Service (clientvm) - 10 pts

```bash
runuser -l merin22 -c "mkdir -p ~/.config/systemd/user"
runuser -l merin22 -c "cd ~/.config/systemd/user && podman generate systemd --name render22 --files --new"
runuser -l merin22 -c "systemctl --user daemon-reload"
runuser -l merin22 -c "systemctl --user enable --now container-render22.service"
```

## Task 03 - Enable Lingering (clientvm) - 10 pts

```bash
loginctl enable-linger merin22
runuser -l merin22 -c "systemctl --user status container-render22.service --no-pager"
```

## Verification

```bash
loginctl show-user merin22 | grep -Eq '^Linger=yes$'
runuser -l merin22 -c 'systemctl --user is-enabled container-render22.service' | grep -qx enabled
runuser -l merin22 -c 'systemctl --user is-active container-render22.service' | grep -qx active
```
