Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../FileHelpers/FileHelpers.psd1')
Import-Module (Join-Path $PSScriptRoot '../UI/UI.psd1')

function Get-ProjectRelativePath {
param(
[Parameter(Mandatory = $true)]
[string]$Path,
[string]$ProjectRoot = (Get-ProjectRoot)
)

$fullPath = [System.IO.Path]::GetFullPath($Path)
$fullRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$rootWithSeparator = $fullRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar

if (-not $fullPath.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
throw "Path '$fullPath' is outside project root '$fullRoot'."
}

return $fullPath.Substring($rootWithSeparator.Length).Replace('\', '/')
}

function Resolve-ProjectPath {
param(
[Parameter(Mandatory = $true)]
[string]$BasePath,
[Parameter(Mandatory = $true)]
[string]$RelativeOrAbsolutePath
)

if ([string]::IsNullOrWhiteSpace($RelativeOrAbsolutePath)) {
return $null
}

if ([System.IO.Path]::IsPathRooted($RelativeOrAbsolutePath)) {
return $RelativeOrAbsolutePath
}

return (Join-Path $BasePath $RelativeOrAbsolutePath)
}

function Get-RequiredProperty {
param(
[Parameter(Mandatory = $true)]
[object]$Object,
[Parameter(Mandatory = $true)]
[string]$Name,
[switch]$AllowZero
)

$property = $Object.PSObject.Properties[$Name]
if ($null -eq $property) {
throw "Missing required property '$Name'."
}

$value = $property.Value
if (-not $AllowZero -and ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)))) {
throw "Property '$Name' must not be empty."
}

return $value
}

function Get-OptionalPropertyValue {
param(
[Parameter(Mandatory = $true)]
[object]$Object,
[Parameter(Mandatory = $true)]
[string]$Name
)

$property = $Object.PSObject.Properties[$Name]
if ($null -eq $property) {
return $null
}

return $property.Value
}

function Get-StringArray {
param(
[AllowNull()]
[object]$Value = $null,
[Parameter(Mandatory = $true)]
[string]$Label,
[switch]$AllowEmpty
)

$items = @()
foreach ($item in @($Value)) {
if ($null -eq $item) {
continue
}

$trimmed = ([string]$item).Trim()
if ($trimmed.Length -eq 0) {
continue
}

$items += $trimmed
}

if (-not $AllowEmpty -and $items.Count -eq 0) {
throw "$Label must contain at least one entry."
}

return ,$items
}

function Get-IntegerArray {
param(
[AllowNull()]
[object]$Value = $null,
[Parameter(Mandatory = $true)]
[string]$Label,
[switch]$AllowEmpty
)

$items = @()
foreach ($item in @($Value)) {
if ($null -eq $item -or [string]::IsNullOrWhiteSpace([string]$item)) {
continue
}

$number = [int]$item
if ($number -le 0) {
throw "$Label entries must be positive integers."
}

$items += $number
}

if (-not $AllowEmpty -and $items.Count -eq 0) {
throw "$Label must contain at least one entry."
}

return ,$items
}

function Get-StringMatrix {
param(
[AllowNull()]
[object]$Value = $null,
[Parameter(Mandatory = $true)]
[string]$Label,
[switch]$AllowEmpty
)

$rows = @()
$rowIndex = 0
$sourceRows = @($Value)
$hasNestedRows = $false

foreach ($row in $sourceRows) {
if ($null -eq $row) {
continue
}

if ($row -isnot [string] -and $row -is [System.Collections.IEnumerable]) {
$hasNestedRows = $true
break
}
}

if (-not $hasNestedRows) {
$sourceRows = ,$sourceRows
}

foreach ($row in $sourceRows) {
$rowIndex++
$rows += ,(Get-StringArray -Value $row -Label ("{0}[{1}]" -f $Label, $rowIndex) -AllowEmpty:$AllowEmpty)
}

if (-not $AllowEmpty -and $rows.Count -eq 0) {
throw "$Label must contain at least one entry."
}

return ,$rows
}

function Format-NumberedSection {
param(
[string]$Title,
[string[]]$Items
)

$lines = @($Title)
if ($Items.Count -eq 0) {
return @($lines + 'None')
}

for ($index = 0; $index -lt $Items.Count; $index++) {
$lines += ('{0}. {1}' -f ($index + 1), $Items[$index])
}

return $lines
}

function Format-BulletedSection {
param(
[string]$Title,
[string[]]$Items
)

$lines = @($Title)
if ($Items.Count -eq 0) {
return @($lines + 'None')
}

foreach ($item in $Items) {
$lines += ('- {0}' -f $item)
}

return $lines
}

function Format-RunBriefText {
param(
[Parameter(Mandatory = $true)]
[object]$Manifest,
[Parameter(Mandatory = $true)]
[ValidateSet('lab', 'exam')]
[string]$Mode,
[Parameter(Mandatory = $true)]
[datetime]$StartedAt,
[Parameter(Mandatory = $true)]
[datetime]$EndsAt
)

$systems = if ($Manifest.Flags.RequiresServer) { 'client and server' } else { 'client' }
$lines = @(
'RHCSA v9 Simulator Run Brief',
('Scenario: {0}' -f $Manifest.Id),
('Category: {0}' -f $Manifest.Category),
('Title: {0}' -f $Manifest.Title),
('Mode: {0}' -f $Mode),
('Objectives: {0}' -f ($Manifest.ObjectiveTags -join ', ')),
('Started: {0}' -f $StartedAt.ToString('yyyy-MM-dd HH:mm:ss')),
('Ends: {0}' -f $EndsAt.ToString('yyyy-MM-dd HH:mm:ss')),
('Systems: {0}' -f $systems),
'',
$Manifest.Description,
''
)

if ($Mode -eq 'lab') {
$lines += Format-NumberedSection -Title 'Tasks' -Items $Manifest.Content.Lab.Tasks
$lines += ''
$lines += Format-BulletedSection -Title 'Hints' -Items $Manifest.Content.Lab.Hints
$lines += ''
$lines += Format-BulletedSection -Title 'Checks' -Items $Manifest.Content.Lab.Checks
$lines += ''
$lines += Format-BulletedSection -Title 'Solution Outline' -Items $Manifest.Content.Lab.SolutionOutline
}
else {
$lines += Format-NumberedSection -Title 'Tasks' -Items $Manifest.Content.Exam.Tasks
}

return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

function Export-RunArtifact {
param(
[Parameter(Mandatory = $true)]
[object]$Manifest,
[Parameter(Mandatory = $true)]
[ValidateSet('lab', 'exam')]
[string]$Mode,
[Parameter(Mandatory = $true)]
[datetime]$StartedAt,
[Parameter(Mandatory = $true)]
[datetime]$EndsAt,
[string]$ProjectRoot = (Get-ProjectRoot)
)

$stateRoot = Initialize-LabStateLayout -ProjectRoot $ProjectRoot
$runId = '{0}-{1}' -f $Manifest.Id, (Get-Date -Format 'yyyyMMdd-HHmmss')
$runRoot = Join-Path (Join-Path $stateRoot 'runs') $runId

if (Test-Path $runRoot) {
Remove-Item -Path $runRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $runRoot | Out-Null

$briefPath = Join-Path $runRoot 'run-brief.txt'
Set-Utf8NoBomFile -Path $briefPath -Content (Format-RunBriefText -Manifest $Manifest -Mode $Mode -StartedAt $StartedAt -EndsAt $EndsAt)

return [PSCustomObject]@{
RunId = $runId
RunRoot = $runRoot
RunRootRelative = (Get-ProjectRelativePath -Path $runRoot -ProjectRoot $ProjectRoot)
GeneratedArtifact = [PSCustomObject]@{
RunBrief = (Get-ProjectRelativePath -Path $briefPath -ProjectRoot $ProjectRoot)
}
}
}

function Export-ActiveRunState {
param(
[Parameter(Mandatory = $true)]
[object]$Manifest,
[Parameter(Mandatory = $true)]
[ValidateSet('lab', 'exam')]
[string]$Mode,
[Parameter(Mandatory = $true)]
[object]$RunArtifact,
[Parameter(Mandatory = $true)]
[datetime]$StartedAt,
[Parameter(Mandatory = $true)]
[datetime]$EndsAt,
[string]$ProjectRoot = (Get-ProjectRoot)
)

$state = [ordered]@{
run_id = $RunArtifact.RunId
status = 'active'
mode = $Mode
started_at = $StartedAt.ToString('o')
ends_at = $EndsAt.ToString('o')
artifact_root = $RunArtifact.RunRootRelative
generated_artifacts = [ordered]@{
run_brief = $RunArtifact.GeneratedArtifact.RunBrief
}
scenario = [ordered]@{
id = $Manifest.Id
category = $Manifest.Category
title = $Manifest.Title
description = $Manifest.Description
objective_tags = @($Manifest.ObjectiveTags)
supported_modes = @($Manifest.SupportedModes)
tracks = @($Manifest.Tracks)
rhel_major = [int]$Manifest.RHELMajor
time_limit_minutes = $Manifest.TimeLimitMinutes
scenario_root = $Manifest.RelativeScenarioRoot
manifest_path = $Manifest.RelativeManifestPath
vm_scripts = [ordered]@{
server = $Manifest.VmScripts.ServerRelative
client = $Manifest.VmScripts.ClientRelative
}
docs = [ordered]@{
lab_tasks = $Manifest.Docs.LabTasksRelative
lab_solution = $Manifest.Docs.LabSolutionRelative
exam_tasks = $Manifest.Docs.ExamTasksRelative
exam_solution = $Manifest.Docs.ExamSolutionRelative
}
flags = [ordered]@{
password_recovery = $Manifest.Flags.PasswordRecovery
requires_server = $Manifest.Flags.RequiresServer
}
}
}

$activeRunPath = Get-ActiveRunPath -ProjectRoot $ProjectRoot
Set-Utf8NoBomFile -Path $activeRunPath -Content ($state | ConvertTo-Json -Depth 10)
return $activeRunPath
}

function Export-BaseSnapshotState {
param(
[Parameter(Mandatory = $true)]
[hashtable]$MachineIdMap,
[ValidateSet('poweroff', 'saved')]
[string]$SnapshotMode = 'poweroff',
[string]$ProjectRoot = (Get-ProjectRoot)
)

$state = [ordered]@{
profile = Get-ProjectProfile -ProjectRoot $ProjectRoot
snapshot_name = 'base-clean'
snapshot_mode = $SnapshotMode
created_at = (Get-Date).ToString('o')
machines = [ordered]@{}
}

foreach ($machineName in $MachineIdMap.Keys) {
$state.machines[$machineName] = [ordered]@{
vm_id = $MachineIdMap[$machineName]
}
}

$statePath = Get-BaseSnapshotStatePath -ProjectRoot $ProjectRoot
Set-Utf8NoBomFile -Path $statePath -Content ($state | ConvertTo-Json -Depth 10)
return $statePath
}

function Get-BaseSnapshotState {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

$statePath = Get-BaseSnapshotStatePath -ProjectRoot $ProjectRoot
if (-not (Test-Path $statePath -PathType Leaf)) {
return $null
}

$rawState = Get-Content $statePath -Raw
if ($rawState.Length -gt 0 -and [int][char]$rawState[0] -eq 0xFEFF) {
$rawState = $rawState.Substring(1)
}

return $rawState | ConvertFrom-Json
}

function Clear-ActiveRunState {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

$activeRunPath = Get-ActiveRunPath -ProjectRoot $ProjectRoot
if (Test-Path $activeRunPath -PathType Leaf) {
Remove-Item -Path $activeRunPath -Force
}
}

function Get-ActiveRunState {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

$activeRunPath = Get-ActiveRunPath -ProjectRoot $ProjectRoot
if (-not (Test-Path $activeRunPath -PathType Leaf)) {
return $null
}

$rawState = Get-Content $activeRunPath -Raw
if ($rawState.Length -gt 0 -and [int][char]$rawState[0] -eq 0xFEFF) {
$rawState = $rawState.Substring(1)
}

return $rawState | ConvertFrom-Json
}

function Stop-ExternalProcessTree {
[CmdletBinding(SupportsShouldProcess)]
param(
[Parameter(Mandatory = $true)]
[int]$ProcessId
)

if (-not $PSCmdlet.ShouldProcess($ProcessId, 'Terminate process tree')) {
return
}

Stop-ExternalProcessDescendants -RootProcessId $ProcessId
Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
}

function Get-ExternalProcessDescendants {
param(
[Parameter(Mandatory = $true)]
[int]$RootProcessId
)

$processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
if ($processes.Count -eq 0) {
return @()
}

$seen = New-Object 'System.Collections.Generic.HashSet[int]'
$pending = New-Object 'System.Collections.Generic.Queue[int]'
$descendants = @()

[void]$seen.Add($RootProcessId)
$pending.Enqueue($RootProcessId)

while ($pending.Count -gt 0) {
$parentId = $pending.Dequeue()
foreach ($process in $processes) {
if ([int]$process.ParentProcessId -ne $parentId) {
continue
}

$processId = [int]$process.ProcessId
if (-not $seen.Add($processId)) {
continue
}

$descendants += $process
$pending.Enqueue($processId)
}
}

return @($descendants)
}

function Stop-ExternalProcessDescendants {
[CmdletBinding(SupportsShouldProcess)]
param(
[Parameter(Mandatory = $true)]
[int]$RootProcessId
)

if (-not $PSCmdlet.ShouldProcess($RootProcessId, 'Terminate descendant process tree')) {
return
}

$descendants = @(Get-ExternalProcessDescendants -RootProcessId $RootProcessId | Where-Object { Test-ExternalProcessTreeWaitTarget -Process $_ } | Sort-Object ProcessId -Descending)
foreach ($process in $descendants) {
Stop-Process -Id ([int]$process.ProcessId) -Force -ErrorAction SilentlyContinue
}
}

function Test-ExternalProcessTreeWaitTarget {
param(
[Parameter(Mandatory = $true)]
[object]$Process
)

$name = [string]$Process.Name
return $name -notin @('VBoxHeadless.exe', 'VirtualBoxVM.exe', 'VBoxSVC.exe')
}

function Wait-ExternalProcessTreeExit {
param(
[Parameter(Mandatory = $true)]
[int]$RootProcessId,
[int]$TimeoutSeconds = 0
)

$deadline = if ($TimeoutSeconds -gt 0) { (Get-Date).AddSeconds($TimeoutSeconds) } else { $null }
do {
$descendants = @(Get-ExternalProcessDescendants -RootProcessId $RootProcessId | Where-Object { Test-ExternalProcessTreeWaitTarget -Process $_ })
if ($descendants.Count -eq 0) {
return $true
}

Start-Sleep -Milliseconds 500
} while ($null -eq $deadline -or (Get-Date) -lt $deadline)

return $false
}

function ConvertTo-NativeProcessArgument {
param(
[AllowNull()]
[string]$Value
)

if ($null -eq $Value) {
return '""'
}

$text = [string]$Value
if ($text.Length -eq 0) {
return '""'
}

if ($text -notmatch '[\s"]') {
return $text
}

$escaped = $text -replace '(\\*)"', '$1$1\"'
$escaped = $escaped -replace '(\\+)$', '$1$1'
return '"' + $escaped + '"'
}

function ConvertTo-NativeProcessArgumentLine {
param(
[string[]]$ArgumentList = @()
)

return (@($ArgumentList | ForEach-Object { ConvertTo-NativeProcessArgument -Value $_ }) -join ' ')
}

function Wait-NativeProcessExit {
param(
[Parameter(Mandatory = $true)]
[System.Diagnostics.Process]$Process,
[int]$TimeoutSeconds = 0
)

$deadline = if ($TimeoutSeconds -gt 0) { (Get-Date).AddSeconds($TimeoutSeconds) } else { $null }
$heartbeat = Get-Command -Name 'Write-WorkflowProgressHeartbeat' -ErrorAction SilentlyContinue
do {
try {
$Process.Refresh()
if ($Process.HasExited) {
return $true
}
}
catch {
return $true
}

if ($heartbeat) {
    & $heartbeat | Out-Null
}

Start-Sleep -Milliseconds 250
} while ($null -eq $deadline -or (Get-Date) -lt $deadline)

return $false
}

function Invoke-ExternalCapture {
param(
[Parameter(Mandatory = $true)]
[string]$FilePath,
[string[]]$ArgumentList = @(),
[int]$TimeoutSeconds = 0,
[switch]$WaitForProcessTree
)

$stdoutPath = [System.IO.Path]::GetTempFileName()
$stderrPath = [System.IO.Path]::GetTempFileName()
$startedAt = Get-Date

try {
$process = Start-Process `
-FilePath $FilePath `
-ArgumentList (ConvertTo-NativeProcessArgumentLine -ArgumentList $ArgumentList) `
-NoNewWindow `
-PassThru `
-RedirectStandardOutput $stdoutPath `
-RedirectStandardError $stderrPath

$timedOut = $false
if (-not (Wait-NativeProcessExit -Process $process -TimeoutSeconds $TimeoutSeconds)) {
$timedOut = $true
Stop-ExternalProcessTree -ProcessId $process.Id
}

$treeTimedOut = $false
if (-not $timedOut -and $WaitForProcessTree) {
    $remainingSeconds = if ($TimeoutSeconds -gt 0) {
        [Math]::Max([int]($TimeoutSeconds - ((Get-Date) - $startedAt).TotalSeconds), 1)
    }
    else {
        0
    }

    $treeExited = Wait-ExternalProcessTreeExit -RootProcessId $process.Id -TimeoutSeconds $remainingSeconds
    if (-not $treeExited) {
        $treeTimedOut = $true
        Stop-ExternalProcessDescendants -RootProcessId $process.Id
    }
}

$process.Refresh()
$stdOut = @(Get-Content $stdoutPath -ErrorAction SilentlyContinue)
$stdErr = @(Get-Content $stderrPath -ErrorAction SilentlyContinue)
if ($timedOut) {
$stdErr += "Command timed out after $TimeoutSeconds seconds."
}
elseif ($treeTimedOut) {
$stdErr += "Command timed out waiting for spawned child processes after $TimeoutSeconds seconds."
}

return [PSCustomObject]@{
ExitCode = if ($timedOut -or $treeTimedOut) { 124 } else { if ($null -eq $process.ExitCode) { 0 } else { $process.ExitCode } }
StdOut = $stdOut
StdErr = $stdErr
}
}
finally {
Remove-Item -Path $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
}
}

function Invoke-ExternalCommand {
param(
[Parameter(Mandatory = $true)]
[string]$FilePath,
[string[]]$ArgumentList = @(),
[string]$FailureMessage = 'Command failed.',
[switch]$IgnoreExitCode,
[switch]$PassThruExitCode,
[switch]$SuppressOutput,
[int]$TimeoutSeconds = 0,
[switch]$WaitForProcessTree
)

$stdoutPath = [System.IO.Path]::GetTempFileName()
$stderrPath = [System.IO.Path]::GetTempFileName()
$startedAt = Get-Date

$stdOut = @()
$stdErr = @()

try {
$process = Start-Process `
-FilePath $FilePath `
-ArgumentList (ConvertTo-NativeProcessArgumentLine -ArgumentList $ArgumentList) `
-NoNewWindow `
-PassThru `
-RedirectStandardOutput $stdoutPath `
-RedirectStandardError $stderrPath

$timedOut = $false
if (-not (Wait-NativeProcessExit -Process $process -TimeoutSeconds $TimeoutSeconds)) {
$timedOut = $true
Stop-ExternalProcessTree -ProcessId $process.Id
}

$treeTimedOut = $false
if (-not $timedOut -and $WaitForProcessTree) {
    $remainingSeconds = if ($TimeoutSeconds -gt 0) {
        [Math]::Max([int]($TimeoutSeconds - ((Get-Date) - $startedAt).TotalSeconds), 1)
    }
    else {
        0
    }

    $treeExited = Wait-ExternalProcessTreeExit -RootProcessId $process.Id -TimeoutSeconds $remainingSeconds
    if (-not $treeExited) {
        $treeTimedOut = $true
        Stop-ExternalProcessDescendants -RootProcessId $process.Id
    }
}

$process.Refresh()
$exitCode = if ($timedOut -or $treeTimedOut) { 124 } else { if ($null -eq $process.ExitCode) { 0 } else { $process.ExitCode } }

$stdOut = @(Get-Content $stdoutPath -ErrorAction SilentlyContinue)
$stdErr = @(Get-Content $stderrPath -ErrorAction SilentlyContinue)
if ($timedOut) {
$stdErr += "Command timed out after $TimeoutSeconds seconds."
}
elseif ($treeTimedOut) {
$stdErr += "Command timed out waiting for spawned child processes after $TimeoutSeconds seconds."
}
}
finally {
Remove-Item -Path $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
}

if (-not $SuppressOutput -and $exitCode -ne 0) {
Write-FailureTranscript -StdOut $stdOut -StdErr $stdErr | Out-Null
}

if (-not $IgnoreExitCode -and $exitCode -ne 0) {
$commandText = @($FilePath) + $ArgumentList
throw "$FailureMessage Command: $($commandText -join ' ') Exit code: $exitCode"
}

if ($PassThruExitCode) {
return $exitCode
}
}

function Test-TransientVagrantFailure {
param(
[string[]]$StdOut = @(),
[string[]]$StdErr = @()
)

$combinedOutput = ((@($StdOut) + @($StdErr)) -join "`n")
if ([string]::IsNullOrWhiteSpace($combinedOutput)) {
return $false
}

$patterns = @(
'The SSH connection was unexpectedly closed by the remote end',
'An error occurred in the underlying SSH library that Vagrant uses',
'timeout during server version negotiating',
'server version negotiating',
'is not yet ready for SSH',
'Connection reset by peer',
'Connection closed by remote host',
'Connection refused',
'connection attempt timed out',
'timed out while waiting for the machine to boot',
'Timeout while waiting for the machine to boot'
)

foreach ($pattern in $patterns) {
if ($combinedOutput -match $pattern) {
return $true
}
}

return $false
}

function Get-NativeExitCode {
param(
[int]$Default = 0
)

if (Test-Path variable:LASTEXITCODE) {
return $LASTEXITCODE
}

return $Default
}

function Invoke-InteractiveExternalCommand {
param(
[Parameter(Mandatory = $true)]
[string]$FilePath,
[string[]]$ArgumentList = @(),
[string]$FailureMessage = 'Command failed.'
)

& $FilePath @ArgumentList
$exitCode = Get-NativeExitCode
if ($exitCode -ne 0) {
$commandText = @($FilePath) + $ArgumentList
throw "$FailureMessage Command: $($commandText -join ' ') Exit code: $exitCode"
}
}

Export-ModuleMember -Function *
