Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../FileHelpers/FileHelpers.psd1') -Force

function Get-PowerShellCompletionScript {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

$scriptPath = (Join-Path $ProjectRoot 'RHCSA.ps1').Replace("'", "''")
$scenarioRoot = (Join-Path $ProjectRoot 'scenarios').Replace("'", "''")

return @"
`$rhcsaScriptPath = '$scriptPath'
`$rhcsaScenarioRoot = '$scenarioRoot'

Register-ArgumentCompleter -CommandName '.\RHCSA.ps1', 'RHCSA.ps1' -ScriptBlock {
param(`$commandName, `$parameterName, `$wordToComplete, `$commandAst, `$fakeBoundParameters)
`$null = `$commandName, `$parameterName, `$fakeBoundParameters

function New-RhcsaCompletionResult {
param([string]`$Value)
[System.Management.Automation.CompletionResult]::new(`$Value, `$Value, 'ParameterValue', `$Value)
}

function Complete-RhcsaValues {
param([string[]]`$Value)
foreach (`$item in @(`$Value | Where-Object { -not [string]::IsNullOrWhiteSpace(`$_) } | Sort-Object -Unique)) {
if (`$item -like "`$wordToComplete*") {
New-RhcsaCompletionResult -Value `$item
}
}
}

function Get-RhcsaScenarioIds {
param([switch]`$LabsOnly)
if (-not (Test-Path `$rhcsaScenarioRoot -PathType Container)) {
return @()
}

if (`$LabsOnly) {
return @(Get-ChildItem -Path (Join-Path `$rhcsaScenarioRoot 'labs') -Filter 'scenario.json' -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object { `$_.Directory.Name } | Sort-Object -Unique)
}

return @(Get-ChildItem -Path `$rhcsaScenarioRoot -Filter 'scenario.json' -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object { `$_.Directory.Name } | Sort-Object -Unique)
}

`$elements = @(`$commandAst.CommandElements | ForEach-Object { `$_.Extent.Text })
if (`$elements.Count -eq 0) {
return
}

`$tokens = @()
if (`$elements.Count -gt 1) {
`$tokens = @(`$elements[1..(`$elements.Count - 1)] | Where-Object { -not [string]::IsNullOrWhiteSpace(`$_) })
}

if (`$tokens.Count -gt 0 -and `$tokens[-1] -eq `$wordToComplete) {
if (`$tokens.Count -eq 1) {
`$tokens = @()
}
else {
`$tokens = @(`$tokens[0..(`$tokens.Count - 2)])
}
}

if (`$tokens.Count -eq 0) {
Complete-RhcsaValues -Value @('up', 'down', 'destroy', 'list', 'start', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'completion', 'help')
return
}

`$root = `$tokens[0].ToLowerInvariant()
`$last = if (`$tokens.Count -gt 0) { [string]`$tokens[-1] } else { '' }

switch (`$root) {
'help' {
Complete-RhcsaValues -Value @('up', 'down', 'destroy', 'list', 'start', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'completion')
return
}
'up' {
Complete-RhcsaValues -Value @('-NoProvision', '-NormalStart', '-HeadlessClient', '-RealisticMode', '-ForceHostCleanup')
return
}
'destroy' {
Complete-RhcsaValues -Value @('-ForceHostCleanup')
return
}
'list' {
if (`$tokens.Count -le 1) {
Complete-RhcsaValues -Value @('labs', 'exams', '-Track')
}
elseif (`$last -eq '-Track') {
Complete-RhcsaValues -Value @('RHCSA9', 'RHCSA10', 'All')
}
return
}
'ssh' {
if (`$tokens.Count -le 1) {
Complete-RhcsaValues -Value @('client', 'server')
}
return
}
'ssh-config' {
if (`$tokens.Count -le 1) {
Complete-RhcsaValues -Value @('client', 'server')
}
return
}
'completion' {
if (`$tokens.Count -le 1) {
Complete-RhcsaValues -Value @('powershell', 'install')
}
return
}
'start' {
if (`$last -eq '-Id') {
Complete-RhcsaValues -Value (Get-RhcsaScenarioIds)
return
}
if (`$last -eq '-Mode') {
Complete-RhcsaValues -Value @('Lab', 'Exam')
return
}
if (`$last -eq '-Track') {
Complete-RhcsaValues -Value @('RHCSA9', 'RHCSA10', 'All')
return
}
Complete-RhcsaValues -Value @('-Id', '-Mode', '-Track')
return
}
'tui' {
if (`$last -eq '-Track') {
Complete-RhcsaValues -Value @('RHCSA9', 'RHCSA10', 'All')
return
}
Complete-RhcsaValues -Value @('-Track')
return
}
'check' {
if (`$last -eq '-Id') {
Complete-RhcsaValues -Value (Get-RhcsaScenarioIds -LabsOnly)
return
}
Complete-RhcsaValues -Value @('-Id')
return
}
}
}
"@
}

function Install-PowerShellCompletion {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

$startMarker = '# >>> RHCSA simulator completion >>>'
$endMarker = '# <<< RHCSA simulator completion <<<'
$completionBlock = @(
$startMarker,
(Get-PowerShellCompletionScript -ProjectRoot $ProjectRoot),
$endMarker
) -join [Environment]::NewLine

$profilePath = $PROFILE.CurrentUserCurrentHost
$profileDirectory = Split-Path -Parent $profilePath
if (-not (Test-Path $profileDirectory)) {
New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
}

$currentContent = if (Test-Path $profilePath) { Get-Content $profilePath -Raw } else { '' }
$pattern = '(?s)' + [regex]::Escape($startMarker) + '.*?' + [regex]::Escape($endMarker)
if ($currentContent -match $pattern) {
$updatedContent = [regex]::Replace($currentContent, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{
param($match)
$null = $match
$completionBlock
})
}
elseif ([string]::IsNullOrWhiteSpace($currentContent)) {
$updatedContent = $completionBlock
}
else {
$updatedContent = ($currentContent.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $completionBlock)
}

Set-Utf8NoBomFile -Path $profilePath -Content $updatedContent
return $profilePath
}

Export-ModuleMember -Function *
