# Dot-sourced by VMControl.psm1. Keep functions in this file internal unless exported by VMControl.psd1.

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

    return $false
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
    foreach ($name in @(Get-LabProjectNameCandidate -ProjectName $projectName)) {
        foreach ($namePattern in @("${name}_server_", "${name}_client_")) {
            if ($CommandLine.IndexOf($namePattern, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                return $true
            }
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

function Stop-LabHostProcessById {
    param(
        [int[]]$ProcessId
    )

    $processIds = @($ProcessId | Where-Object { [int]$_ -gt 0 } | Select-Object -Unique)
    if ($processIds.Count -eq 0) {
        return
    }

    Stop-Process -Id $processIds -Force -ErrorAction SilentlyContinue

    foreach ($process in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
        if ([int]$process.ProcessId -in $processIds) {
            Invoke-CimMethod -InputObject $process -MethodName Terminate -ErrorAction SilentlyContinue | Out-Null
        }
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

        $matchesLab = Test-ProcessCommandLineMatchesLab -CommandLine ([string]$process.CommandLine) -ProjectRoot $ProjectRoot -MachineIds $MachineIds
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
    $safeProcessNames = @('ruby.exe', 'vagrant.exe', 'VBoxManage.exe')
    $processIdsToStop = New-Object 'System.Collections.Generic.List[int]'
    foreach ($process in $processes) {
        if ($labProcessIds.Contains([int]$process.ProcessId)) {
            if ($forceCleanup -or [string]$process.Name -in $safeProcessNames) {
                $processIdsToStop.Add([int]$process.ProcessId)
            }
        }
    }
    if ($processIdsToStop.Count -gt 0) {
        Stop-LabHostProcessById -ProcessId @($processIdsToStop)
        $killed = $processIdsToStop.Count
    }

    if ($killed -gt 0) {
        Start-Sleep -Seconds 2
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
        $ProjectName
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
    foreach ($machine in $registeredVm) {
        $matchesProjectName = $false
        foreach ($pattern in $namePatterns) {
            if ($machine.Name -match $pattern) {
                $matchesProjectName = $true
                break
            }
        }
        if ($matchesProjectName) {
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
    $searchRoots = @($VBoxMachineFolder)
    $boxomaticRoot = Join-Path $VBoxMachineFolder 'boxomatic'
    if (Test-Path -LiteralPath $boxomaticRoot -PathType Container) {
        $searchRoots += $boxomaticRoot
    }

    $candidate = @()
    foreach ($root in $searchRoots) {
        foreach ($pattern in $patterns) {
            $candidate += @(
                Get-ChildItem -LiteralPath $root -Directory -Filter $pattern -ErrorAction SilentlyContinue
            )
        }
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
    foreach ($hardDisk in @(Get-VBoxHardDiskCatalog -VBoxManagePath $VBoxManagePath)) {
        $location = ([string]$hardDisk.Location).Replace('/', '\')
        $matchesProjectFolder = $false
        foreach ($pattern in $projectFolderPatterns) {
            if ($location -match $pattern) {
                $matchesProjectFolder = $true
                break
            }
        }
        if (-not $matchesProjectFolder) {
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

    # Vagrant import folders are global VirtualBox artifacts, not project-owned state.
    # Leave them alone here so destroy/repair cannot remove another project's import.
    $null = $RegisteredVm
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
    $searchRoots = @($VBoxMachineFolder)
    $boxomaticRoot = Join-Path $VBoxMachineFolder 'boxomatic'
    if (Test-Path -LiteralPath $boxomaticRoot -PathType Container) {
        $searchRoots += $boxomaticRoot
    }

    foreach ($root in $searchRoots) {
        foreach ($pattern in $patterns) {
            if (Get-ChildItem -LiteralPath $root -Directory -Filter $pattern -ErrorAction SilentlyContinue | Select-Object -First 1) {
                return $true
            }
        }
    }

    return $false
}

function Assert-LabDiskSpaceReady {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$MinimumFreeGB = 15
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
        [switch]$ForceHostCleanup,
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

    $forceCleanup = Test-ForceHostCleanupEnabled -ForceHostCleanup:$ForceHostCleanup
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
        Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot -ForceHostCleanup:$forceCleanup | Out-Null
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

            Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot -ForceHostCleanup:$forceCleanup | Out-Null
            Wait-LabHypervisorQuiescence -ProjectRoot $ProjectRoot -MaxAttempts 10 -DelaySeconds 1 -ForceHostCleanup:$forceCleanup | Out-Null

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
            Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot -ForceHostCleanup:$forceCleanup | Out-Null
            Wait-LabHypervisorQuiescence -ProjectRoot $ProjectRoot -MaxAttempts 10 -DelaySeconds 1 -ForceHostCleanup:$forceCleanup | Out-Null
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
            Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot -ForceHostCleanup:$forceCleanup | Out-Null
            Wait-LabHypervisorQuiescence -ProjectRoot $ProjectRoot -MaxAttempts 10 -DelaySeconds 1 -ForceHostCleanup:$forceCleanup | Out-Null

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
            Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot -ForceHostCleanup:$forceCleanup | Out-Null
            Wait-LabHypervisorQuiescence -ProjectRoot $ProjectRoot -MaxAttempts 10 -DelaySeconds 1 -ForceHostCleanup:$forceCleanup | Out-Null

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

