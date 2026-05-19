Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-NonEmptyTokenList {
param(
[string[]]$Value = @()
)

return @($Value | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Resolve-CommandRoute {
param(
[string]$AreaValue,
[string]$CommandValue,
[string]$ItemValue,
[string[]]$ExtraValue = @()
)

$resolvedArea = if ([string]::IsNullOrWhiteSpace($AreaValue)) { '' } else { $AreaValue.ToLowerInvariant() }
$tokens = @(Get-NonEmptyTokenList -Value @($CommandValue, $ItemValue) + @($ExtraValue))

switch ($resolvedArea) {
'help' {
if ($tokens.Count -gt 0 -and $tokens[0].ToLowerInvariant() -in @('up', 'resume', 'pause', 'down', 'destroy', 'list', 'start', 'exit-run', 'leave', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'profile', 'timer', 'completion')) {
$nextArea = $tokens[0].ToLowerInvariant()
if ($nextArea -eq 'leave') {
$nextArea = 'exit-run'
}
$remaining = if ($tokens.Count -gt 1) { @($tokens[1..($tokens.Count - 1)]) } else { @() }
return [PSCustomObject]@{ Area = 'help'; Command = $nextArea; Item = $null; Extra = $remaining; Legacy = $false }
}
}
'up' { return [PSCustomObject]@{ Area = 'baseline'; Command = 'up'; Item = $null; Extra = $tokens; Legacy = $false } }
'resume' { return [PSCustomObject]@{ Area = 'baseline'; Command = 'resume'; Item = $null; Extra = $tokens; Legacy = $false } }
'pause' { return [PSCustomObject]@{ Area = 'baseline'; Command = 'pause'; Item = $null; Extra = $tokens; Legacy = $false } }
'down' { return [PSCustomObject]@{ Area = 'baseline'; Command = 'down'; Item = $null; Extra = $tokens; Legacy = $false } }
'destroy' { return [PSCustomObject]@{ Area = 'baseline'; Command = 'destroy'; Item = $null; Extra = $tokens; Legacy = $false } }
'list' {
$listItem = if ($tokens.Count -gt 0) { $tokens[0] } else { $null }
$remaining = if ($tokens.Count -gt 1) { @($tokens[1..($tokens.Count - 1)]) } else { @() }
return [PSCustomObject]@{ Area = 'scenario'; Command = 'list'; Item = $listItem; Extra = $remaining; Legacy = $false }
}
'start' { return [PSCustomObject]@{ Area = 'scenario'; Command = 'start'; Item = $null; Extra = $tokens; Legacy = $false } }
'exit-run' { return [PSCustomObject]@{ Area = 'scenario'; Command = 'exit-run'; Item = $null; Extra = $tokens; Legacy = $false } }
'leave' { return [PSCustomObject]@{ Area = 'scenario'; Command = 'exit-run'; Item = $null; Extra = $tokens; Legacy = $false } }
'repo' { return [PSCustomObject]@{ Area = 'baseline'; Command = 'repo'; Item = $null; Extra = $tokens; Legacy = $false } }
'reset' { return [PSCustomObject]@{ Area = 'scenario'; Command = 'reset'; Item = $null; Extra = $tokens; Legacy = $false } }
'status' { return [PSCustomObject]@{ Area = 'dashboard'; Command = 'status'; Item = $null; Extra = $tokens; Legacy = $false } }
'check' { return [PSCustomObject]@{ Area = 'scenario'; Command = 'check'; Item = $null; Extra = $tokens; Legacy = $false } }
'vms' { return [PSCustomObject]@{ Area = 'vm'; Command = 'status'; Item = $null; Extra = $tokens; Legacy = $false } }
'ssh' {
$targetVm = if ($tokens.Count -gt 0) { $tokens[0] } else { 'client' }
$remaining = if ($tokens.Count -gt 1) { @($tokens[1..($tokens.Count - 1)]) } else { @() }
return [PSCustomObject]@{ Area = 'vm'; Command = 'ssh'; Item = $targetVm; Extra = $remaining; Legacy = $false }
}
'ssh-config' {
$targetVm = if ($tokens.Count -gt 0) { $tokens[0] } else { 'client' }
$remaining = if ($tokens.Count -gt 1) { @($tokens[1..($tokens.Count - 1)]) } else { @() }
return [PSCustomObject]@{ Area = 'vm'; Command = 'ssh-config'; Item = $targetVm; Extra = $remaining; Legacy = $false }
}
'tui' { return [PSCustomObject]@{ Area = 'app'; Command = 'tui'; Item = $null; Extra = $tokens; Legacy = $false } }
'profile' {
$profileItem = if ($tokens.Count -gt 0) { $tokens[0] } else { $null }
$remaining = if ($tokens.Count -gt 1) { @($tokens[1..($tokens.Count - 1)]) } else { @() }
return [PSCustomObject]@{ Area = 'config'; Command = 'profile'; Item = $profileItem; Extra = $remaining; Legacy = $false }
}
'timer' {
$timerItem = if ($tokens.Count -gt 0) { $tokens[0] } else { $null }
$remaining = if ($tokens.Count -gt 1) { @($tokens[1..($tokens.Count - 1)]) } else { @() }
return [PSCustomObject]@{ Area = 'config'; Command = 'timer'; Item = $timerItem; Extra = $remaining; Legacy = $false }
}
'completion' {
$subcommand = if ($tokens.Count -gt 0) { $tokens[0] } else { $null }
$remaining = if ($tokens.Count -gt 1) { @($tokens[1..($tokens.Count - 1)]) } else { @() }
return [PSCustomObject]@{ Area = 'completion'; Command = 'manage'; Item = $subcommand; Extra = $remaining; Legacy = $false }
}
}

return [PSCustomObject]@{
Area = $resolvedArea
Command = if ([string]::IsNullOrWhiteSpace($CommandValue)) { '' } else { $CommandValue.ToLowerInvariant() }
Item = if ([string]::IsNullOrWhiteSpace($ItemValue)) { $null } else { $ItemValue }
Extra = @(Get-NonEmptyTokenList -Value $ExtraValue)
Legacy = ($resolvedArea -in @('baseline', 'scenario', 'vm'))
}
}

Export-ModuleMember -Function *
