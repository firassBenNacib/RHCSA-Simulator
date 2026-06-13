Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../FileHelpers/FileHelpers.psd1')
Import-Module (Join-Path $PSScriptRoot '../Scenarios/Scenarios.psd1')
Import-Module (Join-Path $PSScriptRoot '../VMControl/VMControl.psd1')

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
'(?i)\btest\s',
'(^|[\s''"])\[\s',
'(^|[\s''"])\[\[\s',
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
'(?i)^\s*pvs(?:\s|$)',
'(?i)^\s*vgs(?:\s|$)',
'(?i)^\s*lvs(?:\s|$)',
'(?i)\brpm\s+-q\b',
'(?i)\bgrubby\s+--info\b',
'(?i)\bmatchpathcon\b',
'(?i)\bstat\s+-c\b',
'(?i)\bblkid\s+-o\s+value\b',
'(?i)\bfirewall-cmd\b[^\r\n]*--query-(port|service)\b',
'(?i)\bhostnamectl\s+--static\b',
'(?i)\bgetenforce\b',
'(?i)\bswapon\s+--noheadings\b',
'(?i)\bgetent\s+(passwd|group|hosts)\b',
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

    $tracks = @($activeRun.Tracks)
$track = if ($tracks.Count -gt 0) { [string]$tracks[0] } else { 'rhcsa9' }
$exercise = Get-LabExerciseDefinition -ScenarioId ([string]$activeRun.ScenarioId) -ProjectRoot $ProjectRoot -Track $track
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
Mode = 'lab'
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

$result = Invoke-VagrantVmShellCommandCapture -MachineName $check.Target -Command $check.Command -ProjectRoot $ProjectRoot -SkipVagrantFallback
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
Mode = 'lab'
Results = $results
}
}

function Test-ExamCheckHasShellAssignment {
param(
[string]$Command
)

return ([string]$Command -match '(^|;\s*|&&\s*|\|\|\s*)[A-Za-z_][A-Za-z0-9_]*=')
}

function Split-TopLevelAndClause {
param(
[string]$Command
)

$clauses = New-Object System.Collections.Generic.List[string]
$buffer = New-Object System.Text.StringBuilder
$inSingle = $false
$inDouble = $false
$escaped = $false
$i = 0
while ($i -lt $Command.Length) {
$ch = $Command[$i]
if ($escaped) {
[void]$buffer.Append($ch)
$escaped = $false
$i++
continue
}
if ($ch -eq '\' -and -not $inSingle) {
[void]$buffer.Append($ch)
$escaped = $true
$i++
continue
}
if ($ch -eq "'" -and -not $inDouble) {
$inSingle = -not $inSingle
[void]$buffer.Append($ch)
$i++
continue
}
if ($ch -eq '"' -and -not $inSingle) {
$inDouble = -not $inDouble
[void]$buffer.Append($ch)
$i++
continue
}
if (-not $inSingle -and -not $inDouble -and $i + 1 -lt $Command.Length -and $Command.Substring($i, 2) -eq '&&') {
$clause = $buffer.ToString().Trim()
if (-not [string]::IsNullOrWhiteSpace($clause)) {
$clauses.Add($clause)
}
[void]$buffer.Clear()
$i += 2
continue
}
[void]$buffer.Append($ch)
$i++
}

$tail = $buffer.ToString().Trim()
if (-not [string]::IsNullOrWhiteSpace($tail)) {
$clauses.Add($tail)
}
return @($clauses)
}

function Get-ShellTokenSpan {
param(
[string]$Command
)

$spans = New-Object System.Collections.Generic.List[object]
$i = 0
while ($i -lt $Command.Length) {
while ($i -lt $Command.Length -and [char]::IsWhiteSpace($Command[$i])) {
$i++
}
if ($i -ge $Command.Length) {
break
}

$start = $i
$inSingle = $false
$inDouble = $false
while ($i -lt $Command.Length) {
$ch = $Command[$i]
if ($ch -eq "'" -and -not $inDouble) {
$inSingle = -not $inSingle
$i++
continue
}
if ($ch -eq '"' -and -not $inSingle) {
$inDouble = -not $inDouble
$i++
continue
}
if ($ch -eq '\' -and -not $inSingle -and $i + 1 -lt $Command.Length) {
$i += 2
continue
}
if (-not $inSingle -and -not $inDouble -and [char]::IsWhiteSpace($Command[$i])) {
break
}
$i++
}

$spans.Add([PSCustomObject]@{
Start = $start
End = $i
Text = $Command.Substring($start, $i - $start)
})
}

return @($spans)
}

function Resolve-ExamCheckClause {
param(
[string]$Clause
)

$stripped = $Clause.Trim()
$negatePrefix = ''
if ($stripped.StartsWith('!')) {
$negatePrefix = '! '
$stripped = $stripped.Substring(1).TrimStart()
}

if (-not $stripped.StartsWith('ssh ')) {
return [PSCustomObject]@{ Target = 'client'; Command = $Clause.Trim() }
}

$spans = @(Get-ShellTokenSpan -Command $stripped)
if ($spans.Count -eq 0 -or [string]$spans[0].Text -ne 'ssh') {
return [PSCustomObject]@{ Target = 'client'; Command = $Clause.Trim() }
}

for ($index = 1; $index -lt $spans.Count; $index++) {
$token = [string]$spans[$index].Text
$normalized = $token.Trim([char[]]@("'", '"'))
if ($normalized.StartsWith('-')) {
continue
}
if (-not $normalized.Contains('server')) {
continue
}

$remoteCommand = $stripped.Substring([int]$spans[$index].End).TrimStart()
if ($remoteCommand.ToLowerInvariant().StartsWith('sudo ')) {
$remoteCommand = $remoteCommand.Substring(5).TrimStart()
}
if ([string]::IsNullOrWhiteSpace($remoteCommand)) {
return [PSCustomObject]@{ Target = 'client'; Command = $Clause.Trim() }
}
return [PSCustomObject]@{ Target = 'server'; Command = ($negatePrefix + $remoteCommand).Trim() }
}

return [PSCustomObject]@{ Target = 'client'; Command = $Clause.Trim() }
}

function Invoke-ExamCheckCapture {
param(
[Parameter(Mandatory = $true)]
[ValidateSet('client', 'server')]
[string]$Target,
[Parameter(Mandatory = $true)]
[string]$Command,
[string]$ProjectRoot = (Get-ProjectRoot)
)

return Invoke-VagrantVmShellCommandCapture -MachineName $Target -Command ("set -euo pipefail`n$Command") -ProjectRoot $ProjectRoot -SkipVagrantFallback
}

function Invoke-ExamExerciseCheck {
param(
[object]$ActiveRun,
[string]$ScenarioId,
[string]$ProjectRoot = (Get-ProjectRoot)
)

if (-not [string]::IsNullOrWhiteSpace($ScenarioId) -and [string]$ActiveRun.ScenarioId -ne $ScenarioId) {
throw "Active run is '$($ActiveRun.ScenarioId)'. Start '$ScenarioId' first or run .\RHCSA.ps1 check without -Id."
}

$tracks = @($ActiveRun.Tracks)
$track = if ($tracks.Count -gt 0) { [string]$tracks[0] } else { 'rhcsa9' }
$manifest = Get-ScenarioManifest -ScenarioId ([string]$ActiveRun.ScenarioId) -ProjectRoot $ProjectRoot -Track $track
$checks = @($manifest.Content.Exam.Checks)
if ($checks.Count -eq 0) {
return [PSCustomObject]@{
ScenarioId = [string]$ActiveRun.ScenarioId
Title = [string]$ActiveRun.Title
Mode = 'exam'
NoChecks = $true
Passed = $false
PassedCount = 0
FailedCount = 0
TotalCount = 0
Score = 0
Results = @()
}
}

$results = @()
$requiresServer = [bool]$manifest.Flags.RequiresServer
$checkTargets = @($manifest.Content.Exam.CheckTargets)
$checkIndex = 0
foreach ($command in $checks) {
$checkIndex++
$commandText = [string]$command
$explicitTarget = if ($checkIndex -le $checkTargets.Count) { [string]$checkTargets[$checkIndex - 1] } else { '' }
if ($explicitTarget -in @('client', 'server')) {
$targetCommand = $commandText
if ($explicitTarget -eq 'server') {
$resolved = Resolve-ExamCheckClause -Clause $commandText
$targetCommand = [string]$resolved.Command
}
$targetResult = Invoke-ExamCheckCapture -Target $explicitTarget -Command $targetCommand -ProjectRoot $ProjectRoot
$results += [PSCustomObject]@{
Index = $checkIndex
Target = $explicitTarget
OriginalCommand = $commandText
Command = $targetCommand
ExitCode = [int]$targetResult.ExitCode
Passed = ([int]$targetResult.ExitCode -eq 0)
StdOut = @($targetResult.StdOut)
StdErr = @($targetResult.StdErr)
}
continue
}

$clientResult = Invoke-ExamCheckCapture -Target 'client' -Command $commandText -ProjectRoot $ProjectRoot
if ([int]$clientResult.ExitCode -eq 0) {
$results += [PSCustomObject]@{
Index = $checkIndex
Target = 'client'
OriginalCommand = $commandText
Command = $commandText
ExitCode = 0
Passed = $true
StdOut = @($clientResult.StdOut)
StdErr = @($clientResult.StdErr)
}
continue
}

if (-not $requiresServer -or (Test-ExamCheckHasShellAssignment -Command $commandText)) {
$results += [PSCustomObject]@{
Index = $checkIndex
Target = 'client'
OriginalCommand = $commandText
Command = $commandText
ExitCode = [int]$clientResult.ExitCode
Passed = $false
StdOut = @($clientResult.StdOut)
StdErr = @($clientResult.StdErr)
}
continue
}

$clausePassed = $true
$failedClause = $null
foreach ($clause in @(Split-TopLevelAndClause -Command $commandText)) {
$resolved = Resolve-ExamCheckClause -Clause $clause
$candidateTargets = @([string]$resolved.Target)
if ($requiresServer -and [string]$resolved.Target -eq 'client' -and -not $clause.Trim().StartsWith('ssh ')) {
$candidateTargets += 'server'
}

$attempts = @()
$passed = $false
foreach ($candidateTarget in $candidateTargets) {
$attempt = Invoke-ExamCheckCapture -Target $candidateTarget -Command ([string]$resolved.Command) -ProjectRoot $ProjectRoot
$attempts += [PSCustomObject]@{ Target = $candidateTarget; Result = $attempt }
if ([int]$attempt.ExitCode -eq 0) {
$passed = $true
break
}
}

if (-not $passed) {
$clausePassed = $false
$failedClause = [PSCustomObject]@{
Clause = $clause
ResolvedCommand = [string]$resolved.Command
Attempts = $attempts
}
break
}
}

if ($clausePassed) {
$results += [PSCustomObject]@{
Index = $checkIndex
Target = 'client/server'
OriginalCommand = $commandText
Command = $commandText
ExitCode = 0
Passed = $true
StdOut = @()
StdErr = @()
}
}
else {
$attemptOutput = @()
foreach ($attempt in @($failedClause.Attempts)) {
$attemptResult = $attempt.Result
$attemptOutput += ("[{0}] exit {1}" -f $attempt.Target, [int]$attemptResult.ExitCode)
$attemptOutput += @($attemptResult.StdOut)
$attemptOutput += @($attemptResult.StdErr)
}
$results += [PSCustomObject]@{
Index = $checkIndex
Target = 'client/server'
OriginalCommand = $commandText
Command = [string]$failedClause.ResolvedCommand
ExitCode = 1
Passed = $false
StdOut = @()
StdErr = @($attemptOutput)
}
}
}

$passedCount = @($results | Where-Object { $_.Passed }).Count
$failedCount = @($results | Where-Object { -not $_.Passed }).Count
$score = if ($results.Count -gt 0) { [int][Math]::Round(100.0 * $passedCount / $results.Count) } else { 0 }

return [PSCustomObject]@{
ScenarioId = [string]$ActiveRun.ScenarioId
Title = [string]$ActiveRun.Title
Mode = 'exam'
NoChecks = $false
Passed = ($failedCount -eq 0)
PassedCount = $passedCount
FailedCount = $failedCount
TotalCount = @($results).Count
Score = $score
Results = $results
}
}

function Invoke-ScenarioExerciseCheck {
param(
[string]$ScenarioId,
[string]$ProjectRoot = (Get-ProjectRoot)
)

$activeRun = Get-ScenarioStatus -ProjectRoot $ProjectRoot
if ($null -eq $activeRun) {
throw 'No active run found. Start a lab or exam first with .\RHCSA.ps1 start -Id <scenario-id> -Mode <Lab|Exam>.'
}

switch ([string]$activeRun.Mode) {
'lab' { return Invoke-LabExerciseCheck -ScenarioId $ScenarioId -ProjectRoot $ProjectRoot }
'exam' { return Invoke-ExamExerciseCheck -ActiveRun $activeRun -ScenarioId $ScenarioId -ProjectRoot $ProjectRoot }
default { throw "Unsupported active run mode '$($activeRun.Mode)'." }
}
}

Export-ModuleMember -Function *
