[CmdletBinding(PositionalBinding = $true)]
param(
[Parameter(Position = 0)]
[ArgumentCompleter({
param($commandName, $parameterName, $wordToComplete)
$null = $commandName, $parameterName

foreach ($value in @('help', 'up', 'resume', 'pause', 'down', 'destroy', 'list', 'start', 'exit-run', 'reset', 'status', 'check', 'repo', 'vms', 'ssh', 'ssh-config', 'tui', 'profile', 'timer', 'completion', '-h', '--help')) {
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
'help' { @('up', 'resume', 'pause', 'down', 'destroy', 'list', 'start', 'exit-run', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'profile', 'timer', 'completion') }
'list' { @('all', 'labs', 'lab', 'exams', 'exam') }
'profile' { @('RHCSA9', 'RHCSA10') }
'timer' { @('on', 'off', 'status') }
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
'profile/' {
$candidates = @('RHCSA9', 'RHCSA10')
}
'timer/' {
$candidates = @('on', 'off', 'status')
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

[ValidateSet('Auto', 'RHCSA9', 'RHCSA10', 'All', 'auto', 'rhcsa9', 'rhcsa10', 'all')]
[ArgumentCompleter({
param($commandName, $parameterName, $wordToComplete)
$null = $commandName, $parameterName

foreach ($value in @('Auto', 'RHCSA9', 'RHCSA10', 'All')) {
if ($value -like "$wordToComplete*") {
[System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
}
}
})]
[string]$Track = 'Auto',

[ValidateSet('RHCSA9', 'RHCSA10', 'rhcsa9', 'rhcsa10', 'rhel9', 'rhel10', '9', '10')]
[ArgumentCompleter({
param($commandName, $parameterName, $wordToComplete)
$null = $commandName, $parameterName

foreach ($value in @('RHCSA9', 'RHCSA10')) {
if ($value -like "$wordToComplete*") {
[System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
}
}
})]
[string]$Profile,

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
[switch]$Refresh,
[switch]$ForceHostCleanup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try {
    $script:utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($false)
    [Console]::OutputEncoding = $script:utf8NoBomEncoding
    [Console]::InputEncoding = $script:utf8NoBomEncoding
    $OutputEncoding = $script:utf8NoBomEncoding
}
catch {
    $null = $_
}

$moduleRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'host/modules'))
Get-Module |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace([string]$_.Path) -and
        [System.IO.Path]::GetFullPath([string]$_.Path).StartsWith($moduleRoot, [System.StringComparison]::OrdinalIgnoreCase)
    } |
    Sort-Object { $_.Name.Length } -Descending |
    Remove-Module -Force -ErrorAction SilentlyContinue

Import-Module (Join-Path $PSScriptRoot 'host/modules/FileHelpers/FileHelpers.psd1') -Force
Import-Module (Join-Path $PSScriptRoot 'host/modules/RhcsaSimulator/RhcsaSimulator.psd1') -Force
Import-Module (Join-Path $PSScriptRoot 'host/modules/Rhcsa.Help/Rhcsa.Help.psd1') -Force
Import-Module (Join-Path $PSScriptRoot 'host/modules/Rhcsa.Ui/Rhcsa.Ui.psd1') -Force
Import-Module (Join-Path $PSScriptRoot 'host/modules/Rhcsa.Completion/Rhcsa.Completion.psd1') -Force
Import-Module (Join-Path $PSScriptRoot 'host/modules/Rhcsa.CommandRouting/Rhcsa.CommandRouting.psd1') -Force

$script:ShowWorkflowStatus = $false
$script:ForceHostCleanup = [bool]$ForceHostCleanup
Initialize-RhcsaSimulatorRuntime -ShowWorkflowStatus:$script:ShowWorkflowStatus -ForceHostCleanup:$script:ForceHostCleanup

$projectRoot = Get-ProjectRoot -Start $PSScriptRoot
$boundParameters = $PSBoundParameters

function Get-EffectiveProjectProfile {
    if ($boundParameters.ContainsKey('Profile') -and -not [string]::IsNullOrWhiteSpace($Profile)) {
        return (ConvertTo-ProjectProfile -Profile $Profile)
    }

    return (Get-ProjectProfile -ProjectRoot $projectRoot)
}

function Get-EffectiveScenarioTrack {
    if ($boundParameters.ContainsKey('Track') -and -not [string]::IsNullOrWhiteSpace($Track) -and $Track.ToLowerInvariant() -ne 'auto') {
        return (ConvertTo-ScenarioTrack -Track $Track)
    }

    return (Get-ProjectTrackFromProfile -Profile (Get-EffectiveProjectProfile))
}

if ($Help) {
$helpScope = 'general'
$normalizedArea = if ([string]::IsNullOrWhiteSpace($Area)) { '' } else { $Area.ToLowerInvariant() }
$normalizedCommand = if ([string]::IsNullOrWhiteSpace($Command)) { '' } else { $Command.ToLowerInvariant() }

switch ($normalizedArea) {
'' { $helpScope = 'general' }
'up' { $helpScope = 'up' }
'resume' { $helpScope = 'resume' }
'pause' { $helpScope = 'pause' }
'down' { $helpScope = 'down' }
'destroy' { $helpScope = 'destroy' }
'list' { $helpScope = 'list' }
'start' { $helpScope = 'start' }
'exit-run' { $helpScope = 'exit-run' }
'leave' { $helpScope = 'exit-run' }
'check' { $helpScope = 'check' }
'repo' { $helpScope = 'repo' }
'reset' { $helpScope = 'reset' }
'status' { $helpScope = 'status' }
'vms' { $helpScope = 'vms' }
'ssh' { $helpScope = 'ssh' }
'ssh-config' { $helpScope = 'ssh-config' }
'tui' { $helpScope = 'tui' }
'profile' { $helpScope = 'profile' }
'timer' { $helpScope = 'timer' }
'completion' { $helpScope = 'completion' }
'help' {
$helpScope = if ($normalizedCommand -in @('up', 'resume', 'pause', 'down', 'destroy', 'list', 'start', 'exit-run', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'profile', 'timer', 'completion')) {
$normalizedCommand
}
elseif ($normalizedCommand -eq 'leave') {
'exit-run'
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

$effectiveProfile = Get-EffectiveProjectProfile
$effectiveTrack = Get-EffectiveScenarioTrack
$env:RHCSA_PROFILE = $effectiveProfile
$env:RHCSA_TRACK = $effectiveTrack

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

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown up argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
Set-ProjectProfile -Profile $effectiveProfile -ProjectRoot $projectRoot | Out-Null
}

$baselineStatusBefore = Get-BaselineStatus -ProjectRoot $projectRoot
$activeScenarioBefore = Get-ScenarioStatus -ProjectRoot $projectRoot
if ($Refresh -and $null -ne $activeScenarioBefore) {
throw 'Exit or reset the active run before refresh.'
}

$runningVmCount = @($baselineStatusBefore.MachineStatus | Where-Object { [string]$_.StateHuman -eq 'running' }).Count
$canUseExistingBaseline = (
-not $Refresh -and
-not $NoProvision -and
-not $NormalStart -and
-not $HeadlessClient -and
-not $RealisticMode -and
@('ready', 'available') -contains [string]$baselineStatusBefore.State
)
if ($canUseExistingBaseline) {
if ($runningVmCount -eq 2) {
Format-BaselineAlreadyRunningOutput -MachineStatus @($baselineStatusBefore.MachineStatus) -ScenarioStatus $activeScenarioBefore | Write-Output
}
else {
Format-ResumeOutput -ResumeResult (Resume-LabEnvironment -ProjectRoot $projectRoot) | Write-Output
}
break
}

Write-Output ''
Get-RhcsaAsciiBanner | Write-Output
Write-Output ''
$previousWorkflowPreference = $script:ShowWorkflowStatus
$script:ShowWorkflowStatus = $true
Initialize-RhcsaSimulatorRuntime -ShowWorkflowStatus:$script:ShowWorkflowStatus -ForceHostCleanup:$script:ForceHostCleanup
$workflowCompleted = $false
try {
$result = Start-BaselineSession `
-NoProvision:$NoProvision `
-NormalStart:$NormalStart `
-HeadlessClient:$HeadlessClient `
-RealisticMode:$RealisticMode `
-ForceRefresh:$Refresh `
-ProjectRoot $projectRoot
if (-not ($result.PSObject.Properties.Match('AlreadyReady').Count -gt 0 -and [bool]$result.AlreadyReady)) {
Complete-WorkflowProgress -Area 'baseline' -Message 'Complete'
$workflowCompleted = $true
}
}
finally {
if (-not $workflowCompleted) {
Stop-WorkflowProgress -Area 'baseline'
}
$script:ShowWorkflowStatus = $previousWorkflowPreference
Initialize-RhcsaSimulatorRuntime -ShowWorkflowStatus:$script:ShowWorkflowStatus -ForceHostCleanup:$script:ForceHostCleanup
}
if ($result.PSObject.Properties.Match('AlreadyReady').Count -gt 0 -and [bool]$result.AlreadyReady) {
Format-BaselineAlreadyRunningOutput -MachineStatus @((Get-BaselineStatus -ProjectRoot $projectRoot).MachineStatus) -ScenarioStatus (Get-ScenarioStatus -ProjectRoot $projectRoot) | Write-Output
}
else {
Format-BaselineStartOutput -BaselineResult $result -BaselineStatus (Get-BaselineStatus -ProjectRoot $projectRoot) | Write-Output
}
break
}
'baseline/resume' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'resume' | Write-Output
break
}

if ($item) {
throw "Unknown resume argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown resume argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown resume argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown resume argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown resume argument '-Vm'."
}

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown resume argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown resume argument '-Profile'."
}

if ($NoProvision) {
throw "Unknown resume argument '-NoProvision'."
}

if ($NormalStart) {
throw "Unknown resume argument '-NormalStart'."
}

if ($HeadlessClient) {
throw "Unknown resume argument '-HeadlessClient'."
}

if ($RealisticMode) {
throw "Unknown resume argument '-RealisticMode'."
}

if ($Refresh) {
throw "Unknown resume argument '-Refresh'."
}

Format-ResumeOutput -ResumeResult (Resume-LabEnvironment -ProjectRoot $projectRoot) | Write-Output
break
}
'baseline/pause' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'pause' | Write-Output
break
}

if ($item) {
throw "Unknown pause argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown pause argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown pause argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown pause argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown pause argument '-Vm'."
}

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown pause argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown pause argument '-Profile'."
}

$machineStatus = @(Get-VagrantMachineStatus -ProjectRoot $projectRoot)
$createdStatus = @($machineStatus | Where-Object { [string]$_.StateHuman -ne 'not created' })
$runningOrPausedStatus = @($createdStatus | Where-Object { [string]$_.StateHuman -in @('running', 'paused') })
$savedStatus = @($createdStatus | Where-Object { [string]$_.StateHuman -eq 'saved' })
$poweredOffStatus = @($createdStatus | Where-Object { [string]$_.StateHuman -in @('poweroff', 'aborted') })

if ($createdStatus.Count -eq 0) {
Write-Output (Get-UiHeading -Text 'Simulator not built' -StyleName 'Warning')
Format-VmStatusOutput -MachineStatus $machineStatus | Write-Output
}
elseif ($runningOrPausedStatus.Count -eq 0 -and $savedStatus.Count -eq $createdStatus.Count) {
Write-Output (Get-UiHeading -Text 'VMs already paused' -StyleName 'Info')
Format-VmStatusOutput -MachineStatus $machineStatus | Write-Output
}
elseif ($runningOrPausedStatus.Count -eq 0 -and $poweredOffStatus.Count -eq $createdStatus.Count) {
Write-Output (Get-UiHeading -Text 'VMs are powered off' -StyleName 'Info')
Format-VmStatusOutput -MachineStatus $machineStatus | Write-Output
}
else {
Write-Output (Get-UiHeading -Text 'VMs paused' -StyleName 'Success')
Format-VmStatusOutput -MachineStatus (Suspend-LabEnvironment -ProjectRoot $projectRoot) | Write-Output
}
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

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown down argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown down argument '-Profile'."
}

$machineStatus = @(Get-VagrantMachineStatus -ProjectRoot $projectRoot)
$createdStatus = @($machineStatus | Where-Object { [string]$_.StateHuman -ne 'not created' })
$activeStatus = @($createdStatus | Where-Object { [string]$_.StateHuman -notin @('poweroff', 'aborted') })
if ($createdStatus.Count -eq 0) {
Write-Output (Get-UiHeading -Text 'Simulator not built' -StyleName 'Warning')
Format-VmStatusOutput -MachineStatus $machineStatus | Write-Output
break
}
if ($activeStatus.Count -eq 0) {
Write-Output (Get-UiHeading -Text 'VMs already powered off' -StyleName 'Info')
Format-VmStatusOutput -MachineStatus $machineStatus | Write-Output
break
}

$vagrantCommand = Get-VagrantCommandSpec
$vboxManage = Get-VBoxManagePath
foreach ($machineName in @('server', 'client')) {
$current = $machineStatus | Where-Object { $_.Name -eq $machineName } | Select-Object -First 1
if ($null -eq $current) {
continue
}
if ($current.State -in @('not created', 'poweroff', 'aborted')) {
continue
}
if ($current.State -eq 'saved') {
$vmId = Get-OptionalVagrantMachineId -MachineName $machineName -ProjectRoot $projectRoot
if (-not [string]::IsNullOrWhiteSpace($vmId)) {
Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('discardstate', $vmId) -FailureMessage "Failed to discard saved state for $machineName." -IgnoreExitCode -SuppressOutput -WaitForProcessTree
}
continue
}
Invoke-ExternalCommand -FilePath $vagrantCommand.FilePath -ArgumentList @($vagrantCommand.PrefixArgumentList + @('halt', $machineName, '-f')) -FailureMessage "Failed to halt $machineName." -IgnoreExitCode -SuppressOutput -WaitForProcessTree
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

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown repo argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown repo argument '-Profile'."
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

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown destroy argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown destroy argument '-Profile'."
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

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown list argument '-Profile'."
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

Format-ScenarioCatalogOutput -ScenarioCatalog @(Get-ScenarioCatalog -ProjectRoot $projectRoot -Track $effectiveTrack) -Filter $listFilter -Track $effectiveTrack | Write-Output
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

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown start argument '-Profile'."
}

if (-not $PSBoundParameters.ContainsKey('Id') -or [string]::IsNullOrWhiteSpace($Id)) {
throw 'Scenario start requires -Id <scenario-id>.'
}

$result = Start-ScenarioRun -ScenarioId $Id -Mode $Mode -Track $effectiveTrack -ProjectRoot $projectRoot
Format-ScenarioStartOutput -ScenarioResult $result | Write-Output
break
}
'scenario/exit-run' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'exit-run' | Write-Output
break
}

if ($item) {
throw "Unknown exit-run argument '$item'."
}

if ($remainingItem.Count -gt 0) {
throw "Unknown exit-run argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown exit-run argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown exit-run argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown exit-run argument '-Vm'."
}

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown exit-run argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown exit-run argument '-Profile'."
}

$activeScenario = Get-ScenarioStatus -ProjectRoot $projectRoot
if ($null -eq $activeScenario) {
$leaveResult = [PSCustomObject]@{ Status = 'none'; ScenarioId = '' }
}
else {
Clear-ActiveRunState -ProjectRoot $projectRoot
$leaveResult = [PSCustomObject]@{ Status = 'exited'; ScenarioId = [string]$activeScenario.ScenarioId }
}

Format-LeaveOutput -LeaveResult $leaveResult | Write-Output
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

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown reset argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown reset argument '-Profile'."
}

$status = Get-ScenarioStatus -ProjectRoot $projectRoot
if ($null -eq $status) {
throw 'No active run found. Start one first with .\RHCSA.ps1 start -Id <scenario-id> -Mode <Lab|Exam>.'
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

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown status argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown status argument '-Profile'."
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

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown check argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown check argument '-Profile'."
}

$result = Invoke-ScenarioExerciseCheck -ScenarioId $Id -ProjectRoot $projectRoot
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

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown status argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown status argument '-Profile'."
}

Format-DashboardOutput -BaselineStatus (Get-BaselineStatus -ProjectRoot $projectRoot) -ScenarioStatus (Get-ScenarioStatus -ProjectRoot $projectRoot) -ProjectProfile $effectiveProfile -ScenarioTrack $effectiveTrack | Write-Output
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

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown vms argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown vms argument '-Profile'."
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

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown ssh argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown ssh argument '-Profile'."
}

$targetVm = if ($PSBoundParameters.ContainsKey('Vm')) { $Vm } else { $item }
if ([string]::IsNullOrWhiteSpace($targetVm)) {
$targetVm = 'client'
}

if ($PSBoundParameters.ContainsKey('Vm') -and $item -and $item -ne $Vm) {
throw "Conflicting ssh targets '$item' and '$Vm'."
}

if ($null -eq (Get-ScenarioStatus -ProjectRoot $projectRoot)) {
throw 'No active lab or exam. Start a lab or exam before opening SSH.'
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

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown ssh-config argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown ssh-config argument '-Profile'."
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

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown tui argument '-Profile'."
}

Open-RhcsaTui -ProjectRoot $projectRoot -Track $effectiveTrack
break
}
'config/profile' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'profile' | Write-Output
break
}

if ($remainingItem.Count -gt 0) {
throw "Unknown profile argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown profile argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown profile argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown profile argument '-Vm'."
}

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown profile argument '-Track'."
}

$requestedProfile = if ($PSBoundParameters.ContainsKey('Profile')) { $Profile } else { $item }
if ([string]::IsNullOrWhiteSpace($requestedProfile)) {
$profileContent = @(
(Format-UiKeyValue -Key 'Profile' -Value (Format-StyledText -Text $effectiveProfile.ToUpperInvariant() -StyleName 'Accent')),
(Format-UiKeyValue -Key 'Track' -Value (Format-StyledText -Text $effectiveTrack.ToUpperInvariant() -StyleName 'Accent')),
(Format-UiKeyValue -Key 'Config' -Value (Format-StyledText -Text (Get-ProjectProfilePath -ProjectRoot $projectRoot) -StyleName 'Muted'))
)
Format-UiPanel -Title 'Profile' -TitleStyle 'Info' -ContentLines $profileContent | Write-Output
break
}

$activeScenario = Get-ScenarioStatus -ProjectRoot $projectRoot
if ($null -ne $activeScenario) {
Clear-ActiveRunState -ProjectRoot $projectRoot
Write-Output (Format-StyledText -Text ('Cleared active run for {0} before switching profile.' -f $activeScenario.ScenarioId) -StyleName 'Warning')
}

$updatedProfile = Set-ProjectProfile -Profile $requestedProfile -ProjectRoot $projectRoot
$profileContent = @(
(Format-UiKeyValue -Key 'Profile' -Value (Format-StyledText -Text $updatedProfile.Profile.ToUpperInvariant() -StyleName 'Accent')),
(Format-UiKeyValue -Key 'Track' -Value (Format-StyledText -Text $updatedProfile.Track.ToUpperInvariant() -StyleName 'Accent')),
(Format-UiKeyValue -Key 'Config' -Value (Format-StyledText -Text $updatedProfile.Path -StyleName 'Muted'))
)
Format-UiPanel -Title 'Profile Updated' -TitleStyle 'Success' -ContentLines $profileContent | Write-Output
break
}
'config/timer' {
if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
Get-HelpOutput -Scope 'timer' | Write-Output
break
}

if ($remainingItem.Count -gt 0) {
throw "Unknown timer argument '$($remainingItem[0])'."
}

if ($PSBoundParameters.ContainsKey('Id')) {
throw "Unknown timer argument '-Id'."
}

if ($PSBoundParameters.ContainsKey('Mode')) {
throw "Unknown timer argument '-Mode'."
}

if ($PSBoundParameters.ContainsKey('Vm')) {
throw "Unknown timer argument '-Vm'."
}

if ($PSBoundParameters.ContainsKey('Track')) {
throw "Unknown timer argument '-Track'."
}

if ($PSBoundParameters.ContainsKey('Profile')) {
throw "Unknown timer argument '-Profile'."
}

$timerCommand = if ([string]::IsNullOrWhiteSpace($item)) { 'status' } else { $item.ToLowerInvariant() }
switch ($timerCommand) {
'status' {
$enabled = Get-ProjectTimerDefault -ProjectRoot $projectRoot
$stateText = if ($enabled) { Format-StyledText -Text 'on' -StyleName 'Success' } else { Format-StyledText -Text 'off' -StyleName 'Muted' }
$timerContent = @(
(Format-UiKeyValue -Key 'Default' -Value $stateText)
)
Format-UiPanel -Title 'Timer' -TitleStyle 'Info' -ContentLines $timerContent | Write-Output
break
}
'on' {
Set-ProjectTimerDefault -Enabled $true -ProjectRoot $projectRoot | Out-Null
$timerContent = @(
(Format-UiKeyValue -Key 'Default' -Value (Format-StyledText -Text 'on' -StyleName 'Success'))
)
Format-UiPanel -Title 'Timer Updated' -TitleStyle 'Success' -ContentLines $timerContent | Write-Output
break
}
'off' {
Set-ProjectTimerDefault -Enabled $false -ProjectRoot $projectRoot | Out-Null
$timerContent = @(
(Format-UiKeyValue -Key 'Default' -Value (Format-StyledText -Text 'off' -StyleName 'Muted'))
)
Format-UiPanel -Title 'Timer Updated' -TitleStyle 'Success' -ContentLines $timerContent | Write-Output
break
}
default {
throw "Unknown timer command '$timerCommand'."
}
}
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

if ($area -eq 'config') {
throw 'Unknown config command. Run .\RHCSA.ps1 help for usage.'
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
