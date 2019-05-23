# Script to fully automated deploy
# Best IDE to editing this files is Visual Studio Code with Powershell extension!
# At this moment we are working on subjects:
#   * if wrong you get very detailed info, maybe email in future
#   * detect tools to create which will be used by entire process
#   
#  2017-09-18: implementing... - jadamowski
#  2017-10-12: implementing releasing - jadamowski
Param(
    [Parameter(Mandatory=$true)][string]$CurrentVariant
)

try 
{
    #Get current path of script - this help us find relatives files.
    $StartDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    #Load modules
    . .\Scripts\logFiles.ps1
    . .\Scripts\helpersRoutines.ps1
    . .\Scripts\toolsStatusAnalyzer.ps1
    . .\Scripts\loaderConfigurations.ps1
    . .\Scripts\selfTest.ps1
    . .\Scripts\environmentManager.ps1
    . .\Scripts\backupEnvironment.ps1
    . .\Scripts\deployManager.ps1
    #end of all dynamics modules
    Write-Console "Start Script -------------------------------------------------------------------------------------------" -ForegroundColor Magenta -BackgroundColor Blue

    #begin of selfTest.ps1
    SelfTestCheckRoutines
    #end of selfTest.ps1

    #begin of Tools Status Analyzer
    ToolsStatusAnalyzerCheckRoutines
    #end of Tools Status Analyzer

    #begin of RepositoryManager
    SetupRepositoryEnvironment
    #end of RepositoryManager

    #begin of Backups
    BackupLocalEnvironment
    BackupRemoteEnvironment
    #end of Backups

    #begin of SimpleRelease
    SimpleRelease
    #end of SimpleRelease

    Write-Console "End Of Script-------------------------------------------------------------------------------------------" -ForegroundColor Magenta -BackgroundColor Blue
} catch 
{
    Write-Console "Script stops because error occured" -ForegroundColor Red -BackgroundColor White 
    $objectError = ($_.Exception|format-list -force) | out-string
    Write-Console $objectError -ForegroundColor Red -BackgroundColor White 
    $line = $_.InvocationInfo.ScriptLineNumber
    $file = $_.InvocationInfo.ScriptName
    Write-Console -ForegroundColor Red -BackgroundColor White "Caught exception in: $file at $line"
    Write-Console "End Of Script-------------------------------------------------------------------------------------------" -ForegroundColor Magenta -BackgroundColor Blue
    Break Script
}
