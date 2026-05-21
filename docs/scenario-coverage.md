# Scenario Coverage Review

This project uses original scenario wording. Public objectives may guide coverage gaps, but exam-dump or commercial-course wording must not be copied into the repository.

## Current Scenario Tracks

| Track | Scenarios | Runtime status |
|---|---:|---|
| RHCSA 9 | 56 | full local live replay verified |
| RHCSA 10 | 56 | full local live replay verified |

RHCSA 9 scenarios live under `scenarios/labs/rhcsa9/` and `scenarios/exams/rhcsa9/` with `tracks: ["rhcsa9"]`. RHCSA 10-specific scenarios live under `scenarios/labs/rhcsa10/` and `scenarios/exams/rhcsa10/` with `tracks: ["rhcsa10"]` and `rhel_major: 10`.

## Topic Gap Findings

The RHCSA 9 set covers the expected core areas: boot recovery, DNF repositories, networking, users/groups, sudo, SELinux, firewalld, storage, NFS/autofs, cron/at, logs, tuned, SSH, archives, find/grep, and Podman/container tasks.

The RHCSA 10 track is separate and covers the RHEL 10-specific additions without moving RHCSA 9 Podman/container content into the newer track:

| Topic | Current handling |
|---|---|
| Flatpak repository setup | covered in RHCSA 10 labs and exams |
| Flatpak application lifecycle | covered in RHCSA 10 labs and exams |
| systemd timer units | covered in RHCSA 10 labs and exams |
| Podman/container administration | RHCSA 9 only |
| Storage, users, networking, SELinux | covered with RHCSA 10-specific scenario IDs and metadata |
| Client/server operations | both tracks include client-only, server-only, and client/server scenarios |

## Scenario Quality Rules

- Keep RHCSA 9 and RHCSA 10 tracks separate unless a scenario passes replay on both profiles.
- Keep generated RHCSA 10 exams varied enough that repeated topic blocks do not drift into near-identical exams.
- Do not duplicate PDF exam text. Rewrite tasks as original simulator scenarios with checks and solutions.
- Add runtime scripts only when the baseline needs prepared files, users, repositories, or local services.
- Regenerate scenario Markdown after editing `scenario.json`.

## Runtime Validation Notes

Audit-only validation proves the scenario metadata, generated Markdown, and replay commands are structurally sound. Live replay is still the source of truth for VM behavior because it proves packages, repositories, storage devices, SELinux state, and SSH execution against the real baseline.

Both RHCSA 9 and RHCSA 10 have been verified with full local replay on the supported Windows + VirtualBox + ISO workflow. Re-run live replay after shared runtime, provisioning, or scenario generator changes.
