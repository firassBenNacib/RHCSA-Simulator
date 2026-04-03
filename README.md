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
* [Go](https://go.dev/dl/) installed and on **PATH** if you want to use the TUI

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

Only one run is active at a time.

Scenario source files live under `scenarios/`.

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
