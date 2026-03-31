# Lab 19: Login Greeting Messages - Lab Tasks
Scenario ID: lab-19-login-messages
Mode: Lab
Time limit: 25 minutes
Objectives: users-sudo-ssh

Configure user specific and global shell greetings.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Configure a login message for user nico19 that says: Welcome to you, user Nico, you are amazing!

## Task 02 - Part 02 (clientvm)
Configure a global login message so any user receives: Welcome [username], you are logged in! with the actual login name.

Hints
1. A profile script under /etc/profile.d is acceptable for the global message.
2. A user profile file is acceptable for the user specific message.

Checks
```bash
su - nico19 -c true
su - admin -c true
```
