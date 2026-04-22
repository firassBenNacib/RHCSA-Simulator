Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '../../simulator_common.ps1')

function Initialize-RhcsaSimulatorRuntime {
    [CmdletBinding()]
    param(
        [bool]$ShowWorkflowStatus = $false,
        [bool]$ForceHostCleanup = $false
    )

    $script:ShowWorkflowStatus = $ShowWorkflowStatus
    $script:ForceHostCleanup = $ForceHostCleanup
}

function Get-RhcsaSimulatorRuntimeOption {
    [CmdletBinding()]
    param()

    [PSCustomObject]@{
        ShowWorkflowStatus = ((Test-Path variable:script:ShowWorkflowStatus) -and [bool]$script:ShowWorkflowStatus)
        ForceHostCleanup = ((Test-Path variable:script:ForceHostCleanup) -and [bool]$script:ForceHostCleanup)
    }
}

Export-ModuleMember -Function *
