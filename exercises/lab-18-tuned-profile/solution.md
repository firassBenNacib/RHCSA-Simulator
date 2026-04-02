# Lab 18: Tuned Recommended Profile Solution

## Task 01 - Apply the recommended tuned profile and leave it (clientvm) - 10 pts

```bash
tuned-adm recommended
tuned-adm profile <recommended-profile>
tuned-adm active
```

## Verification

```bash
rec="$(tuned-adm recommended | awk '{print $1}')"; act="$(tuned-adm active | sed -E 's/.*: ([^ ]+).*/\1/')"; test -n "$rec" && test "$act" = "$rec"
```
