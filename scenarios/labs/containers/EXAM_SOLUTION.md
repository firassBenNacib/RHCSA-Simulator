# Container Image And Runtime Management - Exam Solution
Scenario ID: containers
Mode: Exam
Time limit: 75 minutes
Objectives: containers

Practice RHCSA v9 image inspection, podman, skopeo, Containerfile work, bind mounts, and container systemd unit generation.

## Task 01 - Base Image Inspection (clientvm) - 15 pts
```bash
podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar
podman image inspect localhost/rhcsa-httpd-base:latest > /root/rhcsa-httpd-base.inspect.json
```

## Task 02 - Container Build (clientvm) - 15 pts
```bash
cat > /opt/rhcsa/workspaces/container/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
EOF
podman build -t localhost/rhcsa-web:latest /opt/rhcsa/workspaces/container
```

## Task 03 - Running Web Container (clientvm) - 15 pts
```bash
podman rm -f rhcsa-web >/dev/null 2>&1 || true
podman run -d --name rhcsa-web -p 8080:80 -v /opt/rhcsa/workspaces/container/site-content:/var/www/html:Z localhost/rhcsa-web:latest
```

## Task 04 - Container Systemd Unit (clientvm) - 15 pts
```bash
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
podman generate systemd --name rhcsa-web --files --new
```
