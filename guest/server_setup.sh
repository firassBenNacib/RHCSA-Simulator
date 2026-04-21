#!/bin/bash
set -euo pipefail

BOOTSTRAP_ISO_MOUNT="/mnt/rhcsa-bootstrap-iso"

mount_repo_source() {
  local rom_dev="$1"

  mount -t iso9660 -o ro "$rom_dev" /var/www/html/repo >/dev/null 2>&1 && return 0
  mount -t udf -o ro "$rom_dev" /var/www/html/repo >/dev/null 2>&1 && return 0
  return 1
}

systemctl enable --now httpd nfs-server chronyd

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=ntp
firewall-cmd --reload

ROM_DEV="$(lsblk -pnro NAME,TYPE | awk '$2=="rom"{print $1; exit}')"
if [ -z "${ROM_DEV:-}" ]; then
  echo "No virtual DVD device found for the attached RHEL ISO." >&2
  exit 1
fi

mkdir -p /var/www/html/repo
sed -i '\#/var/www/html/repo #d' /etc/fstab
ROM_UUID="$(blkid -s UUID -o value "$ROM_DEV" 2>/dev/null || true)"
if [ -n "${ROM_UUID:-}" ]; then
  echo "UUID=${ROM_UUID} /var/www/html/repo auto ro,nofail 0 0" >> /etc/fstab
else
  echo "${ROM_DEV} /var/www/html/repo auto ro,nofail 0 0" >> /etc/fstab
fi

if mountpoint -q /var/www/html/repo; then
  mount -o remount,ro /var/www/html/repo >/dev/null 2>&1 || true
else
  mount /var/www/html/repo >/dev/null 2>&1 || mount_repo_source "$ROM_DEV"
fi

mkdir -p /exports/direct /exports/indirect /exports/autofs/projects
echo "NFS direct content" > /exports/direct/nfs_file.txt
echo "NFS indirect content" > /exports/indirect/nfs_file.txt
echo "Autofs project seed" > /exports/autofs/projects/README.txt
chown -R nobody:nobody /exports

cat > /etc/exports <<'EOF'
/exports/direct 192.168.122.0/24(ro,sync,no_root_squash)
/exports/indirect 192.168.122.0/24(ro,sync,no_root_squash)
/exports/autofs 192.168.122.0/24(ro,sync,no_root_squash)
EOF

exportfs -arv

grep -q '^allow 192.168.122.0/24$' /etc/chrony.conf || echo 'allow 192.168.122.0/24' >> /etc/chrony.conf
systemctl restart chronyd

mkdir -p /home/admin/data /srv/rhcsa/objectives /var/www/html/training
touch /home/admin/data/file1 /home/admin/data/file2 /home/admin/data/file3
chown -R admin:admin /home/admin/data

cat > /var/www/html/training/index.html <<'EOF'
<html>
  <body>
    <h1>RHCSA simulator server</h1>
    <p>This host provides the offline repo, NFS exports, and support services.</p>
  </body>
</html>
EOF

cat > /srv/rhcsa/objectives/README.txt <<'EOF'
server provides:
- offline HTTP package content
- chrony time source
- NFS exports for mount and autofs scenarios
EOF

restorecon -RF /var/www/html /srv/rhcsa /exports >/dev/null 2>&1 || true

test -f /var/www/html/repo/media.repo || test -d /var/www/html/repo/BaseOS
showmount -e localhost || true
