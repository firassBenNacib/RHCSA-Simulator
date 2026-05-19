@{
RootModule = 'FileHelpers.psm1'
ModuleVersion = '0.1.0'
GUID = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d'
Author = 'Firas Ben Nacib'
CompanyName = 'RHCSA Simulator'
Copyright = '(c) Firas Ben Nacib. All rights reserved.'
Description = 'File path helpers and UTF-8 no-BOM file writing for the RHCSA Simulator.'
PowerShellVersion = '5.1'
FunctionsToExport = @(
    'ConvertTo-ProjectProfile'
    'Get-ActiveRunPath'
    'Get-BaseSnapshotStatePath'
    'Get-ClientLabDiskPath'
    'Get-GeneratedLabMetadataPath'
    'Get-GeneratedLabRuntimeRoot'
    'Get-GeneratedRuntimeRoot'
    'Get-LabDiskGenerationPath'
    'Get-LabDiskGenerationToken'
    'Get-LabDisksRoot'
    'Get-LabStateRoot'
    'Get-ProjectProfile'
    'Get-ProjectProfileData'
    'Get-ProjectProfilePath'
    'Get-ProjectRoot'
    'Get-ProjectScenarioTrack'
    'Get-ProjectTimerDefault'
    'Get-ProjectTrackFromProfile'
    'Initialize-LabStateLayout'
    'Set-LabDiskGeneration'
    'Set-ProjectProfile'
    'Set-ProjectTimerDefault'
    'Set-Utf8NoBomFile'
)
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()
}
