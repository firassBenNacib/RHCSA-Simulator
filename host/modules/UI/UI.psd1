@{
RootModule = 'UI.psm1'
ModuleVersion = '0.1.0'
GUID = 'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e'
Author = 'Firas Ben Nacib'
CompanyName = 'RHCSA Simulator'
Copyright = '(c) Firas Ben Nacib. All rights reserved.'
Description = 'Workflow status and transcript output for the RHCSA Simulator.'
PowerShellVersion = '5.1'
FunctionsToExport = @(
    'Complete-WorkflowProgress'
    'Set-ShowWorkflowStatus'
    'Set-WorkflowProgress'
    'Stop-WorkflowProgress'
    'Test-ProgressOnlyOutputLine'
    'Write-FailureTranscript'
    'Write-WorkflowProgressHeartbeat'
    'Write-WorkflowStatus'
)
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()
}
