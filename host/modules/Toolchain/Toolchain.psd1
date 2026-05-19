@{
RootModule = 'Toolchain.psm1'
ModuleVersion = '0.1.0'
GUID = 'e5f6a7b8-c9d0-4e1f-2a3b-4c5d6e7f8a9b'
Author = 'Firas Ben Nacib'
CompanyName = 'RHCSA Simulator'
Copyright = '(c) Firas Ben Nacib. All rights reserved.'
Description = 'External tool discovery (Vagrant, VBoxManage, Go) and TUI launch for the RHCSA Simulator.'
PowerShellVersion = '5.1'
FunctionsToExport = @(
    'Get-GoExecutablePath'
    'Get-OptionalVBoxManagePath'
    'Get-OptionalVagrantPath'
    'Assert-ProjectVagrantBoxReady'
    'Get-VagrantCommandSpec'
    'Get-ProjectVagrantBoxName'
    'Get-ProjectVagrantBoxUrl'
    'Get-RhcsaTuiBinaryPath'
    'Get-RhcsaTuiSourceFile'
    'Get-VBoxManagePath'
    'Get-VagrantPath'
    'Open-RhcsaTui'
    'Test-CurlExecutableAvailable'
    'Test-RhcsaTuiBinaryIsStale'
    'Test-VagrantArchiveExtractorAvailable'
    'Test-VagrantBoxInstalled'
)
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()
}
