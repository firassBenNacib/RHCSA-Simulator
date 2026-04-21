# Scenario Coverage Review

This project uses original scenario wording. Public Red Hat objectives and private local study PDFs may guide coverage gaps, but exam-dump or commercial-course wording must not be copied into the repository.

## Current Scenario Tracks

| Track | Scenarios | Runtime status |
|---|---:|---|
| RHCSA 9 | 56 | validated with audit-only checks |
| RHCSA 10 | 2 preview labs | content/audit preview, runtime replay pending on a RHEL 10-compatible baseline |

RHCSA 9 scenarios stay on `tracks: ["rhcsa9"]`. RHCSA 10-specific scenarios use `tracks: ["rhcsa10"]` and `rhel_major: 10`.

## Topic Gap Findings

The RHCSA 9 set covers the expected core areas: boot recovery, DNF repositories, networking, users/groups, sudo, SELinux, firewalld, storage, NFS/autofs, cron/at, logs, tuned, SSH, archives, find/grep, and Podman/container tasks.

The RHCSA 10 gap is narrower and should remain separate:

| Topic | Current handling |
|---|---|
| Flatpak repository setup | added as RHCSA 10 preview lab |
| systemd timer units | added as RHCSA 10 preview lab |
| Podman/container administration | RHCSA 9 only |
| Storage, users, networking, SELinux | reusable only after RHEL 10 replay validation |

## Scenario Quality Rules

- Keep RHCSA 9 and RHCSA 10 tracks separate unless a scenario passes replay on both profiles.
- Prefer smaller focused RHCSA 10 labs before adding full RHCSA 10 mock exams.
- Do not duplicate PDF exam text. Rewrite tasks as original simulator scenarios with checks and solutions.
- Add runtime scripts only when the baseline needs prepared files, users, repositories, or local services.
- Regenerate scenario Markdown after editing `scenario.json`.
