# Scenario Coverage Review

This document summarizes the RHCSA Simulator scenario coverage, track separation, and validation status.

The project uses original scenario wording. Public RHCSA objectives may guide coverage planning, but exam dumps, copied exam questions, and commercial-course text must not be copied into this repository.

## Current Scenario Tracks

| Track | Labs | Mock exams | Total scenarios | Runtime status |
|---|---:|---:|---:|---|
| RHCSA 9 | 48 | 8 | 56 | full local live replay verified |
| RHCSA 10 | 48 | 8 | 56 | full local live replay verified |

Scenario directories:

```text
scenarios/labs/rhcsa9/
scenarios/labs/rhcsa10/
scenarios/exams/rhcsa9/
scenarios/exams/rhcsa10/
```

RHCSA 9 scenarios use:

```json
{
  "tracks": ["rhcsa9"],
  "rhel_major": 9
}
```

RHCSA 10 scenarios use:

```json
{
  "tracks": ["rhcsa10"],
  "rhel_major": 10
}
```

## Coverage Summary

The simulator covers the main hands-on administration areas expected from RHCSA-style practice.

## RHCSA 9 Coverage

The RHCSA 9 track covers:

- boot recovery
- DNF repositories
- networking
- users and groups
- sudo
- SELinux
- firewalld
- storage
- NFS and autofs
- cron and at
- logs
- tuned
- SSH
- archives
- find and grep
- Podman/container tasks

Podman and container administration remain part of the RHCSA 9 track.

## RHCSA 10 Coverage

The RHCSA 10 track is separate and covers RHEL 10-specific content without mixing it into RHCSA 9.

| Topic | Current handling |
|---|---|
| Flatpak repository setup | covered in RHCSA 10 labs and exams |
| Flatpak application lifecycle | covered in RHCSA 10 labs and exams |
| systemd timer units | covered in RHCSA 10 labs and exams |
| RPM repositories | covered in RHCSA 10 labs and exams |
| NetworkManager | covered in RHCSA 10 labs and exams |
| Storage | covered with RHCSA 10-specific scenarios |
| Users and groups | covered with RHCSA 10-specific scenarios |
| SELinux | covered with RHCSA 10-specific scenarios |
| Client/server operations | covered in labs and mock exams |

RHCSA 9 Podman/container scenarios should not be moved into RHCSA 10 unless they are deliberately tested and marked as compatible.

## Track Separation Rules

RHCSA 9 and RHCSA 10 tracks should stay separate by default.

A scenario should only be marked as dual-track when:

- it works on both baselines
- package assumptions are valid on both tracks
- checks pass on both tracks
- live replay has been completed on both profiles

Track separation prevents RHCSA 10-specific topics such as Flatpak and systemd timers from leaking into RHCSA 9 practice.

## Scenario Quality Guidelines

Scenario content should be original and consistent.

Use these rules when adding or editing scenarios:

- Keep scenario wording clear and task-oriented.
- Keep RHCSA 9 and RHCSA 10 objectives separate.
- Use runtime scripts when the baseline needs prepared files, users, repositories, services, or storage state.
- Regenerate scenario Markdown after editing `scenario.json`.
- Keep generated RHCSA 10 exams varied so repeated topic blocks do not become near-identical exams.
- Do not copy wording from exam dumps, proprietary training material, or commercial courses.

Allowed references:

- public RHCSA objectives
- official product documentation
- original lab design
- project validation results

Not allowed:

- exam dumps
- copied exam questions
- commercial-course text
- proprietary training material

## Runtime Validation

Validation is split into two levels:

| Validation type | Purpose |
|---|---|
| Scenario audit | Checks scenario metadata, target balance, generated Markdown consistency, and scenario quality guardrails |
| Audit-only validation | Checks replay command structure without starting scenarios |
| Live replay validation | Proves the scenario works against the real VM baseline |

Run both fast checks after scenario edits:

```powershell
<python> .\tools\scenarios\audit_scenarios.py
<python> .\host\verify_scenario_solutions.py --kind all --track all --audit-only
```

Track-specific audit checks:

```powershell
<python> .\host\verify_scenario_solutions.py --kind all --track RHCSA9 --audit-only
<python> .\host\verify_scenario_solutions.py --kind all --track RHCSA10 --audit-only
```

Replace `<python>` with the Python launcher available on your machine, such as `python`, `python3.13.exe`, or `py -3.13`.

Live replay is the source of truth for VM behavior because it validates:

- package availability
- repository setup
- storage devices
- SELinux state
- services
- networking
- SSH execution
- client/server interaction
- scenario checks
- scenario solutions

## Live Replay Commands

Run live replay from Windows PowerShell because the verifier talks to the Windows Vagrant and VirtualBox environment.

RHCSA 9:

```powershell
<python> .\host\verify_scenario_solutions.py --kind lab --track RHCSA9
<python> .\host\verify_scenario_solutions.py --kind exam --track RHCSA9
```

RHCSA 10:

```powershell
<python> .\host\verify_scenario_solutions.py --kind lab --track RHCSA10
<python> .\host\verify_scenario_solutions.py --kind exam --track RHCSA10
```

Focused replay for one changed scenario:

```powershell
<python> .\host\verify_scenario_solutions.py --kind lab --track RHCSA10 --only lab-06-flatpak-remote
<python> .\host\verify_scenario_solutions.py --kind exam --track RHCSA9 --only mock-exam-a
```

## When to Re-Run Validation

Run scenario audit and audit-only validation after:

- editing `scenario.json`
- regenerating scenario Markdown
- changing scenario metadata
- changing scenario generators
- editing checks or replay commands

Run live replay after:

- changing provisioning
- changing VM baseline behavior
- changing package assumptions
- changing storage setup
- changing networking setup
- changing SELinux-related tasks
- changing scenario solutions
- changing shared runtime logic

## Current Status

Both RHCSA 9 and RHCSA 10 have been verified with full local replay on the supported Windows + VirtualBox + ISO workflow.

GitHub-hosted CI keeps static and audit validation in place, but full live replay remains a local validation step because the simulator depends on VirtualBox and local RHEL ISO media.

## Related Documentation

- [Project organization](project-organization.md)
- [RHCSA 9 track notes](rhcsa9-track.md)
- [RHCSA 10 track notes](rhcsa10-track.md)
- [Release process](release.md)
