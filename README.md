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
* [Go 1.25.8+](https://go.dev/dl/) installed and on **PATH** only if you want to build the TUI from source.

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

* `scenarios/labs`
* `scenarios/exams`

Only one run is active at a time.

Generated runtime cache is written locally under `.lab-state/generated/`, is created on demand, and is not part of the repo.

### Quick start

**1) Build the baseline**

```powershell
.\RHCSA.ps1 up
```

**2) List labs and exams**

```powershell
.\RHCSA.ps1 list
.\RHCSA.ps1 list -Track RHCSA10
```

**3) Start a lab**

```powershell
.\RHCSA.ps1 start -Id lab-01-networking-hostname -Mode Lab
.\RHCSA.ps1 start -Id <rhcsa10-lab-id> -Mode Lab -Track RHCSA10
```

**4) Check your progress**

```powershell
.\RHCSA.ps1 check
```

**5) Open SSH**

```powershell
.\RHCSA.ps1 ssh
```

**6) Open the TUI**

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

The TUI defaults to RHCSA 9 scenarios. Use `.\RHCSA.ps1 tui -Track RHCSA10` or set `RHCSA_TRACK=rhcsa10` for the RHCSA 10 catalog. RHCSA 9 and RHCSA 10 catalogs are filtered separately, so RHCSA 9 Podman/container labs are not shown in RHCSA 10 mode and RHCSA 10 Flatpak/systemd timer labs are not shown in RHCSA 9 mode.

**Release binaries**

GitHub Releases publish prebuilt Windows, Linux, and macOS TUI binaries with checksums through GoReleaser. Binaries are not committed to git; source lives under `cmd/rhcsa-tui`, shared packages live under `internal`, and generated binaries stay under `.build/` or local files ignored by git.

**Keyboard summary**

* `Enter` start the selected lab or exam
* `Tab` move between the catalog and the detail pane
* `←` / `→` switch between Labs and Exams from the catalog, or switch documents from the detail pane
* `F1` or `1` open Tasks
* `F2` or `2` open Hints for labs
* `F3` or `3` or `"` open Checks for labs
* `F4` or `4` or `'` open Solutions
* click `[COPY]` in Checks or Solutions to copy that visible check or solution section
* `c` run checks for the active lab
* `r` reset the active run
* `/` open search
* `z` open SSH to `client`
* `x` open SSH to `server`
* `?` open help, then `Esc` or the top-right `X` closes it

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

The default profile is `rhel9`, which uses:

```powershell
$env:RHCSA_PROFILE = 'rhel9'
$env:RHCSA_ISO = 'rhel-9.7-x86_64-dvd.iso'
$env:RHCSA_BOX = 'generic/rocky9'
```

The RHEL 10 profile uses RHEL 10.1 ISO naming and the official Rocky Linux 10 Vagrant box by default:

```powershell
$env:RHCSA_PROFILE = 'rhel10'
$env:RHCSA_ISO = 'rhel-10.1-x86_64-dvd.iso'
$env:RHCSA_BOX = 'rockylinux/10'
.\RHCSA.ps1 up
```

The RHCSA 10 content track contains 48 labs and 8 mock exams. It is audit-validated in CI; full VM replay requires a local RHEL 10-compatible baseline with the required ISO and VirtualBox provider.

The public EX200 page currently states the exam is based on RHEL 10 and includes Flatpak plus systemd timer objectives. Rocky Linux 10 is available as a compatible community target, but AMD/Intel hosts need x86-64-v3 support. See [docs/rhcsa10-track.md](docs/rhcsa10-track.md) for the track plan.

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
  up          Start or refresh the clean baseline
  destroy     Destroy VMs and local simulator state
  list        List labs and mock exams
  start       Start a lab or exam run
  check       Run checks for the active lab
  reset       Reset the active run
  status      Show baseline, VMs, and the active scenario
  vms         Show VM state
  repo        Run the offline repository self-test
  ssh         Open an SSH session
  ssh-config  Print SSH config for external clients
  tui         Open the interactive TUI
  completion  Generate or install PowerShell completion
  help        Show help
```

## Options

**up**

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

* -Track <RHCSA9|RHCSA10|All>

**tui**

* -Track <RHCSA9|RHCSA10|All>

**check**

* -Id <lab-id> optional, but it must match the active lab

**ssh**

* ssh [server|client]

**ssh-config**

* ssh-config [server|client]

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for checks, local ignored files, and scenario rules. See [docs/project-organization.md](docs/project-organization.md) for the current structure, AustinNicely comparison notes, and refactor direction. See [docs/scenario-coverage.md](docs/scenario-coverage.md) for RHCSA 9/RHCSA 10 topic coverage and [docs/release.md](docs/release.md) for release automation.

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
python tools/scenarios/verify_scenario_solutions.py --kind all --track all --audit-only
```

Keep these user entrypoints working:

```powershell
.\RHCSA.ps1 tui
python tools/scenarios/verify_scenario_solutions.py --kind all --audit-only
```

The Go TUI source under `cmd/rhcsa-tui` and shared packages under `internal` must be committed. Built binaries stay ignored and are published through GitHub Releases.

## License

This project is licensed under the [MIT License](./LICENSE).

## Author

Created and maintained by Firas Ben Nacib - [bennacibfiras@gmail.com](mailto:bennacibfiras@gmail.com)
