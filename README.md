# RHCSA Simulator

An interactive PowerShell project for running RHCSA v9 practice labs and mock exams with Vagrant, VirtualBox, SSH helpers, checks, and a terminal UI.

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
* [rhel-9.7-x86_64-dvd.iso](https://developers.redhat.com/content-gateway/file/rhel/Red_Hat_Enterprise_Linux_9.7/rhel-9.7-x86_64-dvd.iso) in the project root, downloaded from [Red Hat Developer](https://developers.redhat.com/products/rhel/download) or the Red Hat Customer Portal
* [Go](https://go.dev/dl/) installed and on **PATH** only if you want to build the TUI from source

## Installation

Clone:

```powershell
git clone <your-repo-url>
cd rhcsa_exam_vms
```

## Usage

The simulator uses two VMs:

* servervm for the offline repository, NFS exports, and time source
* clientvm as the main RHCSA workstation

Scenarios are discovered automatically from the labs and exams folders.

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
```

**3) Start a lab**

```powershell
.\RHCSA.ps1 start -Id lab-01-networking-hostname -Mode Lab
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

Download a prebuilt `rhcsa-tui` binary from GitHub Releases, place it in the simulator repository, and run it directly:

```powershell
.\rhcsa-tui.exe
```

The TUI looks for `RHCSA.ps1` starting from:

* `RHCSA_SIMULATOR_ROOT` if set
* the current working directory
* the directory that contains the TUI binary

**Built-in launcher**

```powershell
.\RHCSA.ps1 tui
```

This is the best option if you already use the PowerShell entrypoint for everything else.

**Keyboard summary**

* `Enter` start the selected lab or exam
* `Tab` move between the catalog and the detail pane
* `←` / `→` switch between Labs and Exams
* `F1` or `1` open Tasks
* `F2` or `2` open Hint for labs
* `F3` or `3` or `"` open Checks for labs
* `F4` or `4` or `'` open Solution
* `c` run checks for the active lab
* `r` reset the active run
* `/` open search
* `z` open SSH to `clientvm`
* `x` open SSH to `servervm`
* `?` open help

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
.\RHCSA.ps1 ssh-config servervm
```

**Download or rebuild the TUI**

Use GitHub Releases for prebuilt binaries, or rebuild locally with:

```powershell
go build -o rhcsa-tui.exe ./cmd/rhcsa-tui
```

The repository includes a GitHub Actions workflow at `.github/workflows/release-tui.yml` that builds and uploads Windows, Linux, and macOS TUI binaries when a GitHub Release is published.

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

**check**

* -Id <lab-id> optional, but it must match the active lab

**ssh**

* ssh [servervm|clientvm]

**ssh-config**

* ssh-config [servervm|clientvm]

## License

This project is licensed under the [MIT License](./LICENSE).

## Author

Created and maintained by Firas Ben Nacib - [bennacibfiras@gmail.com](mailto:bennacibfiras@gmail.com)
