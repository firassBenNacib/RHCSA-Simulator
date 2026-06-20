# Dot-sourced by VMControl.psm1. Keep functions in this file internal unless exported by VMControl.psd1.

function Get-RhcsaCpuX8664V3Status {
    param(
        [AllowEmptyString()]
        [string]$ProjectProfile = '',
        [AllowEmptyString()]
        [string]$VBoxManagePath = ''
    )

    $profile = ConvertTo-ProjectProfile -Profile $ProjectProfile
    if ($profile -ne 'rhel10') {
        return [PSCustomObject]@{
            State = 'not required'
            Passed = $true
            Detail = 'RHCSA9 profile does not require the RHEL10 x86-64-v3 CPU baseline.'
        }
    }

    if ([string]::IsNullOrWhiteSpace($VBoxManagePath) -or -not (Test-Path $VBoxManagePath -PathType Leaf)) {
        return [PSCustomObject]@{
            State = 'unknown'
            Passed = $true
            Detail = 'VBoxManage is unavailable, so host CPU flags could not be checked.'
        }
    }

    try {
        $output = @(& $VBoxManagePath list hostcpuids 2>$null)
    }
    catch {
        return [PSCustomObject]@{
            State = 'unknown'
            Passed = $true
            Detail = 'VBoxManage could not report host CPU flags.'
        }
    }

    $leafData = @{}
    foreach ($line in $output) {
        if ($line -match 'Leaf no\.\s*(0x[0-9a-fA-F]+|\d+),\s*sub-leaf\s*(0x[0-9a-fA-F]+|\d+):\s*eax=(0x[0-9a-fA-F]+|[0-9a-fA-F]+)\s*ebx=(0x[0-9a-fA-F]+|[0-9a-fA-F]+)\s*ecx=(0x[0-9a-fA-F]+|[0-9a-fA-F]+)\s*edx=(0x[0-9a-fA-F]+|[0-9a-fA-F]+)') {
            $leaf = ([Convert]::ToUInt32(($Matches[1] -replace '^0x', ''), 16)).ToString('x')
            $subLeaf = ([Convert]::ToUInt32(($Matches[2] -replace '^0x', ''), 16)).ToString('x')
            $leafData["$leaf/$subLeaf"] = @{
                eax = [Convert]::ToUInt32(($Matches[3] -replace '^0x', ''), 16)
                ebx = [Convert]::ToUInt32(($Matches[4] -replace '^0x', ''), 16)
                ecx = [Convert]::ToUInt32(($Matches[5] -replace '^0x', ''), 16)
                edx = [Convert]::ToUInt32(($Matches[6] -replace '^0x', ''), 16)
            }
        }
        elseif ($line -match '^\s*([0-9a-fA-F]{8})\s+([0-9a-fA-F]{8})\s+([0-9a-fA-F]{8})\s+([0-9a-fA-F]{8})\s+([0-9a-fA-F]{8})\s*$') {
            $leaf = ([Convert]::ToUInt32($Matches[1], 16)).ToString('x')
            $leafData["$leaf/0"] = @{
                eax = [Convert]::ToUInt32($Matches[2], 16)
                ebx = [Convert]::ToUInt32($Matches[3], 16)
                ecx = [Convert]::ToUInt32($Matches[4], 16)
                edx = [Convert]::ToUInt32($Matches[5], 16)
            }
        }
    }

    if (-not $leafData.ContainsKey('1/0') -or -not $leafData.ContainsKey('7/0')) {
        return [PSCustomObject]@{
            State = 'unknown'
            Passed = $true
            Detail = 'VBoxManage output did not include enough CPUID data.'
        }
    }

    function Test-CpuBit {
        param(
            [hashtable]$Data,
            [string]$Leaf,
            [string]$Register,
            [int]$Bit
        )

        if (-not $Data.ContainsKey($Leaf)) {
            return $false
        }
        $value = [uint32]$Data[$Leaf][$Register]
        return (($value -band ([uint32]1 -shl $Bit)) -ne 0)
    }

    $required = @(
        [PSCustomObject]@{ Name = 'sse3'; Leaf = '1/0'; Register = 'ecx'; Bit = 0 }
        [PSCustomObject]@{ Name = 'ssse3'; Leaf = '1/0'; Register = 'ecx'; Bit = 9 }
        [PSCustomObject]@{ Name = 'cx16'; Leaf = '1/0'; Register = 'ecx'; Bit = 13 }
        [PSCustomObject]@{ Name = 'sse4_1'; Leaf = '1/0'; Register = 'ecx'; Bit = 19 }
        [PSCustomObject]@{ Name = 'sse4_2'; Leaf = '1/0'; Register = 'ecx'; Bit = 20 }
        [PSCustomObject]@{ Name = 'popcnt'; Leaf = '1/0'; Register = 'ecx'; Bit = 23 }
        [PSCustomObject]@{ Name = 'osxsave'; Leaf = '1/0'; Register = 'ecx'; Bit = 27 }
        [PSCustomObject]@{ Name = 'avx'; Leaf = '1/0'; Register = 'ecx'; Bit = 28 }
        [PSCustomObject]@{ Name = 'f16c'; Leaf = '1/0'; Register = 'ecx'; Bit = 29 }
        [PSCustomObject]@{ Name = 'fma'; Leaf = '1/0'; Register = 'ecx'; Bit = 12 }
        [PSCustomObject]@{ Name = 'movbe'; Leaf = '1/0'; Register = 'ecx'; Bit = 22 }
        [PSCustomObject]@{ Name = 'avx2'; Leaf = '7/0'; Register = 'ebx'; Bit = 5 }
        [PSCustomObject]@{ Name = 'bmi1'; Leaf = '7/0'; Register = 'ebx'; Bit = 3 }
        [PSCustomObject]@{ Name = 'bmi2'; Leaf = '7/0'; Register = 'ebx'; Bit = 8 }
    )

    $missing = @()
    foreach ($feature in $required) {
        if (-not (Test-CpuBit -Data $leafData -Leaf $feature.Leaf -Register $feature.Register -Bit $feature.Bit)) {
            $missing += $feature.Name
        }
    }

    $hasLzcnt = $false
    if ($leafData.ContainsKey('80000001/0')) {
        $hasLzcnt = Test-CpuBit -Data $leafData -Leaf '80000001/0' -Register 'ecx' -Bit 5
    }
    if (-not $hasLzcnt) {
        $missing += 'lzcnt'
    }

    $hasLahfLm = $false
    if ($leafData.ContainsKey('80000001/0')) {
        $hasLahfLm = Test-CpuBit -Data $leafData -Leaf '80000001/0' -Register 'ecx' -Bit 0
    }
    if (-not $hasLahfLm) {
        $missing += 'lahf_lm'
    }

    if ($missing.Count -gt 0) {
        return [PSCustomObject]@{
            State = 'unsupported'
            Passed = $false
            Detail = ('Missing CPU feature(s): {0}' -f (($missing | Sort-Object -Unique) -join ', '))
        }
    }

    return [PSCustomObject]@{
        State = 'supported'
        Passed = $true
        Detail = 'Required RHEL10 x86-64-v3 CPU features were detected.'
    }
}

function Get-RhcsaPreflightStatus {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $projectProfile = Get-ProjectProfile -ProjectRoot $ProjectRoot
    $track = Get-ProjectTrackFromProfile -Profile $projectProfile
    $profile = ConvertTo-ProjectProfile -Profile $projectProfile
    $major = if ($profile -eq 'rhel10') { '10' } else { '9' }
    $expectedIsoPattern = "rhel-$major.*-x86_64-dvd.iso"
    $cachePath = Get-RhcsaRepoCachePath -ProjectRoot $ProjectRoot -Profile $projectProfile
    $cacheReady = Test-RhcsaRepoCacheReady -ProjectRoot $ProjectRoot -Profile $projectProfile
    $isoPath = Get-RhcsaOfflineIsoPath -ProjectRoot $ProjectRoot -Profile $projectProfile
    $isoDetected = -not [string]::IsNullOrWhiteSpace($isoPath)
    $boxName = Get-ProjectVagrantBoxName -ProjectRoot $ProjectRoot -Profile $projectProfile
    $vagrantPath = Get-OptionalVagrantPath
    $vboxManagePath = Get-OptionalVBoxManagePath
    $cpuStatus = Get-RhcsaCpuX8664V3Status -ProjectProfile $projectProfile -VBoxManagePath $vboxManagePath

    $blockers = @()
    if (-not $cacheReady -and -not $isoDetected) {
        $blockers += "Missing repo cache or ISO matching $expectedIsoPattern."
    }
    if ([string]::IsNullOrWhiteSpace($vagrantPath)) {
        $blockers += 'Vagrant is not installed or not on PATH.'
    }
    if ([string]::IsNullOrWhiteSpace($vboxManagePath)) {
        $blockers += 'VirtualBox VBoxManage is not installed or not on PATH.'
    }
    if (-not [bool]$cpuStatus.Passed) {
        $blockers += [string]$cpuStatus.Detail
    }

    return [PSCustomObject]@{
        Profile = $profile.ToUpperInvariant()
        Track = $track.ToUpperInvariant()
        ExpectedIsoPattern = $expectedIsoPattern
        RepoCache = if ($cacheReady) { [System.IO.Path]::GetFullPath($cachePath) } else { 'not found' }
        DetectedIsoPath = if ($isoDetected) { $isoPath } else { 'not found' }
        VagrantBox = $boxName
        CpuX8664V3 = [string]$cpuStatus.State
        CpuDetail = [string]$cpuStatus.Detail
        Vagrant = if ([string]::IsNullOrWhiteSpace($vagrantPath)) { 'not found' } else { $vagrantPath }
        VirtualBox = if ([string]::IsNullOrWhiteSpace($vboxManagePath)) { 'not found' } else { $vboxManagePath }
        Passed = ($blockers.Count -eq 0)
        Blockers = $blockers
    }
}

