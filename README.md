# RHCSA Simulator

An interactive PowerShell project for running RHCSA practice labs and mock exams with Vagrant, VirtualBox, SSH helpers, checks, and a terminal UI. The validated scenario set targets RHCSA 9 on RHEL 9; a RHEL 10 platform profile is available as preview infrastructure for future RHCSA 10 content.

## Table of Contents

* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Usage](#usage)
* [Commands](#commands)
* [Options](#options)
* [License](#license)
* [Author](#author)

## Prerequisites

* Windows 10 or 11
* PowerShell 5.1 or newer
* [Vagrant](https://developer.hashicorp.com/vagrant/install) installed and on **PATH**
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads) installed and on **PATH**
* `rhel-9.7-x86_64-dvd.iso` in the project root for the validated RHCSA 9 profile
* `rhel-10.1-x86_64-dvd.iso` only if you opt into the preview RHEL 10 profile
* [Go 1.25+](https://go.dev/dl/) installed and on **PATH** only if you want to build the TUI from source

## Installation

Clone:

```powershell
git clone https://github.com/firassBenNacib/rhcsa_exam_vms.git
cd rhcsa_exam_vms
```

Install or refresh the prebuilt TUI binary from the latest GitHub Release:

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

The TUI defaults to RHCSA 9 scenarios. Use `.\RHCSA.ps1 tui -Track RHCSA10` or set `RHCSA_TRACK=rhcsa10` to preview RHCSA 10 content after a RHEL 10-compatible baseline is available.

**Release binaries**

GitHub Releases publish prebuilt Windows, Linux, and macOS TUI binaries. Binaries are not committed to git; source lives under `cmd/rhcsa-tui`, shared packages live under `internal`, and generated binaries stay under `.build/` or local files ignored by git.

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

The repository includes a GitHub Actions workflow at `.github/workflows/release-tui.yml` that builds and uploads Windows, Linux, and macOS TUI binaries when a GitHub Release is published.

### Platform profiles

The default profile is `rhel9`, which uses:

```powershell
$env:RHCSA_PROFILE = 'rhel9'
$env:RHCSA_ISO = 'rhel-9.7-x86_64-dvd.iso'
$env:RHCSA_BOX = 'generic/rocky9'
```

The preview RHEL 10 profile uses RHEL 10.1 ISO naming and a Rocky 10 Vagrant box by default:

```powershell
$env:RHCSA_PROFILE = 'rhel10'
$env:RHCSA_ISO = 'rhel-10.1-x86_64-dvd.iso'
$env:RHCSA_BOX = 'generic/rocky10'
.\RHCSA.ps1 up
```

RHEL 10 support is intentionally marked preview until the full lab/exam replay suite is validated on a RHEL 10 baseline. RHCSA 10 content should be added as separate scenarios where behavior differs, especially Flatpak package tasks and updated systemd/service-management objectives.

The public EX200 page currently states the exam is based on RHEL 10 and includes Flatpak plus systemd timer objectives. Rocky Linux 10 is available as a compatible community target, but AMD/Intel hosts need x86-64-v3 support. See [docs/rhcsa10-track.md](docs/rhcsa10-track.md) for the track plan.

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

## License

This project is licensed under the [MIT License](./LICENSE).

## Author

Created and maintained by Firas Ben Nacib - [bennacibfiras@gmail.com](mailto:bennacibfiras@gmail.com)
