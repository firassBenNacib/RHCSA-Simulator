# Project Organization

This document explains how the RHCSA Simulator repository is organized and where each major part of the project lives.

## Main Entry Points

The project has three main public entry points:

| Path | Purpose |
|---|---|
| `RHCSA.ps1` | Main PowerShell CLI used by learners |
| `rhcsa-tui.cmd` | Windows launcher for the terminal UI |
| `cmd/rhcsa-tui/` | Go source code for the terminal UI |

Most users should interact with the simulator through:

```powershell
.\RHCSA.ps1 tui
```

or through direct CLI commands such as:

```powershell
.\RHCSA.ps1 up
.\RHCSA.ps1 list
.\RHCSA.ps1 start
.\RHCSA.ps1 check
```

## High-Level Architecture

RHCSA Simulator is split across four main layers:

| Layer | Technology | Responsibility |
|---|---|---|
| Host CLI | PowerShell | VM lifecycle, profiles, scenario runs, checks, SSH helpers |
| Terminal UI | Go | Interactive lab and exam interface |
| Scenario tooling | Python | Scenario generation, audits, and validation |
| Guest provisioning | Bash | VM setup, repositories, services, and lab preparation |

This split keeps the user-facing workflow simple while allowing each part of the simulator to use the right tool for its job.

## Repository Layout

```text
RHCSA-Simulator/
├── RHCSA.ps1              # Main PowerShell CLI
├── rhcsa-tui.cmd          # Windows launcher for the TUI
├── install.ps1            # Installer for the prebuilt TUI binary
├── Vagrantfile            # VM definition
├── host/                  # Host-side PowerShell runtime and validation logic
├── guest/                 # Guest VM provisioning scripts
├── cmd/rhcsa-tui/         # Go terminal UI source
├── internal/              # Shared Go packages
├── scenarios/             # Labs and mock exams
├── tools/scenarios/       # Python scenario tools
├── docs/                  # Project documentation
├── demo/                  # Demo images and screencasts
├── .github/               # CI, security, release, and dependency workflows
├── Makefile               # Local development checks
└── README.md              # Main user-facing documentation
```

## Scenario Layout

Scenarios are organized by mode and RHCSA track:

```text
scenarios/
├── labs/
│   ├── rhcsa9/            # RHCSA 9 labs
│   └── rhcsa10/           # RHCSA 10 labs
└── exams/
    ├── rhcsa9/            # RHCSA 9 mock exams
    └── rhcsa10/           # RHCSA 10 mock exams
```

Each track contains:

| Track | Labs | Mock exams | Total scenarios |
|---|---:|---:|---:|
| RHCSA 9 | 48 | 8 | 56 |
| RHCSA 10 | 48 | 8 | 56 |

Each scenario directory normally contains:

```text
scenario.json
LAB_TASKS.md or EXAM_TASKS.md
LAB_SOLUTION.md or EXAM_SOLUTION.md
optional provisioning scripts
```

Scenario IDs should stay globally unique so tooling can resolve scenarios without ambiguity.

## Scenario Metadata

Each scenario is described by a `scenario.json` file.

RHCSA 9 scenarios should include:

```json
{
  "tracks": ["rhcsa9"],
  "rhel_major": 9
}
```

RHCSA 10 scenarios should include:

```json
{
  "tracks": ["rhcsa10"],
  "rhel_major": 10
}
```

Dual-track scenarios should only be marked as shared when they have been tested on both baselines.

## PowerShell Runtime

The main CLI is `RHCSA.ps1`.

Most host-side behavior is implemented in PowerShell modules under:

```text
host/modules/
```

The main modules are:

| Module | Responsibility |
|---|---|
| `FileHelpers` | File I/O and UTF-8 no-BOM writes |
| `UI` | Console output, formatting, and colors |
| `LabState` | Active scenario state and progress files |
| `Scenarios` | Scenario catalog loading and manifest parsing |
| `Toolchain` | Vagrant and VirtualBox path resolution |
| `VMControl` | VM lifecycle, SSH, and interactive commands |
| `Checks` | Lab and exam check execution and scoring |

`RHCSA.ps1` should stay as the stable user-facing entry point. Large behavior should live in modules instead of being added directly to the root script.

## Terminal UI

The TUI source lives under:

```text
cmd/rhcsa-tui/
```

Shared Go packages live under:

```text
internal/
```

Built binaries should not be committed to git. Release binaries are published through GitHub Releases and installed locally into ignored build/output paths.

The normal user entry point remains:

```powershell
.\RHCSA.ps1 tui
```

## Scenario Tooling

Python scenario tools live under:

```text
tools/scenarios/
```

These tools are used for scenario generation, audits, and validation.

Host-side replay and verification helpers live under:

```text
host/
```

Use audit-only validation for fast local checks:

```powershell
python host/verify_scenario_solutions.py --kind all --track all --audit-only
```

Live replay should be used after changes that affect provisioning, checks, runtime behavior, or scenario solutions.

## Runtime State

Generated runtime data should stay outside source-controlled content.

Local runtime state is written under ignored paths such as:

```text
.lab-state/
.build/
```

These files are created locally and should not be committed.

The repository should not contain:

```text
RHEL ISO files
VM images
generated binaries
local lab state
temporary Vagrant state
```

## RHCSA Tracks

RHCSA 10 is the default track for new checkouts because the current EX200 exam is based on RHEL 10.

RHCSA 10 is kept separate so RHEL 10-specific objectives and assumptions do not leak into RHCSA 9 labs.
RHCSA 9 remains available as an explicit RHEL 9 practice profile.

Key differences:

| Area | RHCSA 9 | RHCSA 10 |
|---|---|---|
| Default profile | No | Yes |
| Containers | Podman-focused tasks | Not mixed into RHCSA 9 content |
| Flatpak | Not part of RHCSA 9 track | Included |
| systemd timers | Limited/general systemd usage | Included as RHCSA 10 content |
| Baseline | RHEL 9-compatible | RHEL 10-compatible |

Track-specific notes live in:

```text
docs/rhcsa9-track.md
docs/rhcsa10-track.md
```

## Validation Strategy

GitHub-hosted CI can run static and audit checks, but it cannot fully reproduce the local VirtualBox and RHEL ISO environment.

Therefore, validation is split into two levels:

| Validation type | Purpose |
|---|---|
| CI/static validation | Syntax, unit tests, scenario metadata, audit checks |
| Local live replay | Full VM-based validation against the real lab baseline |

Live replay is the source of truth for behavior involving:

```text
packages
repositories
storage devices
SELinux state
services
networking
SSH execution
client/server interaction
```
