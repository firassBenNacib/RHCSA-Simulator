Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../FileHelpers/FileHelpers.psd1')
Import-Module (Join-Path $PSScriptRoot '../UI/UI.psd1')
Import-Module (Join-Path $PSScriptRoot '../LabState/LabState.psd1')
Import-Module (Join-Path $PSScriptRoot '../Toolchain/Toolchain.psd1')

$script:ForceHostCleanup = $false
$script:VmSshConnectionCache = @{}

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
        $result = Invoke-ExternalCapture -FilePath $vagrantPath -ArgumentList @($vagrantCommand.PrefixArgumentList + $ArgumentList) -TimeoutSeconds $TimeoutSeconds
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
            return 900
        }

        return 900
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

function Get-VmSshReadinessCommand {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    return 'printf __RHCSA_SSH_READY__'
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

function Get-VmSshConnectionCacheKey {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    return ('{0}|{1}' -f ([System.IO.Path]::GetFullPath($ProjectRoot)).ToLowerInvariant(), $MachineName.ToLowerInvariant())
}

function Clear-VmSshConnectionCache {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string[]]$MachineNames = @()
    )

    $targets = @($MachineNames | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { [string]$_ })
    if ($targets.Count -eq 0) {
        $prefix = ('{0}|' -f ([System.IO.Path]::GetFullPath($ProjectRoot)).ToLowerInvariant())
        foreach ($key in @($script:VmSshConnectionCache.Keys)) {
            if ([string]$key -like "$prefix*") {
                $script:VmSshConnectionCache.Remove($key) | Out-Null
            }
        }
        return
    }

    foreach ($machineName in $targets) {
        $key = Get-VmSshConnectionCacheKey -MachineName $machineName -ProjectRoot $ProjectRoot
        if ($script:VmSshConnectionCache.ContainsKey($key)) {
            $script:VmSshConnectionCache.Remove($key) | Out-Null
        }
    }
}

function Remove-VagrantActionMarkers {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string[]]$MachineNames = @()
    )

    $machineStateRoot = Join-Path $ProjectRoot '.vagrant\machines'
    if (-not (Test-Path -LiteralPath $machineStateRoot)) {
        return
    }

    $targets = @($MachineNames | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object {
        Join-Path $machineStateRoot "$_\virtualbox"
    })
    if ($targets.Count -eq 0) {
        $targets = @($machineStateRoot)
    }

    foreach ($target in $targets) {
        if (-not (Test-Path -LiteralPath $target)) {
            continue
        }

        Get-ChildItem -Path $target -Filter 'action_*' -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            }
    }
}

function Get-DefaultVagrantIdentityFiles {
    [OutputType([string[]])]
    param()

    $userProfile = [System.Environment]::GetFolderPath('UserProfile')
    $candidatePaths = @(
        (Join-Path $userProfile '.vagrant.d\insecure_private_keys\vagrant.key.ed25519'),
        (Join-Path $userProfile '.vagrant.d\insecure_private_key'),
        (Join-Path $userProfile '.vagrant.d\insecure_private_keys\vagrant.key.rsa')
    )

    $keyDirectory = Join-Path $userProfile '.vagrant.d\insecure_private_keys'
    if (Test-Path -LiteralPath $keyDirectory -PathType Container) {
        $candidatePaths += @(
            Get-ChildItem -Path $keyDirectory -File -ErrorAction SilentlyContinue |
                Sort-Object {
                    switch -Regex ($_.Name) {
                        '^vagrant\.key\.ed25519$' { '00' }
                        '^vagrant\.key\.rsa$' { '10' }
                        default { '20_{0}' -f $_.Name }
                    }
                } |
                ForEach-Object { $_.FullName }
        )
    }

    return @(
        $candidatePaths |
            Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
            Select-Object -Unique
    )
}

function Get-VagrantMachineIdentityFiles {
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $machineKey = Join-Path $ProjectRoot ".vagrant\machines\$MachineName\virtualbox\private_key"
    $candidatePaths = @($machineKey) + @(Get-DefaultVagrantIdentityFiles)
    return @(
        $candidatePaths |
            Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
            Select-Object -Unique
    )
}

function ConvertTo-VmSshConfigLines {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [Parameter(Mandatory = $true)]
        [object]$ConnectionInfo
    )

    $lines = @(
        "Host $MachineName",
        "  HostName $([string]$ConnectionInfo.HostName)",
        "  User $([string]$ConnectionInfo.User)",
        "  Port $([string]$ConnectionInfo.Port)",
        '  UserKnownHostsFile /dev/null',
        '  StrictHostKeyChecking no',
        '  LogLevel ERROR',
        '  IdentitiesOnly yes',
        '  BatchMode yes',
        '  PreferredAuthentications publickey',
        '  PasswordAuthentication no',
        '  KbdInteractiveAuthentication no',
        '  NumberOfPasswordPrompts 0'
    )

    foreach ($identityFile in @($ConnectionInfo.IdentityFiles | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })) {
        $lines += ('  IdentityFile {0}' -f ([string]$identityFile -replace '\\', '/'))
    }

    return $lines
}

function Get-VirtualBoxSshConnectionInfo {
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    try {
        $machineId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    }
    catch {
        return $null
    }

    if ([string]::IsNullOrWhiteSpace($machineId)) {
        return $null
    }

    $vboxManage = Get-OptionalVBoxManagePath
    if (-not $vboxManage) {
        return $null
    }

    $result = Invoke-ExternalCapture -FilePath $vboxManage -ArgumentList @('showvminfo', $machineId, '--machinereadable') -TimeoutSeconds 20
    if ($result.ExitCode -ne 0) {
        return $null
    }

    foreach ($line in @($result.StdOut)) {
        $text = [string]$line
        if ($text -notmatch '^Forwarding\(\d+\)="([^"]+)"$') {
            continue
        }

        $parts = @($matches[1] -split ',', 6)
        if ($parts.Count -lt 6) {
            continue
        }

        $ruleName = [string]$parts[0]
        $protocol = [string]$parts[1]
        $hostName = [string]$parts[2]
        $hostPortText = [string]$parts[3]
        $guestPortText = [string]$parts[5]

        if ($protocol -ne 'tcp') {
            continue
        }

        if ($ruleName -ne 'ssh' -and $guestPortText -ne '22') {
            continue
        }

        $hostPort = 0
        if (-not [int]::TryParse($hostPortText, [ref]$hostPort) -or $hostPort -le 0) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($hostName) -or $hostName -eq '0.0.0.0') {
            $hostName = '127.0.0.1'
        }

        $connectionInfo = [PSCustomObject]@{
            MachineId = $machineId
            HostName = $hostName
            Port = $hostPort
            User = 'vagrant'
            IdentityFiles = @(Get-VagrantMachineIdentityFiles -MachineName $MachineName -ProjectRoot $ProjectRoot)
        }

        $connectionInfo | Add-Member -NotePropertyName ConfigLines -NotePropertyValue @(ConvertTo-VmSshConfigLines -MachineName $MachineName -ConnectionInfo $connectionInfo)
        return $connectionInfo
    }

    return $null
}

function Get-VmSshConfig {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $localConnectionInfo = Get-VirtualBoxSshConnectionInfo -MachineName $MachineName -ProjectRoot $ProjectRoot
    if ($null -ne $localConnectionInfo) {
        return @($localConnectionInfo.ConfigLines)
    }

    $vagrantCommand = Get-VagrantCommandSpec

    Push-Location $ProjectRoot
    try {
        for ($attempt = 1; $attempt -le 12; $attempt++) {
            $result = Invoke-ExternalCapture -FilePath $vagrantCommand.FilePath -ArgumentList @($vagrantCommand.PrefixArgumentList + @('ssh-config', $MachineName)) -TimeoutSeconds 30
            Wait-VagrantClientQuiescence | Out-Null

            if ($result.ExitCode -eq 0 -and -not (Test-VagrantCommandReportedFailure -StdOut $result.StdOut -StdErr $result.StdErr)) {
                Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
                return @($result.StdOut)
            }

            $combinedOutput = ((@($result.StdOut) + @($result.StdErr)) -join "`n")
            if ($attempt -lt 12 -and $combinedOutput -match 'not yet ready for SSH') {
                Start-Sleep -Seconds 5
                continue
            }

            Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
            throw "Failed to read SSH config for $MachineName."
        }
    }
    finally {
        Pop-Location
    }

    throw "Failed to read SSH config for $MachineName."
}

function Get-VmSshConnectionInfo {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $cacheKey = Get-VmSshConnectionCacheKey -MachineName $MachineName -ProjectRoot $ProjectRoot
    $machineId = $null
    try {
        $machineId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    }
    catch {
        $machineId = $null
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$machineId) -and $script:VmSshConnectionCache.ContainsKey($cacheKey)) {
        $cachedConnectionInfo = $script:VmSshConnectionCache[$cacheKey]
        if ($null -ne $cachedConnectionInfo -and [string]$cachedConnectionInfo.MachineId -eq [string]$machineId) {
            return $cachedConnectionInfo
        }
    }

    $localConnectionInfo = Get-VirtualBoxSshConnectionInfo -MachineName $MachineName -ProjectRoot $ProjectRoot
    if ($null -ne $localConnectionInfo) {
        $script:VmSshConnectionCache[$cacheKey] = $localConnectionInfo
        return $localConnectionInfo
    }

    $configLines = @(Get-VmSshConfig -MachineName $MachineName -ProjectRoot $ProjectRoot)
    $values = @{}

    foreach ($line in $configLines) {
        if ($line -notmatch '^\s*([A-Za-z][A-Za-z0-9]+)\s+(.+?)\s*$') {
            continue
        }

        $key = $matches[1].ToLowerInvariant()
        $value = $matches[2].Trim()
        if (-not $values.ContainsKey($key)) {
            $values[$key] = @()
        }

        $values[$key] += $value
    }

    $connectionInfo = [PSCustomObject]@{
        MachineId = $machineId
        HostName = if ($values.ContainsKey('hostname')) { [string]$values['hostname'][0] } else { '127.0.0.1' }
        Port = if ($values.ContainsKey('port')) { [int]$values['port'][0] } else { 22 }
        User = if ($values.ContainsKey('user')) { [string]$values['user'][0] } else { 'vagrant' }
        IdentityFiles = if ($values.ContainsKey('identityfile')) { @($values['identityfile']) } else { @(Get-DefaultVagrantIdentityFiles) }
        ConfigLines = $configLines
    }

    $script:VmSshConnectionCache[$cacheKey] = $connectionInfo
    return $connectionInfo
}

function Test-SshBannerReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostName,
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [int]$TimeoutMilliseconds = 4000
    )

    $client = New-Object System.Net.Sockets.TcpClient
    $asyncResult = $null
    $stream = $null

    try {
        $asyncResult = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMilliseconds, $false)) {
            return $false
        }

        $client.EndConnect($asyncResult)
        $client.ReceiveTimeout = $TimeoutMilliseconds
        $stream = $client.GetStream()

        $buffer = New-Object byte[] 256
        $bannerBuilder = New-Object System.Text.StringBuilder
        $deadline = (Get-Date).AddMilliseconds($TimeoutMilliseconds)

        do {
            if ($stream.DataAvailable) {
                $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
                if ($bytesRead -le 0) {
                    break
                }

                [void]$bannerBuilder.Append([System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead))
                if ($bannerBuilder.ToString().Contains("`n")) {
                    break
                }
            }
            else {
                Start-Sleep -Milliseconds 100
            }
        } while ((Get-Date) -lt $deadline)

        $banner = $bannerBuilder.ToString().Trim()
        return $banner.StartsWith('SSH-')
    }
    catch {
        return $false
    }
    finally {
        if ($null -ne $asyncResult) {
            $asyncResult.AsyncWaitHandle.Close()
        }

        if ($null -ne $stream) {
            $stream.Dispose()
        }

        $client.Close()
    }
}

function Get-SshExecutablePath {
    $standardPaths = @(
        (Join-Path $env:SystemRoot 'System32\OpenSSH\ssh.exe'),
        'C:\Windows\System32\OpenSSH\ssh.exe',
        'C:\Program Files\Git\usr\bin\ssh.exe',
        'C:\Program Files\Git\bin\ssh.exe',
        'C:\Program Files\Vagrant\embedded\usr\bin\ssh.exe'
    )

    foreach ($path in $standardPaths) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path $path -PathType Leaf)) {
            return $path
        }
    }

    $candidate = Get-Command ssh.exe -ErrorAction SilentlyContinue
    if ($null -ne $candidate -and -not [string]::IsNullOrWhiteSpace([string]$candidate.Source)) {
        return $candidate.Source
    }

    throw 'Unable to locate ssh.exe on this host.'
}

function Get-ScpExecutablePath {
    param(
        [string]$SshPath = ''
    )

    if (-not [string]::IsNullOrWhiteSpace($SshPath)) {
        $sibling = Join-Path (Split-Path -Parent $SshPath) 'scp.exe'
        if (Test-Path $sibling -PathType Leaf) {
            return $sibling
        }
    }

    $candidate = Get-Command scp.exe -ErrorAction SilentlyContinue
    if ($null -ne $candidate -and -not [string]::IsNullOrWhiteSpace([string]$candidate.Source)) {
        return $candidate.Source
    }

    $standardPaths = @(
        'C:\Program Files\Vagrant\embedded\usr\bin\scp.exe',
        (Join-Path $env:SystemRoot 'System32\OpenSSH\scp.exe'),
        'C:\Windows\System32\OpenSSH\scp.exe',
        'C:\Program Files\Git\usr\bin\scp.exe',
        'C:\Program Files\Git\bin\scp.exe'
    )

    foreach ($path in $standardPaths) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path $path -PathType Leaf)) {
            return $path
        }
    }

    throw 'Unable to locate scp.exe on this host.'
}

function ConvertTo-ScpArgumentList {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$SshArgumentList,
        [Parameter(Mandatory = $true)]
        [string]$LocalPath,
        [Parameter(Mandatory = $true)]
        [string]$RemotePath
    )

    if ($SshArgumentList.Count -eq 0) {
        throw 'Cannot build scp arguments from an empty SSH argument list.'
    }

    $target = [string]$SshArgumentList[-1]
    $scpArguments = @()
    for ($index = 0; $index -lt ($SshArgumentList.Count - 1); $index++) {
        $argument = [string]$SshArgumentList[$index]
        if ($argument -eq '-p' -and $index + 1 -lt ($SshArgumentList.Count - 1)) {
            $scpArguments += '-P'
            $scpArguments += [string]$SshArgumentList[$index + 1]
            $index++
            continue
        }

        $scpArguments += $argument
    }

    return @($scpArguments + @($LocalPath, ('{0}:{1}' -f $target, $RemotePath)))
}

function Invoke-SshWithVmConfig {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string[]]$RemoteCommand = @(),
        [switch]$Interactive,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $sshPath = Get-SshExecutablePath
    $configLines = @(Get-VmSshConfig -MachineName $MachineName -ProjectRoot $ProjectRoot)
    $configPath = Join-Path ([System.IO.Path]::GetTempPath()) ("rhcsa-ssh-{0}.conf" -f ([System.Guid]::NewGuid().ToString('N')))

    try {
        Set-Content -Path $configPath -Value $configLines -Encoding ascii
        $argumentList = @('-F', $configPath, $MachineName) + @($RemoteCommand)

        if ($Interactive) {
            $argumentList = @(
                '-F', $configPath,
                '-o', 'PasswordAuthentication=yes',
                '-o', 'PreferredAuthentications=publickey,password',
                $MachineName
            ) + @($RemoteCommand)
            Invoke-InteractiveExternalCommand -FilePath $sshPath -ArgumentList $argumentList -FailureMessage "Failed to open an SSH session for $MachineName."
            return
        }

        return (Invoke-ExternalCapture -FilePath $sshPath -ArgumentList $argumentList)
    }
    finally {
        Remove-Item -Path $configPath -Force -ErrorAction SilentlyContinue
    }
}

function Get-LabCheckScriptPath {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $stateRoot = Initialize-LabStateLayout -ProjectRoot $ProjectRoot
    $fileName = if ($MachineName -eq 'server') { 'check-server.sh' } else { 'check-client.sh' }
    return (Join-Path $stateRoot $fileName)
}

function Clear-LabCheckScriptState {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    foreach ($machineName in @('server', 'client')) {
        $scriptPath = Get-LabCheckScriptPath -MachineName $machineName -ProjectRoot $ProjectRoot
        Remove-Item -Path $scriptPath -Force -ErrorAction SilentlyContinue
    }
}

function Get-LabCheckProvisionerName {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName
    )

    if ($MachineName -eq 'server') {
        return 'check-server'
    }

    return 'check-client'
}

function Write-LabCheckScript {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $scriptPath = Get-LabCheckScriptPath -MachineName $MachineName -ProjectRoot $ProjectRoot
    $quotedCommand = ConvertTo-BashSingleQuotedString -Value $Command
    $content = @(
        '#!/usr/bin/env bash',
        'set -euo pipefail',
        "/bin/bash -lc $quotedCommand"
    ) -join "`n"

    Set-Utf8NoBomFile -Path $scriptPath -Content ($content + "`n")
    return $scriptPath
}

function New-SshSessionKeyFile {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName
    )

    $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) ("rhcsa-{0}-{1}.key" -f $MachineName, [System.Guid]::NewGuid().ToString('N'))
    if ($PSCmdlet.ShouldProcess($tempPath, 'Create temporary SSH session key file')) {
        Copy-Item -Path $SourcePath -Destination $tempPath -Force

        if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
            try {
                $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
                $acl = New-Object System.Security.AccessControl.FileSecurity
                $acl.SetOwner($identity.User)
                $acl.SetAccessRuleProtection($true, $false)
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    $identity.User,
                    [System.Security.AccessControl.FileSystemRights]::FullControl,
                    [System.Security.AccessControl.AccessControlType]::Allow
                )
                $acl.AddAccessRule($rule)
                [System.IO.File]::SetAccessControl($tempPath, $acl)
            }
            catch {
                $grantTarget = if (-not [string]::IsNullOrWhiteSpace([string]$env:USERNAME)) { "{0}:F" -f $env:USERNAME } else { '{0}:F' -f [System.Environment]::UserName }
                $null = & icacls.exe $tempPath '/inheritance:r' '/grant:r' $grantTarget
            }
        }
    }

    return $tempPath
}

function Get-VmDirectSshLaunchSpec {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [switch]$BatchMode
    )

    $connectionInfo = Get-VmSshConnectionInfo -MachineName $MachineName -ProjectRoot $ProjectRoot
    $sshPath = Get-SshExecutablePath
    $keySources = @(
        $connectionInfo.IdentityFiles |
            Where-Object { Test-Path $_ -PathType Leaf } |
            Select-Object -Unique
    )

    if ($keySources.Count -eq 0) {
        throw "No SSH identity file was found for $MachineName."
    }

    $temporaryKeyPaths = @(
        $keySources | ForEach-Object {
            New-SshSessionKeyFile -SourcePath ([string]$_) -MachineName $MachineName
        }
    )
    $argumentList = @(
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'UserKnownHostsFile=/dev/null',
        '-o', 'LogLevel=ERROR',
        '-o', 'IdentitiesOnly=yes',
        '-o', 'PreferredAuthentications=publickey',
        '-o', 'PasswordAuthentication=no',
        '-o', 'KbdInteractiveAuthentication=no',
        '-o', 'NumberOfPasswordPrompts=0',
        '-o', 'PubkeyAcceptedKeyTypes=+ssh-rsa',
        '-o', 'HostKeyAlgorithms=+ssh-rsa'
    )
    foreach ($temporaryKeyPath in $temporaryKeyPaths) {
        $argumentList += @('-i', $temporaryKeyPath)
    }
    $argumentList += @('-p', ([string]$connectionInfo.Port))

    if ($BatchMode) {
        $argumentList += @(
            '-o', 'BatchMode=yes',
            '-o', 'ConnectTimeout=5',
            '-o', 'ConnectionAttempts=1',
            '-o', 'ServerAliveInterval=3',
            '-o', 'ServerAliveCountMax=1'
        )
    }

    $argumentList += ("{0}@{1}" -f $connectionInfo.User, $connectionInfo.HostName)

    return [PSCustomObject]@{
        SshPath = $sshPath
        ArgumentList = $argumentList
        TemporaryKeyPath = @($temporaryKeyPaths | Select-Object -First 1)
        TemporaryKeyPaths = @($temporaryKeyPaths)
    }
}

function Remove-VmDirectSshLaunchSpec {
    param(
        [object]$LaunchSpec
    )

    if ($null -eq $LaunchSpec) {
        return
    }

    $paths = @()
    if ($LaunchSpec.PSObject.Properties.Match('TemporaryKeyPaths').Count -gt 0) {
        $paths += @($LaunchSpec.TemporaryKeyPaths)
    }
    elseif ($LaunchSpec.PSObject.Properties.Match('TemporaryKeyPath').Count -gt 0) {
        $paths += @($LaunchSpec.TemporaryKeyPath)
    }

    foreach ($path in @($paths | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)) {
        Remove-Item -Path ([string]$path) -Force -ErrorAction SilentlyContinue
    }
}

function Open-VmSshSession {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    Test-VagrantSshConnectivity -MachineName $MachineName -ProjectRoot $ProjectRoot
    $launchSpec = Get-VmDirectSshLaunchSpec -MachineName $MachineName -ProjectRoot $ProjectRoot

    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
        $powershellPath = (Get-Command powershell.exe -ErrorAction Stop).Source
        $sshArgs = @($launchSpec.ArgumentList | ForEach-Object { ConvertTo-PowerShellSingleQuotedString -Value ([string]$_) }) -join ', '
        $cleanupCommands = @($launchSpec.TemporaryKeyPaths | ForEach-Object {
            'Remove-Item -Path {0} -Force -ErrorAction SilentlyContinue' -f (ConvertTo-PowerShellSingleQuotedString -Value ([string]$_))
        })
        $launchScript = @(
            ('$sshArgs = @({0})' -f $sshArgs),
            ('& {0} @sshArgs' -f (ConvertTo-PowerShellSingleQuotedString -Value $launchSpec.SshPath)),
            ('$code = $LASTEXITCODE')
        ) + $cleanupCommands + @(
            ('exit $code')
        ) -join '; '

        Start-Process `
            -FilePath $powershellPath `
            -WorkingDirectory $ProjectRoot `
            -ArgumentList @('-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', $launchScript) `
            | Out-Null

        return [PSCustomObject]@{
            Detached = $true
            MachineName = $MachineName
        }
    }

    try {
        Invoke-InteractiveExternalCommand `
            -FilePath $launchSpec.SshPath `
            -ArgumentList $launchSpec.ArgumentList `
            -FailureMessage "Failed to open an SSH session for $MachineName."
    }
    finally {
        Remove-VmDirectSshLaunchSpec -LaunchSpec $launchSpec
    }

    return [PSCustomObject]@{
        Detached = $false
        MachineName = $MachineName
    }
}

function ConvertTo-BashSingleQuotedString {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    return "'{0}'" -f ($Value -replace "'", "'""'""'")
}

function ConvertTo-BashDoubleQuotedString {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    $escaped = $Value.Replace('\', '\\').Replace('"', '\"').Replace('$', '\$').Replace('`', '\`')
    return '"{0}"' -f $escaped
}

function ConvertTo-BashEnvironmentArgumentList {
    param(
        [hashtable]$Environment = @{}
    )

    $argumentList = @()
    foreach ($key in @($Environment.Keys | Sort-Object)) {
        $name = [string]$key
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }

        if ($name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
            throw "Invalid shell environment variable name '$name'."
        }

        $argumentList += ('{0}={1}' -f $name, (ConvertTo-BashDoubleQuotedString -Value ([string]$Environment[$key])))
    }

    return $argumentList
}

function New-DirectSshBashScriptCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptContent,
        [hashtable]$Environment = @{}
    )

    $encodedScript = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ScriptContent))
    $environmentArguments = @(ConvertTo-BashEnvironmentArgumentList -Environment $Environment)
    $sudoCommand = if ($environmentArguments.Count -gt 0) {
        'sudo -n env {0} /bin/bash' -f ($environmentArguments -join ' ')
    }
    else {
        'sudo -n /bin/bash'
    }

    return 'tmpfile=$(mktemp /tmp/rhcsa-ssh.XXXXXX) || exit 125; printf %s {0} | base64 -d > "$tmpfile"; {1} "$tmpfile"; rc=$?; rm -f "$tmpfile"; printf "\n__RHCSA_DIRECT_SSH_EXIT__:%s\n" "$rc"; exit 0' -f (ConvertTo-BashDoubleQuotedString -Value $encodedScript), $sudoCommand
}

function ConvertFrom-DirectSshBashScriptResult {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Result
    )

    $exitCode = $null
    $stdout = @()
    foreach ($line in @($Result.StdOut)) {
        if ([string]$line -match '^__RHCSA_DIRECT_SSH_EXIT__:(\d+)$') {
            $exitCode = [int]$matches[1]
            continue
        }

        $stdout += $line
    }

    $stderr = @()
    foreach ($line in @($Result.StdErr)) {
        if ([string]$line -match '^__RHCSA_DIRECT_SSH_EXIT__:(\d+)$') {
            $exitCode = [int]$matches[1]
            continue
        }

        $stderr += $line
    }

    if ($null -eq $exitCode) {
        $exitCode = if ([int]$Result.ExitCode -ne 0) { [int]$Result.ExitCode } else { 124 }
        $stderr += 'Direct SSH command did not return the RHCSA exit marker.'
    }

    return [PSCustomObject]@{
        ExitCode = $exitCode
        StdOut = $stdout
        StdErr = $stderr
    }
}

function ConvertTo-PowerShellSingleQuotedString {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    return "'{0}'" -f ($Value -replace "'", "''")
}

function Test-VagrantSshConnectivity {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$RetryCount = 5,
        [int]$RetryDelaySeconds = 3
    )

    $vmId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    if (-not [string]::IsNullOrWhiteSpace($vmId)) {
        $vboxManage = Get-VBoxManagePath
        $vboxState = Get-VBoxMachineState -VmId $vmId -VBoxManagePath $vboxManage
        if ($vboxState -and [string]$vboxState -in @('poweroff', 'saved', 'aborted')) {
            Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('startvm', $vmId, '--type', 'headless') -FailureMessage "Failed to start $MachineName before SSH connectivity validation." -SuppressOutput
            Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
        }
    }

    $machineStatus = @(Get-VagrantMachineStatus -ProjectRoot $ProjectRoot | Where-Object { [string]$_.Name -eq $MachineName } | Select-Object -First 1)
    $currentVmState = if (-not [string]::IsNullOrWhiteSpace($vmId)) { Get-VBoxMachineState -VmId $vmId -VBoxManagePath (Get-VBoxManagePath) } else { $null }
    if ($machineStatus.Count -gt 0 -and [string]$currentVmState -ne 'running') {
        $stateHuman = [string]$machineStatus[0].StateHuman
        $upTimeoutSeconds = Get-VagrantUpTimeoutSeconds -ProjectRoot $ProjectRoot
        switch ($stateHuman) {
            'not created' {
                throw "$MachineName is not created. Run .\RHCSA.ps1 up first."
            }
            'poweroff' {
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed." -TimeoutSeconds $upTimeoutSeconds -SuppressOutput
            }
            'saved' {
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed." -TimeoutSeconds $upTimeoutSeconds -SuppressOutput
            }
            'paused' {
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed." -TimeoutSeconds $upTimeoutSeconds -SuppressOutput
            }
        }
    }

    $readinessCommand = Get-VmSshReadinessCommand -ProjectRoot $ProjectRoot
    $readinessTimeoutSeconds = 15
    $lastOutput = ''
    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        $connectionInfo = $null
        try {
            $connectionInfo = Get-VmSshConnectionInfo -MachineName $MachineName -ProjectRoot $ProjectRoot
        }
        catch {
            $lastOutput = $_.Exception.Message
        }

        if (
            $null -eq $connectionInfo -or
            -not (Test-SshBannerReady -HostName ([string]$connectionInfo.HostName) -Port ([int]$connectionInfo.Port) -TimeoutMilliseconds 3000)
        ) {
            $lastOutput = if ($null -eq $connectionInfo) { $lastOutput } else { "SSH banner is not ready on $($connectionInfo.HostName):$($connectionInfo.Port)." }
            if ($attempt -lt $RetryCount) {
                Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
                continue
            }

            $suffix = if ([string]::IsNullOrWhiteSpace($lastOutput)) { '' } else { " Last SSH output: $(ConvertTo-CompactWorkflowMessage -Message $lastOutput)" }
            throw "Failed to validate SSH connectivity for $MachineName.$suffix"
        }

        $launchSpec = $null
        try {
            $launchSpec = Get-VmDirectSshLaunchSpec -MachineName $MachineName -ProjectRoot $ProjectRoot -BatchMode
            $result = Invoke-ExternalCapture -FilePath $launchSpec.SshPath -ArgumentList ($launchSpec.ArgumentList + @($readinessCommand)) -TimeoutSeconds $readinessTimeoutSeconds
        }
        finally {
            Remove-VmDirectSshLaunchSpec -LaunchSpec $launchSpec
        }

        if ($result.ExitCode -eq 0 -and ((@($result.StdOut) -join "`n") -match '__RHCSA_SSH_READY__')) {
            Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
            return
        }

        $combinedOutput = ((@($result.StdOut) + @($result.StdErr)) -join "`n")
        $lastOutput = $combinedOutput
        $isRetryable = $combinedOutput -match 'Permission denied|Connection refused|Connection reset|timed out|Connection timed out|Connection closed|No route to host|Broken pipe|kex_exchange_identification|banner exchange'
        if ($attempt -lt $RetryCount -and $isRetryable) {
            Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
            continue
        }

        $suffix = if ([string]::IsNullOrWhiteSpace($lastOutput)) { '' } else { " Last SSH output: $(ConvertTo-CompactWorkflowMessage -Message $lastOutput)" }
        throw "Failed to validate SSH connectivity for $MachineName.$suffix"
    }
}

function Test-VmBatchSshReady {
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$TimeoutSeconds = 15
    )

    $launchSpec = $null
    try {
        $connectionInfo = Get-VmSshConnectionInfo -MachineName $MachineName -ProjectRoot $ProjectRoot
        if (-not (Test-SshBannerReady -HostName ([string]$connectionInfo.HostName) -Port ([int]$connectionInfo.Port) -TimeoutMilliseconds 3000)) {
            return $false
        }

        $launchSpec = Get-VmDirectSshLaunchSpec -MachineName $MachineName -ProjectRoot $ProjectRoot -BatchMode
        $readinessCommand = Get-VmSshReadinessCommand -ProjectRoot $ProjectRoot
        $result = Invoke-ExternalCapture -FilePath $launchSpec.SshPath -ArgumentList ($launchSpec.ArgumentList + @($readinessCommand)) -TimeoutSeconds $TimeoutSeconds
        if ($result.ExitCode -eq 0 -and ((@($result.StdOut) -join "`n") -match '__RHCSA_SSH_READY__')) {
            Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
            return $true
        }
    }
    catch {
        return $false
    }
    finally {
        Remove-VmDirectSshLaunchSpec -LaunchSpec $launchSpec
    }

    return $false
}

function Invoke-VagrantVmShellCommandCapture {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$RetryCount = 2,
        [int]$RetryDelaySeconds = 5,
        [switch]$SkipConnectivityCheck,
        [switch]$SkipVagrantFallback
    )

    try {
        if (-not $SkipConnectivityCheck.IsPresent) {
            Test-VagrantSshConnectivity -MachineName $MachineName -ProjectRoot $ProjectRoot
        }

        for ($attempt = 1; $attempt -le ($RetryCount + 1); $attempt++) {
            $launchSpec = $null
            try {
                $launchSpec = Get-VmDirectSshLaunchSpec -MachineName $MachineName -ProjectRoot $ProjectRoot -BatchMode
                $remoteCommand = New-DirectSshBashScriptCommand -ScriptContent $Command
                $result = Invoke-ExternalCapture `
                    -FilePath $launchSpec.SshPath `
                    -ArgumentList ($launchSpec.ArgumentList + @($remoteCommand)) `
                    -TimeoutSeconds 60
                $result = ConvertFrom-DirectSshBashScriptResult -Result $result
            }
            finally {
                Remove-VmDirectSshLaunchSpec -LaunchSpec $launchSpec
            }

            $combinedOutput = ((@($result.StdOut) + @($result.StdErr)) -join "`n")
            $canRetry = $attempt -le $RetryCount -and $combinedOutput -match 'Permission denied|Connection refused|Connection reset|timed out|Connection closed|No route to host|Broken pipe|kex_exchange_identification'
            if ($canRetry) {
                Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
                continue
            }

            if ($result.ExitCode -eq 0) {
                Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
            }
            return $result
        }
    }
    catch {
        if ($SkipVagrantFallback) {
            throw
        }
        $fallbackReason = ConvertTo-CompactWorkflowMessage -Message $_.Exception.Message
        Write-WorkflowStatus -Area 'check' -Message "Falling back to Vagrant provision transport for $MachineName checks: $fallbackReason"
    }

    $vagrantCommand = Get-VagrantCommandSpec
    $provisionerName = Get-LabCheckProvisionerName -MachineName $MachineName

    Clear-LabCheckScriptState -ProjectRoot $ProjectRoot
    Write-LabCheckScript -MachineName $MachineName -Command $Command -ProjectRoot $ProjectRoot | Out-Null

    Push-Location $ProjectRoot
    try {
        for ($attempt = 1; $attempt -le ($RetryCount + 1); $attempt++) {
            $result = Invoke-ExternalCapture -FilePath $vagrantCommand.FilePath -ArgumentList @($vagrantCommand.PrefixArgumentList + @('provision', $MachineName, '--provision-with', $provisionerName, '--no-color')) -TimeoutSeconds 180
            if ($result.ExitCode -eq 0 -and -not (Test-VagrantCommandReportedFailure -StdOut $result.StdOut -StdErr $result.StdErr)) {
                Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
                return $result
            }

            $canRetry = $attempt -le $RetryCount -and (Test-TransientVagrantFailure -StdOut $result.StdOut -StdErr $result.StdErr)
            if ($canRetry) {
                Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
                continue
            }

            return $result
        }
    }
    finally {
        Pop-Location
        Clear-LabCheckScriptState -ProjectRoot $ProjectRoot
    }
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

function Invoke-VagrantVmScript {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [AllowEmptyString()]
        [string]$ProvisionerName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$RetryCount = 2,
        [int]$RetryDelaySeconds = 5,
        [int]$TimeoutSeconds = 120,
        [string]$RetryArea = 'scenario',
        [string]$RetryMessage = 'Retrying the VM overlay after a transient SSH/provider failure',
        [hashtable]$Environment = @{},
        [switch]$SkipConnectivityCheck,
        [switch]$SkipVagrantFallback
    )

    $scriptContent = Get-Content -Path $ScriptPath -Raw -Encoding UTF8

    try {
        if (-not $SkipConnectivityCheck.IsPresent) {
            Test-VagrantSshConnectivity -MachineName $MachineName -ProjectRoot $ProjectRoot
        }

        for ($attempt = 1; $attempt -le ($RetryCount + 1); $attempt++) {
            $launchSpec = $null
            $localScriptPath = $null
            try {
                $launchSpec = Get-VmDirectSshLaunchSpec -MachineName $MachineName -ProjectRoot $ProjectRoot -BatchMode
                $scriptId = [System.Guid]::NewGuid().ToString('N')
                $localScriptPath = Join-Path ([System.IO.Path]::GetTempPath()) ("rhcsa-{0}-{1}.sh" -f $MachineName, $scriptId)
                $remoteScriptPath = "/tmp/rhcsa-${MachineName}-${scriptId}.sh"
                Set-Utf8NoBomFile -Path $localScriptPath -Content $scriptContent

                $scpPath = Get-ScpExecutablePath -SshPath $launchSpec.SshPath
                $scpArguments = ConvertTo-ScpArgumentList -SshArgumentList $launchSpec.ArgumentList -LocalPath $localScriptPath -RemotePath $remoteScriptPath
                $copyResult = Invoke-ExternalCapture -FilePath $scpPath -ArgumentList $scpArguments -TimeoutSeconds 60
                if ([int]$copyResult.ExitCode -ne 0) {
                    $result = [PSCustomObject]@{
                        ExitCode = [int]$copyResult.ExitCode
                        StdOut = @($copyResult.StdOut)
                        StdErr = @($copyResult.StdErr)
                    }
                }
                else {
                    $environmentArguments = @(ConvertTo-BashEnvironmentArgumentList -Environment $Environment)
                    $sudoCommand = if ($environmentArguments.Count -gt 0) {
                        'sudo -n env {0} /bin/bash' -f ($environmentArguments -join ' ')
                    }
                    else {
                        'sudo -n /bin/bash'
                    }
                    $quotedRemoteScriptPath = ConvertTo-BashDoubleQuotedString -Value $remoteScriptPath
                    $remoteCommand = '{0} {1}; rc=$?; rm -f {1}; printf "\n__RHCSA_DIRECT_SSH_EXIT__:%s\n" "$rc"; exit 0' -f $sudoCommand, $quotedRemoteScriptPath
                    $result = Invoke-ExternalCapture `
                        -FilePath $launchSpec.SshPath `
                        -ArgumentList ($launchSpec.ArgumentList + @($remoteCommand)) `
                        -TimeoutSeconds $TimeoutSeconds
                    $result = ConvertFrom-DirectSshBashScriptResult -Result $result
                }
            }
            finally {
                if (-not [string]::IsNullOrWhiteSpace([string]$localScriptPath)) {
                    Remove-Item -Path $localScriptPath -Force -ErrorAction SilentlyContinue
                }
                Remove-VmDirectSshLaunchSpec -LaunchSpec $launchSpec
            }

            $combinedOutput = ((@($result.StdOut) + @($result.StdErr)) -join "`n")
            $canRetry = $attempt -le $RetryCount -and $combinedOutput -match 'Permission denied|Connection refused|Connection reset|timed out|Connection closed|No route to host|Broken pipe|kex_exchange_identification'
            if ($canRetry) {
                Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
                continue
            }

            if ($result.ExitCode -eq 0) {
                Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
                return $result
            }

            if ($SkipVagrantFallback) {
                Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
            }
            $failureTail = ((@($result.StdErr) + @($result.StdOut)) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Last 8) -join ' | '
            if (-not [string]::IsNullOrWhiteSpace($failureTail)) {
                throw "Direct SSH execution failed for $MachineName script '$ScriptPath'. Last output: $failureTail"
            }
            throw "Direct SSH execution failed for $MachineName script '$ScriptPath'."
        }
    }
    catch {
        if ($SkipVagrantFallback) {
            throw
        }
        $fallbackReason = ConvertTo-CompactWorkflowMessage -Message $_.Exception.Message
        Write-WorkflowStatus -Area $RetryArea -Message "Falling back to Vagrant provision transport for $MachineName overlay: $fallbackReason"
    }

    $vagrantCommand = Get-VagrantCommandSpec

    Push-Location $ProjectRoot
    try {
        for ($attempt = 1; $attempt -le ($RetryCount + 1); $attempt++) {
            $fallbackArguments = if ([string]::IsNullOrWhiteSpace($ProvisionerName)) {
                @('provision', $MachineName, '--no-color')
            }
            else {
                @('provision', $MachineName, '--provision-with', $ProvisionerName, '--no-color')
            }

            $result = Invoke-ExternalCapture -FilePath $vagrantCommand.FilePath -ArgumentList @($vagrantCommand.PrefixArgumentList + $fallbackArguments) -TimeoutSeconds $TimeoutSeconds
            if ($result.ExitCode -eq 0 -and -not (Test-VagrantCommandReportedFailure -StdOut $result.StdOut -StdErr $result.StdErr)) {
                Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
                return $result
            }

            $canRetry = $attempt -le $RetryCount -and (Test-TransientVagrantFailure -StdOut $result.StdOut -StdErr $result.StdErr)
            if ($canRetry) {
                Write-WorkflowStatus -Area $RetryArea -Message $RetryMessage
                Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
                continue
            }

            Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
            throw "Failed to apply $MachineName overlay via Vagrant provision transport."
        }
    }
    finally {
        Pop-Location
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

        $isoName = [string]$env:RHCSA_ISO
        if ([string]::IsNullOrWhiteSpace($isoName)) {
            $isoName = if ($ProjectProfile -eq 'rhel10') { 'rhel-10.1-x86_64-dvd.iso' } else { 'rhel-9.7-x86_64-dvd.iso' }
        }

        $isoPath = if ([System.IO.Path]::IsPathRooted($isoName)) {
            $isoName
        }
        else {
            Join-Path $ProjectRoot $isoName
        }

        if (-not (Test-Path $isoPath -PathType Leaf)) {
            throw "Missing offline ISO: $isoPath"
        }

        return $isoPath
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

    try {
        Write-WorkflowStatus -Area $RetryArea -Message "Configuring $MachineName private network"
        Set-GuestPrivateNetwork -MachineName $MachineName -ProjectRoot $ProjectRoot
        if ($MachineName -eq 'server') {
            Mount-Rhcsa10ServerOfflineIso -ProjectRoot $ProjectRoot
        }
        foreach ($scriptPath in $scriptPaths) {
            Write-WorkflowStatus -Area $RetryArea -Message ("Running {0} on {1}" -f (Split-Path -Leaf $scriptPath), $MachineName)
            Invoke-VagrantVmScript `
                -MachineName $MachineName `
                -ScriptPath $scriptPath `
                -ProvisionerName '' `
                -ProjectRoot $ProjectRoot `
                -RetryCount 1 `
                -RetryDelaySeconds 10 `
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

function Get-ScenarioProvisionEnvironment {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $environment = @{}
    $activeRun = Get-ActiveRunState -ProjectRoot $ProjectRoot
    if ($null -eq $activeRun) {
        return $environment
    }

    if ($null -ne $activeRun.PSObject.Properties['run_id']) {
        $environment.RHCSA_RUN_ID = [string]$activeRun.run_id
    }

    if ($null -ne $activeRun.PSObject.Properties['mode']) {
        $environment.RHCSA_SCENARIO_MODE = [string]$activeRun.mode
    }

    $scenarioId = $null
    if ($null -ne $activeRun.PSObject.Properties['scenario'] -and $null -ne $activeRun.scenario -and $null -ne $activeRun.scenario.PSObject.Properties['id']) {
        $scenarioId = [string]$activeRun.scenario.id
    }
    elseif ($null -ne $activeRun.PSObject.Properties['scenario_id']) {
        $scenarioId = [string]$activeRun.scenario_id
    }

    if (-not [string]::IsNullOrWhiteSpace($scenarioId)) {
        $environment.RHCSA_SCENARIO_ID = $scenarioId
    }

    return $environment
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
        [string]$VBoxManagePath = (Get-VBoxManagePath)
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
            Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList (@('snapshot', $VmId) + $SnapshotArgumentList) -FailureMessage $FailureMessage
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

    if ((Get-ProjectProfile -ProjectRoot $ProjectRoot) -eq 'rhel10') {
        return 'saved'
    }

    return 'poweroff'
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

    foreach ($machineName in $machineNames) {
        $snapshotReady[$machineName] = $false
        $idFile = Join-Path $ProjectRoot ".vagrant\machines\$machineName\virtualbox\id"
        if (-not (Test-Path $idFile -PathType Leaf)) {
            continue
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
  fixfiles -F onboot >/dev/null 2>&1 || touch /.autorelabel
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
        foreach ($machine in @('server', 'client')) {
            Invoke-VagrantVmShellCommandCapture `
                -MachineName $machine `
                -Command "nohup sh -c 'sleep 1; systemctl reboot || reboot' >/dev/null 2>&1 & exit 0" `
                -ProjectRoot $ProjectRoot `
                -RetryCount 0 | Out-Null
        }

        Start-Sleep -Seconds 10
        Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @('server', 'client')
        foreach ($machine in @('server', 'client')) {
            Wait-VagrantGuestSshReady -MachineName $machine -ProjectRoot $ProjectRoot -Area 'baseline' -MaxAttempts 90 -DelaySeconds 5 -RequiredSuccesses 1 -StabilizationDelaySeconds 3
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

if command -v fixfiles >/dev/null 2>&1; then
  fixfiles -F restore >/dev/null 2>&1 || true
fi

if command -v restorecon >/dev/null 2>&1; then
  restorecon -RF /usr/sbin/sshd /etc/ssh /var/www /var/log /home /root /opt /etc/systemd /usr/lib/systemd /var/lib/containers >/dev/null 2>&1 || true
fi

if ls -Zd /usr/sbin/sshd /etc/ssh/sshd_config /var/www/html 2>/dev/null | grep -q unlabeled_t; then
  echo "SELinux relabel did not complete" >&2
  exit 1
fi
if [ -f /etc/selinux/config ]; then
  sed -ri 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
fi
if command -v grubby >/dev/null 2>&1; then
  grubby --update-kernel=ALL --remove-args="enforcing=0 selinux=0" >/dev/null 2>&1 || true
  grubby --update-kernel=ALL --args="selinux=1 enforcing=1" >/dev/null 2>&1 || true
fi
setenforce 1 >/dev/null 2>&1 || true
systemctl restart sshd >/dev/null 2>&1 || true
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

    # RHCSA10 cold boots are expensive on VirtualBox/Windows hosts. Use a
    # saved-state baseline by default so normal start/reset paths resume from a
    # clean, already-booted guest instead of repeating the full kernel boot.
    $useSavedStateSnapshots = (
        (Get-ProjectProfile -ProjectRoot $ProjectRoot) -eq 'rhel10' -and
        $env:RHCSA_DISABLE_RHEL10_SAVED_SNAPSHOT -notmatch '^(1|true|yes|on)$'
    )

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
            Wait-VagrantGuestSshReady -MachineName $machine -ProjectRoot $ProjectRoot -Area 'baseline' -MaxAttempts 60 -DelaySeconds 5 -RequiredSuccesses 1 -StabilizationDelaySeconds 3
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
            Stop-VBoxMachineForSnapshot -MachineName $machine -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage
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
        [int]$StabilizationDelaySeconds = 3
    )

    $consecutiveSuccesses = 0
    $didRhel10BootReset = $false
    $powerStateStartAttempts = 0
    $rhel10BootResetAttempt = [Math]::Min(6, [Math]::Max(1, $MaxAttempts - 2))

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
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

        $vmId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
        if (-not [string]::IsNullOrWhiteSpace($vmId)) {
            $vboxManage = Get-VBoxManagePath
            $vboxState = Get-VBoxMachineState -VmId $vmId -VBoxManagePath $vboxManage
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

        if (
            -not $didRhel10BootReset -and
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
            -StabilizationDelaySeconds $StabilizationDelaySeconds
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
                    -StabilizationDelaySeconds $StabilizationDelaySeconds
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
                    -StabilizationDelaySeconds $StabilizationDelaySeconds
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
                -StabilizationDelaySeconds $StabilizationDelaySeconds
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
            -StabilizationDelaySeconds $StabilizationDelaySeconds
    }
}

function Invoke-ScenarioProvisioning {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    Push-Location $ProjectRoot
    try {
        $scenarioEnvironment = Get-ScenarioProvisionEnvironment -ProjectRoot $ProjectRoot
        $needsServerReadiness = [bool]$Manifest.Flags.RequiresServer -or -not [string]::IsNullOrWhiteSpace([string]$Manifest.VmScripts.ServerRelative)
        if ($needsServerReadiness) {
            Confirm-VagrantGuestProvisionReadiness -MachineName 'server' -ProjectRoot $ProjectRoot -AllowStartupRetry
        }
        Confirm-VagrantGuestProvisionReadiness -MachineName 'client' -ProjectRoot $ProjectRoot -AllowStartupRetry

        if (-not [string]::IsNullOrWhiteSpace($Manifest.VmScripts.ServerRelative)) {
            Write-WorkflowStatus -Area 'scenario' -Message "Applying the server overlay for '$($Manifest.Id)'"
            Invoke-VagrantVmScript `
                -MachineName 'server' `
                -ScriptPath $Manifest.VmScripts.Server `
                -ProvisionerName 'scenario-server' `
                -ProjectRoot $ProjectRoot `
                -RetryArea 'scenario' `
                -Environment $scenarioEnvironment `
                -RetryMessage "Retrying the server overlay for '$($Manifest.Id)' after a transient SSH/provider failure" `
                -TimeoutSeconds 900 `
                -SkipVagrantFallback | Out-Null
        }

        if (-not [string]::IsNullOrWhiteSpace($Manifest.VmScripts.ClientRelative)) {
            Confirm-VagrantGuestProvisionReadiness -MachineName 'client' -ProjectRoot $ProjectRoot -MaxAttempts 6 -DelaySeconds 5 -RequiredSuccesses 1 -StabilizationDelaySeconds 2 -AllowStartupRetry
            Write-WorkflowStatus -Area 'scenario' -Message "Applying the client overlay for '$($Manifest.Id)'"
            Invoke-VagrantVmScript `
                -MachineName 'client' `
                -ScriptPath $Manifest.VmScripts.Client `
                -ProvisionerName 'scenario-client' `
                -ProjectRoot $ProjectRoot `
                -RetryCount 3 `
                -RetryDelaySeconds 10 `
                -TimeoutSeconds 900 `
                -RetryArea 'scenario' `
                -Environment $scenarioEnvironment `
                -RetryMessage "Retrying the client overlay for '$($Manifest.Id)' after a transient SSH/provider failure" `
                -SkipVagrantFallback | Out-Null
        }
    }
    finally {
        Pop-Location
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

function Test-ForceHostCleanupEnabled {
    param(
        [switch]$ForceHostCleanup
    )

    if ($ForceHostCleanup.IsPresent) {
        return $true
    }

    if ((Test-Path variable:script:ForceHostCleanup) -and [bool]$script:ForceHostCleanup) {
        return $true
    }

    return ($env:RHCSA_FORCE_HOST_CLEANUP -match '^(1|true|yes|on)$')
}

function Get-LabMachineIdList {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $ids = @()
    foreach ($machineName in @('server', 'client')) {
        $idFile = Join-Path $ProjectRoot ".vagrant\machines\$machineName\virtualbox\id"
        if (-not (Test-Path -LiteralPath $idFile -PathType Leaf)) {
            continue
        }

        $id = (Get-Content -LiteralPath $idFile -Raw -ErrorAction SilentlyContinue).Trim()
        if (-not [string]::IsNullOrWhiteSpace($id)) {
            $ids += $id
        }
    }

    return $ids
}

function Test-VagrantMachineMetadataPresent {
    [OutputType([bool])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    foreach ($machineName in @('server', 'client')) {
        $idFile = Join-Path $ProjectRoot ".vagrant\machines\$machineName\virtualbox\id"
        if (Test-Path -LiteralPath $idFile -PathType Leaf) {
            return $true
        }
    }

    return $false
}

function Test-ProcessCommandLineMatchesLab {
    param(
        [string]$CommandLine,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string[]]$MachineIds = @()
    )

    if ([string]::IsNullOrWhiteSpace($CommandLine)) {
        return $false
    }

    $normalizedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    if ($CommandLine.IndexOf($normalizedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        return $true
    }

    $projectName = Split-Path -Leaf $ProjectRoot
    foreach ($namePattern in @("${projectName}_server_", "${projectName}_client_")) {
        if ($CommandLine.IndexOf($namePattern, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
    }

    foreach ($machineId in @($MachineIds)) {
        if (-not [string]::IsNullOrWhiteSpace($machineId) -and $CommandLine.IndexOf($machineId, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
    }

    return $false
}

function Test-ProcessStillLive {
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ProcessId
    )

    try {
        $process = [System.Diagnostics.Process]::GetProcessById($ProcessId)
        return (-not $process.HasExited)
    }
    catch {
        return $false
    }
}

function Get-LabRelatedProcessIdSet {
    param(
        [object[]]$ProcessList,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string[]]$MachineIds = @(),
        [switch]$ForceHostCleanup
    )

    $labProcessNames = @('ruby.exe', 'vagrant.exe', 'VBoxManage.exe', 'VBoxHeadless.exe', 'VirtualBoxVM.exe', 'VBoxSVC.exe')
    $ids = New-Object 'System.Collections.Generic.HashSet[int]'
    $processById = @{}
    $liveProcessList = @($ProcessList | Where-Object { Test-ProcessStillLive -ProcessId ([int]$_.ProcessId) })
    foreach ($process in @($liveProcessList)) {
        $processById[[int]$process.ProcessId] = $process
    }

    foreach ($process in @($liveProcessList)) {
        $name = [string]$process.Name
        if ($name -notin $labProcessNames) {
            continue
        }

        $matchesLab = $ForceHostCleanup.IsPresent -or (Test-ProcessCommandLineMatchesLab -CommandLine ([string]$process.CommandLine) -ProjectRoot $ProjectRoot -MachineIds $MachineIds)
        if (-not $matchesLab) {
            continue
        }

        $current = $process
        while ($null -ne $current) {
            $currentName = [string]$current.Name
            if ($currentName -notin $labProcessNames) {
                break
            }

            [void]$ids.Add([int]$current.ProcessId)
            $parentId = [int]$current.ParentProcessId
            if (-not $processById.ContainsKey($parentId)) {
                break
            }

            $current = $processById[$parentId]
        }

        $pending = New-Object 'System.Collections.Generic.Queue[int]'
        $pending.Enqueue([int]$process.ProcessId)
        while ($pending.Count -gt 0) {
            $parentId = $pending.Dequeue()
            foreach ($child in @($liveProcessList)) {
                if ([int]$child.ParentProcessId -ne $parentId) {
                    continue
                }

                $childName = [string]$child.Name
                if ($childName -notin $labProcessNames) {
                    continue
                }

                $childId = [int]$child.ProcessId
                if ($ids.Add($childId)) {
                    $pending.Enqueue($childId)
                }
            }
        }
    }

    return ,$ids
}

function Invoke-LabHypervisorLockCleanup {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([int])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [switch]$ForceHostCleanup
    )

    if (-not $PSCmdlet.ShouldProcess($ProjectRoot, 'Clean stale Vagrant and VirtualBox processes for this lab')) {
        return 0
    }

    Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot
    Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot

    $forceCleanup = Test-ForceHostCleanupEnabled -ForceHostCleanup:$ForceHostCleanup
    $machineIds = @(Get-LabMachineIdList -ProjectRoot $ProjectRoot)
    $killed = 0

    $processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
    $labProcessIds = Get-LabRelatedProcessIdSet -ProcessList $processes -ProjectRoot $ProjectRoot -MachineIds $machineIds -ForceHostCleanup:$forceCleanup
    foreach ($process in $processes) {
        if ($labProcessIds.Contains([int]$process.ProcessId)) {
            Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
            $killed++
        }
    }

    if ($killed -gt 0) {
        Start-Sleep -Seconds 2
    }
    if ($forceCleanup -and (Test-LabHypervisorBusy -ProjectRoot $ProjectRoot -ForceHostCleanup)) {
        $fallbackNames = @('ruby.exe', 'vagrant.exe', 'VBoxManage.exe', 'VBoxSVC.exe', 'VBoxHeadless.exe', 'VirtualBoxVM.exe')
        foreach ($process in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
            if ([string]$process.Name -in $fallbackNames) {
                Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
                $killed++
            }
        }
        if ($killed -gt 0) {
            Start-Sleep -Seconds 2
        }
    }

    return $killed
}

function Test-LabHypervisorBusy {
    [OutputType([bool])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [switch]$ForceHostCleanup
    )

    $forceCleanup = Test-ForceHostCleanupEnabled -ForceHostCleanup:$ForceHostCleanup
    $machineIds = @(Get-LabMachineIdList -ProjectRoot $ProjectRoot)
    $processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
    $labProcessIds = Get-LabRelatedProcessIdSet -ProcessList $processes -ProjectRoot $ProjectRoot -MachineIds $machineIds -ForceHostCleanup:$forceCleanup
    return ($labProcessIds.Count -gt 0)
}

function Wait-LabHypervisorQuiescence {
    [OutputType([bool])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$MaxAttempts = 20,
        [int]$DelaySeconds = 2,
        [switch]$ForceHostCleanup
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        if (-not (Test-LabHypervisorBusy -ProjectRoot $ProjectRoot -ForceHostCleanup:$ForceHostCleanup)) {
            return $true
        }
        Start-Sleep -Seconds $DelaySeconds
    }

    return $false
}

function Test-VagrantClientBusy {
    [OutputType([bool])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [switch]$ForceHostCleanup
    )

    $forceCleanup = Test-ForceHostCleanupEnabled -ForceHostCleanup:$ForceHostCleanup
    $machineIds = @(Get-LabMachineIdList -ProjectRoot $ProjectRoot)
    $processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
    foreach ($process in $processes) {
        if ($forceCleanup -and [string]$process.Name -in @('ruby.exe', 'vagrant.exe')) {
            return $true
        }

        if (
            [string]$process.Name -in @('ruby.exe', 'vagrant.exe') -and
            (Test-ProcessCommandLineMatchesLab -CommandLine ([string]$process.CommandLine) -ProjectRoot $ProjectRoot -MachineIds $machineIds)
        ) {
            return $true
        }
    }

    return $false
}

function Wait-VagrantClientQuiescence {
    [OutputType([bool])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$MaxAttempts = 30,
        [int]$DelaySeconds = 2,
        [switch]$ForceHostCleanup
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        if (-not (Test-VagrantClientBusy -ProjectRoot $ProjectRoot -ForceHostCleanup:$ForceHostCleanup)) {
            return $true
        }
        Start-Sleep -Seconds $DelaySeconds
    }

    return $false
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
        throw
    }
}

function Start-ScenarioRun {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScenarioId,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Lab', 'Exam')]
        [string]$Mode,
        [ValidateSet('RHCSA9', 'RHCSA10', 'All', 'rhcsa9', 'rhcsa10', 'all')]
        [string]$Track = 'RHCSA9',
        [switch]$ForceRestart,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $modeLower = $Mode.ToLowerInvariant()
    $trackLower = ConvertTo-ScenarioTrack -Track $Track
    $manifest = Get-ScenarioManifest -ScenarioId $ScenarioId -ProjectRoot $ProjectRoot -Track $trackLower
    if ($modeLower -notin $manifest.SupportedModes) {
        throw "Scenario '$ScenarioId' does not support mode '$modeLower'. Supported modes: $($manifest.SupportedModes -join ', ')."
    }

    if (-not $PSCmdlet.ShouldProcess($ScenarioId, "Start scenario run in $modeLower mode")) {
        return $null
    }

    Initialize-LabStateLayout -ProjectRoot $ProjectRoot | Out-Null
    Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null

    $previousActiveRun = Get-ScenarioStatus -ProjectRoot $ProjectRoot
    if (-not $ForceRestart.IsPresent -and
        $null -ne $previousActiveRun -and
        $previousActiveRun.ScenarioId -eq $ScenarioId -and
        $previousActiveRun.Mode -eq $modeLower) {
        return [PSCustomObject]@{
            Manifest = $manifest
            Mode = $modeLower
            RunArtifact = [PSCustomObject]@{
                RunId = $previousActiveRun.RunId
                GeneratedArtifact = [PSCustomObject]@{
                    RunBrief = $previousActiveRun.RunBrief
                }
            }
            StartedAt = [datetime]::Parse($previousActiveRun.StartedAt)
            EndsAt = [datetime]::Parse($previousActiveRun.EndsAt)
            BaselineResult = $null
            RestoreMethod = 'already-active'
            ReplacedActiveRun = $previousActiveRun
            AlreadyActive = $true
        }
    }

    $needsBaselineBootstrap = $false
    foreach ($machine in @('server', 'client')) {
        if (-not (Test-Path (Join-Path $ProjectRoot ".vagrant\machines\$machine\virtualbox\id"))) {
            $needsBaselineBootstrap = $true
        }
    }

    if (-not $needsBaselineBootstrap) {
        foreach ($machine in @('server', 'client')) {
            if (-not (Test-BaseSnapshot -MachineName $machine -ProjectRoot $ProjectRoot)) {
                $needsBaselineBootstrap = $true
            }
        }
    }

    if (-not $needsBaselineBootstrap -and -not (Test-BaseSnapshotModeReady -ProjectRoot $ProjectRoot)) {
        $needsBaselineBootstrap = $true
    }

    $baselineResult = $null
    $restoreMethod = 'snapshot'
    $restoreMachineNames = @('server', 'client')

    if ($needsBaselineBootstrap) {
        Write-WorkflowStatus -Area 'scenario' -Message 'Baseline snapshots are missing; rebuilding the clean baseline first'
        $baselineResult = Start-BaselineSession -NormalStart -ProjectRoot $ProjectRoot
    }

    foreach ($machine in @('server', 'client')) {
        if (-not (Test-BaseSnapshot -MachineName $machine -ProjectRoot $ProjectRoot)) {
            throw "Missing 'base-clean' snapshot for $machine. Recreate the baseline with .\RHCSA.ps1 up and try again."
        }
    }

    $startedAt = Get-Date
    $endsAt = $startedAt.AddMinutes($manifest.TimeLimitMinutes)
    $runArtifact = Export-RunArtifact -Manifest $manifest -Mode $modeLower -StartedAt $startedAt -EndsAt $endsAt -ProjectRoot $ProjectRoot
    try {
        Export-ActiveRunState -Manifest $manifest -Mode $modeLower -RunArtifact $runArtifact -StartedAt $startedAt -EndsAt $endsAt -ProjectRoot $ProjectRoot | Out-Null
        if ($modeLower -eq 'lab') {
            $null = Initialize-LabExerciseCache -Manifest $manifest -ProjectRoot $ProjectRoot
        }

        try {
            if ($null -eq $previousActiveRun -and (Test-LiveCleanBaselineAvailable -ProjectRoot $ProjectRoot -MachineNames $restoreMachineNames)) {
                $restoreMethod = 'live-clean-baseline'
                Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
            }
            else {
                Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
                Invoke-BaseSnapshotRestore -ProjectRoot $ProjectRoot -MachineNames $restoreMachineNames
            }
        }
        catch {
            $baselineStatusAfterRestoreFailure = Get-BaselineStatus -ProjectRoot $ProjectRoot
            if ([string]$baselineStatusAfterRestoreFailure.State -in @('ready', 'available')) {
                throw
            }

            $restoreMethod = 'baseline-rebuild'
            $baselineResult = Start-BaselineSession -ProjectRoot $ProjectRoot
            Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
        }

	        $null = Repair-BaselineSnapshotIfNeeded -Manifest $manifest -ProjectRoot $ProjectRoot

	        Invoke-ScenarioProvisioning -Manifest $manifest -ProjectRoot $ProjectRoot
	        $startedAt = Get-Date
	        $endsAt = $startedAt.AddMinutes($manifest.TimeLimitMinutes)
	        $briefPath = Join-Path $ProjectRoot ([string]$runArtifact.GeneratedArtifact.RunBrief)
	        Set-Utf8NoBomFile -Path $briefPath -Content (Format-RunBriefText -Manifest $manifest -Mode $modeLower -StartedAt $startedAt -EndsAt $endsAt)
	        Export-ActiveRunState -Manifest $manifest -Mode $modeLower -RunArtifact $runArtifact -StartedAt $startedAt -EndsAt $endsAt -ProjectRoot $ProjectRoot | Out-Null

	        if ($manifest.Flags.PasswordRecovery) {
	            Invoke-ClientRecoveryConsole -ProjectRoot $ProjectRoot
        }
    }
    catch {
        Clear-ActiveRunState -ProjectRoot $ProjectRoot
        throw
    }

    return [PSCustomObject]@{
        Manifest = $manifest
        Mode = $modeLower
        RunArtifact = $runArtifact
        StartedAt = $startedAt
        EndsAt = $endsAt
        BaselineResult = $baselineResult
        RestoreMethod = $restoreMethod
        ReplacedActiveRun = $previousActiveRun
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
        Results = $results
    }
}

function Reset-ScenarioRun {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $activeRun = Get-ActiveRunState -ProjectRoot $ProjectRoot
    if ($null -eq $activeRun) {
        throw 'No active run found. Start one first with .\RHCSA.ps1 start -Id <scenario-id> -Mode Lab.'
    }

    if (-not $PSCmdlet.ShouldProcess([string]$activeRun.scenario.id, 'Reset scenario run')) {
        return $null
    }

    $tracks = @($activeRun.scenario.tracks)
    $track = if ($tracks.Count -gt 0) { [string]$tracks[0] } else { 'rhcsa9' }
    $mode = ([string]$activeRun.mode).Substring(0, 1).ToUpperInvariant() + ([string]$activeRun.mode).Substring(1)
    return Start-ScenarioRun -ScenarioId $activeRun.scenario.id -Mode $mode -Track $track -ForceRestart -ProjectRoot $ProjectRoot
}

function Get-VBoxMachineFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VBoxManagePath
    )

    $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @('list', 'systemproperties') -TimeoutSeconds 15
    if ($result.ExitCode -ne 0 -or -not $result.StdOut) {
        return $null
    }

    $line = $result.StdOut | Where-Object { $_ -match '^Default machine folder:' } | Select-Object -First 1
    if (-not $line) {
        return $null
    }

    return ($line -replace '^Default machine folder:\s*', '').Trim()
}

function Get-VBoxVmCatalog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VBoxManagePath
    )

    $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @('list', 'vms') -TimeoutSeconds 15
    if ($result.ExitCode -ne 0 -or -not $result.StdOut) {
        return @()
    }

    $items = @()
    foreach ($line in $result.StdOut) {
        if ($line -match '^"(.+)"\s+\{([0-9a-fA-F-]+)\}$') {
            $items += [PSCustomObject]@{
                Name = $matches[1]
                Id = $matches[2]
            }
        }
    }

    return $items
}

function Test-VBoxVmRegistration {
    param(
        [object[]]$RegisteredVm = @(),
        [Parameter(Mandatory = $true)]
        [string]$VmId
    )

    return $null -ne ($RegisteredVm | Where-Object { $_.Id -eq $VmId } | Select-Object -First 1)
}

function Get-LabProjectNameCandidate {
    param(
        [string]$ProjectName
    )

    $names = @(
        $ProjectName,
        'RHCSA-Simulator',
        'RHCSA_SIMULATOR',
        'rhcsa_exam_vms'
    ) | Where-Object {
        -not [string]::IsNullOrWhiteSpace([string]$_)
    } | Select-Object -Unique

    return @($names)
}

function Get-LabVBoxVmCandidate {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$VBoxManagePath = (Get-VBoxManagePath)
    )

    $projectName = Split-Path -Leaf $ProjectRoot
    $registeredVm = @(Get-VBoxVmCatalog -VBoxManagePath $VBoxManagePath)
    $candidate = @()

    foreach ($machineName in @('server', 'client')) {
        $vmId = Get-OptionalVagrantMachineId -MachineName $machineName -ProjectRoot $ProjectRoot
        if ($vmId) {
            $match = $registeredVm | Where-Object { $_.Id -eq $vmId } | Select-Object -First 1
            if ($null -ne $match) {
                $candidate += $match
            }
        }
    }

    $namePatterns = @(Get-LabProjectNameCandidate -ProjectName $projectName | ForEach-Object {
        '^' + [regex]::Escape([string]$_) + '_(server|client)_'
    })
    $legacyPattern = '^rhcsa-ex200-(server|client)'

    foreach ($machine in $registeredVm) {
        $matchesProjectName = $false
        foreach ($pattern in $namePatterns) {
            if ($machine.Name -match $pattern) {
                $matchesProjectName = $true
                break
            }
        }
        if ($matchesProjectName -or $machine.Name -match $legacyPattern) {
            if (-not ($candidate | Where-Object { $_.Id -eq $machine.Id })) {
                $candidate += $machine
            }
        }
    }

    return @($candidate | Sort-Object Id -Unique)
}

function Remove-OrphanLabDiskSet {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([object[]])]
    param(
        [ValidateSet('client')]
        [string]$MachineName = 'client',
        [switch]$Force,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $diskRoot = Join-Path $ProjectRoot '.lab-disks'
    if (-not (Test-Path -LiteralPath $diskRoot)) {
        return @()
    }

    $vboxManage = Get-OptionalVBoxManagePath
    $shouldPrune = $Force.IsPresent
    $vmId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    if (-not $shouldPrune -and [string]::IsNullOrWhiteSpace($vmId)) {
        $shouldPrune = $true
    }
    elseif (-not $shouldPrune) {
        if ($vboxManage) {
            $registeredVm = @(Get-VBoxVmCatalog -VBoxManagePath $vboxManage)
            if (-not (Test-VBoxVmRegistration -RegisteredVm $registeredVm -VmId $vmId)) {
                $shouldPrune = $true
            }
        }
    }

    if (-not $shouldPrune) {
        return @()
    }

    if ($vboxManage) {
        try {
            Invoke-VBoxHardDiskCleanup -VBoxManagePath $vboxManage -FolderPath $diskRoot
        }
        catch {
            Write-Verbose "Ignoring VirtualBox disk cleanup failure while pruning orphaned lab disks in '$diskRoot'."
        }
    }

    $removed = @()
    Get-ChildItem -LiteralPath $diskRoot -Filter ("{0}-disk*.vdi" -f $MachineName) -File -ErrorAction SilentlyContinue |
        ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove orphaned lab disk file')) {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path -LiteralPath $_.FullName)) {
                    $removed += $_.FullName
                }
            }
        }

    return @($removed)
}

function Invoke-VBoxVmRemoval {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VBoxManagePath,
        [Parameter(Mandatory = $true)]
        [string]$VmId,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList @('controlvm', $VmId, 'poweroff') -FailureMessage "Failed to power off VM '$VmId' before unregister." -IgnoreExitCode -SuppressOutput -TimeoutSeconds 30
    Start-Sleep -Seconds 2

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        $exitCode = Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList @('unregistervm', $VmId, '--delete') -FailureMessage "Failed to unregister VM '$VmId'." -IgnoreExitCode -PassThruExitCode -SuppressOutput -TimeoutSeconds 90
        if ($exitCode -eq 0) {
            return
        }
        Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null
        Wait-LabHypervisorQuiescence -ProjectRoot $ProjectRoot -MaxAttempts 5 -DelaySeconds 1 | Out-Null

        $exitCode = Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList @('unregistervm', $VmId) -FailureMessage "Failed to unregister VM '$VmId' without media deletion." -IgnoreExitCode -PassThruExitCode -SuppressOutput -TimeoutSeconds 60
        if ($exitCode -eq 0) {
            return
        }
        Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null
        Wait-LabHypervisorQuiescence -ProjectRoot $ProjectRoot -MaxAttempts 5 -DelaySeconds 1 | Out-Null

        Start-Sleep -Seconds ([Math]::Min(2 * $attempt, 10))
    }
}

function Get-VBoxHardDiskCatalog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VBoxManagePath
    )

    $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @('list', 'hdds') -TimeoutSeconds 15
    if ($result.ExitCode -ne 0 -or -not $result.StdOut) {
        return @()
    }

    $items = @()
    $uuid = $null
    $location = $null
    $parentUuid = $null

    foreach ($line in $result.StdOut) {
        if ($line -match '^UUID:\s+(.+)$') {
            if ($uuid -and $location) {
                $items += [PSCustomObject]@{
                    UUID = $uuid
                    Location = $location
                    ParentUUID = $parentUuid
                }
            }

            $uuid = $matches[1].Trim()
            $location = $null
            $parentUuid = $null
            continue
        }

        if ($line -match '^Location:\s+(.+)$') {
            $location = $matches[1].Trim()
            continue
        }

        if ($line -match '^Parent UUID:\s+(.+)$') {
            $parentUuid = $matches[1].Trim()
            continue
        }

        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($uuid -and $location) {
                $items += [PSCustomObject]@{
                    UUID = $uuid
                    Location = $location
                    ParentUUID = $parentUuid
                }
            }

            $uuid = $null
            $location = $null
            $parentUuid = $null
        }
    }

    if ($uuid -and $location) {
        $items += [PSCustomObject]@{
            UUID = $uuid
            Location = $location
            ParentUUID = $parentUuid
        }
    }

    return $items
}

function Invoke-VBoxHardDiskCleanup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VBoxManagePath,
        [Parameter(Mandatory = $true)]
        [string]$FolderPath
    )

    $folderFull = if (Test-Path -LiteralPath $FolderPath) {
        (Resolve-Path -LiteralPath $FolderPath).Path
    }
    else {
        [System.IO.Path]::GetFullPath($FolderPath)
    }
    $folderNorm = $folderFull.Replace('/', '\').ToLowerInvariant().TrimEnd('\') + '\'

    $hardDiskCatalog = @(Get-VBoxHardDiskCatalog -VBoxManagePath $VBoxManagePath)
    $targetDisks = @($hardDiskCatalog | Where-Object {
        $_.Location.Replace('/', '\').ToLowerInvariant().StartsWith($folderNorm)
    })

    if ($targetDisks.Count -eq 0) {
        return
    }

    $diskByUuid = @{}
    foreach ($hardDisk in $targetDisks) {
        $diskByUuid[$hardDisk.UUID] = $hardDisk
    }

    $depthMemo = @{}
    function Get-VBoxDiskDepth {
        param([string]$Uuid)

        if ($depthMemo.ContainsKey($Uuid)) {
            return $depthMemo[$Uuid]
        }

        $item = $diskByUuid[$Uuid]
        if ($null -eq $item -or [string]::IsNullOrWhiteSpace($item.ParentUUID) -or -not $diskByUuid.ContainsKey($item.ParentUUID)) {
            $depthMemo[$Uuid] = 0
            return 0
        }

        $depth = 1 + (Get-VBoxDiskDepth -Uuid $item.ParentUUID)
        $depthMemo[$Uuid] = $depth
        return $depth
    }

    $targetDisks = @($targetDisks | Sort-Object -Property @{ Expression = { Get-VBoxDiskDepth -Uuid $_.UUID }; Descending = $true })
    foreach ($hardDisk in $targetDisks) {
        $diskUuid = [string]$hardDisk.UUID
        $bracedDiskUuid = if ($diskUuid -match '^\{.+\}$') { $diskUuid } else { "{0}{1}{2}" -f '{', $diskUuid, '}' }
        foreach ($argumentList in @(
            @('closemedium', 'disk', $bracedDiskUuid, '--delete'),
            @('closemedium', 'disk', $bracedDiskUuid),
            @('closemedium', 'disk', $hardDisk.UUID, '--delete'),
            @('closemedium', 'disk', $hardDisk.UUID),
            @('closemedium', 'disk', $hardDisk.Location, '--delete'),
            @('closemedium', 'disk', $hardDisk.Location)
        )) {
            $exitCode = Invoke-ExternalCommand `
                -FilePath $VBoxManagePath `
                -ArgumentList $argumentList `
                -FailureMessage "Failed to close VirtualBox medium '$($hardDisk.UUID)'." `
                -IgnoreExitCode `
                -PassThruExitCode `
                -SuppressOutput `
                -TimeoutSeconds 5
            if ($exitCode -eq 0 -or $exitCode -eq 124) {
                break
            }
        }
    }
}

function Initialize-VBoxLabDiskFile {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [int]$SizeMB,
        [switch]$SkipFolderCleanup,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$VBoxManagePath = (Get-VBoxManagePath)
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if ((Test-Path -LiteralPath $Path) -and (Get-Item -LiteralPath $Path).Length -gt 0) {
        return $Path
    }

    if (-not $SkipFolderCleanup) {
        Invoke-VBoxHardDiskCleanup -VBoxManagePath $VBoxManagePath -FolderPath (Get-LabDisksRoot -ProjectRoot $ProjectRoot)
    }
    Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue

    if ($PSCmdlet.ShouldProcess($Path, "Create $SizeMB MB VirtualBox disk")) {
        $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @(
            'createmedium', 'disk',
            '--filename', $Path,
            '--size', $SizeMB.ToString(),
            '--format', 'VDI'
        )

        $pathReady = $false
        for ($attempt = 1; $attempt -le 10; $attempt++) {
            if (Test-Path -LiteralPath $Path) {
                $pathReady = $true
                break
            }
            Start-Sleep -Milliseconds 200
        }

        $transcript = ((@($result.StdOut + $result.StdErr) -join [Environment]::NewLine).Trim())
        $reportedSuccess = $pathReady -and $transcript -match 'Medium created\.' -and $transcript -notmatch '(?im)\berror:'
        if ((-not $reportedSuccess) -and ($result.ExitCode -ne 0 -or -not $pathReady)) {
            throw "Failed to create VDI ${Path}: $transcript"
        }
    }

    return $Path
}

function Initialize-ClientLabDiskSet {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([object[]])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vboxManage = Get-VBoxManagePath
    $paths = @(
        (Get-ClientLabDiskPath -DiskNumber 1 -ProjectRoot $ProjectRoot),
        (Get-ClientLabDiskPath -DiskNumber 2 -ProjectRoot $ProjectRoot)
    )

    $needsRebuild = $false
    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            $needsRebuild = $true
            break
        }

        $item = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
        if ($null -eq $item -or $item.Length -le 0) {
            $needsRebuild = $true
            break
        }
    }

    if ($needsRebuild) {
        Invoke-VBoxHardDiskCleanup -VBoxManagePath $vboxManage -FolderPath (Get-LabDisksRoot -ProjectRoot $ProjectRoot)
    }

    foreach ($path in $paths) {
        Initialize-VBoxLabDiskFile -Path $path -SizeMB 2048 -SkipFolderCleanup:$needsRebuild -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage | Out-Null
    }

    return $paths
}

function Invoke-OrphanVmFolderCleanup {
    param(
        [string]$VBoxMachineFolder,
        [string]$ProjectName
    )

    foreach ($folder in @(Get-LabVBoxVmFolderCandidate -VBoxMachineFolder $VBoxMachineFolder -ProjectName $ProjectName)) {
        Invoke-LiteralPathRemovalWithRetry -LiteralPath $folder.FullName -Recurse -Force -MaxAttempts 10 | Out-Null
    }
}

function Get-LabVBoxVmFolderCandidate {
    param(
        [string]$VBoxMachineFolder,
        [string]$ProjectName
    )

    if (-not $VBoxMachineFolder -or -not (Test-Path -LiteralPath $VBoxMachineFolder)) {
        return @()
    }

    $patterns = @()
    foreach ($name in @(Get-LabProjectNameCandidate -ProjectName $ProjectName)) {
        $patterns += "${name}_server_*"
        $patterns += "${name}_client_*"
    }
    $patterns += 'rhcsa-ex200-server*'
    $patterns += 'rhcsa-ex200-client*'

    $candidate = @()
    foreach ($pattern in $patterns) {
        $candidate += @(
            Get-ChildItem -LiteralPath $VBoxMachineFolder -Directory -Filter $pattern -ErrorAction SilentlyContinue
        )
    }

    return @($candidate | Sort-Object FullName -Unique)
}

function Invoke-LabVBoxVmFolderMediaCleanup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VBoxManagePath,
        [string]$VBoxMachineFolder,
        [string]$ProjectName
    )

    foreach ($folder in @(Get-LabVBoxVmFolderCandidate -VBoxMachineFolder $VBoxMachineFolder -ProjectName $ProjectName)) {
        Invoke-VBoxHardDiskCleanup -VBoxManagePath $VBoxManagePath -FolderPath $folder.FullName
    }

    $projectFolderPatterns = @(Get-LabProjectNameCandidate -ProjectName $ProjectName | ForEach-Object {
        '\\VirtualBox VMs\\' + [regex]::Escape([string]$_) + '_(server|client)_'
    })
    $legacyFolderPattern = '\\VirtualBox VMs\\rhcsa-ex200-(server|client)'
    foreach ($hardDisk in @(Get-VBoxHardDiskCatalog -VBoxManagePath $VBoxManagePath)) {
        $location = ([string]$hardDisk.Location).Replace('/', '\')
        $matchesProjectFolder = $false
        foreach ($pattern in $projectFolderPatterns) {
            if ($location -match $pattern) {
                $matchesProjectFolder = $true
                break
            }
        }
        if (-not $matchesProjectFolder -and $location -notmatch $legacyFolderPattern) {
            continue
        }

        $diskFolder = Split-Path -Parent $location
        if (-not [string]::IsNullOrWhiteSpace($diskFolder)) {
            Invoke-VBoxHardDiskCleanup -VBoxManagePath $VBoxManagePath -FolderPath $diskFolder
        }
    }
}

function Invoke-OrphanVagrantImportFolderCleanup {
    param(
        [string]$VBoxMachineFolder,
        [object[]]$RegisteredVm = @()
    )

    if (-not $VBoxMachineFolder -or -not (Test-Path -LiteralPath $VBoxMachineFolder)) {
        return
    }

    $registeredNames = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($vm in @($RegisteredVm)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$vm.Name)) {
            [void]$registeredNames.Add([string]$vm.Name)
        }
    }

    $patterns = @(
        'generic-rocky9-virtualbox-*',
        'Rocky-10-Vagrant-Vbox-*',
        'rockylinux-10-*',
        'almalinux-10-*'
    )

    foreach ($pattern in $patterns) {
        Get-ChildItem -LiteralPath $VBoxMachineFolder -Directory -Filter $pattern -ErrorAction SilentlyContinue |
            ForEach-Object {
                if ($registeredNames.Contains($_.Name)) {
                    return
                }

                Invoke-LiteralPathRemovalWithRetry -LiteralPath $_.FullName -Recurse -Force -MaxAttempts 10 | Out-Null
            }
    }
}

function Test-VBoxFolderArtifactPresent {
    param(
        [string]$VBoxMachineFolder,
        [string]$ProjectName
    )

    if (-not $VBoxMachineFolder -or -not (Test-Path -LiteralPath $VBoxMachineFolder)) {
        return $false
    }

    $patterns = @()
    foreach ($name in @(Get-LabProjectNameCandidate -ProjectName $ProjectName)) {
        $patterns += "$name`_server_*"
        $patterns += "$name`_client_*"
    }
    $patterns += @(
        'rhcsa-ex200-server*',
        'rhcsa-ex200-client*',
        'generic-rocky9-virtualbox-*',
        'Rocky-10-Vagrant-Vbox-*',
        'rockylinux-10-*',
        'almalinux-10-*'
    )

    foreach ($pattern in $patterns) {
        if (Get-ChildItem -LiteralPath $VBoxMachineFolder -Directory -Filter $pattern -ErrorAction SilentlyContinue | Select-Object -First 1) {
            return $true
        }
    }

    return $false
}

function Assert-LabDiskSpaceReady {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$MinimumFreeGB = 20
    )

    $paths = @($ProjectRoot)
    $vboxManage = Get-OptionalVBoxManagePath
    if ($vboxManage) {
        $vboxMachineFolder = Get-VBoxMachineFolder -VBoxManagePath $vboxManage
        if (-not [string]::IsNullOrWhiteSpace($vboxMachineFolder)) {
            $paths += $vboxMachineFolder
        }
    }

    $checkedDrive = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($path in @($paths)) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        $fullPath = [System.IO.Path]::GetFullPath($path)
        $root = [System.IO.Path]::GetPathRoot($fullPath)
        if ([string]::IsNullOrWhiteSpace($root)) {
            continue
        }

        $driveName = $root.TrimEnd('\', ':')
        if (-not $checkedDrive.Add($driveName)) {
            continue
        }

        $drive = Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue
        if ($null -eq $drive -or $null -eq $drive.Free) {
            continue
        }

        $freeGB = [Math]::Round(([double]$drive.Free / 1GB), 1)
        if ($drive.Free -lt ($MinimumFreeGB * 1GB)) {
            throw "Not enough free disk space on drive ${driveName}:. RHCSA VM startup needs at least ${MinimumFreeGB} GB free; currently ${freeGB} GB is available. Run .\RHCSA.ps1 destroy, remove stale VirtualBox VMs, or free disk space before running .\RHCSA.ps1 up."
        }
    }
}

function Invoke-WindowsPathRemovalFallback {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath,
        [switch]$Recurse
    )

    if ($env:OS -ne 'Windows_NT' -or [string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return
    }

    $cmdPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    if (-not (Test-Path -LiteralPath $cmdPath)) {
        return
    }

    try {
        $item = Get-Item -LiteralPath $LiteralPath -ErrorAction Stop
        $isDirectory = [bool]$item.PSIsContainer
    }
    catch {
        $isDirectory = $Recurse.IsPresent
    }

    $escapedPath = ([string]$LiteralPath).Replace('"', '""')
    $commandText = if ($isDirectory -or $Recurse.IsPresent) {
        'rmdir /s /q "{0}"' -f $escapedPath
    }
    else {
        'del /f /q "{0}"' -f $escapedPath
    }

    & $cmdPath /c $commandText *> $null
}

function Invoke-LiteralPathRemovalWithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath,
        [switch]$Recurse,
        [switch]$Force,
        [int]$MaxAttempts = 5
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        if (-not (Test-Path -LiteralPath $LiteralPath)) {
            return $true
        }

        try {
            Remove-Item -LiteralPath $LiteralPath -Recurse:$Recurse -Force:$Force -ErrorAction Stop
        }
        catch {
            Invoke-WindowsPathRemovalFallback -LiteralPath $LiteralPath -Recurse:$Recurse
            Start-Sleep -Milliseconds ([Math]::Min(250 * $attempt, 1000))
        }

        if (Test-Path -LiteralPath $LiteralPath) {
            Invoke-WindowsPathRemovalFallback -LiteralPath $LiteralPath -Recurse:$Recurse
        }

        if (-not (Test-Path -LiteralPath $LiteralPath)) {
            return $true
        }
    }

    return (-not (Test-Path -LiteralPath $LiteralPath))
}

function Test-LocalLabArtifactsPresent {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $paths = @(
        (Join-Path $ProjectRoot '.vagrant'),
        (Join-Path $ProjectRoot '.lab-state'),
        (Join-Path $ProjectRoot '.lab-disks'),
        (Join-Path $ProjectRoot 'output'),
        (Join-Path $ProjectRoot 'builds'),
        (Join-Path $ProjectRoot 'packer_cache')
    )

    foreach ($path in $paths) {
        if (Test-Path -LiteralPath $path) {
            return $true
        }
    }

    if (Get-ChildItem -Path $ProjectRoot -Filter '*.vdi' -File -ErrorAction SilentlyContinue | Select-Object -First 1) {
        return $true
    }

    return $false
}

function Remove-LabEnvironment {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$PreserveState,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $notes = @()
    if (-not $PSCmdlet.ShouldProcess($ProjectRoot, 'Destroy RHCSA lab environment and cleanup local state')) {
        return [PSCustomObject]@{
            Skipped = $true
            AlreadyClean = $false
            Notes = $notes
            RemovedPaths = @()
            RemainingPaths = @()
            RemainingVms = @()
            CleanupComplete = $true
        }
    }

    Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot
    Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot

    $projectName = Split-Path -Leaf $ProjectRoot
    $vboxManage = Get-OptionalVBoxManagePath
    $registeredVBoxMachines = @()
    $vboxMachineFolder = $null
    $hasVBoxFolderArtifacts = $false
    if ($vboxManage) {
        try {
            $registeredVBoxMachines = @(Get-LabVBoxVmCandidate -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage)
            $vboxMachineFolder = Get-VBoxMachineFolder -VBoxManagePath $vboxManage
            $hasVBoxFolderArtifacts = Test-VBoxFolderArtifactPresent -VBoxMachineFolder $vboxMachineFolder -ProjectName $projectName
        }
        catch {
            $registeredVBoxMachines = @()
        }
    }

    $hasLocalArtifacts = Test-LocalLabArtifactsPresent -ProjectRoot $ProjectRoot
    if (-not $hasLocalArtifacts -and $registeredVBoxMachines.Count -eq 0 -and -not $hasVBoxFolderArtifacts) {
        return [PSCustomObject]@{
            Skipped = $false
            AlreadyClean = $true
            Notes = @('No local simulator state was present.')
            RemovedPaths = @()
            RemainingPaths = @()
            RemainingVms = @()
            CleanupComplete = $true
        }
    }

    $labDisksDir = Join-Path $ProjectRoot '.lab-disks'
    $legacyDisksDir = Join-Path $ProjectRoot '.vagrant\disks'
    $machineIds = @(Get-LabMachineIdList -ProjectRoot $ProjectRoot)
    $hasMachineMetadata = $machineIds.Count -gt 0
    $hasCreatedMachines = ($machineIds.Count -gt 0) -or ($registeredVBoxMachines.Count -gt 0)
    $hasVBoxDiskArtifacts = (Test-Path -LiteralPath $labDisksDir) -or (Test-Path -LiteralPath $legacyDisksDir)
    $hasLocalVdiArtifacts = $null -ne (Get-ChildItem -Path $ProjectRoot -Filter '*.vdi' -File -ErrorAction SilentlyContinue | Select-Object -First 1)
    $shouldInspectHypervisor = $hasCreatedMachines -or $hasVBoxDiskArtifacts -or $hasLocalVdiArtifacts -or $hasVBoxFolderArtifacts
    $removedPaths = @()
    $remainingPaths = @()
    $remainingVms = @()
    $remainingVBoxFolders = @()

    if ($shouldInspectHypervisor) {
        Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null
    }

    Push-Location $ProjectRoot
    try {
        if ($shouldInspectHypervisor -and $vboxManage) {
            $directCandidates = @($registeredVBoxMachines)
            if ($directCandidates.Count -eq 0) {
                $directCandidates = @(Get-LabVBoxVmCandidate -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage)
            }

            foreach ($candidate in $directCandidates) {
                Invoke-VBoxVmRemoval -VBoxManagePath $vboxManage -VmId $candidate.Id -ProjectRoot $ProjectRoot
            }

            Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null
            Wait-LabHypervisorQuiescence -ProjectRoot $ProjectRoot -MaxAttempts 10 -DelaySeconds 1 | Out-Null

            foreach ($candidate in (Get-LabVBoxVmCandidate -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage)) {
                Invoke-VBoxVmRemoval -VBoxManagePath $vboxManage -VmId $candidate.Id -ProjectRoot $ProjectRoot
            }
        }

        if ((Test-Path '.\Vagrantfile') -and $hasMachineMetadata -and $hasCreatedMachines -and -not $vboxManage) {
            try {
                $vagrantCommand = Get-VagrantCommandSpec
                $exitCode = Invoke-ExternalCommand `
                    -FilePath $vagrantCommand.FilePath `
                    -ArgumentList @($vagrantCommand.PrefixArgumentList + @('destroy', '-f')) `
                    -FailureMessage 'vagrant destroy failed.' `
                    -IgnoreExitCode `
                    -PassThruExitCode `
                    -SuppressOutput `
                    -TimeoutSeconds 180 `
                $exitCodeText = if ($null -eq $exitCode) { '' } else { ([string]$exitCode).Trim() }
                if ([string]::IsNullOrWhiteSpace($exitCodeText)) {
                    $notes += 'vagrant destroy did not return an exit code. Continuing cleanup.'
                }
                elseif ($exitCodeText -ne '0') {
                    $notes += "vagrant destroy returned exit code $exitCodeText. Continuing cleanup."
                }
            }
            catch {
                $notes += 'vagrant destroy failed. Continuing cleanup.'
            }
        }

        if ($shouldInspectHypervisor -and $vboxManage) {
            try {
                Invoke-VBoxHardDiskCleanup -VBoxManagePath $vboxManage -FolderPath $labDisksDir
                Invoke-VBoxHardDiskCleanup -VBoxManagePath $vboxManage -FolderPath $legacyDisksDir
                if ([string]::IsNullOrWhiteSpace($vboxMachineFolder)) {
                    $vboxMachineFolder = Get-VBoxMachineFolder -VBoxManagePath $vboxManage
                }
                Invoke-LabVBoxVmFolderMediaCleanup -VBoxManagePath $vboxManage -VBoxMachineFolder $vboxMachineFolder -ProjectName $projectName
            }
            catch {
                $notes += 'VirtualBox left stale disk registrations behind. Continuing with local disk cleanup.'
            }
            if ([string]::IsNullOrWhiteSpace($vboxMachineFolder)) {
                $vboxMachineFolder = Get-VBoxMachineFolder -VBoxManagePath $vboxManage
            }
            Invoke-OrphanVmFolderCleanup -VBoxMachineFolder $vboxMachineFolder -ProjectName $projectName
            Invoke-OrphanVagrantImportFolderCleanup -VBoxMachineFolder $vboxMachineFolder -RegisteredVm (Get-VBoxVmCatalog -VBoxManagePath $vboxManage)
            Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null
            Wait-LabHypervisorQuiescence -ProjectRoot $ProjectRoot -MaxAttempts 10 -DelaySeconds 1 | Out-Null
            $remainingVms = @(Get-LabVBoxVmCandidate -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage)
            if ($remainingVms.Count -gt 0) {
                $notes += ('VirtualBox still reports lab VM(s): {0}' -f (($remainingVms | ForEach-Object { $_.Name }) -join ', '))
            }
        }

        $paths = @(
            '.\.vagrant',
            '.\.lab-disks',
            '.\output',
            '.\builds',
            '.\packer_cache'
        )

        if (-not $PreserveState) {
            $paths += '.\.lab-state'
        }

        foreach ($path in $paths) {
            if (Test-Path $path) {
                if (Invoke-LiteralPathRemovalWithRetry -LiteralPath $path -Recurse -Force) {
                    $removedPaths += $path
                }
                else {
                    $remainingPaths += $path
                }
            }
        }

        Get-ChildItem -Path . -Filter '*.vdi' -File -ErrorAction SilentlyContinue |
            ForEach-Object {
                if (Invoke-LiteralPathRemovalWithRetry -LiteralPath $_.FullName -Force) {
                    $removedPaths += $_.FullName
                }
                else {
                    $remainingPaths += $_.FullName
                }
            }

        if ($remainingPaths.Count -gt 0) {
            Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null
            Wait-LabHypervisorQuiescence -ProjectRoot $ProjectRoot -MaxAttempts 10 -DelaySeconds 1 | Out-Null

            if ($vboxManage) {
                foreach ($diskFolder in @($labDisksDir, $legacyDisksDir)) {
                    try {
                        Invoke-VBoxHardDiskCleanup -VBoxManagePath $vboxManage -FolderPath $diskFolder
                    }
                    catch {
                        $notes += "VirtualBox disk cleanup could not fully release '$diskFolder'."
                    }
                }
                try {
                    if ([string]::IsNullOrWhiteSpace($vboxMachineFolder)) {
                        $vboxMachineFolder = Get-VBoxMachineFolder -VBoxManagePath $vboxManage
                    }
                    Invoke-LabVBoxVmFolderMediaCleanup -VBoxManagePath $vboxManage -VBoxMachineFolder $vboxMachineFolder -ProjectName $projectName
                    Invoke-OrphanVmFolderCleanup -VBoxMachineFolder $vboxMachineFolder -ProjectName $projectName
                }
                catch {
                    $notes += 'VirtualBox VM folder media cleanup could not fully release stale VM disks.'
                }
            }

            Remove-OrphanLabDiskSet -ProjectRoot $ProjectRoot -Force | Out-Null

            $retryRemainingPaths = @()
            foreach ($path in $remainingPaths) {
                if (Invoke-LiteralPathRemovalWithRetry -LiteralPath $path -Recurse -Force -MaxAttempts 10) {
                    $removedPaths += $path
                }
                else {
                    $retryRemainingPaths += $path
                }
            }
            $remainingPaths = @($retryRemainingPaths)
        }

        if ($remainingPaths.Count -gt 0 -and ($remainingPaths | Where-Object { $_ -match '\\.lab-disks($|\\|/)' })) {
            $processNames = if (Test-ForceHostCleanupEnabled) {
                @('VBoxSVC', 'VBoxHeadless', 'VirtualBoxVM', 'VBoxManage')
            }
            else {
                @('VBoxSVC')
            }
            Stop-Process -Name $processNames -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2

            if ($vboxManage) {
                try {
                    Invoke-VBoxHardDiskCleanup -VBoxManagePath $vboxManage -FolderPath $labDisksDir
                    Invoke-VBoxHardDiskCleanup -VBoxManagePath $vboxManage -FolderPath $legacyDisksDir
                    if ([string]::IsNullOrWhiteSpace($vboxMachineFolder)) {
                        $vboxMachineFolder = Get-VBoxMachineFolder -VBoxManagePath $vboxManage
                    }
                    Invoke-LabVBoxVmFolderMediaCleanup -VBoxManagePath $vboxManage -VBoxMachineFolder $vboxMachineFolder -ProjectName $projectName
                    Invoke-OrphanVmFolderCleanup -VBoxMachineFolder $vboxMachineFolder -ProjectName $projectName
                }
                catch {
                    $notes += 'VirtualBox service restart did not release every stale disk registration.'
                }
            }

            $serviceRetryRemainingPaths = @()
            foreach ($path in $remainingPaths) {
                if (Invoke-LiteralPathRemovalWithRetry -LiteralPath $path -Recurse -Force -MaxAttempts 10) {
                    $removedPaths += $path
                }
                else {
                    $serviceRetryRemainingPaths += $path
                }
            }
            $remainingPaths = @($serviceRetryRemainingPaths)
        }

        if ($remainingPaths.Count -gt 0) {
            $notes += ('Local state path(s) still present: {0}' -f ($remainingPaths -join ', '))
        }

        if ($vboxManage) {
            if ([string]::IsNullOrWhiteSpace($vboxMachineFolder)) {
                $vboxMachineFolder = Get-VBoxMachineFolder -VBoxManagePath $vboxManage
            }
            $remainingVBoxFolders = @(Get-LabVBoxVmFolderCandidate -VBoxMachineFolder $vboxMachineFolder -ProjectName $projectName | Where-Object {
                Test-Path -LiteralPath $_.FullName
            })
            if ($remainingVBoxFolders.Count -gt 0) {
                $notes += ('VirtualBox VM folder(s) still present: {0}' -f (($remainingVBoxFolders | ForEach-Object { $_.FullName }) -join ', '))
            }
        }
    }
    finally {
        Pop-Location
    }

    return [PSCustomObject]@{
        Skipped = $false
        AlreadyClean = $false
        Notes = $notes
        RemovedPaths = $removedPaths
        RemainingPaths = $remainingPaths
        RemainingVms = $remainingVms
        RemainingVBoxFolders = $remainingVBoxFolders
        CleanupComplete = (($remainingPaths.Count -eq 0) -and ($remainingVms.Count -eq 0) -and ($remainingVBoxFolders.Count -eq 0))
    }
}


Export-ModuleMember -Function *
