# Lab 43: Package Install And Remove Solution

## Task 01 - Use the prepared local repositories on clientvm to (clientvm) - 10 pts

```bash
dnf install -y tree dos2unix
```

## Task 02 - Remove dos2unix and leave tree installed (clientvm) - 10 pts

```bash
dnf remove -y dos2unix
rpm -q tree
```

## Verification

```bash
rpm -q tree
! rpm -q dos2unix
```
