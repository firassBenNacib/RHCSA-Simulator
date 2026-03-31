# RHCSA-Lab/Exam-Simulator

An interactive PowerShell entrypoint for building, resetting, and running RHCSA v9 labs and mock exams on Vagrant and VirtualBox.

### Demo



## Table of Contents

* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Usage](#usage)
* [Commands](#commands)
* [Options](#options)
* [Credits](#credits)
* [License](#license)
* [Author](#author)

## Prerequisites

* Windows host
* PowerShell 5.1+
* [Vagrant](https://developer.hashicorp.com/vagrant/install) installed and on `PATH`
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads) installed and on `PATH`
* The bundled `rhel-9.7-x86_64-dvd.iso` present in the project root

## Installation

Clone:

```powershell
git clone <your-repo-url>
cd rhcsa_exam_vms
```

The simulator content is aligned to the official EX200V9K objective list from Red Hat's exam objectives PDF:
[Red Hat Certification Exam Objectives by Version](https://learn.redhat.com/jfvwy86652/attachments/jfvwy86652/Linux/2255/1/Red%20Hat%20Certification%20Exam%20Objectives%20by%20Version%20%281%29.pdf)

The imported objective review in this repo intentionally excludes Flatpak and RPM-management additions that you asked to keep out of scope for this simulator build.

## Usage

The project uses a fixed two-VM layout:

* `servervm` provides the offline HTTP repo, NFS exports, and time source
* `clientvm` is the main RHCSA workstation

The baseline preinstalls the RHCSA v9 toolchain broadly so labs and exams focus on execution rather than dependency setup. Scenarios are split into:

* `scenarios/labs/<id>` for focused practice labs
* `scenarios/exams/<id>` for full mock exams

Every run is reset from the `base-clean` snapshot, and each run generates one trainee-facing file under `.lab-state/runs/<run-id>/run-brief.txt`.

Lab directories now contain only `LAB_TASKS.md` and `LAB_SOLUTION.md`. Exam directories now contain only `EXAM_TASKS.md` and `EXAM_SOLUTION.md`.

### Quick start

**1) Create or refresh the clean baseline**

```powershell
.\RHCSA.ps1 baseline up
```

**2) List labs and exams**

```powershell
.\RHCSA.ps1 scenario list
```

**3) Start an objective lab**

```powershell
.\RHCSA.ps1 scenario start -Id lab-01-networking-hostname -Mode Lab
```

**4) Start a mock exam**

```powershell
.\RHCSA.ps1 scenario start -Id mock-exam-a -Mode Exam
```

**5) Check or reset the active run**

```powershell
.\RHCSA.ps1 scenario status
```

```powershell
.\RHCSA.ps1 scenario reset
```

### SSH access

Use Vagrant's SSH integration by default:

```powershell
vagrant ssh clientvm
```

```powershell
vagrant ssh servervm
```

If you need a raw `ssh` command for another client, get the generated connection details with:

```powershell
vagrant ssh-config clientvm
```

```powershell
vagrant ssh-config servervm
```

`vagrant ssh` is the safer default because it automatically uses the right port, username, and private key for the current machine state.

### Optional commands

**Destroy the entire local lab**

```powershell
.\RHCSA.ps1 baseline destroy
```

**Start the baseline without provisioning**

```powershell
.\RHCSA.ps1 baseline up -NoProvision
```

**Run a 22-question recovery-focused mock exam**

```powershell
.\RHCSA.ps1 scenario start -Id mock-exam-c -Mode Exam
```

**Regenerate scenario Markdown files after editing a manifest**

```powershell
python .\host\generate_scenario_markdown.py
```

## Commands

```text
Usage: .\RHCSA.ps1 <area> <command> [options]

Areas
  baseline    Manage the clean Vagrant baseline
  scenario    Manage RHCSA lab and exam scenarios
  help        Show help

Commands
  baseline up         Start or refresh the clean baseline
  baseline destroy    Destroy the VMs and local runtime state
  scenario list       List all labs and exams
  scenario start      Start a lab or exam run
  scenario reset      Reset the current run
  scenario status     Show the active run
```

## Options

**Global**

* No global options currently. Use `.\RHCSA.ps1 help` for the built-in command reference.

**baseline up**

* `-NoProvision`
* `-NormalStart`
* `-HeadlessClient`
* `-RealisticMode`

**scenario start**

* `-Id <scenario-id>`
* `-Mode <Lab|Exam>`

## Credits

* Red Hat exam objective mapping based on the official EX200V9K objectives PDF
* Scenario task and solution Markdown is generated from the scenario manifests
* Built on Vagrant and VirtualBox for local lab orchestration

## License

This project is licensed under the [MIT License](./LICENSE).

## Author

Created and maintained by Firas Ben Nacib - [bennacibfiras@gmail.com](mailto:bennacibfiras@gmail.com)


The scenario bank now includes additional focused labs for umask, password aging, pwquality, default ACLs, at jobs, SSH keys, shell loops, and extra full mock exams.