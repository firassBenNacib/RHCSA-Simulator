# Lab 42: Process Kill And Renice Solution

## Task 01 - user worker42 has a CPU-bound process whose PID is (clientvm) - 10 pts

```bash
kill "$(cat /home/worker42/cpu.pid)"
```

## Task 02 - User worker42 also has a long-running sleep process (clientvm) - 10 pts

```bash
renice 10 -p "$(cat /home/worker42/sleep.pid)"
```

## Verification

```bash
[ ! -d "/proc/$(cat /home/worker42/cpu.pid)" ]
ps -o ni= -p "$(cat /home/worker42/sleep.pid)" | tr -d ' ' | grep -qx 10
```
