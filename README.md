# RHCSA Simulator

An interactive PowerShell project for running RHCSA practice labs and mock exams with Vagrant, VirtualBox, SSH helpers, checks, and a terminal UI. The catalog contains separate RHCSA 9 and RHCSA 10 tracks so users can train against the right objective set without mixing Podman-era RHCSA 9 tasks with Flatpak and systemd timer RHCSA 10 tasks.

## Table of Contents

* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Usage](#usage)
* [Commands](#commands)
* [Options](#options)
* [Development](#development)
* [License](#license)
* [Author](#author)

## Prerequisites

* Windows 10 or 11
* PowerShell 5.1 or newer
* [Vagrant](https://developer.hashicorp.com/vagrant/install) installed and on **PATH**
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads) installed and on **PATH**
* `rhel-9.7-x86_64-dvd.iso` in the project root for the validated RHCSA 9 profile
* `rhel-10.1-x86_64-dvd.iso` if you use the RHCSA 10 profile
* [Go 1.25+](https://go.dev/dl/) installed and on **PATH** only if you want to build the TUI from source.

## Installation

Clone:

```powershell
git clone https://github.com/firassBenNacib/rhcsa_exam_vms.git
cd rhcsa_exam_vms
```

Install or refresh the prebuilt TUI binary from the latest GitHub Release. The installer downloads the Windows TUI archive, extracts `rhcsa-tui.exe` into `.build/`, and keeps the source tree clean:

```powershell
irm https://raw.githubusercontent.com/firassBenNacib/rhcsa_exam_vms/main/install.ps1 -OutFile install.ps1
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

If you trust the repository and want a one-line installer:

```powershell
irm https://raw.githubusercontent.com/firassBenNacib/rhcsa_exam_vms/main/install.ps1 | iex
```

Private forks can use the same installer by setting `GITHUB_TOKEN` before running it.

## Usage

The simulator uses two VMs:

* server for the offline repository, NFS exports, and time source
* client as the main RHCSA workstation

Scenario source files live under:

* `scenarios/labs/<track>/` (e.g. `scenarios/labs/rhcsa9/`, `scenarios/labs/rhcsa10/`)
* `scenarios/exams/<track>/` (e.g. `scenarios/exams/rhcsa9/`, `scenarios/exams/rhcsa10/`)

Only one run is active at a time.

Generated runtime cache is written locally under `.lab-state/generated/`, is created on demand, and is not part of the repo.

### Quick start

**1) Build the baseline**

```powershell
.\RHCSA.ps1 up
```

Switch the project to RHCSA 10 when you want the RHEL 10/Rocky 10 baseline and RHCSA 10 catalog:

```powershell
.\RHCSA.ps1 profile RHCSA10
.\RHCSA.ps1 up
```

Switch back to the default RHCSA 9 profile:

```powershell
.\RHCSA.ps1 profile RHCSA9
```

**2) List labs and exams**

```powershell
.\RHCSA.ps1 list
```

**3) Start a lab**

```powershell
.\RHCSA.ps1 start -Id lab-01-networking-hostname -Mode Lab
```

**4) Check your progress**

```powershell
.\RHCSA.ps1 check
```

`check` works for the active lab or exam. Exam checks report a check count and a check-weighted score.

**5) Pause, resume, or exit a run**

```powershell
.\RHCSA.ps1 pause
.\RHCSA.ps1 resume
.\RHCSA.ps1 exit-run
```

`pause` saves VM state for fast resume. `down` powers VMs off. `exit-run` leaves the active lab or exam context without resetting VMs or undoing learner changes.

**6) Open SSH**

```powershell
.\RHCSA.ps1 ssh
```

SSH is available only while a lab or exam is active.

**7) Open the TUI**

```powershell
.\RHCSA.ps1 tui
```

### TUI usage

There are two supported ways to use the TUI:

**Recommended for users**

Use the PowerShell entrypoint. It reuses `.build\rhcsa-tui.exe` when available and rebuilds only when source files changed:

```powershell
.\RHCSA.ps1 tui
```

You can also double-click:

```powershell
.\rhcsa-tui.cmd
```

`rhcsa-tui.exe` is a terminal application, not a desktop GUI application. Double-clicking the executable directly can open and close a console too quickly to see. Use `rhcsa-tui.cmd` for double-click launches, or run the executable from a terminal:

```powershell
.\.build\rhcsa-tui.exe --project-root C:\path\to\rhcsa_exam_vms
.\.build\rhcsa-tui.exe --project-root C:\path\to\rhcsa_exam_vms --track rhcsa10
```

The TUI finds `RHCSA.ps1` from:

* `--project-root` if passed
* `RHCSA_SIMULATOR_ROOT` if set
* the current working directory
* the directory that contains the TUI binary

The TUI follows the project profile automatically. RHCSA 9 is the default when no profile file exists. Run `.\RHCSA.ps1 profile RHCSA10` to switch the project to RHCSA 10, then open `.\RHCSA.ps1 tui` normally. RHCSA 9 Podman/container labs are hidden in RHCSA 10 mode and RHCSA 10 Flatpak/systemd timer labs are hidden in RHCSA 9 mode. `-Track` still exists as a temporary override when you explicitly want a different catalog for one command.

**Release binaries**

GitHub Releases publish prebuilt Windows, Linux, and macOS TUI binaries with checksums through GoReleaser. Binaries are not committed to git; source lives under `cmd/rhcsa-tui`, shared packages live under `internal`, and generated binaries stay under `.build/` or local files ignored by git.

**Keyboard summary**

* `Enter` start the selected lab or exam
* `Tab` move between the catalog and the detail pane
* `←` / `→` switch between Labs and Exams from the catalog, or switch documents from the detail pane
* `F1` or `1` open Tasks
* `F2` or `2` open Hints for labs
* `F3` or `3` or `"` open Checks
* `F4` or `4` or `'` open Solutions
* click `[COPY]` in Checks or Solutions to copy that visible check or solution section
* `c` run checks for the active lab or exam
* `r` reset the active run
* `e` exit the active lab or exam context without changing VM state
* `/` open search
* `t` toggle the per-run timer display
* `z` open SSH to `client`
* `x` open SSH to `server`
* `?` open help, then `Esc` or the top-right `X` closes it
* `q` quit the TUI

Mouse support uses modern SGR terminal mouse events. Windows Terminal, current PowerShell terminals, Linux terminals, and macOS Terminal/iTerm2 support this mode. If mouse clicks do not register in an older terminal, use the keyboard shortcuts above or run the TUI in a modern terminal emulator.

**Build from source**

```powershell
go build -o rhcsa-tui.exe ./cmd/rhcsa-tui
.\rhcsa-tui.exe
```

### Optional commands

**Destroy the simulator**

```powershell
.\RHCSA.ps1 destroy
```

**Power off or save VM state**

```powershell
.\RHCSA.ps1 pause
.\RHCSA.ps1 down
.\RHCSA.ps1 resume
```

**Refresh the clean baseline explicitly**

```powershell
.\RHCSA.ps1 up -Refresh
```

Plain `up` is non-interactive and automation-safe. If the baseline is already ready and VMs are running, it reports the current VM state instead of rebuilding. Use `up -Refresh` when you intentionally want to restore the clean baseline.

**Start without provisioning**

```powershell
.\RHCSA.ps1 up -NoProvision
```

**Start an exam**

```powershell
.\RHCSA.ps1 start -Id mock-exam-a -Mode Exam
```

**Reset the active run**

```powershell
.\RHCSA.ps1 reset
```

**Exit the active run without resetting VMs**

```powershell
.\RHCSA.ps1 exit-run
```

**Set the default TUI timer mode**

```powershell
.\RHCSA.ps1 timer status
.\RHCSA.ps1 timer on
.\RHCSA.ps1 timer off
```

The timer is off by default. When enabled, the TUI shows the active run timer after a lab or exam starts. Pressing `t` in the TUI remains a per-run override.

**Show status**

```powershell
.\RHCSA.ps1 status
.\RHCSA.ps1 vms
```

**Show SSH config**

```powershell
.\RHCSA.ps1 ssh-config
.\RHCSA.ps1 ssh-config server
```

**Download or rebuild the TUI**

Use GitHub Releases for prebuilt binaries, or rebuild locally with:

```powershell
go build -o rhcsa-tui.exe ./cmd/rhcsa-tui
```

The repository includes:

* `.github/workflows/ci.yml` for Go tests/vet/staticcheck/build, Go coverage artifacts, Python syntax and unit tests, scenario audits, PowerShell parsing, PSScriptAnalyzer, Vagrantfile syntax, and whitespace checks.
* `.github/workflows/security.yml` for Go vulnerability scans and dependency review on pull requests.
* `.github/workflows/release-please.yml` for automated release PRs and semantic version tags from `main`.
* `.github/workflows/release-tui.yml` for GoReleaser-built Windows, Linux, and macOS TUI archives with checksums and generated changelogs.
* `.github/workflows/runtime-replay.yml` for manual self-hosted Windows replay against a local VirtualBox/RHEL ISO environment.
* `.github/dependabot.yml` for weekly Go module, Python dependency, and GitHub Actions update PRs.
* `.goreleaser.yml` for release packaging.
* `Makefile` for repeatable local checks on Linux/macOS/WSL.

### Platform profiles

The project stores the active RHCSA version locally in `.rhcsa-profile.json`.

RHCSA 9 is the default if that file does not exist:

```powershell
.\RHCSA.ps1 profile
.\RHCSA.ps1 profile RHCSA9
```

Switch to RHCSA 10 inside the project:

```powershell
.\RHCSA.ps1 profile RHCSA10
.\RHCSA.ps1 up
```

The saved project profile controls:

* which Vagrant baseline is used
* which labs and exams the CLI lists by default
* which catalog the TUI opens by default

Advanced users can still override ISO or box selection with `RHCSA_ISO`, `RHCSA_BOX`, and `RHCSA_BOX_URL`, but normal usage should go through `.\RHCSA.ps1 profile RHCSA9|RHCSA10`.

Both bundled tracks contain 48 labs and 8 mock exams. RHCSA 9 is the default validated baseline. RHCSA 10 uses a separate RHEL 10-compatible baseline and catalog so newer objectives do not leak into RHCSA 9 practice.

The default RHCSA 10 box name is `boxomatic/almalinux-10`, which boots reliably on the supported Windows + VirtualBox workflow. You can still use another AlmaLinux, Rocky Linux, RHEL 10, or locally maintained RHEL-compatible box with `RHCSA_BOX` and, when needed, `RHCSA_BOX_URL`:

```powershell
$env:RHCSA_BOX = 'boxomatic/almalinux-10'
```

The public EX200 page currently states the exam is based on RHEL 10 and includes Flatpak plus systemd timer objectives. Rocky Linux 10 is available as a compatible community target, but AMD/Intel hosts need x86-64-v3 support. See [docs/rhcsa9-track.md](docs/rhcsa9-track.md) and [docs/rhcsa10-track.md](docs/rhcsa10-track.md) for track-specific notes.

### Scenario replay verification

Use Windows Python for live replay because the verifier talks to the Windows Vagrant and VirtualBox environment:

```powershell
python3.13.exe .\host\verify_scenario_solutions.py --kind lab --track RHCSA9
python3.13.exe .\host\verify_scenario_solutions.py --kind exam --track RHCSA9
python3.13.exe .\host\verify_scenario_solutions.py --kind lab --track RHCSA10
python3.13.exe .\host\verify_scenario_solutions.py --kind exam --track RHCSA10
```

For static manifest checks without replaying VMs:

```powershell
python3.13.exe .\host\verify_scenario_solutions.py --kind all --track all --audit-only
```

### Host cleanup

The simulator scopes cleanup to this project by default. It should not kill unrelated Vagrant or VirtualBox processes owned by other projects. If a host is stuck behind stale global Vagrant or VirtualBox locks, use the explicit last-resort switch:

```powershell
.\RHCSA.ps1 up -ForceHostCleanup
.\RHCSA.ps1 destroy -ForceHostCleanup
```

You can also set `RHCSA_FORCE_HOST_CLEANUP=1` for one terminal session.

## Commands

```text
Usage: .\RHCSA.ps1 <command> [options]

Commands
  up          Start or verify the clean baseline
  resume      Resume paused or powered-off VMs
  pause       Save VM state for fast resume
  down        Power off the simulator VMs
  destroy     Destroy VMs and local simulator state
  list        List labs and mock exams
  start       Start a lab or exam run
  exit-run    Exit the active lab or exam context
  check       Run checks for the active lab or exam
  reset       Reset the active run
  status      Show baseline, VMs, and the active scenario
  vms         Show VM state
  repo        Run the offline repository self-test
  ssh         Open SSH for the active run
  ssh-config  Print SSH config for external clients
  tui         Open the interactive TUI
  profile     Show or change the project RHCSA version
  timer       Show or change the default timer mode
  completion  Generate or install PowerShell completion
  help        Show help
```

## Options

**up**

* -Profile <RHCSA9|RHCSA10>
* -Refresh
* -NoProvision
* -NormalStart
* -HeadlessClient
* -RealisticMode
* -ForceHostCleanup

**start**

* -Id <scenario-id>
* -Mode <Lab|Exam>
* -Track <RHCSA9|RHCSA10|All>

**list**

* -Track <Auto|RHCSA9|RHCSA10|All>

**tui**

* -Track <Auto|RHCSA9|RHCSA10|All>

**profile**

* profile
* profile <RHCSA9|RHCSA10>

**check**

* -Id <scenario-id> optional, but it must match the active lab or exam

**timer**

* timer status
* timer on
* timer off

**ssh**

* ssh [server|client]

**ssh-config**

* ssh-config [server|client]

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for checks, local ignored files, and scenario rules. See [docs/project-organization.md](docs/project-organization.md) for the current structure, comparison notes, and refactor direction. See [docs/scenario-coverage.md](docs/scenario-coverage.md) for RHCSA 9/RHCSA 10 topic coverage, [docs/rhcsa9-track.md](docs/rhcsa9-track.md) and [docs/rhcsa10-track.md](docs/rhcsa10-track.md) for track notes, and [docs/release.md](docs/release.md) for release automation.

Fast local checks:

```bash
make test
```

Windows PowerShell equivalents:

```powershell
go test ./...
go vet ./...
go build ./cmd/rhcsa-tui
python -m unittest discover tools/scenarios/tests
python host/verify_scenario_solutions.py --kind all --track all --audit-only
```

Keep these user entrypoints working:

```powershell
.\RHCSA.ps1 tui
python host/verify_scenario_solutions.py --kind all --audit-only
```

The Go TUI source under `cmd/rhcsa-tui` and shared packages under `internal` must be committed. Built binaries stay ignored and are published through GitHub Releases.

## License

This project is licensed under the [MIT License](./LICENSE).

## Author

Created and maintained by Firas Ben Nacib - [bennacibfiras@gmail.com](mailto:bennacibfiras@gmail.com)
