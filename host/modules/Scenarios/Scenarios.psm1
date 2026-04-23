Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../FileHelpers/FileHelpers.psd1') -Force
Import-Module (Join-Path $PSScriptRoot '../LabState/LabState.psd1') -Force

$script:ValidObjectiveTags = @(
'essential-tools',
'shell-scripting',
'boot-and-recovery',
'processes-logs-tuning',
'storage-lvm',
'filesystems-and-autofs',
'software-scheduling-time',
'software-management',
'networking-and-firewall',
'users-sudo-ssh',
'selinux-and-default-perms',
'containers'
)

function ConvertTo-ScenarioTrack {
param(
[AllowEmptyString()]
[string]$Track
)

$value = ([string]$Track).Trim().ToLowerInvariant() -replace '[-_]', ''
switch ($value) {
{ $_ -in @('', 'all') } { return 'all' }
{ $_ -in @('9', 'rhel9', 'rhcsa9', 'ex2009') } { return 'rhcsa9' }
{ $_ -in @('10', 'rhel10', 'rhcsa10', 'ex20010') } { return 'rhcsa10' }
default { throw "Unsupported scenario track '$Track'. Use RHCSA9, RHCSA10, or All." }
}
}

function Get-ScenarioTrackArray {
param(
[AllowNull()]
[object]$Value = $null,
[string]$Label = 'tracks'
)

$raw = @(Get-StringArray -Value $Value -Label $Label -AllowEmpty)
if ($raw.Count -eq 0) {
return ,@('rhcsa9')
}

$tracks = @()
foreach ($item in $raw) {
$track = ConvertTo-ScenarioTrack -Track $item
if ($track -ne 'all' -and $track -notin $tracks) {
$tracks += $track
}
}

if ($tracks.Count -eq 0) {
return ,@('rhcsa9')
}

return ,$tracks
}

function Test-ScenarioTrackMatch {
param(
[string[]]$ScenarioTracks = @('rhcsa9'),
[string]$Track = 'rhcsa9'
)

$normalized = ConvertTo-ScenarioTrack -Track $Track
if ($normalized -eq 'all') {
return $true
}

return $normalized -in @($ScenarioTracks)
}

function Resolve-ScenarioScriptPath {
param(
[Parameter(Mandatory = $true)]
[string]$ScenarioRoot,
[string]$RelativePath,
[Parameter(Mandatory = $true)]
[string]$Label,
[string]$ProjectRoot = (Get-ProjectRoot)
)

if ([string]::IsNullOrWhiteSpace($RelativePath)) {
return [PSCustomObject]@{
FullPath = $null
RelativePath = $null
}
}

$candidate = Resolve-ProjectPath -BasePath $ScenarioRoot -RelativeOrAbsolutePath $RelativePath
if (-not (Test-Path $candidate -PathType Leaf)) {
throw "Scenario file for $Label not found: $RelativePath"
}

$fullPath = (Resolve-Path $candidate).Path
return [PSCustomObject]@{
FullPath = $fullPath
RelativePath = (Get-ProjectRelativePath -Path $fullPath -ProjectRoot $ProjectRoot)
}
}

function Resolve-ScenarioDocPath {
param(
[Parameter(Mandatory = $true)]
[string]$ScenarioRoot,
[Parameter(Mandatory = $true)]
[string]$FileName,
[Parameter(Mandatory = $true)]
[string]$Label,
[string]$ProjectRoot = (Get-ProjectRoot)
)

$candidate = Join-Path $ScenarioRoot $FileName
if (-not (Test-Path $candidate -PathType Leaf)) {
throw "Scenario file for $Label not found: $FileName"
}

$fullPath = (Resolve-Path $candidate).Path
return [PSCustomObject]@{
FullPath = $fullPath
RelativePath = (Get-ProjectRelativePath -Path $fullPath -ProjectRoot $ProjectRoot)
}
}

function ConvertTo-ScenarioManifest {
param(
[Parameter(Mandatory = $true)]
[string]$ManifestPath,
[string]$ProjectRoot = (Get-ProjectRoot)
)

$manifestFullPath = (Resolve-Path $ManifestPath).Path
$scenarioRoot = Split-Path -Parent $manifestFullPath
$relativeScenarioRoot = Get-ProjectRelativePath -Path $scenarioRoot -ProjectRoot $ProjectRoot
$segments = $relativeScenarioRoot -split '/'

 if ($segments.Count -ne 4 -or $segments[0] -ne 'scenarios' -or $segments[1] -notin @('labs', 'exams') -or $segments[2] -notin @('rhcsa9', 'rhcsa10')) {
 throw "Scenario root '$relativeScenarioRoot' must be in the form scenarios/labs/<track>/<id> or scenarios/exams/<track>/<id>." } $scenarioCategory = $segments[1]
 $scenarioTrack = $segments[2]
 $scenarioFolderName = $segments[3]
$raw = Get-Content $manifestFullPath -Raw | ConvertFrom-Json

$id = [string](Get-RequiredProperty -Object $raw -Name 'id')
if ($id -ne $scenarioFolderName) {
throw "Scenario id '$id' must match folder name '$scenarioFolderName'."
}

$title = [string](Get-RequiredProperty -Object $raw -Name 'title')
$description = [string](Get-RequiredProperty -Object $raw -Name 'description')
$objectiveTags = Get-StringArray -Value (Get-RequiredProperty -Object $raw -Name 'objective_tags') -Label "Scenario '$id' objective_tags"
$supportedModes = @(
Get-StringArray -Value (Get-RequiredProperty -Object $raw -Name 'supported_modes') -Label "Scenario '$id' supported_modes" |
ForEach-Object { $_.ToLowerInvariant() }
)

foreach ($tag in $objectiveTags) {
if ($tag -notin $script:ValidObjectiveTags) {
throw "Scenario '$id' has invalid objective tag '$tag'."
}
}

foreach ($mode in $supportedModes) {
if ($mode -notin @('lab', 'exam')) {
throw "Scenario '$id' has invalid supported mode '$mode'."
}
}

$timeLimit = [int](Get-RequiredProperty -Object $raw -Name 'time_limit_minutes' -AllowZero)
if ($timeLimit -lt 0) {
throw "Scenario '$id' time_limit_minutes must be zero or greater."
}

$tracks = Get-ScenarioTrackArray -Value (Get-OptionalPropertyValue -Object $raw -Name 'tracks') -Label "Scenario '$id' tracks"
$rhelMajorRaw = Get-OptionalPropertyValue -Object $raw -Name 'rhel_major'
$rhelMajor = if ($null -eq $rhelMajorRaw -or [string]::IsNullOrWhiteSpace([string]$rhelMajorRaw)) { 9 } else { [int]$rhelMajorRaw }
if ($rhelMajor -notin @(9, 10)) {
throw "Scenario '$id' rhel_major must be 9 or 10."
}

$flags = Get-RequiredProperty -Object $raw -Name 'flags'
$passwordRecovery = [bool](Get-RequiredProperty -Object $flags -Name 'password_recovery' -AllowZero)
$requiresServer = [bool](Get-RequiredProperty -Object $flags -Name 'requires_server' -AllowZero)

$vmScriptsRaw = Get-OptionalPropertyValue -Object $raw -Name 'vm_scripts'
if ($null -eq $vmScriptsRaw) {
$vmScriptsRaw = [PSCustomObject]@{}
}

$serverScriptValue = Get-OptionalPropertyValue -Object $vmScriptsRaw -Name 'server'
if ($null -eq $serverScriptValue) {
$serverScriptValue = Get-OptionalPropertyValue -Object $vmScriptsRaw -Name 'servervm'
}
$clientScriptValue = Get-OptionalPropertyValue -Object $vmScriptsRaw -Name 'client'
if ($null -eq $clientScriptValue) {
$clientScriptValue = Get-OptionalPropertyValue -Object $vmScriptsRaw -Name 'clientvm'
}

$serverScript = Resolve-ScenarioScriptPath -ScenarioRoot $scenarioRoot -RelativePath ([string]$serverScriptValue) -Label 'vm_scripts.server' -ProjectRoot $ProjectRoot
$clientScript = Resolve-ScenarioScriptPath -ScenarioRoot $scenarioRoot -RelativePath ([string]$clientScriptValue) -Label 'vm_scripts.client' -ProjectRoot $ProjectRoot
$content = Get-RequiredProperty -Object $raw -Name 'content'
$labContent = Get-OptionalPropertyValue -Object $content -Name 'lab'
$examContent = Get-OptionalPropertyValue -Object $content -Name 'exam'

if ('lab' -in $supportedModes -and $null -eq $labContent) {
throw "Scenario '$id' supports lab mode but content.lab is missing."
}

if ('exam' -in $supportedModes -and $null -eq $examContent) {
throw "Scenario '$id' supports exam mode but content.exam is missing."
}

$labTasksDoc = if ('lab' -in $supportedModes) {
Resolve-ScenarioDocPath -ScenarioRoot $scenarioRoot -FileName 'LAB_TASKS.md' -Label 'LAB_TASKS.md' -ProjectRoot $ProjectRoot
}
else {
[PSCustomObject]@{ FullPath = $null; RelativePath = $null }
}

$labSolutionDoc = if ('lab' -in $supportedModes) {
Resolve-ScenarioDocPath -ScenarioRoot $scenarioRoot -FileName 'LAB_SOLUTION.md' -Label 'LAB_SOLUTION.md' -ProjectRoot $ProjectRoot
}
else {
[PSCustomObject]@{ FullPath = $null; RelativePath = $null }
}

$examTasksDoc = if ('exam' -in $supportedModes) {
Resolve-ScenarioDocPath -ScenarioRoot $scenarioRoot -FileName 'EXAM_TASKS.md' -Label 'EXAM_TASKS.md' -ProjectRoot $ProjectRoot
}
else {
[PSCustomObject]@{ FullPath = $null; RelativePath = $null }
}

$examSolutionDoc = if ('exam' -in $supportedModes) {
Resolve-ScenarioDocPath -ScenarioRoot $scenarioRoot -FileName 'EXAM_SOLUTION.md' -Label 'EXAM_SOLUTION.md' -ProjectRoot $ProjectRoot
}
else {
[PSCustomObject]@{ FullPath = $null; RelativePath = $null }
}

$labTasks = @()
$labTaskTitles = @()
$labTaskPoints = @()
$labSolutionCommands = @()
$labHints = @()
$labChecks = @()
$labSolutionOutline = @()
if ($null -ne $labContent) {
$labTasks = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'tasks') -Label "Scenario '$id' content.lab.tasks"
$labTaskTitles = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'task_titles') -Label "Scenario '$id' content.lab.task_titles"
$labTaskPoints = Get-IntegerArray -Value (Get-RequiredProperty -Object $labContent -Name 'task_points') -Label "Scenario '$id' content.lab.task_points"
$labSolutionCommands = Get-StringMatrix -Value (Get-RequiredProperty -Object $labContent -Name 'solution_commands') -Label "Scenario '$id' content.lab.solution_commands"
$labHints = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'hints' -AllowZero) -Label "Scenario '$id' content.lab.hints" -AllowEmpty
$labChecks = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'checks' -AllowZero) -Label "Scenario '$id' content.lab.checks" -AllowEmpty
$labSolutionOutline = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'solution_outline' -AllowZero) -Label "Scenario '$id' content.lab.solution_outline" -AllowEmpty

if ($labTaskTitles.Count -ne $labTasks.Count) {
throw "Scenario '$id' content.lab.task_titles must match the task count."
}

if ($labTaskPoints.Count -ne $labTasks.Count) {
throw "Scenario '$id' content.lab.task_points must match the task count."
}

if ($labSolutionCommands.Count -ne $labTasks.Count) {
throw "Scenario '$id' content.lab.solution_commands must match the task count."
}
}

$examTasks = @()
$examTaskTitles = @()
$examTaskPoints = @()
$examSolutionCommands = @()
if ($null -ne $examContent) {
$examTasks = Get-StringArray -Value (Get-RequiredProperty -Object $examContent -Name 'tasks') -Label "Scenario '$id' content.exam.tasks"
$examTaskTitles = Get-StringArray -Value (Get-RequiredProperty -Object $examContent -Name 'task_titles') -Label "Scenario '$id' content.exam.task_titles"
$examTaskPoints = Get-IntegerArray -Value (Get-RequiredProperty -Object $examContent -Name 'task_points') -Label "Scenario '$id' content.exam.task_points"
$examSolutionCommands = Get-StringMatrix -Value (Get-RequiredProperty -Object $examContent -Name 'solution_commands') -Label "Scenario '$id' content.exam.solution_commands"

if ($examTaskTitles.Count -ne $examTasks.Count) {
throw "Scenario '$id' content.exam.task_titles must match the task count."
}

if ($examTaskPoints.Count -ne $examTasks.Count) {
throw "Scenario '$id' content.exam.task_points must match the task count."
}

if ($examSolutionCommands.Count -ne $examTasks.Count) {
throw "Scenario '$id' content.exam.solution_commands must match the task count."
}

if ((($examTaskPoints | Measure-Object -Sum).Sum) -ne 100) {
throw "Scenario '$id' content.exam.task_points must sum to 100."
}
}

 return [PSCustomObject]@{
 Id = $id
 Category = $scenarioCategory
 Track = $scenarioTrack
Title = $title
Description = $description
ObjectiveTags = $objectiveTags
SupportedModes = $supportedModes
TimeLimitMinutes = $timeLimit
Tracks = $tracks
RHELMajor = $rhelMajor
ScenarioRoot = $scenarioRoot
RelativeScenarioRoot = $relativeScenarioRoot
ManifestPath = $manifestFullPath
RelativeManifestPath = (Get-ProjectRelativePath -Path $manifestFullPath -ProjectRoot $ProjectRoot)
VmScripts = [PSCustomObject]@{
Server = $serverScript.FullPath
ServerRelative = $serverScript.RelativePath
Client = $clientScript.FullPath
ClientRelative = $clientScript.RelativePath
}
Docs = [PSCustomObject]@{
LabTasks = $labTasksDoc.FullPath
LabTasksRelative = $labTasksDoc.RelativePath
LabSolution = $labSolutionDoc.FullPath
LabSolutionRelative = $labSolutionDoc.RelativePath
ExamTasks = $examTasksDoc.FullPath
ExamTasksRelative = $examTasksDoc.RelativePath
ExamSolution = $examSolutionDoc.FullPath
ExamSolutionRelative = $examSolutionDoc.RelativePath
}
Flags = [PSCustomObject]@{
PasswordRecovery = $passwordRecovery
RequiresServer = $requiresServer
}
Content = [PSCustomObject]@{
Lab = [PSCustomObject]@{
Tasks = $labTasks
TaskTitles = $labTaskTitles
TaskPoints = $labTaskPoints
SolutionCommands = $labSolutionCommands
Hints = $labHints
Checks = $labChecks
SolutionOutline = $labSolutionOutline
}
Exam = [PSCustomObject]@{
Tasks = $examTasks
TaskTitles = $examTaskTitles
TaskPoints = $examTaskPoints
SolutionCommands = $examSolutionCommands
}
}
}
}

function Get-ScenarioCatalog {
param(
[string]$ProjectRoot = (Get-ProjectRoot),
[string]$Track = 'rhcsa9'
)

$scenariosRoot = Join-Path $ProjectRoot 'scenarios'
if (-not (Test-Path $scenariosRoot -PathType Container)) {
return @()
}

$manifestFiles = @(Get-ChildItem -Path $scenariosRoot -Filter 'scenario.json' -File -Recurse | Sort-Object FullName)
$catalog = foreach ($file in $manifestFiles) {
ConvertTo-ScenarioManifest -ManifestPath $file.FullName -ProjectRoot $ProjectRoot
}

return @($catalog | Where-Object { Test-ScenarioTrackMatch -ScenarioTracks @($_.Tracks) -Track $Track } | Sort-Object Category, Id)
}

function Get-ScenarioManifest {
param(
[Parameter(Mandatory = $true)]
[string]$ScenarioId,
[string]$ProjectRoot = (Get-ProjectRoot),
[string]$Track = 'rhcsa9'
)

$matchingManifest = @(Get-ScenarioCatalog -ProjectRoot $ProjectRoot -Track $Track | Where-Object { $_.Id -eq $ScenarioId })
if ($matchingManifest.Count -eq 0) {
throw "Scenario '$ScenarioId' not found."
}

if ($matchingManifest.Count -gt 1) {
throw "Scenario id '$ScenarioId' is duplicated in the scenario catalog."
}

return $matchingManifest[0]
}

function ConvertTo-ExerciseCheckEntry {
param(
[Parameter(Mandatory = $true)]
[string]$Command,
[Parameter(Mandatory = $true)]
[int]$Index
)

$trimmedCommand = $Command.Trim()
$target = 'client'
$effectiveCommand = $trimmedCommand

if ($trimmedCommand -match '^\s*ssh\s+(?<host>\S*server\S*)\s+(?<remote>.+?)\s*$') {
$remoteCommand = [string]$matches['remote']
$remoteCommand = ($remoteCommand -replace '^\s*sudo\s+', '').Trim()
if (-not [string]::IsNullOrWhiteSpace($remoteCommand)) {
$target = 'server'
$effectiveCommand = $trimmedCommand
$effectiveCommand = $effectiveCommand -replace '(?i)(^|&&\s*)ssh\s+\S*server\S*\s+(?:sudo\s+)?', '$1'
$effectiveCommand = $effectiveCommand.Trim()
}
}
elseif ($trimmedCommand -match '^\s*#\s*server\s+') {
$target = 'server'
$effectiveCommand = $trimmedCommand -replace '^\s*#\s*server\s+', ''
$effectiveCommand = $effectiveCommand.Trim()
}

return [PSCustomObject]@{
Index = $Index
Target = $target
OriginalCommand = $trimmedCommand
Command = $effectiveCommand
}
}

function Format-ScenarioText {
param(
[AllowEmptyString()]
[string]$Text
)

if ($null -eq $Text) {
return ''
}

$normalized = ($Text -replace "`r`n", "`n").Trim("`n")
$lines = @($normalized -split "`n" | ForEach-Object { $_.TrimEnd() })
if ($lines.Count -eq 1 -and -not [string]::IsNullOrWhiteSpace($lines[0])) {
if ($lines[0][-1] -notin @('.', ':', '!', '?')) {
$lines[0] += '.'
}
}

return (($lines -join "`n").Trim())
}

function Get-ScenarioLabHintsMarkdown {
param(
[Parameter(Mandatory = $true)]
[object]$Manifest
)

$lines = @(
"# $($Manifest.Title) Hints",
''
)

$hints = @($Manifest.Content.Lab.Hints)
if ($hints.Count -eq 0) {
$lines += '- No hints are defined for this lab.'
return (($lines -join [Environment]::NewLine) + [Environment]::NewLine)
}

foreach ($hint in $hints) {
$text = Format-ScenarioText -Text ([string]$hint)
$text = $text.TrimEnd('.')
$lines += "- $text."
}

return (($lines -join [Environment]::NewLine) + [Environment]::NewLine)
}

function Get-ScenarioLabCheckScript {
param(
[Parameter(Mandatory = $true)]
[object[]]$Checks
)

$lines = @()

if ($Checks.Count -eq 0) {
$lines += '# No automated checks are defined for this lab.'
$lines += 'echo "No automated checks are defined for this lab."'
return (($lines -join [Environment]::NewLine) + [Environment]::NewLine)
}

foreach ($check in $Checks) {
$lines += ('# Check {0:d2} [{1}]' -f [int]$check.Index, [string]$check.Target)
if ([string]$check.Command -ne [string]$check.OriginalCommand) {
$lines += "# Source: $([string]$check.OriginalCommand)"
}
$lines += [string]$check.Command
$lines += ''
}

return (($lines -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine)
}

function Get-ScenarioSourceHash {
param(
[Parameter(Mandatory = $true)]
[string]$Path
)

return [string](Get-FileHash -Path $Path -Algorithm SHA256).Hash
}

function Initialize-LabExerciseCache {
[OutputType([pscustomobject])]
param(
[Parameter(Mandatory = $true)]
[object]$Manifest,
[string]$ProjectRoot = (Get-ProjectRoot)
)

if ([string]$Manifest.Category -ne 'labs') {
throw "Scenario '$($Manifest.Id)' is not a lab exercise."
}

Initialize-LabStateLayout -ProjectRoot $ProjectRoot | Out-Null
$runtimeRoot = Get-GeneratedLabRuntimeRoot -ScenarioId $Manifest.Id -ProjectRoot $ProjectRoot
if (-not (Test-Path -LiteralPath $runtimeRoot)) {
New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
}

$promptPath = Join-Path $runtimeRoot 'prompt.md'
$hintPath = Join-Path $runtimeRoot 'hint.md'
$checkPath = Join-Path $runtimeRoot 'check.sh'
$solutionPath = Join-Path $runtimeRoot 'solution.md'
$metadataPath = Join-Path $runtimeRoot 'exercise.json'
$sourceHash = Get-ScenarioSourceHash -Path $Manifest.ManifestPath

$checks = @()
$checkIndex = 0
foreach ($checkCommand in @($Manifest.Content.Lab.Checks)) {
$checkIndex++
$checks += ConvertTo-ExerciseCheckEntry -Command ([string]$checkCommand) -Index $checkIndex
}

$expectedCheckMetadata = @(
foreach ($check in $checks) {
[ordered]@{
index = [int]$check.Index
target = [string]$check.Target
original_command = [string]$check.OriginalCommand
command = [string]$check.Command
}
}
)

$existingMetadata = $null
if (Test-Path -LiteralPath $metadataPath -PathType Leaf) {
try {
$rawMetadata = Get-Content -LiteralPath $metadataPath -Raw
if ($rawMetadata.Length -gt 0 -and [int][char]$rawMetadata[0] -eq 0xFEFF) {
$rawMetadata = $rawMetadata.Substring(1)
}
$existingMetadata = $rawMetadata | ConvertFrom-Json
}
catch {
$existingMetadata = $null
}
}

$pathsReady = @($promptPath, $hintPath, $checkPath, $solutionPath) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
$checksReady = $false
if ($null -ne $existingMetadata) {
$expectedChecksJson = ($expectedCheckMetadata | ConvertTo-Json -Depth 8 -Compress)
$existingChecksJson = (@($existingMetadata.checks) | ConvertTo-Json -Depth 8 -Compress)
$checksReady = $expectedChecksJson -eq $existingChecksJson
}
$cacheFresh = $null -ne $existingMetadata -and
[string](Get-OptionalPropertyValue -Object $existingMetadata -Name 'source_hash') -eq $sourceHash -and
$pathsReady.Count -eq 4 -and
$checksReady

if (-not $cacheFresh) {
Copy-Item -LiteralPath $Manifest.Docs.LabTasks -Destination $promptPath -Force
Copy-Item -LiteralPath $Manifest.Docs.LabSolution -Destination $solutionPath -Force

Set-Utf8NoBomFile -Path $hintPath -Content (Get-ScenarioLabHintsMarkdown -Manifest $Manifest)
Set-Utf8NoBomFile -Path $checkPath -Content (Get-ScenarioLabCheckScript -Checks $checks)

$metadata = [ordered]@{
id = $Manifest.Id
title = $Manifest.Title
description = $Manifest.Description
time_limit_minutes = [int]$Manifest.TimeLimitMinutes
objective_tags = @($Manifest.ObjectiveTags)
requires_server = [bool]$Manifest.Flags.RequiresServer
source_manifest = $Manifest.RelativeManifestPath
source_hash = $sourceHash
paths = [ordered]@{
prompt = Get-ProjectRelativePath -Path $promptPath -ProjectRoot $ProjectRoot
hint = Get-ProjectRelativePath -Path $hintPath -ProjectRoot $ProjectRoot
check = Get-ProjectRelativePath -Path $checkPath -ProjectRoot $ProjectRoot
solution = Get-ProjectRelativePath -Path $solutionPath -ProjectRoot $ProjectRoot
metadata = Get-ProjectRelativePath -Path $metadataPath -ProjectRoot $ProjectRoot
}
checks = $expectedCheckMetadata
}

Set-Utf8NoBomFile -Path $metadataPath -Content (($metadata | ConvertTo-Json -Depth 8) + [Environment]::NewLine)
$existingMetadata = $metadata | ConvertTo-Json -Depth 8 | ConvertFrom-Json
}

return $existingMetadata
}

function Get-LabExerciseDefinition {
param(
[Parameter(Mandatory = $true)]
[string]$ScenarioId,
[string]$ProjectRoot = (Get-ProjectRoot)
)

$manifest = Get-ScenarioManifest -ScenarioId $ScenarioId -ProjectRoot $ProjectRoot
if ($manifest.Category -ne 'labs') {
throw "Scenario '$ScenarioId' is not a lab exercise."
}

$metadata = Initialize-LabExerciseCache -Manifest $manifest -ProjectRoot $ProjectRoot
$exerciseChecks = @(
@($metadata.checks) | ForEach-Object {
[PSCustomObject]@{
Index = [int]$_.index
Target = [string]$_.target
OriginalCommand = [string]$_.original_command
Command = [string]$_.command
}
}
)

return [PSCustomObject]@{
Id = [string]$metadata.id
Title = [string]$metadata.title
Description = [string]$metadata.description
TimeLimitMinutes = [int]$metadata.time_limit_minutes
ObjectiveTags = @($metadata.objective_tags)
RequiresServer = [bool]$metadata.requires_server
SourceManifest = [string]$metadata.source_manifest
Paths = [PSCustomObject]@{
Prompt = [string]$metadata.paths.prompt
Hint = [string]$metadata.paths.hint
Check = [string]$metadata.paths.check
Solution = [string]$metadata.paths.solution
Metadata = [string]$metadata.paths.metadata
}
Checks = $exerciseChecks
}
}

function Get-ScenarioStatus {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

$activeRun = Get-ActiveRunState -ProjectRoot $ProjectRoot
if ($null -eq $activeRun) {
return $null
}

$tracks = @($activeRun.scenario.tracks)
if ($tracks.Count -eq 0) {
$tracks = @('rhcsa9')
}

$rhelMajor = 9
if ($null -ne $activeRun.scenario.rhel_major) {
$rhelMajor = [int]$activeRun.scenario.rhel_major
}

return [PSCustomObject]@{
ScenarioId = [string]$activeRun.scenario.id
Category = [string]$activeRun.scenario.category
Title = [string]$activeRun.scenario.title
Mode = [string]$activeRun.mode
ObjectiveTags = @($activeRun.scenario.objective_tags)
Tracks = $tracks
RHELMajor = $rhelMajor
RunId = [string]$activeRun.run_id
StartedAt = [string]$activeRun.started_at
EndsAt = [string]$activeRun.ends_at
ArtifactRoot = [string]$activeRun.artifact_root
RunBrief = [string]$activeRun.generated_artifacts.run_brief
LabTasksDoc = [string]$activeRun.scenario.docs.lab_tasks
LabSolutionDoc = [string]$activeRun.scenario.docs.lab_solution
ExamTasksDoc = [string]$activeRun.scenario.docs.exam_tasks
ExamSolutionDoc = [string]$activeRun.scenario.docs.exam_solution
}
}

Export-ModuleMember -Function *
