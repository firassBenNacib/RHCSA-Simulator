# SELinux And Default File Permissions - Lab Tasks
Scenario ID: selinux-and-default-perms
Mode: Lab
Time limit: 60 minutes
Objectives: selinux-and-default-perms

Practice RHCSA v9 SELinux troubleshooting together with default permissions, SELinux port labels, and booleans.

## Task 01 - Default Umask (clientvm) - 10 pts
Set the system-wide default umask to 027 for interactive shells.

## Task 02 - Apache Site On 8089 (clientvm) - 15 pts
Update Apache so /srv/rhcsa/selinux-site/index.html is served at http://localhost:8089/ while SELinux remains enforcing.

## Task 03 - Persistent SELinux Labels (clientvm) - 15 pts
Apply persistent SELinux file-context and port-label changes so the site path and TCP port 8089 continue to work after relabel or reboot.

## Task 04 - Persistent SELinux Boolean (clientvm) - 10 pts
Set the SELinux boolean httpd_can_network_connect to on persistently.

## Task 05 - Enforcing Mode (clientvm) - 5 pts
Keep SELinux in enforcing mode throughout the task.

Hints
1. A profile.d script is acceptable for the umask task.
2. Use semanage fcontext and restorecon for persistent labeling.
3. Apache must be pointed to the custom content directory before curl will work.
4. Use semanage port for the custom TCP port and getsebool or setsebool for the boolean.

Checks
```bash
grep -R '^umask 027' /etc/profile /etc/profile.d 2>/dev/null
getenforce
ls -Zd /srv/rhcsa/selinux-site /srv/rhcsa/selinux-site/index.html
semanage port -l | grep http_port_t | grep 8089
getsebool httpd_can_network_connect
curl http://localhost:8089/
```
