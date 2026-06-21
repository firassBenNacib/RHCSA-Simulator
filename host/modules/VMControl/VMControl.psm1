Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../FileHelpers/FileHelpers.psd1')
Import-Module (Join-Path $PSScriptRoot '../UI/UI.psd1')
Import-Module (Join-Path $PSScriptRoot '../LabState/LabState.psd1')
Import-Module (Join-Path $PSScriptRoot '../Toolchain/Toolchain.psd1')

$script:ForceHostCleanup = $false
$script:VmSshConnectionCache = @{}
$script:VmControlModuleParts = @(
    'VMControl.Repo.ps1'
    'VMControl.Preflight.ps1'
    'VMControl.Ssh.ps1'
    'VMControl.Cleanup.ps1'
    'VMControl.Scenario.ps1'
)
foreach ($modulePart in $script:VmControlModuleParts) {
    . (Join-Path $PSScriptRoot $modulePart)
}

function Set-ForceHostCleanup {
[CmdletBinding(SupportsShouldProcess)]
param(
[bool]$Enabled
)

if (-not $PSCmdlet.ShouldProcess('force host cleanup option', 'Set')) {
return
}

$script:ForceHostCleanup = $Enabled
}

function Invoke-VagrantCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,
        [string]$FailureMessage = 'Vagrant command failed.',
        [string]$RetryArea = 'baseline',
        [string]$RetryMessage = 'Retrying the Vagrant command after a transient SSH/provider failure',
        [int]$RetryCount = 2,
        [int]$RetryDelaySeconds = 15,
        [int]$TimeoutSeconds = 900,
        [switch]$IgnoreExitCode,
        [switch]$PassThruExitCode,
        [switch]$SuppressOutput
    )

    $vagrantCommand = Get-VagrantCommandSpec
    $vagrantPath = [string]$vagrantCommand.FilePath
    for ($attempt = 1; $attempt -le ($RetryCount + 1); $attempt++) {
        $result = Invoke-VagrantExternalCapture -FilePath $vagrantPath -ArgumentList @($vagrantCommand.PrefixArgumentList + $ArgumentList) -TimeoutSeconds $TimeoutSeconds
        Wait-VagrantClientQuiescence | Out-Null

        $reportedFailure = ($result.ExitCode -ne 0) -or (Test-VagrantCommandReportedFailure -StdOut $result.StdOut -StdErr $result.StdErr)
        if (-not $reportedFailure) {
            if ($PassThruExitCode) {
                return 0
            }

            return
        }

        # Do not retry if we killed the process ourselves via our timeout.
        # Only retry on Vagrant-reported transient SSH/provider failures.
        $combinedForTimeoutCheck = ((@($result.StdOut) + @($result.StdErr)) -join "`n")
        $isOurTimeout = $combinedForTimeoutCheck -match 'Command timed out after \d+ seconds'
        $canRetry = $attempt -le $RetryCount -and -not $isOurTimeout -and (Test-TransientVagrantFailure -StdOut $result.StdOut -StdErr $result.StdErr)
        if ($canRetry) {
            Write-WorkflowStatus -Area $RetryArea -Message $RetryMessage
            Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
            continue
        }

        if (-not $SuppressOutput) {
            Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
        }

        if (-not $IgnoreExitCode) {
            $commandText = @($vagrantPath) + @($vagrantCommand.PrefixArgumentList) + $ArgumentList
            throw "$FailureMessage Command: $($commandText -join ' ') Exit code: $($result.ExitCode)"
        }

        if ($PassThruExitCode) {
            return $result.ExitCode
        }

        return
    }
}

function Invoke-VagrantExternalCapture {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,
        [int]$TimeoutSeconds = 900
    )

    $previousRepoCacheMode = [string]$env:RHCSA_ALLOW_REPO_CACHE
    $env:RHCSA_ALLOW_REPO_CACHE = '1'
    try {
        return Invoke-ExternalCapture -FilePath $FilePath -ArgumentList $ArgumentList -TimeoutSeconds $TimeoutSeconds
    }
    finally {
        if ([string]::IsNullOrEmpty($previousRepoCacheMode)) {
            Remove-Item Env:\RHCSA_ALLOW_REPO_CACHE -ErrorAction SilentlyContinue
        }
        else {
            $env:RHCSA_ALLOW_REPO_CACHE = $previousRepoCacheMode
        }
    }
}

function Get-VagrantUpTimeoutSeconds {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $override = [string]$env:RHCSA_VAGRANT_UP_TIMEOUT
    if (-not [string]::IsNullOrWhiteSpace($override)) {
        $parsed = 0
        if ([int]::TryParse($override.Trim(), [ref]$parsed) -and $parsed -gt 0) {
            return $parsed
        }
    }

    $projectProfile = Get-ProjectProfile -ProjectRoot $ProjectRoot
    if ($projectProfile -eq 'rhel10') {
        try {
            $boxName = Get-ProjectVagrantBoxName -ProjectRoot $ProjectRoot -Profile $projectProfile
            if (-not (Test-VagrantBoxInstalled -BoxName $boxName -ProjectRoot $ProjectRoot)) {
                return 1800
            }
        }
        catch {
            return 1800
        }

        return 1800
    }

    return 300
}

function ConvertTo-CompactWorkflowMessage {
    param(
        [AllowEmptyString()]
        [string]$Message,
        [int]$MaxLength = 240
    )

    $compactMessage = ([string]$Message -replace '[\r\n]+', ' ' -replace '\s+', ' ').Trim()
    if ($compactMessage.Length -le $MaxLength) {
        return $compactMessage
    }

    return ('{0}...' -f $compactMessage.Substring(0, [Math]::Max($MaxLength - 3, 0)))
}

function Test-VagrantCommandReportedFailure {
    [OutputType([bool])]
    param(
        [string[]]$StdOut = @(),
        [string[]]$StdErr = @()
    )

    $combinedOutput = ((@($StdOut) + @($StdErr)) -join "`n")
    if ([string]::IsNullOrWhiteSpace($combinedOutput)) {
        return $false
    }

    $failurePatterns = @(
        'This is an error\.',
        'Vagrant encountered an error',
        'An error occurred',
        'The executable ''.+'' Vagrant is trying to run was not found',
        'No usable default provider could be found',
        'command responded with a non-zero exit status',
        'error occurred while executing `VBoxManage',
        'could not be found in the %PATH% variable'
    )

    foreach ($pattern in $failurePatterns) {
        if ($combinedOutput -match $pattern) {
            return $true
        }
    }

    return $false
}

function Invoke-VagrantMachineStep {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [switch]$Provision,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$RetryArea = 'baseline'
    )

    $upArgumentList = @('up', $MachineName, '--no-provision', '--no-color')
    $upFailureMessage = "'vagrant up $MachineName --no-provision' failed."
    $upRetryMessage = if ($Provision) {
        "Retrying $MachineName startup before provisioning after a transient SSH/provider failure"
    }
    else {
        "Retrying $MachineName startup after a transient SSH/provider failure"
    }

    Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
    $upTimeoutSeconds = Get-VagrantUpTimeoutSeconds -ProjectRoot $ProjectRoot
    $provisionReadinessMaxAttempts = if ((Get-ProjectProfile -ProjectRoot $ProjectRoot) -eq 'rhel10') { 48 } else { 12 }

    $existingStatus = @(
        Get-VagrantMachineStatus -ProjectRoot $ProjectRoot |
            Where-Object { [string]$_.Name -eq $MachineName } |
            Select-Object -First 1
    )
    if ($existingStatus.Count -gt 0 -and [string]$existingStatus[0].StateHuman -eq 'running') {
        Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName startup; VM is already running, waiting for SSH readiness"
        $registeredMachineId = Wait-VagrantMachineRegistration -MachineName $MachineName -ProjectRoot $ProjectRoot -MaxAttempts 45 -DelaySeconds 2
        if ([string]::IsNullOrWhiteSpace($registeredMachineId)) {
            throw "Vagrant machine '$MachineName' did not finish local registration after startup recovery."
        }
        Wait-VagrantGuestSshReady `
            -MachineName $MachineName `
            -ProjectRoot $ProjectRoot `
            -Area $RetryArea `
            -MaxAttempts 60 `
            -DelaySeconds 5 `
            -RequiredSuccesses 1 `
            -StabilizationDelaySeconds 3
        if ($Provision) {
            Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName startup; resuming provisioning"
            Invoke-BaselineGuestProvisioning -MachineName $MachineName -ProjectRoot $ProjectRoot -RetryArea $RetryArea
        }
        return
    }

    $optionalVmId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    if (-not [string]::IsNullOrWhiteSpace($optionalVmId)) {
        $vboxState = $null
        try {
            $vboxState = Get-VBoxMachineState -VmId $optionalVmId -VBoxManagePath (Get-VBoxManagePath)
        }
        catch {
            $vboxState = $null
        }

        if ([string]$vboxState -eq 'running') {
            Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName startup; VM is already running, waiting for SSH readiness"
            Wait-VagrantGuestSshReady `
                -MachineName $MachineName `
                -ProjectRoot $ProjectRoot `
                -Area $RetryArea `
                -MaxAttempts 60 `
                -DelaySeconds 5 `
                -RequiredSuccesses 1 `
                -StabilizationDelaySeconds 3
            if ($Provision) {
                Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName startup; resuming provisioning"
                Invoke-BaselineGuestProvisioning -MachineName $MachineName -ProjectRoot $ProjectRoot -RetryArea $RetryArea
            }
            return
        }
    }

    try {
        Invoke-VagrantCommand -ArgumentList $upArgumentList -FailureMessage $upFailureMessage -RetryArea $RetryArea -RetryMessage $upRetryMessage -TimeoutSeconds $upTimeoutSeconds -SuppressOutput
        $registeredMachineId = Wait-VagrantMachineRegistration -MachineName $MachineName -ProjectRoot $ProjectRoot -MaxAttempts 45 -DelaySeconds 2
        if ([string]::IsNullOrWhiteSpace($registeredMachineId)) {
            throw "Vagrant machine '$MachineName' did not finish local registration after startup."
        }
        Assert-VagrantMachineReadyForWorkflow -MachineName $MachineName -ProjectRoot $ProjectRoot
        if ($Provision) {
            Confirm-VagrantGuestProvisionReadiness `
                -MachineName $MachineName `
                -ProjectRoot $ProjectRoot `
                -Area $RetryArea `
                -MaxAttempts $provisionReadinessMaxAttempts `
                -DelaySeconds 5 `
                -RequiredSuccesses 1 `
                -StabilizationDelaySeconds 3 `
                -AllowStartupRetry
            Invoke-BaselineGuestProvisioning -MachineName $MachineName -ProjectRoot $ProjectRoot -RetryArea $RetryArea
        }
        return
    }
    catch {
        $machineStatus = @(Get-VagrantMachineStatus -ProjectRoot $ProjectRoot | Where-Object { [string]$_.Name -eq $MachineName } | Select-Object -First 1)
        if ($machineStatus.Count -eq 0) {
            throw
        }

        $stateHuman = [string]$machineStatus[0].StateHuman
        switch ($stateHuman) {
            'running' {
                Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName startup; VM is already running, waiting for SSH readiness"
                $registeredMachineId = Wait-VagrantMachineRegistration -MachineName $MachineName -ProjectRoot $ProjectRoot -MaxAttempts 45 -DelaySeconds 2
                if ([string]::IsNullOrWhiteSpace($registeredMachineId)) {
                    throw "Vagrant machine '$MachineName' did not finish local registration after startup recovery."
                }
                Assert-VagrantMachineReadyForWorkflow -MachineName $MachineName -ProjectRoot $ProjectRoot
                # The VM is running but vagrant up was killed before SSH was ready.
                # Just wait for SSH without re-entering the full startup flow.
                Wait-VagrantGuestSshReady `
                    -MachineName $MachineName `
                    -ProjectRoot $ProjectRoot `
                    -Area $RetryArea `
                    -MaxAttempts 60 `
                    -DelaySeconds 5 `
                    -RequiredSuccesses 1 `
                    -StabilizationDelaySeconds 3
                if (-not $Provision) {
                    return
                }

                Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName startup; resuming provisioning"
                Invoke-BaselineGuestProvisioning -MachineName $MachineName -ProjectRoot $ProjectRoot -RetryArea $RetryArea
                return
            }
            'poweroff' {
                Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName import; resuming VM startup"
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed after partial import recovery." -RetryArea $RetryArea -RetryMessage "Retrying $MachineName startup after a transient SSH/provider failure" -TimeoutSeconds $upTimeoutSeconds -SuppressOutput
                $registeredMachineId = Wait-VagrantMachineRegistration -MachineName $MachineName -ProjectRoot $ProjectRoot -MaxAttempts 45 -DelaySeconds 2
                if ([string]::IsNullOrWhiteSpace($registeredMachineId)) {
                    throw "Vagrant machine '$MachineName' did not finish local registration after startup recovery."
                }
                Assert-VagrantMachineReadyForWorkflow -MachineName $MachineName -ProjectRoot $ProjectRoot
                if ($Provision) {
                    Confirm-VagrantGuestProvisionReadiness `
                        -MachineName $MachineName `
                        -ProjectRoot $ProjectRoot `
                        -Area $RetryArea `
                        -MaxAttempts $provisionReadinessMaxAttempts `
                        -DelaySeconds 5 `
                        -RequiredSuccesses 1 `
                        -StabilizationDelaySeconds 3 `
                        -AllowStartupRetry
                    Invoke-BaselineGuestProvisioning -MachineName $MachineName -ProjectRoot $ProjectRoot -RetryArea $RetryArea
                }
                return
            }
            'saved' {
                Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName import; resuming VM startup"
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed after partial import recovery." -RetryArea $RetryArea -RetryMessage "Retrying $MachineName startup after a transient SSH/provider failure" -TimeoutSeconds $upTimeoutSeconds -SuppressOutput
                $registeredMachineId = Wait-VagrantMachineRegistration -MachineName $MachineName -ProjectRoot $ProjectRoot -MaxAttempts 45 -DelaySeconds 2
                if ([string]::IsNullOrWhiteSpace($registeredMachineId)) {
                    throw "Vagrant machine '$MachineName' did not finish local registration after startup recovery."
                }
                Assert-VagrantMachineReadyForWorkflow -MachineName $MachineName -ProjectRoot $ProjectRoot
                if ($Provision) {
                    Confirm-VagrantGuestProvisionReadiness `
                        -MachineName $MachineName `
                        -ProjectRoot $ProjectRoot `
                        -Area $RetryArea `
                        -MaxAttempts $provisionReadinessMaxAttempts `
                        -DelaySeconds 5 `
                        -RequiredSuccesses 1 `
                        -StabilizationDelaySeconds 3 `
                        -AllowStartupRetry
                    Invoke-BaselineGuestProvisioning -MachineName $MachineName -ProjectRoot $ProjectRoot -RetryArea $RetryArea
                }
                return
            }
            'paused' {
                Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName import; resuming VM startup"
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed after partial import recovery." -RetryArea $RetryArea -RetryMessage "Retrying $MachineName startup after a transient SSH/provider failure" -TimeoutSeconds $upTimeoutSeconds -SuppressOutput
                $registeredMachineId = Wait-VagrantMachineRegistration -MachineName $MachineName -ProjectRoot $ProjectRoot -MaxAttempts 45 -DelaySeconds 2
                if ([string]::IsNullOrWhiteSpace($registeredMachineId)) {
                    throw "Vagrant machine '$MachineName' did not finish local registration after startup recovery."
                }
                Assert-VagrantMachineReadyForWorkflow -MachineName $MachineName -ProjectRoot $ProjectRoot
                if ($Provision) {
                    Confirm-VagrantGuestProvisionReadiness `
                        -MachineName $MachineName `
                        -ProjectRoot $ProjectRoot `
                        -Area $RetryArea `
                        -MaxAttempts $provisionReadinessMaxAttempts `
                        -DelaySeconds 5 `
                        -RequiredSuccesses 1 `
                        -StabilizationDelaySeconds 3 `
                        -AllowStartupRetry
                    Invoke-BaselineGuestProvisioning -MachineName $MachineName -ProjectRoot $ProjectRoot -RetryArea $RetryArea
                }
                return
            }
        }

        throw
    }
}


function Get-VagrantMachineStatus {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$TimeoutSeconds = 30
    )

    if ((Get-ProjectProfile -ProjectRoot $ProjectRoot) -eq 'rhel10') {
        $fallback = @(Get-VirtualBoxMachineStatusFallback -ProjectRoot $ProjectRoot)
        if ($fallback.Count -gt 0) {
            return $fallback
        }
    }

    $vagrantCommand = Get-VagrantCommandSpec

    Push-Location $ProjectRoot
    try {
        $result = Invoke-ExternalCapture -FilePath $vagrantCommand.FilePath -ArgumentList @($vagrantCommand.PrefixArgumentList + @('status', '--machine-readable')) -TimeoutSeconds $TimeoutSeconds
    }
    finally {
        Pop-Location
    }

    if ($result.ExitCode -ne 0 -or (Test-VagrantCommandReportedFailure -StdOut $result.StdOut -StdErr $result.StdErr)) {
        $fallback = @(Get-VirtualBoxMachineStatusFallback -ProjectRoot $ProjectRoot)
        if ($fallback.Count -gt 0) {
            return $fallback
        }

        Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
        throw "Failed to read local Vagrant machine status."
    }

    $statusMap = @{}
    foreach ($line in @($result.StdOut)) {
        $text = [string]$line
        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        $parts = $text -split ',', 4
        if ($parts.Count -ne 4) {
            continue
        }

        $machineName = [string]$parts[1]
        $eventName = [string]$parts[2]
        $eventValue = [string]$parts[3]

        if ([string]::IsNullOrWhiteSpace($machineName)) {
            continue
        }

        if (-not $statusMap.ContainsKey($machineName)) {
            $statusMap[$machineName] = [ordered]@{
                Name = $machineName
                State = 'not_created'
                StateHuman = 'not created'
                Provider = 'virtualbox'
            }
        }

        switch ($eventName) {
            'state' { $statusMap[$machineName].State = $eventValue }
            'state-human-short' { $statusMap[$machineName].StateHuman = $eventValue }
            'provider-name' { $statusMap[$machineName].Provider = $eventValue }
        }
    }

    $machineStatus = foreach ($machineName in @('server', 'client')) {
        if ($statusMap.ContainsKey($machineName)) {
            [PSCustomObject]$statusMap[$machineName]
        }
        else {
            [PSCustomObject]@{
                Name = $machineName
                State = 'not_created'
                StateHuman = 'not created'
                Provider = 'virtualbox'
            }
        }
    }

    return @($machineStatus)
}

function Get-VagrantMachineBoxName {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $boxMetaPath = Join-Path $ProjectRoot ".vagrant\machines\$MachineName\virtualbox\box_meta"
    if (-not (Test-Path -LiteralPath $boxMetaPath -PathType Leaf)) {
        return ''
    }

    try {
        $metadata = (Get-Content -LiteralPath $boxMetaPath -Raw) | ConvertFrom-Json
        return [string]$metadata.name
    }
    catch {
        return ''
    }
}

function ConvertFrom-VirtualBoxState {
    param(
        [string]$State
    )

    $normalized = ([string]$State).Trim().ToLowerInvariant()
    switch ($normalized) {
        'running' { return [PSCustomObject]@{ State = 'running'; StateHuman = 'running' } }
        'poweroff' { return [PSCustomObject]@{ State = 'poweroff'; StateHuman = 'poweroff' } }
        'saved' { return [PSCustomObject]@{ State = 'saved'; StateHuman = 'saved' } }
        'paused' { return [PSCustomObject]@{ State = 'paused'; StateHuman = 'paused' } }
        'aborted' { return [PSCustomObject]@{ State = 'aborted'; StateHuman = 'aborted' } }
        default { return [PSCustomObject]@{ State = $normalized; StateHuman = if ([string]::IsNullOrWhiteSpace($normalized)) { 'unknown' } else { $normalized } } }
    }
}

function Get-VirtualBoxMachineStatusFallback {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$TimeoutSeconds = 5
    )

    $vboxManage = Get-OptionalVBoxManagePath
    $fallbackStatus = @()

    foreach ($machineName in @('server', 'client')) {
        $machineId = Get-OptionalVagrantMachineId -MachineName $machineName -ProjectRoot $ProjectRoot
        if ([string]::IsNullOrWhiteSpace($machineId)) {
            $fallbackStatus += [PSCustomObject]@{
                Name = $machineName
                State = 'not_created'
                StateHuman = 'not created'
                Provider = 'virtualbox'
            }
            continue
        }

        if (-not $vboxManage) {
            $fallbackStatus += [PSCustomObject]@{
                Name = $machineName
                State = 'unknown'
                StateHuman = 'unknown'
                Provider = 'virtualbox'
            }
            continue
        }

        $result = Invoke-ExternalCapture -FilePath $vboxManage -ArgumentList @('showvminfo', $machineId, '--machinereadable') -TimeoutSeconds $TimeoutSeconds
        if ($result.ExitCode -ne 0) {
            $fallbackStatus += [PSCustomObject]@{
                Name = $machineName
                State = 'unknown'
                StateHuman = 'unknown'
                Provider = 'virtualbox'
            }
            continue
        }

        $vmStateLine = @($result.StdOut | Where-Object { [string]$_ -match '^VMState=' } | Select-Object -First 1)
        $vmStateValue = if ($vmStateLine.Count -gt 0) {
            ([string]$vmStateLine[0] -replace '^VMState="?([^"]+)"?$', '$1')
        }
        else {
            'unknown'
        }

        $stateInfo = ConvertFrom-VirtualBoxState -State $vmStateValue
        $fallbackStatus += [PSCustomObject]@{
            Name = $machineName
            State = [string]$stateInfo.State
            StateHuman = [string]$stateInfo.StateHuman
            Provider = 'virtualbox'
        }
    }

    return @($fallbackStatus)
}

function Test-GuestBaselineMarker {
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$TimeoutSeconds = 10
    )

    $expectedMarker = 'rhcsa-{0}-baseline-ready' -f (Get-ProjectProfile -ProjectRoot $ProjectRoot)
    $remoteCommand = 'cat /etc/rhcsa/baseline-ready 2>/dev/null || true'
    $launchSpec = $null
    try {
        $launchSpec = Get-VmDirectSshLaunchSpec -MachineName $MachineName -ProjectRoot $ProjectRoot -BatchMode
        $result = Invoke-ExternalCapture -FilePath $launchSpec.SshPath -ArgumentList ($launchSpec.ArgumentList + @($remoteCommand)) -TimeoutSeconds $TimeoutSeconds
        $marker = (@($result.StdOut) | Select-Object -First 1)
        if (([string]$marker).Trim() -eq $expectedMarker) {
            return $true
        }
    }
    catch {
        $null = $_
    }
    finally {
        Remove-VmDirectSshLaunchSpec -LaunchSpec $launchSpec
    }

    try {
        $fallbackResult = Invoke-VagrantVmShellCommandCapture -MachineName $MachineName -Command $remoteCommand -ProjectRoot $ProjectRoot -RetryCount 0
        foreach ($line in @($fallbackResult.StdOut)) {
            $normalized = ([string]$line).Trim() -replace '^(server|client):\s*', ''
            if ($normalized -eq $expectedMarker) {
                return $true
            }
        }
    }
    catch {
        return $false
    }

    return $false
}

function Assert-GuestBaselineMarker {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$MaxAttempts = 3,
        [int]$DelaySeconds = 3
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        if (Test-GuestBaselineMarker -MachineName $MachineName -ProjectRoot $ProjectRoot) {
            return
        }

        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    $projectProfile = Get-ProjectProfile -ProjectRoot $ProjectRoot
    throw "Guest baseline marker is missing or incorrect on $MachineName for profile '$projectProfile'."
}

function Get-GuestPrivateNetworkAddress {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName
    )

    if ($MachineName -eq 'server') {
        return '192.168.122.3'
    }

    return '192.168.122.2'
}

function Set-GuestPrivateNetwork {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $privateAddress = Get-GuestPrivateNetworkAddress -MachineName $MachineName
    $networkScript = @'
set -euo pipefail
private_ip="__RHCSA_PRIVATE_IP__"
default_iface="$(ip route show default 2>/dev/null | awk '{print $5; exit}')"
private_iface="$(nmcli -t -f DEVICE,TYPE dev status | awk -F: -v default_iface="$default_iface" '$2=="ethernet" && $1 != default_iface {print $1; exit}')"
if [ -z "$private_iface" ]; then
  private_iface="$(ip -o link show | awk -F': ' -v default_iface="$default_iface" '$2 != "lo" && $2 != default_iface {print $2; exit}')"
fi
if [ -z "$private_iface" ]; then
  echo "Cannot find the VirtualBox private-network interface." >&2
  exit 1
fi

ip link set "$private_iface" up
ip -4 addr flush dev "$private_iface" || true
ip addr add "${private_ip}/24" dev "$private_iface"

connection_name="System eth1"
connection_uuid="$(cat /proc/sys/kernel/random/uuid)"
connection_file="/etc/NetworkManager/system-connections/${connection_name}.nmconnection"
install -d -m 700 /etc/NetworkManager/system-connections
while IFS=: read -r existing_uuid existing_name; do
  [[ "$existing_name" == "$connection_name" ]] || continue
  nmcli connection delete uuid "$existing_uuid" >/dev/null 2>&1 || true
done < <(nmcli -t -f UUID,NAME connection show 2>/dev/null)
rm -f /etc/NetworkManager/system-connections/rhcsa-private-*.nmconnection
cat > "$connection_file" <<EOF
[connection]
id=${connection_name}
uuid=${connection_uuid}
type=ethernet
interface-name=${private_iface}
autoconnect=true

[ethernet]

[ipv4]
method=manual
address1=${private_ip}/24

[ipv6]
method=disabled
EOF
chmod 600 "$connection_file"
restorecon "$connection_file" >/dev/null 2>&1 || true
nmcli con reload >/dev/null 2>&1 || true
nmcli con up "$connection_name" >/dev/null 2>&1 || nmcli dev reapply "$private_iface" >/dev/null 2>&1 || true
'@ -replace '__RHCSA_PRIVATE_IP__', $privateAddress

    $result = Invoke-VagrantVmShellCommandCapture -MachineName $MachineName -Command $networkScript -ProjectRoot $ProjectRoot -RetryCount 1 -RetryDelaySeconds 3 -SkipConnectivityCheck
    if ([int]$result.ExitCode -ne 0) {
        Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
        throw "Failed to configure $MachineName private network address $privateAddress."
    }
}

function Invoke-BaselineGuestProvisioning {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$RetryArea = 'baseline'
    )

    function Get-OfflineIsoPathForProfile {
        param(
            [string]$ProjectRoot,
            [Alias('Profile')]
            [string]$ProjectProfile
        )

        return Get-RhcsaOfflineIsoPath -ProjectRoot $ProjectRoot -Profile $ProjectProfile -Required
    }

    function Mount-Rhcsa10ServerOfflineIso {
        param(
            [string]$ProjectRoot
        )

        if ((Get-ProjectProfile -ProjectRoot $ProjectRoot) -ne 'rhel10') {
            return
        }

        $vmId = Get-OptionalVagrantMachineId -MachineName 'server' -ProjectRoot $ProjectRoot
        if ([string]::IsNullOrWhiteSpace($vmId)) {
            throw "Vagrant machine 'server' is not registered; cannot attach the offline ISO."
        }

        $isoPath = Get-OfflineIsoPathForProfile -ProjectRoot $ProjectRoot -Profile 'rhel10'
        $vboxManage = Get-VBoxManagePath

        Invoke-ExternalCommand `
            -FilePath $vboxManage `
            -ArgumentList @('storageattach', $vmId, '--storagectl', 'IDE Controller', '--port', '1', '--device', '0', '--type', 'dvddrive', '--medium', $isoPath) `
            -FailureMessage 'Failed to attach the RHCSA10 offline ISO to server.' `
            -SuppressOutput `
            -TimeoutSeconds 30
    }

    $scriptPaths = @(
        (Join-Path $ProjectRoot 'guest/common_setup.sh'),
        (Join-Path $ProjectRoot ("guest/{0}_setup.sh" -f $MachineName))
    )
    $baselineEnvironment = @{
        RHCSA_PROFILE = (Get-ProjectProfile -ProjectRoot $ProjectRoot)
        RHCSA_NODE_NAME = $MachineName
    }
    $directProvisionRetryCount = if ($baselineEnvironment.RHCSA_PROFILE -eq 'rhel10') { 4 } else { 1 }
    $directProvisionRetryDelaySeconds = if ($baselineEnvironment.RHCSA_PROFILE -eq 'rhel10') { 12 } else { 10 }

    try {
        Write-WorkflowStatus -Area $RetryArea -Message "Configuring $MachineName private network"
        Set-GuestPrivateNetwork -MachineName $MachineName -ProjectRoot $ProjectRoot
        if ($MachineName -eq 'server') {
            $profile = Get-ProjectProfile -ProjectRoot $ProjectRoot
            $isoPath = Get-RhcsaOfflineIsoPath -ProjectRoot $ProjectRoot -Profile $profile
            if ([string]::IsNullOrWhiteSpace($isoPath)) {
                Copy-RhcsaRepoCacheToServer -ProjectRoot $ProjectRoot | Out-Null
            }
            else {
                Mount-Rhcsa10ServerOfflineIso -ProjectRoot $ProjectRoot
            }
        }
        foreach ($scriptPath in $scriptPaths) {
            Write-WorkflowStatus -Area $RetryArea -Message ("Running {0} on {1}" -f (Split-Path -Leaf $scriptPath), $MachineName)
            Invoke-VagrantVmScript `
                -MachineName $MachineName `
                -ScriptPath $scriptPath `
                -ProvisionerName '' `
                -ProjectRoot $ProjectRoot `
                -RetryCount $directProvisionRetryCount `
                -RetryDelaySeconds $directProvisionRetryDelaySeconds `
                -TimeoutSeconds 900 `
                -RetryArea $RetryArea `
                -RetryMessage "Retrying direct guest provisioning on $MachineName after a transient SSH failure" `
                -Environment $baselineEnvironment `
                -SkipConnectivityCheck `
                -SkipVagrantFallback | Out-Null
        }
        Assert-GuestBaselineMarker -MachineName $MachineName -ProjectRoot $ProjectRoot
        Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
        return
    }
    catch {
        $fallbackReason = ConvertTo-CompactWorkflowMessage -Message $_.Exception.Message
        if ((Get-ProjectProfile -ProjectRoot $ProjectRoot) -eq 'rhel10') {
            throw "Direct RHCSA10 guest provisioning failed for ${MachineName}: $fallbackReason"
        }

        Write-WorkflowStatus -Area $RetryArea -Message "Falling back to Vagrant guest provisioning for ${MachineName}: $fallbackReason"
    }

    Invoke-VagrantCommand -ArgumentList @('provision', $MachineName, '--no-color') -FailureMessage "'vagrant provision $MachineName' failed after direct guest provisioning fallback." -RetryArea $RetryArea -RetryMessage "Retrying $MachineName provisioning after a transient SSH/provider failure"
    Assert-GuestBaselineMarker -MachineName $MachineName -ProjectRoot $ProjectRoot
    Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
}

function Test-BaselineOfflineRepoHealth {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$RetryCount = 12,
        [int]$RetryDelaySeconds = 5
    )

    $repoCommand = 'curl -fsS http://server/repo/BaseOS/repodata/repomd.xml >/dev/null && curl -fsS http://server/repo/AppStream/repodata/repomd.xml >/dev/null'

    $results = @()
    for ($attempt = 1; $attempt -le [Math]::Max(1, $RetryCount); $attempt++) {
        try {
            $serverResult = Invoke-VagrantVmShellCommandCapture -MachineName 'server' -Command $repoCommand -ProjectRoot $ProjectRoot -RetryCount 0 -SkipConnectivityCheck -SkipVagrantFallback
        }
        catch {
            $serverResult = [PSCustomObject]@{
                ExitCode = 255
                StdOut = @()
                StdErr = @($_.Exception.Message)
            }
        }

        try {
            $clientResult = Invoke-VagrantVmShellCommandCapture -MachineName 'client' -Command $repoCommand -ProjectRoot $ProjectRoot -RetryCount 0 -SkipConnectivityCheck -SkipVagrantFallback
        }
        catch {
            $clientResult = [PSCustomObject]@{
                ExitCode = 255
                StdOut = @()
                StdErr = @($_.Exception.Message)
            }
        }

        $results = @(
            [PSCustomObject]@{
                MachineName = 'server'
                ExitCode = [int]$serverResult.ExitCode
                Passed = ([int]$serverResult.ExitCode -eq 0)
            }
            [PSCustomObject]@{
                MachineName = 'client'
                ExitCode = [int]$clientResult.ExitCode
                Passed = ([int]$clientResult.ExitCode -eq 0)
            }
        )

        $failedMachines = @($results | Where-Object { -not $_.Passed } | ForEach-Object { [string]$_.MachineName })
        if ($failedMachines.Count -eq 0) {
            return [PSCustomObject]@{
                Passed = $true
                FailedMachines = @()
                Results = $results
            }
        }

        if ($attempt -lt $RetryCount) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    $failedMachines = @($results | Where-Object { -not $_.Passed } | ForEach-Object { [string]$_.MachineName })

    return [PSCustomObject]@{
        Passed = ($failedMachines.Count -eq 0)
        FailedMachines = $failedMachines
        Results = $results
    }
}

function Get-VagrantMachineId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $id = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    if ([string]::IsNullOrWhiteSpace($id)) {
        throw "Vagrant machine id file not found for '$MachineName'."
    }

    return $id
}

function Get-OptionalVagrantMachineId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $idFile = Join-Path $ProjectRoot ".vagrant\machines\$MachineName\virtualbox\id"
    if (Test-Path $idFile -PathType Leaf) {
        $id = (Get-Content $idFile -Raw).Trim()
        if (-not [string]::IsNullOrWhiteSpace($id)) {
            return $id
        }
    }

    $projectName = Split-Path -Leaf $ProjectRoot
    $vmNamePrefix = '{0}_{1}_' -f $projectName, $MachineName
    $vboxManage = Get-VBoxManagePath
    foreach ($listTarget in @('runningvms', 'vms')) {
        $result = Invoke-ExternalCapture -FilePath $vboxManage -ArgumentList @('list', $listTarget) -TimeoutSeconds 15
        if ($result.ExitCode -ne 0) {
            continue
        }

        foreach ($line in $result.StdOut) {
            if ($line -match '^"([^"]+)"\s+\{([0-9A-Fa-f-]+)\}$') {
                $vmName = [string]$matches[1]
                $vmId = [string]$matches[2]
                if (-not $vmName.StartsWith($vmNamePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    continue
                }

                $idDirectory = Split-Path -Parent $idFile
                if (-not (Test-Path -LiteralPath $idDirectory)) {
                    New-Item -ItemType Directory -Path $idDirectory -Force | Out-Null
                }

                Set-Utf8NoBomFile -Path $idFile -Content $vmId
                return $vmId
            }
        }
    }

    return $null
}

function Wait-VagrantMachineRegistration {
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$MaxAttempts = 30,
        [int]$DelaySeconds = 2
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $machineId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
        if (-not [string]::IsNullOrWhiteSpace($machineId)) {
            return $machineId
        }

        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    return $null
}

function Assert-VagrantMachineReadyForWorkflow {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $machineId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    if ([string]::IsNullOrWhiteSpace($machineId)) {
        throw "Vagrant machine '$MachineName' has no registered machine id."
    }

    $machineStatus = @(
        Get-VagrantMachineStatus -ProjectRoot $ProjectRoot |
            Where-Object { [string]$_.Name -eq $MachineName } |
            Select-Object -First 1
    )
    if ($machineStatus.Count -eq 0) {
        throw "Vagrant machine '$MachineName' has no readable local Vagrant status."
    }

    if ([string]$machineStatus[0].StateHuman -eq 'not created') {
        throw "Vagrant machine '$MachineName' is still reported as not created after startup."
    }
}

function Get-VBoxSnapshotCatalog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VmId,
        [string]$VBoxManagePath = (Get-VBoxManagePath)
    )

    $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @('snapshot', $VmId, 'list', '--machinereadable')
    if ($result.ExitCode -ne 0 -or -not $result.StdOut) {
        return @()
    }

    $snapshotNames = @()
    foreach ($line in $result.StdOut) {
        if ($line -match '^SnapshotName.*?="(.+)"$') {
            $snapshotNames += $matches[1]
        }
    }

    return $snapshotNames
}

function Wait-VBoxMachineReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VmId,
        [string]$VBoxManagePath = (Get-VBoxManagePath),
        [int]$TimeoutSeconds = 60
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @('showvminfo', $VmId, '--machinereadable')
        if ($result.ExitCode -eq 0) {
            return
        }

        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)

    throw "VirtualBox VM '$VmId' remained locked for more than $TimeoutSeconds seconds."
}

function Get-VBoxMachineState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VmId,
        [string]$VBoxManagePath = (Get-VBoxManagePath)
    )

    $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @('showvminfo', $VmId, '--machinereadable')
    if ($result.ExitCode -ne 0) {
        return $null
    }

    foreach ($line in $result.StdOut) {
        if ($line -match '^VMState="(.+)"$') {
            return [string]$matches[1]
        }
    }

    return $null
}

function Wait-VBoxMachineState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VmId,
        [Parameter(Mandatory = $true)]
        [string[]]$DesiredState,
        [string]$VBoxManagePath = (Get-VBoxManagePath),
        [int]$TimeoutSeconds = 90
    )

    $expected = @($DesiredState | ForEach-Object { $_.ToLowerInvariant() })
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $lastState = $null

    do {
        $state = Get-VBoxMachineState -VmId $VmId -VBoxManagePath $VBoxManagePath
        if ($null -ne $state) {
            $lastState = [string]$state
            if ($lastState.ToLowerInvariant() -in $expected) {
                return $lastState
            }
        }

        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)

    $expectedLabel = $DesiredState -join ', '
    if ($lastState) {
        throw "VirtualBox VM '$VmId' did not reach state '$expectedLabel' within $TimeoutSeconds seconds. Last state: $lastState."
    }

    throw "VirtualBox VM '$VmId' did not reach state '$expectedLabel' within $TimeoutSeconds seconds."
}

function Suspend-LabEnvironment {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vboxManage = Get-VBoxManagePath
    foreach ($machineName in @('server', 'client')) {
        $vmId = Get-OptionalVagrantMachineId -MachineName $machineName -ProjectRoot $ProjectRoot
        if ([string]::IsNullOrWhiteSpace($vmId)) {
            continue
        }

        $state = Get-VBoxMachineState -VmId $vmId -VBoxManagePath $vboxManage
        if ([string]::IsNullOrWhiteSpace([string]$state)) {
            continue
        }

        $state = [string]$state
        if ($state.ToLowerInvariant() -in @('poweroff', 'saved', 'aborted')) {
            continue
        }

        if ($PSCmdlet.ShouldProcess($machineName, 'Save VirtualBox VM state')) {
            Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('controlvm', $vmId, 'savestate') -FailureMessage "Failed to save state for $machineName." -SuppressOutput -TimeoutSeconds 120
            Wait-VBoxMachineState -VmId $vmId -DesiredState @('saved') -VBoxManagePath $vboxManage -TimeoutSeconds 120 | Out-Null
        }
    }

    Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot
    Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot
    return (Get-VagrantMachineStatus -ProjectRoot $ProjectRoot)
}

function Stop-VBoxMachineForSnapshot {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$VBoxManagePath = (Get-VBoxManagePath),
        [switch]$FastPowerOff
    )

    if (-not $PSCmdlet.ShouldProcess($MachineName, 'Stop VM before snapshot operation')) {
        return
    }

    $vmId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    if ($null -eq $vmId) {
        return
    }

    $state = Get-VBoxMachineState -VmId $vmId -VBoxManagePath $VBoxManagePath
    if ($state -and $state.ToLowerInvariant() -notin @('poweroff', 'saved', 'aborted')) {
        if ($FastPowerOff.IsPresent) {
            Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList @('controlvm', $vmId, 'poweroff') -FailureMessage "Failed to power off $MachineName before snapshot restore." -IgnoreExitCode -SuppressOutput -TimeoutSeconds 45
            Wait-VBoxMachineState -VmId $vmId -DesiredState @('poweroff', 'saved', 'aborted') -VBoxManagePath $VBoxManagePath -TimeoutSeconds 45 | Out-Null
            Start-Sleep -Seconds 1
            return
        }

        $shutdownSpec = $null
        try {
            $shutdownSpec = Get-VmDirectSshLaunchSpec -MachineName $MachineName -ProjectRoot $ProjectRoot -BatchMode
            Invoke-ExternalCapture -FilePath $shutdownSpec.SshPath -ArgumentList ($shutdownSpec.ArgumentList + @('sudo -n systemctl poweroff || sudo -n shutdown -h now || sudo -n poweroff')) -TimeoutSeconds 20 | Out-Null
        }
        catch {
        }
        finally {
            Remove-VmDirectSshLaunchSpec -LaunchSpec $shutdownSpec
        }

        try {
            Wait-VBoxMachineState -VmId $vmId -DesiredState @('poweroff', 'saved', 'aborted') -VBoxManagePath $VBoxManagePath -TimeoutSeconds 60 | Out-Null
            Start-Sleep -Seconds 2
            return
        }
        catch {
        }

        Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList @('controlvm', $vmId, 'acpipowerbutton') -FailureMessage "Failed to request ACPI power off for $MachineName." -IgnoreExitCode -SuppressOutput -TimeoutSeconds 15
    }

    try {
        Wait-VBoxMachineState -VmId $vmId -DesiredState @('poweroff', 'saved', 'aborted') -VBoxManagePath $VBoxManagePath -TimeoutSeconds 90 | Out-Null
    }
    catch {
        $vagrantCommand = Get-VagrantCommandSpec
        Invoke-ExternalCommand -FilePath $vagrantCommand.FilePath -ArgumentList @($vagrantCommand.PrefixArgumentList + @('halt', $MachineName, '-f')) -FailureMessage "Failed to halt $MachineName." -IgnoreExitCode -SuppressOutput -TimeoutSeconds 30
        Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList @('controlvm', $vmId, 'poweroff') -FailureMessage "Failed to force power off $MachineName." -IgnoreExitCode -SuppressOutput -TimeoutSeconds 60
        Wait-VBoxMachineState -VmId $vmId -DesiredState @('poweroff', 'saved', 'aborted') -VBoxManagePath $VBoxManagePath -TimeoutSeconds 45 | Out-Null
    }

    Start-Sleep -Seconds 2
}

function Invoke-VBoxSnapshotCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VmId,
        [Parameter(Mandatory = $true)]
        [string[]]$SnapshotArgumentList,
        [Parameter(Mandatory = $true)]
        [string]$FailureMessage,
        [string]$VBoxManagePath = (Get-VBoxManagePath)
    )

    $lastError = $null
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        Wait-VBoxMachineReady -VmId $VmId -VBoxManagePath $VBoxManagePath

        try {
            Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList (@('snapshot', $VmId) + $SnapshotArgumentList) -FailureMessage $FailureMessage -TimeoutSeconds 300
            return
        }
        catch {
            $lastError = $_
            if ($attempt -ge 5) {
                throw
            }

            Start-Sleep -Seconds ([Math]::Min(2 * $attempt, 10))
        }
    }

    if ($null -ne $lastError) {
        throw $lastError
    }
}

function Test-BaseSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vmId = Get-VagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    $state = Get-BaseSnapshotState -ProjectRoot $ProjectRoot
    if ($null -ne $state -and [string]$state.snapshot_name -eq 'base-clean') {
        $machineState = $state.machines.PSObject.Properties[$MachineName]
        if ($null -ne $machineState -and [string]$machineState.Value.vm_id -eq $vmId) {
            return $true
        }
    }

    return ('base-clean' -in (Get-VBoxSnapshotCatalog -VmId $vmId))
}

function Get-RequiredBaseSnapshotMode {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    if (Test-Rhel10SavedSnapshotAllowed -ProjectRoot $ProjectRoot) {
        return 'saved'
    }

    return 'poweroff'
}

function Get-Rhel10SavedSnapshotDisablePath {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    return (Join-Path (Get-LabStateRoot -ProjectRoot $ProjectRoot) 'rhel10-saved-snapshot-disabled')
}

function Test-Rhel10SavedSnapshotAllowed {
    [OutputType([bool])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    if ((Get-ProjectProfile -ProjectRoot $ProjectRoot) -ne 'rhel10') {
        return $false
    }

    if ($env:RHCSA_ENABLE_RHEL10_SAVED_SNAPSHOT -match '^(1|true|yes|on)$') {
        return $true
    }

    return $false
}

function Disable-Rhel10SavedSnapshotForHost {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$Reason = 'VirtualBox saved-state restore failed.'
    )

    if ((Get-ProjectProfile -ProjectRoot $ProjectRoot) -ne 'rhel10') {
        return
    }

    Initialize-LabStateLayout -ProjectRoot $ProjectRoot | Out-Null
    Set-Utf8NoBomFile -Path (Get-Rhel10SavedSnapshotDisablePath -ProjectRoot $ProjectRoot) -Content @"
disabled_at=$((Get-Date).ToString('o'))
reason=$Reason
"@
}

function Test-BaseSnapshotModeReady {
    [OutputType([bool])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $requiredMode = Get-RequiredBaseSnapshotMode -ProjectRoot $ProjectRoot
    $state = Get-BaseSnapshotState -ProjectRoot $ProjectRoot
    if ($null -eq $state -or [string]$state.snapshot_name -ne 'base-clean') {
        return $false
    }

    $stateModeProperty = $state.PSObject.Properties['snapshot_mode']
    $stateMode = if ($null -eq $stateModeProperty -or [string]::IsNullOrWhiteSpace([string]$stateModeProperty.Value)) {
        'poweroff'
    }
    else {
        [string]$stateModeProperty.Value
    }

    return ($stateMode -eq $requiredMode)
}

function Get-LiveCleanBaselineStatePath {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    return (Join-Path (Get-LabStateRoot -ProjectRoot $ProjectRoot) 'live-clean-baseline.json')
}

function Clear-LiveCleanBaselineState {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $path = Get-LiveCleanBaselineStatePath -ProjectRoot $ProjectRoot
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Remove-Item -LiteralPath $path -Force
    }
}

function Set-LiveCleanBaselineState {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    Initialize-LabStateLayout -ProjectRoot $ProjectRoot | Out-Null
    $baseState = Get-BaseSnapshotState -ProjectRoot $ProjectRoot
    if ($null -eq $baseState -or [string]$baseState.snapshot_name -ne 'base-clean') {
        Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
        return
    }

    $state = [ordered]@{
        profile = Get-ProjectProfile -ProjectRoot $ProjectRoot
        snapshot_name = 'base-clean'
        snapshot_created_at = [string]$baseState.created_at
        created_at = (Get-Date).ToString('o')
        machines = [ordered]@{}
    }

    foreach ($machine in @('server', 'client')) {
        $machineState = $baseState.machines.PSObject.Properties[$machine]
        if ($null -eq $machineState -or [string]::IsNullOrWhiteSpace([string]$machineState.Value.vm_id)) {
            Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
            return
        }

        $state.machines[$machine] = [ordered]@{
            vm_id = [string]$machineState.Value.vm_id
        }
    }

    Set-Utf8NoBomFile -Path (Get-LiveCleanBaselineStatePath -ProjectRoot $ProjectRoot) -Content ($state | ConvertTo-Json -Depth 10)
}

function Test-LiveCleanBaselineAvailable {
    [OutputType([bool])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string[]]$MachineNames = @('client')
    )

    $path = Get-LiveCleanBaselineStatePath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return $false
    }

    try {
        $state = (Get-Content -LiteralPath $path -Raw) | ConvertFrom-Json
    }
    catch {
        Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
        return $false
    }

    if ([string]$state.profile -ne (Get-ProjectProfile -ProjectRoot $ProjectRoot) -or [string]$state.snapshot_name -ne 'base-clean') {
        Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
        return $false
    }

    $baseState = Get-BaseSnapshotState -ProjectRoot $ProjectRoot
    if ($null -eq $baseState -or [string]$baseState.snapshot_name -ne 'base-clean' -or [string]$baseState.created_at -ne [string]$state.snapshot_created_at) {
        Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
        return $false
    }

    $vboxManage = Get-VBoxManagePath
    $targetMachines = @($MachineNames | Where-Object { $_ -in @('server', 'client') } | Select-Object -Unique)
    if ($targetMachines.Count -eq 0) {
        $targetMachines = @('client')
    }

    foreach ($machine in $targetMachines) {
        $recordedMachine = $state.machines.PSObject.Properties[$machine]
        if ($null -eq $recordedMachine) {
            Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
            return $false
        }

        $currentVmId = Get-OptionalVagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
        if ([string]::IsNullOrWhiteSpace($currentVmId) -or [string]$recordedMachine.Value.vm_id -ne $currentVmId) {
            Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
            return $false
        }

        $baseMachine = $baseState.machines.PSObject.Properties[$machine]
        if ($null -eq $baseMachine -or [string]$baseMachine.Value.vm_id -ne $currentVmId) {
            Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
            return $false
        }

        $vmState = Get-VBoxMachineState -VmId $currentVmId -VBoxManagePath $vboxManage
        if ([string]$vmState -ne 'running') {
            return $false
        }

        if (-not (Test-VmBatchSshReady -MachineName $machine -ProjectRoot $ProjectRoot -TimeoutSeconds 10)) {
            return $false
        }
    }

    return $true
}

function Get-BaselineStatus {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $machineStatus = @(Get-VagrantMachineStatus -ProjectRoot $ProjectRoot)
    $machineNames = @('server', 'client')
    $snapshotReady = @{}
    $boxCompatible = @{}
    $expectedBoxName = Get-ProjectVagrantBoxName -ProjectRoot $ProjectRoot
    $allCreatedMachinesUseCurrentProfile = $true

    foreach ($machineName in $machineNames) {
        $snapshotReady[$machineName] = $false
        $boxCompatible[$machineName] = $true
        $idFile = Join-Path $ProjectRoot ".vagrant\machines\$machineName\virtualbox\id"
        if (-not (Test-Path $idFile -PathType Leaf)) {
            continue
        }

        $actualBoxName = Get-VagrantMachineBoxName -MachineName $machineName -ProjectRoot $ProjectRoot
        $machineCurrentStatus = @($machineStatus | Where-Object { [string]$_.Name -eq $machineName } | Select-Object -First 1)
        $machineRunning = ($machineCurrentStatus.Count -gt 0 -and [string]$machineCurrentStatus[0].StateHuman -eq 'running')
        $missingBoxMetaButGuestMatches = (
            [string]::IsNullOrWhiteSpace($actualBoxName) -and
            $machineRunning -and
            (Test-GuestBaselineMarker -MachineName $machineName -ProjectRoot $ProjectRoot)
        )
        if ((-not $missingBoxMetaButGuestMatches) -and ([string]::IsNullOrWhiteSpace($actualBoxName) -or [string]$actualBoxName -ne [string]$expectedBoxName)) {
            $boxCompatible[$machineName] = $false
            $allCreatedMachinesUseCurrentProfile = $false
        }

        try {
            $snapshotReady[$machineName] = [bool](Test-BaseSnapshot -MachineName $machineName -ProjectRoot $ProjectRoot)
        }
        catch {
            $snapshotReady[$machineName] = $false
        }
    }

    $runningCount = @($machineStatus | Where-Object { [string]$_.StateHuman -eq 'running' }).Count
    $createdCount = @($machineStatus | Where-Object { [string]$_.StateHuman -ne 'not created' }).Count
    $snapshotsReady = ($snapshotReady['server'] -and $snapshotReady['client'])

    $state = 'missing'
    $stateText = 'not built'
    if ($createdCount -eq 0) {
        $state = 'missing'
        $stateText = 'not built'
    }
    elseif (-not $allCreatedMachinesUseCurrentProfile) {
        $state = 'incomplete'
        $stateText = 'profile mismatch'
    }
    elseif ($snapshotsReady -and $runningCount -eq $machineNames.Count) {
        $state = 'ready'
        $stateText = 'ready'
    }
    elseif ($snapshotsReady) {
        $state = 'available'
        $stateText = 'available'
    }
    else {
        $state = 'incomplete'
        $stateText = 'incomplete'
    }

    return [PSCustomObject]@{
        State = $state
        StateText = $stateText
        SnapshotsReady = $snapshotsReady
        MachineStatus = $machineStatus
        SnapshotReady = [PSCustomObject]@{
            Server = $snapshotReady['server']
            Client = $snapshotReady['client']
        }
        BoxCompatible = [PSCustomObject]@{
            Server = $boxCompatible['server']
            Client = $boxCompatible['client']
        }
    }
}

function Test-LabMachinesInVBoxState {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$DesiredState,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vboxManage = Get-VBoxManagePath
    $expected = @($DesiredState | ForEach-Object { $_.ToLowerInvariant() })
    foreach ($machine in @('server', 'client')) {
        $vmId = Get-OptionalVagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
        if ([string]::IsNullOrWhiteSpace($vmId)) {
            return $false
        }

        $state = Get-VBoxMachineState -VmId $vmId -VBoxManagePath $vboxManage
        if ([string]::IsNullOrWhiteSpace([string]$state) -or ([string]$state).ToLowerInvariant() -notin $expected) {
            return $false
        }
    }

    return $true
}

function Resume-SavedLabEnvironment {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vboxManage = Get-VBoxManagePath
    foreach ($machine in @('server', 'client')) {
        $vmId = Get-VagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
        Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('startvm', $vmId, '--type', 'headless') -FailureMessage "Failed to resume $machine from saved state." -SuppressOutput
    }

    Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot
    Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @('server', 'client')
    foreach ($machine in @('server', 'client')) {
        Wait-VagrantGuestSshReady -MachineName $machine -ProjectRoot $ProjectRoot -Area 'baseline' -MaxAttempts 60 -DelaySeconds 5 -RequiredSuccesses 1 -StabilizationDelaySeconds 3
    }
}

function Resume-LabEnvironment {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $baselineStatus = Get-BaselineStatus -ProjectRoot $ProjectRoot
    if ([string]$baselineStatus.State -in @('missing', 'incomplete')) {
        return [PSCustomObject]@{
            Status = 'not-built'
            MachineStatus = @($baselineStatus.MachineStatus)
        }
    }

    $machineStatus = @(Get-VagrantMachineStatus -ProjectRoot $ProjectRoot)
    $runningCount = @($machineStatus | Where-Object { [string]$_.StateHuman -eq 'running' }).Count
    if ($runningCount -eq 2) {
        Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot
        Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @('server', 'client')
        return [PSCustomObject]@{
            Status = 'already-running'
            MachineStatus = @($machineStatus)
        }
    }

    if (-not $PSCmdlet.ShouldProcess($ProjectRoot, 'Resume simulator VMs')) {
        return [PSCustomObject]@{
            Status = 'skipped'
            MachineStatus = @($machineStatus)
        }
    }

    $vboxManage = Get-VBoxManagePath
    foreach ($machine in @('server', 'client')) {
        $vmId = Get-OptionalVagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
        if ([string]::IsNullOrWhiteSpace($vmId)) {
            return [PSCustomObject]@{
                Status = 'not-built'
                MachineStatus = @(Get-VagrantMachineStatus -ProjectRoot $ProjectRoot)
            }
        }

        $state = Get-VBoxMachineState -VmId $vmId -VBoxManagePath $vboxManage
        $state = ([string]$state).ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($state)) {
            throw "Unable to read VirtualBox state for $machine."
        }

        switch ($state) {
            'running' { }
            'paused' {
                Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('controlvm', $vmId, 'resume') -FailureMessage "Failed to resume paused $machine VM." -SuppressOutput
            }
            { $_ -in @('poweroff', 'saved', 'aborted') } {
                Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('startvm', $vmId, '--type', 'headless') -FailureMessage "Failed to resume $machine VM." -SuppressOutput
            }
            default {
                throw "Cannot resume $machine from VirtualBox state '$state'."
            }
        }
    }

    Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot
    Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @('server', 'client')
    foreach ($machine in @('server', 'client')) {
        $vmId = Get-VagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
        Wait-VBoxMachineState -VmId $vmId -DesiredState @('running') -VBoxManagePath $vboxManage -TimeoutSeconds 90 | Out-Null
        Wait-VagrantGuestSshReady -MachineName $machine -ProjectRoot $ProjectRoot -Area 'baseline' -MaxAttempts 60 -DelaySeconds 5 -RequiredSuccesses 1 -StabilizationDelaySeconds 3
    }

    if ($null -eq (Get-ActiveRunState -ProjectRoot $ProjectRoot) -and [bool]$baselineStatus.SnapshotsReady) {
        Set-LiveCleanBaselineState -ProjectRoot $ProjectRoot
    }

    return [PSCustomObject]@{
        Status = 'resumed'
        MachineStatus = @(Get-VagrantMachineStatus -ProjectRoot $ProjectRoot)
    }
}

function Enable-Rhel10SelinuxBeforeBaselineSnapshot {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    if ((Get-ProjectProfile -ProjectRoot $ProjectRoot) -ne 'rhel10') {
        return
    }

    $configureCommand = @'
set -e
if [ -f /etc/selinux/config ]; then
  sed -ri 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
  grep -q '^SELINUXTYPE=' /etc/selinux/config || echo 'SELINUXTYPE=targeted' >> /etc/selinux/config
fi
if command -v grubby >/dev/null 2>&1; then
  grubby --update-kernel=ALL --remove-args="selinux=0 enforcing=0 enforcing=1" >/dev/null 2>&1 || true
  grubby --update-kernel=ALL --args="selinux=1 enforcing=0" >/dev/null 2>&1 || true
fi
current="$(getenforce 2>/dev/null || echo unknown)"
if [ "$current" = "Disabled" ]; then
  echo reboot-required
else
  echo no-reboot
fi
'@

    $needsReboot = $false
    foreach ($machine in @('server', 'client')) {
        $result = Invoke-VagrantVmShellCommandCapture -MachineName $machine -Command $configureCommand -ProjectRoot $ProjectRoot -RetryCount 1
        if ($result.ExitCode -ne 0) {
            Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
            throw "Failed to prepare SELinux boot policy on $machine."
        }

        if (((@($result.StdOut) + @($result.StdErr)) -join "`n") -match 'reboot-required') {
            $needsReboot = $true
        }
    }

    if ($needsReboot) {
        Write-WorkflowStatus -Area 'baseline' -Message 'Preparing system policy' -Index 7
        $vboxManage = Get-VBoxManagePath
        foreach ($machine in @('server', 'client')) {
            Invoke-VagrantVmShellCommandCapture -MachineName $machine -Command 'sync' -ProjectRoot $ProjectRoot -RetryCount 0 | Out-Null
            $vmId = Get-VagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
            Invoke-ExternalCommand `
                -FilePath $vboxManage `
                -ArgumentList @('controlvm', $vmId, 'reset') `
                -FailureMessage "Failed to restart $machine after preparing RHCSA10 system policy." `
                -SuppressOutput `
                -TimeoutSeconds 30
        }

        Start-Sleep -Seconds 15
        Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @('server', 'client')
        foreach ($machine in @('server', 'client')) {
            Confirm-BaselineGuestReadiness -MachineName $machine -ProjectRoot $ProjectRoot -Area 'baseline' -MaxAttempts 60 -DelaySeconds 5 -RequiredSuccesses 1 -StabilizationDelaySeconds 3 -Rhel10BootResetAttempt 12
        }
    }

$verifyCommand = @'
set -e
mode="$(getenforce 2>/dev/null || echo Disabled)"
if [ "$mode" = "Disabled" ]; then
  echo "SELinux is disabled" >&2
  exit 1
fi

if command -v restorecon >/dev/null 2>&1; then
  for path in \
    /usr/sbin/sshd \
    /etc/ssh \
    /var/www \
    /var/log \
    /home \
    /root \
    /opt \
    /etc/systemd \
    /usr/lib/systemd \
    /var/lib/containers
  do
    [ -e "$path" ] && restorecon -RF "$path" >/dev/null 2>&1 || true
  done
fi

if command -v restorecon >/dev/null 2>&1; then
  restorecon -RF /usr/sbin/sshd /etc/ssh /var/www /var/log /home /root /opt /etc/systemd /usr/lib/systemd /var/lib/containers >/dev/null 2>&1 || true
fi

if ls -Zd /usr/sbin/sshd /etc/ssh/sshd_config /var/www/html 2>/dev/null | grep -q unlabeled_t; then
  echo "SELinux relabel did not complete" >&2
  exit 1
fi
if [ -f /etc/selinux/config ]; then
  sed -ri 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
fi
if command -v grubby >/dev/null 2>&1; then
  grubby --update-kernel=ALL --remove-args="selinux=0 enforcing=1" >/dev/null 2>&1 || true
  grubby --update-kernel=ALL --args="selinux=1 enforcing=0" >/dev/null 2>&1 || true
fi
setenforce 0 >/dev/null 2>&1 || true
systemctl restart httpd >/dev/null 2>&1 || true
systemctl restart nfs-server chronyd firewalld crond atd tuned >/dev/null 2>&1 || true
getenforce
'@

    foreach ($machine in @('server', 'client')) {
        $result = Invoke-VagrantVmShellCommandCapture -MachineName $machine -Command $verifyCommand -ProjectRoot $ProjectRoot -RetryCount 1
        if ($result.ExitCode -ne 0) {
            Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
            throw "SELinux did not become available on $machine. Run .\RHCSA.ps1 destroy and then .\RHCSA.ps1 up."
        }
    }

    Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @('server', 'client')
    foreach ($machine in @('server', 'client')) {
        Confirm-BaselineGuestReadiness -MachineName $machine -ProjectRoot $ProjectRoot -Area 'baseline' -MaxAttempts 24 -DelaySeconds 5 -RequiredSuccesses 1 -StabilizationDelaySeconds 2 -Rhel10BootResetAttempt 6
    }
}

function Invoke-BaseSnapshotInitialization {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [switch]$ForceRefresh
    )

    $vboxManage = Get-VBoxManagePath
    $targetMachine = @()
    $machineIdMap = @{}

    foreach ($machine in @('server', 'client')) {
        $machineId = Wait-VagrantMachineRegistration -MachineName $machine -ProjectRoot $ProjectRoot -MaxAttempts 20 -DelaySeconds 2
        if ([string]::IsNullOrWhiteSpace($machineId)) {
            throw "Cannot create base snapshots because '$machine' has not been created yet."
        }
        Assert-VagrantMachineReadyForWorkflow -MachineName $machine -ProjectRoot $ProjectRoot

        $machineIdMap[$machine] = $machineId

        if ($ForceRefresh -or -not (Test-BaseSnapshot -MachineName $machine -ProjectRoot $ProjectRoot)) {
            $targetMachine += $machine
        }
    }

    if ($targetMachine.Count -eq 0) {
        return $false
    }

    # Saved-state snapshots are fast but crash-prone on some Windows hosts.
    # Keep them opt-in and speed up the stable poweroff restore path instead.
    $useSavedStateSnapshots = Test-Rhel10SavedSnapshotAllowed -ProjectRoot $ProjectRoot

    Push-Location $ProjectRoot
    try {
        if ($useSavedStateSnapshots) {
            Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @('server', 'client')
            foreach ($machine in @('server', 'client')) {
                Wait-VagrantGuestSshReady -MachineName $machine -ProjectRoot $ProjectRoot -Area 'baseline' -MaxAttempts 60 -DelaySeconds 5 -RequiredSuccesses 1 -StabilizationDelaySeconds 3
            }

            foreach ($machine in @('server', 'client')) {
                $vmId = [string]$machineIdMap[$machine]
                $currentState = Get-VBoxMachineState -VmId $vmId -VBoxManagePath $vboxManage
                if ($currentState -and $currentState.ToLowerInvariant() -eq 'saved') {
                    continue
                }

                Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('controlvm', $vmId, 'savestate') -FailureMessage "Failed to save $machine before baseline snapshot creation." -SuppressOutput -TimeoutSeconds 90
                Wait-VBoxMachineState -VmId $vmId -DesiredState @('saved') -VBoxManagePath $vboxManage -TimeoutSeconds 90 | Out-Null
            }
        }
        else {
            foreach ($machine in @('server', 'client')) {
                Stop-VBoxMachineForSnapshot -MachineName $machine -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage
            }
        }

        foreach ($machine in $targetMachine) {
            $vmId = [string]$machineIdMap[$machine]
            if (Test-BaseSnapshot -MachineName $machine -ProjectRoot $ProjectRoot) {
                Invoke-VBoxSnapshotCommand -VmId $vmId -SnapshotArgumentList @('delete', 'base-clean') -FailureMessage "Failed to delete existing base-clean snapshot for $machine." -VBoxManagePath $vboxManage
            }
            $snapshotDescription = if ($useSavedStateSnapshots) { 'RHCSA-simulator-saved-state-baseline' } else { 'RHCSA-simulator-clean-baseline' }
            $snapshotArguments = @('take', 'base-clean', "--description=$snapshotDescription")
            Invoke-VBoxSnapshotCommand -VmId $vmId -SnapshotArgumentList $snapshotArguments -FailureMessage "Failed to create base-clean snapshot for $machine." -VBoxManagePath $vboxManage
        }

        foreach ($machine in @('server', 'client')) {
            if (-not $machineIdMap.ContainsKey($machine)) {
                $machineIdMap[$machine] = Get-VagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
            }
        }

        $snapshotMode = if ($useSavedStateSnapshots) { 'saved' } else { 'poweroff' }
        Export-BaseSnapshotState -MachineIdMap $machineIdMap -SnapshotMode $snapshotMode -ProjectRoot $ProjectRoot | Out-Null

        Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @('server', 'client')
        foreach ($machine in @('server', 'client')) {
            $vmId = $machineIdMap[$machine]
            Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('startvm', $vmId, '--type', 'headless') -FailureMessage "Failed to restart $machine after snapshot creation." -SuppressOutput
        }

        foreach ($machine in @('server', 'client')) {
            Confirm-BaselineGuestReadiness -MachineName $machine -ProjectRoot $ProjectRoot -Area 'baseline' -MaxAttempts 60 -DelaySeconds 5 -RequiredSuccesses 1 -StabilizationDelaySeconds 3 -Rhel10BootResetAttempt 12
        }
    }
    finally {
        Pop-Location
    }

    return $true
}

function Invoke-BaseSnapshotRestore {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string[]]$MachineNames = @('server', 'client')
    )

    $vboxManage = Get-VBoxManagePath
    $targetMachines = @($MachineNames | Where-Object { $_ -in @('server', 'client') } | Select-Object -Unique)
    if ($targetMachines.Count -eq 0) {
        $targetMachines = @('server', 'client')
    }

    Write-WorkflowStatus -Area 'scenario' -Message 'Restoring the clean baseline snapshots'

    Push-Location $ProjectRoot
    try {
        foreach ($machine in $targetMachines) {
            Stop-VBoxMachineForSnapshot -MachineName $machine -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage -FastPowerOff
        }

        foreach ($machine in $targetMachines) {
            $vmId = Get-VagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
            $restoreSucceeded = $false
            $lastRestoreError = $null

            for ($attempt = 1; $attempt -le 3 -and -not $restoreSucceeded; $attempt++) {
                try {
                    $currentState = Get-VBoxMachineState -VmId $vmId -VBoxManagePath $vboxManage
                    if ($currentState -and $currentState.ToLowerInvariant() -notin @('poweroff', 'saved', 'aborted')) {
                        Stop-VBoxMachineForSnapshot -MachineName $machine -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage
                    }

                    Invoke-VBoxSnapshotCommand -VmId $vmId -SnapshotArgumentList @('restore', 'base-clean') -FailureMessage "Failed to restore snapshot 'base-clean' for $machine." -VBoxManagePath $vboxManage
                    $restoreSucceeded = $true
                }
                catch {
                    $lastRestoreError = $_
                    $message = $_.ToString()
                    if ($attempt -lt 3 -and $message -match 'VBOX_E_INVALID_VM_STATE|machine state: Running') {
                        Stop-VBoxMachineForSnapshot -MachineName $machine -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage
                        Start-Sleep -Seconds (2 * $attempt)
                        continue
                    }

                    throw
                }
            }

            if (-not $restoreSucceeded -and $null -ne $lastRestoreError) {
                throw $lastRestoreError
            }
        }

        foreach ($machine in $targetMachines) {
            $vmId = Get-VagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
            Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('startvm', $vmId, '--type', 'headless') -FailureMessage "Failed to start $machine after restoring base snapshots." -SuppressOutput -TimeoutSeconds 60
        }

        Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames $targetMachines
        foreach ($machine in $targetMachines) {
            Wait-VagrantGuestSshReady -MachineName $machine -ProjectRoot $ProjectRoot -Area 'scenario' -MaxAttempts 60 -DelaySeconds 5 -RequiredSuccesses 1 -StabilizationDelaySeconds 3
        }
    }
    finally {
        Pop-Location
    }
}

function Wait-VagrantGuestSshReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$Area = 'scenario',
        [int]$MaxAttempts = 18,
        [int]$DelaySeconds = 10,
        [int]$RequiredSuccesses = 1,
        [int]$StabilizationDelaySeconds = 3,
        [int]$Rhel10BootResetAttempt = 36
    )

    $consecutiveSuccesses = 0
    $powerStateStartAttempts = 0
    $missingRegistrationAttempts = 0
    $allowRhel10BootReset = $env:RHCSA_DISABLE_RHEL10_BOOT_RESET -notmatch '^(1|true|yes|on)$'
    $didRhel10BootReset = $false
    # RHEL10 can pause during early boot; callers choose how early a reset is safe.
    $rhel10BootResetAttempt = [Math]::Min([Math]::Max(1, $Rhel10BootResetAttempt), [Math]::Max(1, $MaxAttempts - 2))
    $hostCleanupParameters = @{ ProjectRoot = $ProjectRoot }
    if (Test-ForceHostCleanupEnabled) {
        $hostCleanupParameters['ForceHostCleanup'] = $true
    }

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $vmId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
        if ([string]::IsNullOrWhiteSpace($vmId)) {
            $missingRegistrationAttempts += 1
            if ($missingRegistrationAttempts -ge 2) {
                Invoke-LabHypervisorLockCleanup @hostCleanupParameters | Out-Null
                throw "Vagrant machine '$MachineName' is still reported as not created after startup."
            }
        }
        else {
            $vboxManage = Get-VBoxManagePath
            $vboxState = Get-VBoxMachineState -VmId $vmId -VBoxManagePath $vboxManage
            if ([string]::IsNullOrWhiteSpace([string]$vboxState)) {
                $missingRegistrationAttempts += 1
                if ($missingRegistrationAttempts -ge 2) {
                    Invoke-LabHypervisorLockCleanup @hostCleanupParameters | Out-Null
                    throw "Vagrant machine '$MachineName' is still reported as not created after startup."
                }
            }
            else {
                $missingRegistrationAttempts = 0
            }
            if (
                $vboxState -and
                [string]$vboxState -in @('poweroff', 'saved', 'aborted') -and
                $powerStateStartAttempts -lt 3 -and
                $attempt -lt $MaxAttempts
            ) {
                $powerStateStartAttempts += 1
                Write-WorkflowStatus -Area $Area -Message "Starting $MachineName after post-restore power state '$vboxState'"
                Invoke-ExternalCommand `
                    -FilePath $vboxManage `
                    -ArgumentList @('startvm', $vmId, '--type', 'headless') `
                    -FailureMessage "Failed to start $MachineName while waiting for SSH readiness." `
                    -SuppressOutput `
                    -TimeoutSeconds 60
                Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
                Start-Sleep -Seconds ([Math]::Max(10, $DelaySeconds))
                continue
            }
        }

        if (Test-VmBatchSshReady -MachineName $MachineName -ProjectRoot $ProjectRoot) {
            $consecutiveSuccesses += 1
            if ($consecutiveSuccesses -ge $RequiredSuccesses) {
                Start-Sleep -Seconds $StabilizationDelaySeconds
                return
            }

            Write-WorkflowStatus -Area $Area -Message "Confirmed $MachineName SSH once; waiting for stable readiness ($consecutiveSuccesses/$RequiredSuccesses)"
            Start-Sleep -Seconds $StabilizationDelaySeconds
            continue
        }

        $consecutiveSuccesses = 0

        if (
            -not $didRhel10BootReset -and
            $allowRhel10BootReset -and
            (Get-ProjectProfile -ProjectRoot $ProjectRoot) -eq 'rhel10' -and
            $attempt -ge $rhel10BootResetAttempt -and
            $attempt -lt $MaxAttempts
        ) {
            if (-not [string]::IsNullOrWhiteSpace($vmId)) {
                if ($vboxState -and [string]$vboxState -eq 'running') {
                    Write-WorkflowStatus -Area $Area -Message "Resetting $MachineName after RHCSA10 boot readiness stalled"
                    Invoke-ExternalCommand `
                        -FilePath $vboxManage `
                        -ArgumentList @('controlvm', $vmId, 'reset') `
                        -FailureMessage "Failed to reset $MachineName after RHCSA10 boot readiness stalled." `
                        -SuppressOutput `
                        -TimeoutSeconds 30
                    Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
                    $didRhel10BootReset = $true
                    Start-Sleep -Seconds ([Math]::Max(10, $DelaySeconds))
                    continue
                }
            }
        }

        if ($attempt -lt $MaxAttempts) {
            if ($attempt -eq 1 -or $attempt % 6 -eq 0 -or $attempt -eq ($MaxAttempts - 1)) {
                Write-WorkflowStatus -Area $Area -Message "Waiting for $MachineName SSH readiness before provisioning ($attempt/$MaxAttempts)"
            }
            Start-Sleep -Seconds $DelaySeconds
            continue
        }

        throw "Failed to confirm SSH readiness for $MachineName before provisioning."
    }
}

function Confirm-VagrantGuestProvisionReadiness {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$Area = 'scenario',
        [int]$MaxAttempts = 18,
        [int]$DelaySeconds = 10,
        [int]$RequiredSuccesses = 1,
        [int]$StabilizationDelaySeconds = 3,
        [int]$Rhel10BootResetAttempt = 36,
        [switch]$AllowStartupRetry
    )

    try {
        Wait-VagrantGuestSshReady `
            -MachineName $MachineName `
            -ProjectRoot $ProjectRoot `
            -Area $Area `
            -MaxAttempts $MaxAttempts `
            -DelaySeconds $DelaySeconds `
            -RequiredSuccesses $RequiredSuccesses `
            -StabilizationDelaySeconds $StabilizationDelaySeconds `
            -Rhel10BootResetAttempt $Rhel10BootResetAttempt
        return
    }
    catch {
        if (-not $AllowStartupRetry.IsPresent) {
            throw
        }

        $vboxManage = Get-VBoxManagePath
        $vmId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
        if (-not [string]::IsNullOrWhiteSpace($vmId)) {
            $vboxState = Get-VBoxMachineState -VmId $vmId -VBoxManagePath $vboxManage
            if ($vboxState -and [string]$vboxState -eq 'running') {
                Write-WorkflowStatus -Area $Area -Message "Extending $MachineName SSH readiness wait before provisioning"
                Wait-VagrantGuestSshReady `
                    -MachineName $MachineName `
                    -ProjectRoot $ProjectRoot `
                    -Area $Area `
                    -MaxAttempts ([Math]::Max([int][Math]::Ceiling($MaxAttempts / 2.0), 8)) `
                    -DelaySeconds $DelaySeconds `
                    -RequiredSuccesses $RequiredSuccesses `
                    -StabilizationDelaySeconds $StabilizationDelaySeconds `
                    -Rhel10BootResetAttempt $Rhel10BootResetAttempt
                return
            }

            if ($vboxState -and [string]$vboxState -in @('poweroff', 'saved', 'aborted')) {
                Write-WorkflowStatus -Area $Area -Message "Starting $MachineName after a transient post-restore SSH readiness failure"
                Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('startvm', $vmId, '--type', 'headless') -FailureMessage "Failed to start $MachineName after readiness failure." -SuppressOutput
                Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
                Wait-VagrantGuestSshReady `
                    -MachineName $MachineName `
                    -ProjectRoot $ProjectRoot `
                    -Area $Area `
                    -MaxAttempts ([Math]::Max([int][Math]::Ceiling($MaxAttempts / 2.0), 8)) `
                    -DelaySeconds $DelaySeconds `
                    -RequiredSuccesses $RequiredSuccesses `
                    -StabilizationDelaySeconds $StabilizationDelaySeconds `
                    -Rhel10BootResetAttempt $Rhel10BootResetAttempt
                return
            }
        }

        $machineStatus = @(Get-VagrantMachineStatus -ProjectRoot $ProjectRoot | Where-Object { [string]$_.Name -eq $MachineName } | Select-Object -First 1)
        if ($machineStatus.Count -gt 0 -and [string]$machineStatus[0].StateHuman -eq 'running') {
            Write-WorkflowStatus -Area $Area -Message "Extending $MachineName SSH readiness wait before provisioning"
            Wait-VagrantGuestSshReady `
                -MachineName $MachineName `
                -ProjectRoot $ProjectRoot `
                -Area $Area `
                -MaxAttempts ([Math]::Max([int][Math]::Ceiling($MaxAttempts / 2.0), 8)) `
                -DelaySeconds $DelaySeconds `
                -RequiredSuccesses $RequiredSuccesses `
                -StabilizationDelaySeconds $StabilizationDelaySeconds `
                -Rhel10BootResetAttempt $Rhel10BootResetAttempt
            return
        }

        Write-WorkflowStatus -Area $Area -Message "Retrying $MachineName startup after a transient post-restore SSH readiness failure"
        Invoke-VagrantMachineStep -MachineName $MachineName -ProjectRoot $ProjectRoot -RetryArea $Area
        Wait-VagrantGuestSshReady `
            -MachineName $MachineName `
            -ProjectRoot $ProjectRoot `
            -Area $Area `
            -MaxAttempts ([Math]::Max($MaxAttempts / 2, 8)) `
            -DelaySeconds $DelaySeconds `
            -RequiredSuccesses $RequiredSuccesses `
            -StabilizationDelaySeconds $StabilizationDelaySeconds `
            -Rhel10BootResetAttempt $Rhel10BootResetAttempt
    }
}

function Confirm-BaselineGuestReadiness {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$Area = 'baseline',
        [int]$MaxAttempts = 60,
        [int]$DelaySeconds = 5,
        [int]$RequiredSuccesses = 1,
        [int]$StabilizationDelaySeconds = 3,
        [int]$Rhel10BootResetAttempt = 36
    )

    try {
        Wait-VagrantGuestSshReady `
            -MachineName $MachineName `
            -ProjectRoot $ProjectRoot `
            -Area $Area `
            -MaxAttempts $MaxAttempts `
            -DelaySeconds $DelaySeconds `
            -RequiredSuccesses $RequiredSuccesses `
            -StabilizationDelaySeconds $StabilizationDelaySeconds `
            -Rhel10BootResetAttempt $Rhel10BootResetAttempt
        return
    }
    catch {
        if ((Get-ProjectProfile -ProjectRoot $ProjectRoot) -ne 'rhel10') {
            throw
        }

        $message = $_.ToString()
        if ($message -notmatch 'Failed to confirm SSH readiness|still reported as not created after startup') {
            throw
        }

        Write-WorkflowStatus -Area $Area -Message "Extending $MachineName SSH readiness wait after RHCSA10 startup"
        Confirm-VagrantGuestProvisionReadiness `
            -MachineName $MachineName `
            -ProjectRoot $ProjectRoot `
            -Area $Area `
            -MaxAttempts ([Math]::Max($MaxAttempts, 60)) `
            -DelaySeconds $DelaySeconds `
            -RequiredSuccesses $RequiredSuccesses `
            -StabilizationDelaySeconds $StabilizationDelaySeconds `
            -Rhel10BootResetAttempt $Rhel10BootResetAttempt `
            -AllowStartupRetry
    }
}

function Test-GuestBaselineReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    if (-not (Test-Path (Join-Path $ProjectRoot ".vagrant\machines\$MachineName\virtualbox\id"))) {
        return $false
    }

    return (Test-BaseSnapshot -MachineName $MachineName -ProjectRoot $ProjectRoot)
}

function Repair-BaselineSnapshotIfNeeded {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $machineToCheck = @('server', 'client')

    $missingBaseline = @()
    foreach ($machine in $machineToCheck) {
        if (-not (Test-GuestBaselineReady -MachineName $machine -ProjectRoot $ProjectRoot)) {
            $missingBaseline += $machine
        }
    }

    if ($missingBaseline.Count -eq 0) {
        return $false
    }

    Start-BaselineSession -ProjectRoot $ProjectRoot | Out-Null
    Invoke-BaseSnapshotRestore -ProjectRoot $ProjectRoot

    foreach ($machine in $machineToCheck) {
        if (-not (Test-GuestBaselineReady -MachineName $machine -ProjectRoot $ProjectRoot)) {
            throw "The restored baseline snapshot is incomplete on $machine. Run .\RHCSA.ps1 up and verify the guest provisioning logs."
        }
    }

    return $true
}

function Invoke-ClientRecoveryConsole {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vboxManage = Get-VBoxManagePath

    Push-Location $ProjectRoot
    try {
        Write-WorkflowStatus -Area 'scenario' -Message 'Opening the client recovery console'
        $clientId = Get-VagrantMachineId -MachineName 'client' -ProjectRoot $ProjectRoot
        Stop-VBoxMachineForSnapshot -MachineName 'client' -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage
        Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('startvm', $clientId, '--type', 'gui') -FailureMessage 'Failed to start client in GUI mode for password recovery.'
    }
    finally {
        Pop-Location
    }
}

function Start-BaselineSession {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$NoProvision,
        [switch]$NormalStart,
        [switch]$HeadlessClient,
        [switch]$RealisticMode,
        [switch]$ForceRefresh,
        [switch]$SkipEnvironmentRecovery,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $notices = @()
    if ($HeadlessClient) {
        $notices += 'HeadlessClient is deprecated. Use .\RHCSA.ps1 start for password recovery scenarios.'
    }

    if ($RealisticMode) {
        $notices += 'RealisticMode is deprecated. Use .\RHCSA.ps1 start for password recovery scenarios.'
    }

    if ($NormalStart) {
        $notices += 'NormalStart is now the default baseline behavior.'
    }

    if (-not $PSCmdlet.ShouldProcess($ProjectRoot, 'Start baseline Vagrant environment')) {
        return [PSCustomObject]@{
            Skipped = $true
            Notices = $notices
            CreatedBaseSnapshot = $false
            SnapshotReady = $false
        }
    }

    $baselineStatus = Get-BaselineStatus -ProjectRoot $ProjectRoot
    $baselineSnapshotModeReady = Test-BaseSnapshotModeReady -ProjectRoot $ProjectRoot

    if (-not $ForceRefresh -and -not $NoProvision -and $baselineSnapshotModeReady -and [string]$baselineStatus.State -eq 'ready') {
        Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot
        return [PSCustomObject]@{
            Skipped = $false
            Notices = $notices
            CreatedBaseSnapshot = $false
            SnapshotReady = $true
            ClearedActiveRun = $false
            AlreadyReady = $true
        }
    }

    if (-not $ForceRefresh -and -not $NoProvision -and $baselineSnapshotModeReady -and [string]$baselineStatus.State -eq 'available') {
        Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null
        if (Test-LabMachinesInVBoxState -DesiredState @('saved') -ProjectRoot $ProjectRoot) {
            Resume-SavedLabEnvironment -ProjectRoot $ProjectRoot
            Set-LiveCleanBaselineState -ProjectRoot $ProjectRoot
        }
        else {
            Invoke-BaseSnapshotRestore -ProjectRoot $ProjectRoot -MachineNames @('server', 'client')
            Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
        }
        Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot
        return [PSCustomObject]@{
            Skipped = $false
            Notices = $notices
            CreatedBaseSnapshot = $false
            SnapshotReady = $true
            ClearedActiveRun = $false
            AlreadyReady = $true
        }
    }

    Assert-RhcsaOfflineSourceReady -ProjectRoot $ProjectRoot -Profile (Get-ProjectProfile -ProjectRoot $ProjectRoot)
    Assert-LabDiskSpaceReady -ProjectRoot $ProjectRoot

    if (-not $SkipEnvironmentRecovery -and [string]$baselineStatus.State -eq 'incomplete') {
        $notices += 'Detected an incomplete baseline from a prior failed run. Rebuilding it from scratch.'
        Remove-LabEnvironment -PreserveState -ProjectRoot $ProjectRoot | Out-Null
    }

    Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null
    Wait-LabHypervisorQuiescence | Out-Null
    $vboxManageForCleanup = Get-OptionalVBoxManagePath
    if ($vboxManageForCleanup) {
        $vboxMachineFolder = Get-VBoxMachineFolder -VBoxManagePath $vboxManageForCleanup
        $registeredVm = @(Get-VBoxVmCatalog -VBoxManagePath $vboxManageForCleanup)
        Invoke-OrphanVagrantImportFolderCleanup -VBoxMachineFolder $vboxMachineFolder -RegisteredVm $registeredVm
    }
    Remove-OrphanLabDiskSet -ProjectRoot $ProjectRoot | Out-Null
    Assert-LabDiskSpaceReady -ProjectRoot $ProjectRoot
    if ([string]::IsNullOrWhiteSpace((Get-OptionalVagrantMachineId -MachineName 'client' -ProjectRoot $ProjectRoot))) {
        Set-LabDiskGeneration -ProjectRoot $ProjectRoot | Out-Null
    }
    Initialize-ClientLabDiskSet -ProjectRoot $ProjectRoot | Out-Null

    $workflowProgressTotal = if ($NoProvision) { 6 } else { 10 }
    Set-WorkflowProgress -Area 'baseline' -Index 0 -Total $workflowProgressTotal

    try {
        Write-WorkflowStatus -Area 'baseline' -Message 'Preparing environment' -Index 1
        Assert-ProjectVagrantBoxReady -ProjectRoot $ProjectRoot

        try {
            Push-Location $ProjectRoot
            try {
                if ($NoProvision) {
                    Write-WorkflowStatus -Area 'baseline' -Message 'Provisioning server' -Index 2
                    Invoke-VagrantMachineStep -MachineName 'server' -ProjectRoot $ProjectRoot
                    Write-WorkflowStatus -Area 'baseline' -Message 'Provisioning client' -Index 4
                    Invoke-VagrantMachineStep -MachineName 'client' -ProjectRoot $ProjectRoot
                }
                else {
                    Write-WorkflowStatus -Area 'baseline' -Message 'Provisioning server' -Index 2
                    Invoke-VagrantMachineStep -MachineName 'server' -Provision -ProjectRoot $ProjectRoot
                    Write-WorkflowStatus -Area 'baseline' -Message 'Provisioning client' -Index 6
                    Invoke-VagrantMachineStep -MachineName 'client' -Provision -ProjectRoot $ProjectRoot
                }
            }
            finally {
                Pop-Location
            }
        }
        catch {
            $message = $_.ToString()
            if (-not $SkipEnvironmentRecovery -and $message -match 'E_ACCESSDENIED|object functionality is limited|another process is already executing an action on the machine|Vagrant locks each machine') {
                $notices += 'Detected a stale VirtualBox machine lock. Rebuilding the Vagrant environment and retrying.'
                Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null
                Wait-LabHypervisorQuiescence | Out-Null
                Remove-LabEnvironment -PreserveState -ProjectRoot $ProjectRoot | Out-Null
                $recoveryResult = Start-BaselineSession `
                    -NoProvision:$NoProvision `
                    -NormalStart:$NormalStart `
                    -HeadlessClient:$HeadlessClient `
                    -RealisticMode:$RealisticMode `
                    -SkipEnvironmentRecovery `
                    -ProjectRoot $ProjectRoot
                $recoveryResult.Notices = @($notices + @($recoveryResult.Notices))
                return $recoveryResult
            }

            if (
                -not $SkipEnvironmentRecovery -and
                $message -match 'client-disk[0-9]+(?:-[0-9A-Za-z_-]+)?\.vdi' -and
                $message -match 'VERR_ALREADY_EXISTS|VERR_FILE_NOT_FOUND|Invalid UUID or filename|Could not find file for the medium'
            ) {
                @(Remove-OrphanLabDiskSet -Force -ProjectRoot $ProjectRoot) | Out-Null
                $notices += 'Rebuilt the client lab disk set after a stale or missing disk error.'
                Set-LabDiskGeneration -ProjectRoot $ProjectRoot | Out-Null
                Remove-LabEnvironment -PreserveState -ProjectRoot $ProjectRoot | Out-Null
                $recoveryResult = Start-BaselineSession `
                    -NoProvision:$NoProvision `
                    -NormalStart:$NormalStart `
                    -HeadlessClient:$HeadlessClient `
                    -RealisticMode:$RealisticMode `
                    -SkipEnvironmentRecovery `
                    -ProjectRoot $ProjectRoot
                $recoveryResult.Notices = @($notices + @($recoveryResult.Notices))
                return $recoveryResult
            }

            throw
        }

        $createdBaseSnapshot = $false
        $snapshotReady = $false
        if ($NoProvision) {
            $snapshotReady = (Test-BaseSnapshot -MachineName 'server' -ProjectRoot $ProjectRoot) -and
                             (Test-BaseSnapshot -MachineName 'client' -ProjectRoot $ProjectRoot)
            if (-not $snapshotReady) {
                $notices += "Baseline VMs are running, but 'base-clean' snapshots were not created because -NoProvision was used."
            }
        }
        else {
            Assert-GuestBaselineMarker -MachineName 'server' -ProjectRoot $ProjectRoot
            Assert-GuestBaselineMarker -MachineName 'client' -ProjectRoot $ProjectRoot

            Write-WorkflowStatus -Area 'baseline' -Message 'Preparing system policy' -Index 7
            Enable-Rhel10SelinuxBeforeBaselineSnapshot -ProjectRoot $ProjectRoot

            Write-WorkflowStatus -Area 'baseline' -Message 'Validating offline repository' -Index 8
            $repoRetryCount = if ((Get-ProjectProfile -ProjectRoot $ProjectRoot) -eq 'rhel10') { 36 } else { 12 }
            $repoHealth = Test-BaselineOfflineRepoHealth -ProjectRoot $ProjectRoot -RetryCount $repoRetryCount
            if (-not $repoHealth.Passed) {
                $failedLabel = ($repoHealth.FailedMachines -join ', ')
                if (-not $SkipEnvironmentRecovery -and (Get-ProjectProfile -ProjectRoot $ProjectRoot) -ne 'rhel10') {
                    $notices += "Detected an incomplete offline package repo baseline on $failedLabel. Rebuilding it from scratch."
                    Remove-LabEnvironment -PreserveState -ProjectRoot $ProjectRoot | Out-Null
                    $recoveryResult = Start-BaselineSession `
                        -NoProvision:$NoProvision `
                        -NormalStart:$NormalStart `
                        -HeadlessClient:$HeadlessClient `
                        -RealisticMode:$RealisticMode `
                        -SkipEnvironmentRecovery `
                        -ProjectRoot $ProjectRoot
                    $recoveryResult.Notices = @($notices + @($recoveryResult.Notices))
                    return $recoveryResult
                }

                throw "The offline package repo baseline is unavailable on $failedLabel. Run .\RHCSA.ps1 destroy and then .\RHCSA.ps1 up."
            }

            Write-WorkflowStatus -Area 'baseline' -Message 'Creating baseline snapshots' -Index 9
            $createdBaseSnapshot = Invoke-BaseSnapshotInitialization -ProjectRoot $ProjectRoot -ForceRefresh
            $snapshotReady = $true
        }

        $clearedActiveRun = $false
        if ($null -ne (Get-ActiveRunState -ProjectRoot $ProjectRoot)) {
            Clear-ActiveRunState -ProjectRoot $ProjectRoot
            $clearedActiveRun = $true
        }

        if (-not $NoProvision -and $snapshotReady) {
            Set-LiveCleanBaselineState -ProjectRoot $ProjectRoot
        }
        else {
            Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
        }

        return [PSCustomObject]@{
            Skipped = $false
            Notices = $notices
            CreatedBaseSnapshot = $createdBaseSnapshot
            SnapshotReady = $snapshotReady
            ClearedActiveRun = $clearedActiveRun
        }
    }
    catch {
        $message = $_.ToString()
        if (
            -not $SkipEnvironmentRecovery -and
            $message -match 'Failed to confirm SSH readiness|still reported as not created after startup|Direct SSH command did not return the RHCSA exit marker|VBoxHeadless|VirtualBox VM .* remained locked'
        ) {
            $notices += 'Detected an unstable VirtualBox guest startup. Rebuilding the baseline once.'
            $cleanupParameters = @{ ProjectRoot = $ProjectRoot }
            if (Test-ForceHostCleanupEnabled) {
                $cleanupParameters['ForceHostCleanup'] = $true
            }
            Remove-LabEnvironment @cleanupParameters | Out-Null
            $recoveryResult = Start-BaselineSession `
                -NoProvision:$NoProvision `
                -NormalStart:$NormalStart `
                -HeadlessClient:$HeadlessClient `
                -RealisticMode:$RealisticMode `
                -SkipEnvironmentRecovery `
                -ProjectRoot $ProjectRoot
            $recoveryResult.Notices = @($notices + @($recoveryResult.Notices))
            return $recoveryResult
        }

        throw
    }
}

Export-ModuleMember -Function *
