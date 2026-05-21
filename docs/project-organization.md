# Project Organization

## Current Shape

The simulator has three public surfaces:

* `RHCSA.ps1` for users.
* `cmd/rhcsa-tui` for the terminal UI source.
* `tools/scenarios` for scenario tooling commands.

The implementation is intentionally split between PowerShell orchestration, Go TUI code, Python scenario tools, and guest shell provisioning. This is normal for a VM-based lab simulator, but large files should keep shrinking behind stable entrypoints.

## Scenario Directory Layout

Scenarios are organized into track-specific subdirectories:

```
scenarios/
  labs/
    rhcsa9/     # 48 RHCSA 9 labs
    rhcsa10/    # 48 RHCSA 10 labs
  exams/
    rhcsa9/     # 8 RHCSA 9 mock exams
    rhcsa10/    # 8 RHCSA 10 mock exams
```

Each scenario directory contains `scenario.json`, `LAB_TASKS.md`/`EXAM_TASKS.md`, `LAB_SOLUTION.md`/`EXAM_SOLUTION.md`, and any guest provisioning scripts. Scenario IDs are globally unique so all-track tooling can resolve one target unambiguously. Progress tracking still uses composite `track/id` keys so future same-name track variants can be handled deliberately.

## PowerShell Modules

The PowerShell host code is split into focused `.psm1` modules under `host/modules/`:

| Module | Responsibility |
|---|---|
| FileHelpers | File I/O, UTF-8 no-BOM writes |
| UI | Console formatting, colors |
| LabState | Active-run state, progress JSON |
| Scenarios | Catalog loading, manifest parsing |
| Toolchain | Vagrant/VirtualBox path resolution |
| VMControl | VM lifecycle, SSH, interactive commands |
| Checks | Lab and exam check execution and scoring |

## Recommended Direction

Keep `RHCSA.ps1` as a small facade over focused PowerShell modules. The modules live under `host/modules/` and are imported by `host/modules/RhcsaSimulator`.

Keep Python implementation in `tools/scenarios/`. Host orchestration should stay in PowerShell; Python tooling should not be mixed back into `host/`.

Keep Go package tests beside package source. In Go, colocated `*_test.go` files are idiomatic. A separate `tests/` directory should only be used for end-to-end flows, fixtures, or black-box integration tests that span multiple packages.

## Track Notes

RHCSA 9 remains the default stable track. RHCSA 10 stays separate so Flatpak, systemd timer, and RHEL 10 package assumptions do not leak into RHCSA 9 labs and exams.

Both tracks contain 48 labs and 8 mock exams. Full live replay for RHCSA 9 and RHCSA 10 is verified locally against the Windows + VirtualBox + ISO workflow. CI keeps audit/static validation because GitHub-hosted runners cannot run the VirtualBox/RHEL ISO environment used by the simulator.

Track-specific notes live in `docs/rhcsa9-track.md` and `docs/rhcsa10-track.md`.

Do not copy tasks from exam dumps or proprietary PDFs. Use those materials only as a coverage-gap signal.
