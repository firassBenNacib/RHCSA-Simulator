# Lab 19: Login Greeting Messages - Lab Solution
Scenario ID: lab-19-login-messages
Mode: Lab
Time limit: 25 minutes
Objectives: users-sudo-ssh

Configure user specific and global shell greetings.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
id nico19 || useradd -m nico19
vim /home/nico19/.bash_profile
echo "Welcome to you, user Nico, you are amazing!"
```

## Task 02 - Part 02 (clientvm)
```bash
vim /etc/profile.d/lab19-greeting.sh
echo "Welcome ${USER}, you are logged in!"
```

Verification
```bash
su - nico19 -c true
su - admin -c true
```
