[CmdletBinding(PositionalBinding = $true)]
param(
[Parameter(Position = 0)]
[ArgumentCompleter({
param($commandName, $parameterName, $wordToComplete)
$null = $commandName, $parameterName

foreach ($value in @('help', 'up', 'down', 'destroy', 'list', 'start', 'reset', 'status', 'check', 'repo', 'vms', 'ssh', 'ssh-config', 'tui', 'completion', '-h', '--help')) {
if ($value -like "$wordToComplete*") {
[System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
}
}
})]
[string]$Area,

[Parameter(Position = 1)]
[ArgumentCompleter({
param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
$null = $commandName, $parameterName, $commandAst

$area = [string]$fakeBoundParameters['Area']
$candidates = switch ($area.ToLowerInvariant()) {
'help' { @('up', 'down', 'destroy', 'list', 'start', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'completion') }
'list' { @('all', 'labs', 'lab', 'exams', 'exam') }
'ssh' { @('client', 'server') }
'ssh-config' { @('client', 'server') }
'completion' { @('powershell', 'install') }
default { @() }
}

foreach ($value in $candidates) {
if ($value -like "$wordToComplete*") {
[System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
}
}
})]
[string]$Command,

[Parameter(Position = 2)]
[ArgumentCompleter({
param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
$null = $commandName, $parameterName, $commandAst

$area = [string]$fakeBoundParameters['Area']
$command = [string]$fakeBoundParameters['Command']
$candidates = @()

switch ("$($area.ToLowerInvariant())/$($command.ToLowerInvariant())") {
'list/' {
$candidates = @('all', 'labs', 'lab', 'exams', 'exam')
}
'ssh/' {
$candidates = @('server', 'client')
}
'ssh-config/' {
$candidates = @('server', 'client')
}
}

foreach ($value in $candidates) {
if ($value -like "$wordToComplete*") {
[System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
}
}
})]
[string]$Item,

[Parameter(ValueFromRemainingArguments = $true)]
[string[]]$Extra,

[ArgumentCompleter({
param($commandName, $parameterName, $wordToComplete, $commandAst)
$null = $commandName, $parameterName

$scriptRoot = Split-Path -Parent $commandAst.Extent.File
$scenarioRoot = Join-Path $scriptRoot 'scenarios'
if (-not (Test-Path $scenarioRoot -PathType Container)) {
return
}

$ids = @(Get-ChildItem -Path $scenarioRoot -Filter 'scenario.json' -File -Recurse -ErrorAction SilentlyContinue |
ForEach-Object {
try {
($_.Directory.Name)
}
catch {
$null
}
} |
Sort-Object -Unique)

foreach ($value in $ids) {
if ($value -like "$wordToComplete*") {
[System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
}
}
})]
[string]$Id,

[ValidateSet('Lab', 'Exam')]
[ArgumentCompleter({
param($commandName, $parameterName, $wordToComplete)
$null = $commandName, $parameterName

foreach ($value in @('Lab', 'Exam')) {
if ($value -like "$wordToComplete*") {
[System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
}
}
})]
[string]$Mode = 'Lab',

[ValidateSet('RHCSA9', 'RHCSA10', 'All', 'rhcsa9', 'rhcsa10', 'all')]
[ArgumentCompleter({
param($commandName, $parameterName, $wordToComplete)
$null = $commandName, $parameterName

foreach ($value in @('RHCSA9', 'RHCSA10', 'All')) {
if ($value -like "$wordToComplete*") {
[System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
}
}
})]
[string]$Track = 'RHCSA9',

[ValidateSet('server', 'client', 'servervm', 'clientvm')]
[ArgumentCompleter({
param($commandName, $parameterName, $wordToComplete)
$null = $commandName, $parameterName

foreach ($value in @('server', 'client', 'servervm', 'clientvm')) {
if ($value -like "$wordToComplete*") {
[System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
}
}
})]
[string]$Vm,

[Alias('h')]
[switch]$Help,

[switch]$NoProvision,
[switch]$NormalStart,
[switch]$HeadlessClient,
[switch]$RealisticMode,
[switch]$ForceHostCleanup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'host/modules/RhcsaSimulator/RhcsaSimulator.psd1') -Force
Import-Module (Join-Path $PSScriptRoot 'host/modules/Rhcsa.Help/Rhcsa.Help.psd1') -Force
Import-Module (Join-Path $PSScriptRoot 'host/modules/Rhcsa.Ui/Rhcsa.Ui.psd1') -Force
Import-Module (Join-Path $PSScriptRoot 'host/modules/Rhcsa.Completion/Rhcsa.Completion.psd1') -Force
Import-Module (Join-Path $PSScriptRoot 'host/modules/Rhcsa.CommandRouting/Rhcsa.CommandRouting.psd1') -Force

$script:ShowWorkflowStatus = $false
$script:ForceHostCleanup = [bool]$ForceHostCleanup
Initialize-RhcsaSimulatorRuntime -ShowWorkflowStatus:$script:ShowWorkflowStatus -ForceHostCleanup:$script:ForceHostCleanup

$projectRoot = Get-ProjectRoot -Start $PSScriptRoot

if ($Help) {
$helpScope = 'general'
$normalizedArea = if ([string]::IsNullOrWhiteSpace($Area)) { '' } else { $Area.ToLowerInvariant() }
$normalizedCommand = if ([string]::IsNullOrWhiteSpace($Command)) { '' } else { $Command.ToLowerInvariant() }

switch ($normalizedArea) {
'' { $helpScope = 'general' }
'up' { $helpScope = 'up' }
'down' { $helpScope = 'down' }
'destroy' { $helpScope = 'destroy' }
'list' { $helpScope = 'list' }
'start' { $helpScope = 'start' }
'check' { $helpScope = 'check' }
'repo' { $helpScope = 'repo' }
'reset' { $helpScope = 'reset' }
'status' { $helpScope = 'status' }
'vms' { $helpScope = 'vms' }
'ssh' { $helpScope = 'ssh' }
'ssh-config' { $helpScope = 'ssh-config' }
'tui' { $helpScope = 'tui' }
'completion' { $helpScope = 'completion' }
'help' {
$helpScope = if ($normalizedCommand -in @('up', 'down', 'destroy', 'list', 'start', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'completion')) {
$normalizedCommand
}
else {
'general'
}
}
default { $helpScope = 'general' }
}

Get-HelpOutput -Scope $helpScope | Write-Output
return
}

$route = Resolve-CommandRoute -AreaValue $Area -CommandValue $Command -ItemValue $Item -ExtraValue $Extra
$area = [string]$route.Area
$command = [string]$route.Command
$item = if ([string]::IsNullOrWhiteSpace([string]$route.Item)) { $null } else { [string]$route.Item }
$remainingItem = @($route.Extra)
$isLegacyRoute = [bool]$route.Legacy

try {
if ($area -eq 'help') {
if ($remainingItem.Count -gt 0) {
throw "Unknown help argument '$($remainingItem[0])'."
}

$helpScope = if ([string]::IsNullOrWhiteSpace($command)) { 'general' } else { $command }
Get-HelpOutput -Scope $helpScope | Write-Output
return
}

if ([string]::IsNullOrWhiteSpace($area) -or (Test-HelpToken -Token $area)) {
Get-HelpOutput -Scope 'general' | Write-Output
return
}

if ($isLegacyRoute) {
throw 'Unknown command. Run .\RHCSA.ps1 help for usage.'
}

switch ("$area/$command") {
'baseline/up' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'up' | Write-Output
break
}

if ($item) {
throw "Unknown up argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown up argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown up argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown up argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown up argument '-Vm'."
}

Write-Output ''
Get-RhcsaAsciiBanner | Write-Output
Write-Output ''
$previousWorkflowPreference = $script:ShowWorkflowStatus
$script:ShowWorkflowStatus = $true
Initialize-RhcsaSimulatorRuntime -ShowWorkflowStatus:$script:ShowWorkflowStatus -ForceHostCleanup:$script:ForceHostCleanup
try {
$result = Start-BaselineSession `
-NoProvision:$NoProvision `
-NormalStart:$NormalStart `
-HeadlessClient:$HeadlessClient `
-RealisticMode:$RealisticMode `
-ProjectRoot $projectRoot
}
finally {
$script:ShowWorkflowStatus = $previousWorkflowPreference
Initialize-RhcsaSimulatorRuntime -ShowWorkflowStatus:$script:ShowWorkflowStatus -ForceHostCleanup:$script:ForceHostCleanup
}
Format-BaselineStartOutput -BaselineResult $result -BaselineStatus (Get-BaselineStatus -ProjectRoot $projectRoot) | Write-Output
break
}
'baseline/down' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'down' | Write-Output
break
}

if ($item) {
throw "Unknown down argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown down argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown down argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown down argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown down argument '-Vm'."
}

$machineStatus = @(Get-VagrantMachineStatus -ProjectRoot $projectRoot)
$vagrantPath = Get-VagrantPath
foreach ($machineName in @('server', 'client')) {
$current = $machineStatus | Where-Object { $_.Name -eq $machineName } | Select-Object -First 1
if ($null -eq $current) {
continue
}
if ($current.State -in @('not created', 'poweroff', 'saved', 'aborted')) {
continue
}
Invoke-ExternalCommand -FilePath $vagrantPath -ArgumentList @('halt', $machineName, '-f') -FailureMessage "Failed to halt $machineName." -IgnoreExitCode -SuppressOutput
}

Write-Output (Get-UiHeading -Text 'VMs powered off' -StyleName 'Success')
Format-VmStatusOutput -MachineStatus (Get-VagrantMachineStatus -ProjectRoot $projectRoot) | Write-Output
break
}
'baseline/repo' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'repo' | Write-Output
break
}

if ($item) {
throw "Unknown repo argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown repo argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown repo argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown repo argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown repo argument '-Vm'."
}

$result = Test-BaselineOfflineRepoHealth -ProjectRoot $projectRoot
Format-RepoHealthOutput -RepoHealthResult $result | Write-Output
if (-not $result.Passed) {
exit 1
}
break
}
'baseline/destroy' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'destroy' | Write-Output
break
}

if ($item) {
throw "Unknown destroy argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown destroy argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown destroy argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown destroy argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown destroy argument '-Vm'."
}

$result = Remove-LabEnvironment -ProjectRoot $projectRoot
Format-DestroyOutput -DestroyResult $result | Write-Output
break
}
'scenario/list' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'list' | Write-Output
break
}

if ($remainingItem.Count -gt 0) {
throw "Unknown list argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown list argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown list argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown list argument '-Vm'."
}

$listFilter = 'all'
if ($item) {
switch ($item.ToLowerInvariant()) {
'all' { $listFilter = 'all' }
'lab' { $listFilter = 'labs' }
'labs' { $listFilter = 'labs' }
'exam' { $listFilter = 'exams' }
'exams' { $listFilter = 'exams' }
default { throw "Unknown list argument '$item'." }
}
}

Format-ScenarioCatalogOutput -ScenarioCatalog @(Get-ScenarioCatalog -ProjectRoot $projectRoot -Track $Track) -Filter $listFilter -Track $Track | Write-Output
break
}
'scenario/start' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'start' | Write-Output
break
}

if ($item) {
throw "Unknown start argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown start argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown start argument '-Vm'."
}

if (-not $PSBoundParameters.ContainsKey('Id') -or [string]::IsNullOrWhiteSpace($Id)) {
throw 'Scenario start requires -Id <scenario-id>.'
}

$result = Start-ScenarioRun -ScenarioId $Id -Mode $Mode -Track $Track -ProjectRoot $projectRoot
Format-ScenarioStartOutput -ScenarioResult $result | Write-Output
break
}
'scenario/reset' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'reset' | Write-Output
break
}

if ($item) {
throw "Unknown reset argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown reset argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown reset argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown reset argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown reset argument '-Vm'."
}

$status = Get-ScenarioStatus -ProjectRoot $projectRoot
if ($null -eq $status) {
throw 'No active run found. Start one first with .\RHCSA.ps1 start -Id <scenario-id> -Mode Lab.'
}

$result = Reset-ScenarioRun -ProjectRoot $projectRoot
Format-ScenarioResetOutput -ScenarioResult $result | Write-Output
break
}
'scenario/status' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'status' | Write-Output
break
}

if ($item) {
throw "Unknown status argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown status argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown status argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown status argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown status argument '-Vm'."
}

Format-ScenarioStatusOutput -ScenarioStatus (Get-ScenarioStatus -ProjectRoot $projectRoot) | Write-Output
break
}
'scenario/check' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'check' | Write-Output
break
}

if ($item) {
throw "Unknown check argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown check argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown check argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown check argument '-Vm'."
}

$result = Invoke-LabExerciseCheck -ScenarioId $Id -ProjectRoot $projectRoot
Format-ExerciseCheckOutput -CheckResult $result | Write-Output
if (-not $result.Passed) {
exit 1
}
break
}
'dashboard/status' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'status' | Write-Output
break
}

if ($item) {
throw "Unknown status argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown status argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown status argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown status argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown status argument '-Vm'."
}

Format-DashboardOutput -BaselineStatus (Get-BaselineStatus -ProjectRoot $projectRoot) -ScenarioStatus (Get-ScenarioStatus -ProjectRoot $projectRoot) | Write-Output
break
}
'vm/status' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'vms' | Write-Output
break
}

if ($item) {
throw "Unknown vms argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown vms argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown vms argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown vms argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown vms argument '-Vm'."
}

Format-VmStatusOutput -MachineStatus (Get-VagrantMachineStatus -ProjectRoot $projectRoot) | Write-Output
break
}
'vm/ssh' {
if ((-not $PSBoundParameters.ContainsKey('Vm')) -and $item -and (Test-HelpToken -Token $item)) {
Get-HelpOutput -Scope 'ssh' | Write-Output
break
}
if ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0])) {
Get-HelpOutput -Scope 'ssh' | Write-Output
break
}

if ($remainingItem.Count -gt 0) {
throw "Unknown ssh argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown ssh argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown ssh argument '-Mode'."
}

$targetVm = if ($PSBoundParameters.ContainsKey('Vm')) { $Vm } else { $item }
if ([string]::IsNullOrWhiteSpace($targetVm)) {
$targetVm = 'client'
}

if ($PSBoundParameters.ContainsKey('Vm') -and $item -and $item -ne $Vm) {
throw "Conflicting ssh targets '$item' and '$Vm'."
}

$session = Open-VmSshSession -MachineName (ConvertTo-VmName -Name $targetVm) -ProjectRoot $projectRoot
Format-VmSshOutput -SessionResult $session | Write-Output
break
}
'vm/ssh-config' {
if ((-not $PSBoundParameters.ContainsKey('Vm')) -and $item -and (Test-HelpToken -Token $item)) {
Get-HelpOutput -Scope 'ssh-config' | Write-Output
break
}
if ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0])) {
Get-HelpOutput -Scope 'ssh-config' | Write-Output
break
}

if ($remainingItem.Count -gt 0) {
throw "Unknown ssh-config argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown ssh-config argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown ssh-config argument '-Mode'."
}

$targetVm = if ($PSBoundParameters.ContainsKey('Vm')) { $Vm } else { $item }
if ([string]::IsNullOrWhiteSpace($targetVm)) {
$targetVm = 'client'
}

if ($PSBoundParameters.ContainsKey('Vm') -and $item -and $item -ne $Vm) {
throw "Conflicting ssh-config targets '$item' and '$Vm'."
}

Get-VmSshConfig -MachineName (ConvertTo-VmName -Name $targetVm) -ProjectRoot $projectRoot | Write-Output
break
}
'app/tui' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'tui' | Write-Output
break
}

if ($item) {
throw "Unknown tui argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown tui argument '$($remainingItem[0])'."
}

Open-RhcsaTui -ProjectRoot $projectRoot -Track $Track
break
}
'completion/manage' {
$completionCommand = if ([string]::IsNullOrWhiteSpace($item)) { 'help' } else { $item.ToLowerInvariant() }
if ($remainingItem.Count -gt 0) {
throw "Unknown completion argument '$($remainingItem[0])'."
}

if (Test-HelpToken -Token $completionCommand) {
Get-HelpOutput -Scope 'completion' | Write-Output
break
}

switch ($completionCommand) {
'powershell' {
Get-PowerShellCompletionScript -ProjectRoot $projectRoot | Write-Output
break
}
'install' {
$profilePath = Install-PowerShellCompletion -ProjectRoot $projectRoot
Write-Output (Get-UiHeading -Text 'Completion installed' -StyleName 'Success')
Write-Output (Format-UiLabelValue -Label 'Profile' -Value $profilePath)
break
}
default {
throw "Unknown completion command '$completionCommand'."
}
}
break
}
default {
if ($area -eq 'completion') {
throw 'Unknown completion command. Run .\RHCSA.ps1 help completion for usage.'
}

throw 'Unknown command. Run .\RHCSA.ps1 help for usage.'
}
}
}
catch {
Format-ErrorOutput -Message $_.Exception.Message | Write-Output
$recommendedHelp = if ($isLegacyRoute) {
'.\RHCSA.ps1 help'
}
else {
Get-RecommendedHelpCommand -Area $area -Command $command
}
Write-Output (Format-StyledText -Text ("Use: {0}" -f $recommendedHelp) -StyleName 'Muted')
exit 1
}
