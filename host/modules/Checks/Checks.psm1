Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../FileHelpers/FileHelpers.psd1') -Force
Import-Module (Join-Path $PSScriptRoot '../Scenarios/Scenarios.psd1') -Force
Import-Module (Join-Path $PSScriptRoot '../VMControl/VMControl.psd1') -Force

function Test-IsAssertiveExerciseCheck {
param(
[string]$Command
)

if ([string]::IsNullOrWhiteSpace($Command)) {
return $false
}

$trimmed = $Command.Trim()
$assertivePatterns = @(
'(?i)\bgrep\b[^\r\n]*\s-[A-Za-z]*q[A-Za-z]*(?:\s|$)',
'(?i)\bgrep\b[^\r\n]*\s-[A-Za-z]*E[A-Za-z]*(?:\s|$)',
'(?i)\bgrep\b[^\r\n]*\s-[A-Za-z]*F[A-Za-z]*(?:\s|$)',
'(?i)\bgrep\b[^\r\n]*\s-[A-Za-z]*x[A-Za-z]*(?:\s|$)',
'(^|\s)test\s ',
'(^|\s)\[\s ',
'(^|\s)\[\[\s ',
'(^|\s)!\s',
'(?i)\bdiff\s',
'(?i)\bcmp\s',
'(?i)\bawk\b.*\bexit\b',
'(?i)\bid\s+\S+',
'(?i)\bvisudo\s+-cf\b',
'(?i)\bsystemctl\s+is-enabled\b',
'(?i)\bsystemctl\s+is-active\b',
'(?i)\bmountpoint\s+-q\b',
'(?i)\bfindmnt\b',
'(?i)\bpodman\s+image\s+exists\b',
'(?i)\bpodman\s+ps\b[^\r\n]*--format\b',
'(?i)\brpm\s+-q\b',
'(?i)\bgrubby\s+--info\b',
'(?i)\bmatchpathcon\b',
'(?i)\bstat\s+-c\b',
'(?i)\bblkid\s+-o\s+value\b',
'(?i)\bfirewall-cmd\b[^\r\n]*--query-(port|service)\b',
'(?i)\bhostnamectl\s+--static\b',
'(?i)\bgetenforce\b',
'(?i)\bswapon\s+--noheadings\b',
'(?i)\bgetent\s+passwd\b',
'(?i)\bgetent\s+hosts\b',
'(?i)\bchage\s+-l\b',
'(?i)\bcrontab\s+-l\b',
'(?i)\batq\b',
'(?i)\bsemanage\s+port\s+-l\b',
'(?i)\bcurl\b[^\r\n]*\s-f(?:[sS]*)(?:\s|$)',
'(?i)\bssh\b[^\r\n]*\bBatchMode=yes\b'
)

foreach ($pattern in $assertivePatterns) {
if ($trimmed -match $pattern) {
return $true
}
}

return $false
}

function Invoke-LabExerciseCheck {
param(
[string]$ScenarioId,
[string]$ProjectRoot = (Get-ProjectRoot)
)

$activeRun = Get-ScenarioStatus -ProjectRoot $ProjectRoot
if ($null -eq $activeRun) {
throw 'No active lab run found. Start a lab first with .\RHCSA.ps1 start -Id <lab-id> -Mode Lab.'
}

if ([string]$activeRun.Mode -ne 'lab') {
throw 'Automated check is available for labs only right now.'
}

if (-not [string]::IsNullOrWhiteSpace($ScenarioId) -and [string]$activeRun.ScenarioId -ne $ScenarioId) {
throw "Active run is '$($activeRun.ScenarioId)'. Start '$ScenarioId' first or run .\RHCSA.ps1 check without -Id."
}

$exercise = Get-LabExerciseDefinition -ScenarioId ([string]$activeRun.ScenarioId) -ProjectRoot $ProjectRoot
$checks = @($exercise.Checks)
if ($checks.Count -eq 0) {
return [PSCustomObject]@{
ScenarioId = [string]$activeRun.ScenarioId
Title = [string]$activeRun.Title
Exercise = $exercise
NoChecks = $true
Passed = $false
PassedCount = 0
FailedCount = 0
TotalCount = 0
Results = @()
}
}

$results = @()
foreach ($check in $checks) {
if (-not (Test-IsAssertiveExerciseCheck -Command $check.Command)) {
$results += [PSCustomObject]@{
Index = [int]$check.Index
Target = [string]$check.Target
OriginalCommand = [string]$check.OriginalCommand
Command = [string]$check.Command
ExitCode = 125
Passed = $false
StdOut = @()
StdErr = @('Weak automated check in scenario metadata. Replace display-style commands with assertive commands that return non-zero when the task is incomplete.')
}
continue
}

$result = Invoke-VagrantVmShellCommandCapture -MachineName $check.Target -Command $check.Command -ProjectRoot $ProjectRoot
$results += [PSCustomObject]@{
Index = [int]$check.Index
Target = [string]$check.Target
OriginalCommand = [string]$check.OriginalCommand
Command = [string]$check.Command
ExitCode = [int]$result.ExitCode
Passed = ([int]$result.ExitCode -eq 0)
StdOut = @($result.StdOut)
StdErr = @($result.StdErr)
}
}

$passedCount = @($results | Where-Object { $_.Passed }).Count
$failedCount = @($results | Where-Object { -not $_.Passed }).Count

return [PSCustomObject]@{
ScenarioId = [string]$activeRun.ScenarioId
Title = [string]$activeRun.Title
Exercise = $exercise
NoChecks = $false
Passed = ($failedCount -eq 0)
PassedCount = $passedCount
FailedCount = $failedCount
TotalCount = @($results).Count
Results = $results
}
}

Export-ModuleMember -Function *
