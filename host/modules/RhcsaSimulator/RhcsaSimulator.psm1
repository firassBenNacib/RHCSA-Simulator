Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../FileHelpers/FileHelpers.psd1')
Import-Module (Join-Path $PSScriptRoot '../UI/UI.psd1')
Import-Module (Join-Path $PSScriptRoot '../LabState/LabState.psd1')
Import-Module (Join-Path $PSScriptRoot '../Scenarios/Scenarios.psd1')
Import-Module (Join-Path $PSScriptRoot '../Toolchain/Toolchain.psd1')
Import-Module (Join-Path $PSScriptRoot '../VMControl/VMControl.psd1')
Import-Module (Join-Path $PSScriptRoot '../Checks/Checks.psd1')

$script:RuntimeShowWorkflowStatus = $false
$script:RuntimeForceHostCleanup = $false

function Initialize-RhcsaSimulatorRuntime {
[CmdletBinding()]
param(
[bool]$ShowWorkflowStatus = $false,
[bool]$ForceHostCleanup = $false
)

$script:RuntimeShowWorkflowStatus = $ShowWorkflowStatus
$script:RuntimeForceHostCleanup = $ForceHostCleanup
Set-ShowWorkflowStatus -Enabled $ShowWorkflowStatus
Set-ForceHostCleanup -Enabled $ForceHostCleanup
}

function Get-RhcsaSimulatorRuntimeOption {
[CmdletBinding()]
param()

[PSCustomObject]@{
ShowWorkflowStatus = [bool]$script:RuntimeShowWorkflowStatus
ForceHostCleanup = [bool]$script:RuntimeForceHostCleanup
}
}

Export-ModuleMember -Function *
