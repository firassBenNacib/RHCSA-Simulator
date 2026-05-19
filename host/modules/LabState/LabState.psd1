@{
RootModule = 'LabState.psm1'
ModuleVersion = '0.1.0'
GUID = 'c3d4e5f6-a7b8-4c9d-0e1f-2a3b4c5d6e7f'
Author = 'Firas Ben Nacib'
CompanyName = 'RHCSA Simulator'
Copyright = '(c) Firas Ben Nacib. All rights reserved.'
Description = 'Lab state management, external command execution, and run state for the RHCSA Simulator.'
PowerShellVersion = '5.1'
FunctionsToExport = @(
    'Clear-ActiveRunState'
    'Export-ActiveRunState'
    'Export-BaseSnapshotState'
    'Export-RunArtifact'
    'Format-BulletedSection'
    'Format-NumberedSection'
    'Format-RunBriefText'
    'Get-ActiveRunState'
    'Get-BaseSnapshotState'
    'Get-IntegerArray'
    'Get-NativeExitCode'
    'Get-OptionalPropertyValue'
    'Get-ProjectRelativePath'
    'Get-RequiredProperty'
    'Get-StringArray'
    'Get-StringMatrix'
    'Invoke-ExternalCapture'
    'Invoke-ExternalCommand'
    'Invoke-InteractiveExternalCommand'
    'Resolve-ProjectPath'
    'Test-TransientVagrantFailure'
)
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()
}
