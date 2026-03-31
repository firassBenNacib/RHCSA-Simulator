# Filesystems, NFS, And Autofs - Lab Solution
Scenario ID: filesystems-and-autofs
Mode: Lab
Time limit: 60 minutes
Objectives: filesystems-and-autofs

Practice RHCSA v9 persistent network mounts and indirect automount maps against the reusable server infrastructure.

## Task 01 - Persistent NFS Mount (clientvm) - 15 pts
```bash
mkdir -p /mnt/direct-share
grep -q '^servervm:/exports/direct /mnt/direct-share ' /etc/fstab || echo 'servervm:/exports/direct /mnt/direct-share nfs defaults,_netdev 0 0' >> /etc/fstab
mount /mnt/direct-share
```

## Task 02 - Autofs Indirect Map (clientvm) - 15 pts
```bash
mkdir -p /projects
cat > /etc/auto.rhcsa <<'EOF'
readme -fstype=nfs servervm:/exports/autofs/projects
EOF
cat > /etc/auto.master.d/rhcsa.autofs <<'EOF'
/projects /etc/auto.rhcsa
EOF
```

## Task 03 - Autofs Verification (clientvm) - 10 pts
```bash
systemctl enable --now autofs
ls -l /projects/readme
```

Verification
```bash
findmnt /mnt/direct-share
systemctl status autofs --no-pager
ls -l /projects/readme
```
