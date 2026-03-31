# Mock Exam B: System Review And Hardening - Lab Tasks
Scenario ID: mock-exam-b
Mode: Lab
Time limit: 120 minutes
Objectives: storage-lvm, processes-logs-tuning, selinux-and-default-perms, essential-tools

A redesigned RHCSA v9 mock exam focused on local storage, default permissions, SELinux labeling and port control, process tuning, logging, and file workflows.

## Task 01 - LVM Storage Layout (clientvm) - 20 pts
Use the attached data disks to create volume group opsdata_vg, an XFS logical volume named records sized to 700 MiB mounted persistently at /srv/records, an ext4 logical volume named archive sized to 300 MiB mounted persistently at /mnt/archive, and a 256 MiB swap logical volume named reviewswap activated at boot.

## Task 02 - Default Permissions (clientvm) - 20 pts
Set the system-wide default umask to 027 and adjust /srv/reports so it is owned by root:reviewers, group writable, inaccessible to others, and setgid for new files.

## Task 03 - Apache With SELinux (clientvm) - 20 pts
Make Apache serve /srv/rhcsa/review-site/index.html successfully at http://localhost:8089/ while SELinux remains enforcing, using persistent file context and port-label changes, set httpd_can_network_connect persistently to on, and keep the service enabled at boot.

## Task 04 - Processes Logs And Tuning (clientvm) - 20 pts
Lower the priority of the seeded CPU-intensive process without stopping it, configure persistent journaling, activate the throughput-performance tuned profile, and enable and start review-stamp.service.

## Task 05 - Archive And Log Filtering (clientvm) - 20 pts
Create /root/reports-bundle.tar.gz from /srv/reports and extract only the ALERT lines from /opt/rhcsa/workspaces/review-material/alerts.log into /root/alerts-only.log.

Hints
1. The storage work is local to clientvm and should survive reboot through fstab and swap configuration.
2. Serving content from /srv usually needs both Apache configuration changes and persistent SELinux labeling.
3. This exam also expects a custom SELinux http port label and a persistent SELinux boolean change.
4. The file-work task is separate from the storage task; use the seeded /srv/reports content.

Checks
```bash
vgs
lvs
findmnt /srv/records
findmnt /mnt/archive
swapon --show
ls -ld /srv/reports
getenforce
grep -R '^umask 027' /etc/profile /etc/profile.d 2>/dev/null
tuned-adm active
systemctl status review-stamp.service --no-pager
semanage port -l | grep http_port_t | grep 8089
getsebool httpd_can_network_connect
curl http://localhost:8089/
cat /root/alerts-only.log
```
