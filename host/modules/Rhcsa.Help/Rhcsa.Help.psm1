Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../Rhcsa.Ui/Rhcsa.Ui.psd1')

function Test-HelpToken {
param(
[string]$Token
)

if ([string]::IsNullOrWhiteSpace($Token)) {
return $false
}

return ($Token.ToLowerInvariant() -in @('help', '-h', '--help', '/?'))
}

function ConvertTo-VmName {
param(
[string]$Name
)

$value = if ([string]::IsNullOrWhiteSpace($Name)) { 'client' } else { $Name.ToLowerInvariant() }
switch ($value) {
'servervm' { return 'server' }
'clientvm' { return 'client' }
'server' { return 'server' }
default { return 'client' }
}
}

function Get-RecommendedHelpCommand {
param(
[string]$Area,
[string]$Command
)

switch ("$Area/$Command") {
'baseline/up' { return '.\RHCSA.ps1 help up' }
'baseline/resume' { return '.\RHCSA.ps1 help resume' }
'baseline/pause' { return '.\RHCSA.ps1 help pause' }
'baseline/down' { return '.\RHCSA.ps1 help down' }
'baseline/destroy' { return '.\RHCSA.ps1 help destroy' }
'scenario/list' { return '.\RHCSA.ps1 help list' }
'scenario/start' { return '.\RHCSA.ps1 help start' }
'scenario/exit-run' { return '.\RHCSA.ps1 help exit-run' }
'scenario/check' { return '.\RHCSA.ps1 help check' }
'baseline/repo' { return '.\RHCSA.ps1 help repo' }
'scenario/reset' { return '.\RHCSA.ps1 help reset' }
'dashboard/status' { return '.\RHCSA.ps1 help status' }
'vm/status' { return '.\RHCSA.ps1 help vms' }
'vm/ssh' { return '.\RHCSA.ps1 help ssh' }
'vm/ssh-config' { return '.\RHCSA.ps1 help ssh-config' }
'app/tui' { return '.\RHCSA.ps1 help tui' }
'config/profile' { return '.\RHCSA.ps1 help profile' }
'config/timer' { return '.\RHCSA.ps1 help timer' }
'completion/manage' { return '.\RHCSA.ps1 help completion' }
default { return '.\RHCSA.ps1 help' }
}
}

function Format-ErrorOutput {
param(
[string]$Message
)

return @('{0} {1}' -f (Format-StyledText -Text 'Error:' -StyleName 'Warning'), $Message)
}

function Format-HelpUsageLine {
param(
[string]$CommandText
)

return 'Usage: {0}' -f (Format-StyledText -Text $CommandText -StyleName 'Command')
}

function Format-HelpEntryList {
param(
[object[]]$Entry
)

$nameWidth = Get-MaxCellWidth -Value ($Entry | ForEach-Object { $_.Name }) -Minimum 4
$lines = @()
foreach ($item in @($Entry)) {
$lines += (' {0} {1}' -f (Format-PaddedCell -Text $item.Name -Width $nameWidth -StyleName 'Accent'), $item.Description)
}

return $lines
}

function Get-HelpOutput {
param(
[ValidateSet('general', 'up', 'resume', 'pause', 'down', 'destroy', 'list', 'start', 'exit-run', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'profile', 'timer', 'completion')]
[string]$Scope = 'general'
)

switch ($Scope) {
'up' {
return @(
(Get-UiHeading -Text 'up'),
(Format-StyledText -Text 'Build the clean baseline, or report that the simulator is already running.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 up [-Profile RHCSA9|RHCSA10] [-Refresh] [-NoProvision] [-NormalStart] [-HeadlessClient] [-RealisticMode] [-ForceHostCleanup]'),
'',
'Options:',
' -Profile Persist the project baseline profile before startup',
' -Refresh Re-run baseline provisioning even when the simulator is already running',
' -NoProvision Start both VMs without guest provisioning',
' -NormalStart Compatibility switch; normal behavior is already the default',
' -HeadlessClient Compatibility switch for older workflows',
' -RealisticMode Compatibility switch for older workflows',
' -ForceHostCleanup Kill global Vagrant/VirtualBox lock holders as a last resort',
'',
'Examples:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 up'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 up -NoProvision')
)
}
'resume' {
return @(
(Get-UiHeading -Text 'resume'),
(Format-StyledText -Text 'Resume paused or powered-off simulator VMs without rebuilding the baseline.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 resume'),
'',
'Example:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 resume')
)
}
'pause' {
return @(
(Get-UiHeading -Text 'pause'),
(Format-StyledText -Text 'Save the simulator VM states for a fast later resume.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 pause'),
'',
'Example:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 pause')
)
}
'down' {
return @(
(Get-UiHeading -Text 'down'),
(Format-StyledText -Text 'Power off the simulator VMs without destroying the baseline or local state.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 down'),
'',
'Example:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 down')
)
}
'destroy' {
return @(
(Get-UiHeading -Text 'destroy'),
(Format-StyledText -Text 'Destroy both VMs and clean local simulator state.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 destroy [-ForceHostCleanup]'),
'',
'Options:',
' -ForceHostCleanup Kill global Vagrant/VirtualBox lock holders as a last resort',
'',
'Example:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 destroy')
)
}
'list' {
return @(
(Get-UiHeading -Text 'list'),
(Format-StyledText -Text 'List available labs and mock exams.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 list [labs|exams] [-Track Auto|RHCSA9|RHCSA10|All]'),
'',
'Examples:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 list'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 list labs'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 list exams'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 profile RHCSA10'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 list -Track All')
)
}
'start' {
return @(
(Get-UiHeading -Text 'start'),
(Format-StyledText -Text 'Start a lab or exam run.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 start -Id <scenario-id> -Mode <Lab|Exam> [-Track Auto|RHCSA9|RHCSA10|All]'),
'',
'Options:',
' -Id Scenario id to start',
' -Mode Lab or Exam',
' -Track Scenario track, default project profile',
'',
'Examples:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 start -Id lab-01-networking-hostname -Mode Lab'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 start -Id mock-exam-a -Mode Exam')
)
}
'exit-run' {
return @(
(Get-UiHeading -Text 'exit-run'),
(Format-StyledText -Text 'Exit the active lab/exam context without resetting VMs or undoing learner changes.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 exit-run'),
'',
'Example:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 exit-run')
)
}
'check' {
return @(
(Get-UiHeading -Text 'check'),
(Format-StyledText -Text 'Run the automated checks for the active lab or exam.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 check [-Id <scenario-id>]'),
'',
'Example:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 check')
)
}
'repo' {
return @(
(Get-UiHeading -Text 'repo'),
(Format-StyledText -Text 'Run the offline package repository self-test on server and client.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 repo'),
'',
'Example:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 repo')
)
}
'reset' {
return @(
(Get-UiHeading -Text 'reset'),
(Format-StyledText -Text 'Reset the active run back to the clean baseline and reapply its overlay.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 reset'),
'',
'Example:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 reset')
)
}
'status' {
return @(
(Get-UiHeading -Text 'status'),
(Format-StyledText -Text 'Show baseline, VM state, and the active scenario.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 status')
)
}
'vms' {
return @(
(Get-UiHeading -Text 'vms'),
(Format-StyledText -Text 'Show VM state for server and client.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 vms')
)
}
'ssh' {
return @(
(Get-UiHeading -Text 'ssh'),
(Format-StyledText -Text 'Open an SSH session for the active lab or exam. Defaults to client.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 ssh [server|client]'),
'',
(Format-StyledText -Text 'On Windows this opens a dedicated PowerShell window for the session.' -StyleName 'Muted'),
'',
'Examples:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 ssh'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 ssh server')
)
}
'ssh-config' {
return @(
(Get-UiHeading -Text 'ssh-config'),
(Format-StyledText -Text 'Print SSH config for external SSH clients. Defaults to client.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 ssh-config [server|client]'),
'',
'Examples:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 ssh-config'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 ssh-config server')
)
}
'tui' {
return @(
(Get-UiHeading -Text 'tui'),
(Format-StyledText -Text 'Open the labs-first interactive terminal UI.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 tui [-Track Auto|RHCSA9|RHCSA10|All]'),
'',
'Example:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 tui'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 tui -Track RHCSA10')
)
}
'profile' {
return @(
(Get-UiHeading -Text 'profile'),
(Format-StyledText -Text 'Show or change the project RHCSA version.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 profile [RHCSA9|RHCSA10]'),
'',
'Examples:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 profile'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 profile RHCSA10'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 up -Profile RHCSA9')
)
}
'timer' {
return @(
(Get-UiHeading -Text 'timer'),
(Format-StyledText -Text 'Show or change the default TUI timer behavior for new runs.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 timer [on|off|status]'),
'',
'Examples:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 timer status'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 timer on'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 timer off')
)
}
'completion' {
return @(
(Get-UiHeading -Text 'completion'),
(Format-StyledText -Text 'Generate or install PowerShell tab completion for commands, lab ids, modes, and VM names.' -StyleName 'Muted'),
(Format-HelpUsageLine -CommandText '.\RHCSA.ps1 completion <powershell|install>'),
'',
'Examples:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 completion powershell'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 completion install')
)
}
default {
$entry = @(
[PSCustomObject]@{ Name = 'up'; Description = 'Start or verify the clean baseline' }
[PSCustomObject]@{ Name = 'resume'; Description = 'Resume paused or powered-off VMs' }
[PSCustomObject]@{ Name = 'pause'; Description = 'Save VM state for fast resume' }
[PSCustomObject]@{ Name = 'down'; Description = 'Power off the simulator VMs' }
[PSCustomObject]@{ Name = 'destroy'; Description = 'Destroy VMs and local simulator state' }
[PSCustomObject]@{ Name = 'list'; Description = 'List labs and mock exams' }
[PSCustomObject]@{ Name = 'start'; Description = 'Start a lab or exam run' }
[PSCustomObject]@{ Name = 'exit-run'; Description = 'Exit the active lab or exam context' }
[PSCustomObject]@{ Name = 'check'; Description = 'Run checks for the active lab or exam' }
[PSCustomObject]@{ Name = 'repo'; Description = 'Run the offline repo self-test' }
[PSCustomObject]@{ Name = 'reset'; Description = 'Reset the active run' }
[PSCustomObject]@{ Name = 'status'; Description = 'Show baseline, VMs, and active scenario' }
[PSCustomObject]@{ Name = 'vms'; Description = 'Show VM state' }
[PSCustomObject]@{ Name = 'ssh'; Description = 'Open SSH for the active run' }
[PSCustomObject]@{ Name = 'ssh-config'; Description = 'Print SSH config for external clients' }
[PSCustomObject]@{ Name = 'tui'; Description = 'Open the interactive TUI' }
[PSCustomObject]@{ Name = 'profile'; Description = 'Show or change the project version' }
[PSCustomObject]@{ Name = 'timer'; Description = 'Show or change the default timer mode' }
[PSCustomObject]@{ Name = 'completion'; Description = 'Generate or install PowerShell completion' }
)
return @(
(Get-UiHeading -Text 'RHCSA Simulator'),
(Format-StyledText -Text 'Usage: .\RHCSA.ps1 <command> [args]' -StyleName 'Muted'),
'',
'Commands:',
(Format-HelpEntryList -Entry $entry),
'',
(Format-StyledText -Text 'Help: .\RHCSA.ps1 help <command>' -StyleName 'Muted'),
'',
'Examples:',
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 up'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 pause'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 down'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 list labs'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 start -Id lab-01-networking-hostname -Mode Lab'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 ssh'),
(Format-UiCommandLine -CommandText '.\RHCSA.ps1 tui')
)
}
}
}

Export-ModuleMember -Function *
