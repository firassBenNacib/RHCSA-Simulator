# Users, Sudo, And SSH Access - Lab Solution
Scenario ID: users-sudo-ssh
Mode: Lab
Time limit: 60 minutes
Objectives: users-sudo-ssh

Practice RHCSA v9 local account management, password policy, privileged access, SSH key-based login, and secure file transfer.

## Task 01 - sysmgrs And analyst (clientvm) - 10 pts
```bash
groupadd sysmgrs
useradd -m -g sysmgrs analyst
```

## Task 02 - Password Aging Policy (clientvm) - 10 pts
```bash
chage -M 30 -W 7 analyst
```

## Task 03 - Sudoers Drop-In (clientvm) - 10 pts
```bash
echo '%sysmgrs ALL=(root) NOPASSWD: /usr/bin/systemctl restart httpd' > /etc/sudoers.d/sysmgrs-httpd
visudo -cf /etc/sudoers.d/sysmgrs-httpd
```

## Task 04 - Analyst SSH Key Login (clientvm) - 10 pts
```bash
install -d -m 700 -o analyst -g sysmgrs /home/analyst/.ssh
cat /home/admin/.ssh/id_rsa.pub > /home/analyst/.ssh/authorized_keys
chown analyst:sysmgrs /home/analyst/.ssh/authorized_keys
chmod 600 /home/analyst/.ssh/authorized_keys
```

## Task 05 - SSH File Transfer (clientvm) - 10 pts
```bash
# Enter the password redhat when scp prompts.
runuser -l admin -c "scp -o StrictHostKeyChecking=no admin@servervm:/srv/rhcsa/objectives/README.txt /home/admin/servervm-objectives.txt"
install -o analyst -g sysmgrs -m 0644 /home/admin/servervm-objectives.txt /home/analyst/servervm-objectives.txt
rm -f /home/admin/servervm-objectives.txt
```

Verification
```bash
id analyst
chage -l analyst
sudo -l -U analyst
ls -ld /home/analyst/.ssh /home/analyst/.ssh/authorized_keys
ls -l /home/analyst/servervm-objectives.txt
```
