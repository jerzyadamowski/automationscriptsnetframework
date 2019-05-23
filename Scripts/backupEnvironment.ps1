$global:publishProfilesRootLocation = [string]$null;
$global:publishLeafRootLocation = [string]$null;
$global:publishLocalToPointLocation = [string]$null;

. .\Scripts\internal\copierSetup.ps1
function BackupLocalEnvironment {
    Param()

    $variantConfiguration = GetVariantConfiguration
    if ([System.Convert]::ToBoolean($variantConfiguration.DoBackupLocal) -eq $false) {
        Write-Console "Skipped local backup" -ForegroundColor DarkRed -BackgroundColor Black
        return 
    }

    GetPublishDirectoriesAndCopyFiles
    CopyFilesForLocal
    CompressBackupAndRemoveSourceFiles -sourceToArchiveDirectory $global:publishLocalToPointLocation
}

function BackupRemoteEnvironment {
    Param()

    $variantConfiguration = GetVariantConfiguration
    if ([System.Convert]::ToBoolean($variantConfiguration.DoBackupRemote) -eq $false) {
        Write-Console "Skipped remote backup" -ForegroundColor DarkRed -BackgroundColor Black
        return 
    }

    GetRemoteDirectoriesToBackup
    CompressBackupAndRemoveSourceFiles -sourceToArchiveDirectory $global:backupPublishLocationRemote
}

function GetPublishDirectoriesAndCopyFiles {
    Param()

    $global:publishProfilesRootLocation = (Split-Path -Path $global:publishProfilesLocation)
    $global:publishLeafRootLocation = Split-Path (Split-Path -Path $global:publishProfilesLocation) -Leaf

    $currentVariant = $global:currentVariant
    $version = GetValueVariantConfiguration "Version"

    $global:publishLocalToPointLocation = Join-Path (Join-Path -Path $backupPublishLocationLocal -ChildPath $version) -ChildPath $currentVariant
}

function CopyFilesForLocal {
    Param()

    Write-Console "Backup local publish files"
    Write-Progress -Activity "Backup local Files" -Status "Progress:" -PercentComplete 50
    $pathToBackup = Join-Path -Path $global:backupPublishLocationLocal -ChildPath $global:publishLeafRootLocation
    BackupRemoteManager -sourceDirectory $global:publishProfilesRootLocation -destinationDirectory $pathToBackup  
    Write-Console "Warning: robocopy exit codes exceptions: https://ss64.com/nt/robocopy-exit.html" -ForegroundColor DarkYellow -BackgroundColor Black
    Write-Progress -Activity "Backup local Files" -Status "Progress:" -PercentComplete 100 -Completed

}

function GetRemoteDirectoriesToBackup {
    Param()

    $variantConfiguration = GetVariantConfiguration
    $applications = $variantConfiguration.Applications
    $mainConfiguration = GetMainConfiguration



    Write-Progress -Activity "Backup remote Files" -Status "Progress:" -PercentComplete 50    
    foreach($app in $applications) {
        if ([System.Convert]::ToBoolean($app.IsActive) -ne $true) {
            continue
        }
        foreach($project in $app.Projects) {
            if ([System.Convert]::ToBoolean($project.IsActive) -ne $true) {
                continue
            }
            foreach($projectLocation in $project.RealLocationProject) {
                $projectPathAsDirectoryName = $projectLocation -replace "\\", "_"
                $projectPathAsDirectoryName = $projectPathAsDirectoryName -replace ":", "_"
                Write-Console "Backup remote real production files"
                $pathToBackup = Join-Path -Path $global:backupPublishLocationRemote -ChildPath $projectPathAsDirectoryName
                BackupRemoteManager -sourceDirectory $projectLocation -destinationDirectory $pathToBackup  
                Write-Console "Warning: robocopy exit codes exceptions: https://ss64.com/nt/robocopy-exit.html" -ForegroundColor DarkYellow -BackgroundColor Black
            }
        }
    }
    Write-Progress -Activity "Backup remote Files" -Status "Progress:" -PercentComplete 100 -Completed
}

function CompressBackupAndRemoveSourceFiles {
    Param(
        [Parameter(Mandatory=$true)][String]$sourceToArchiveDirectory
        )

    $directoryRootToBackup = Split-Path -Path $sourceToArchiveDirectory
    $leafName = Split-Path -Path $sourceToArchiveDirectory -Leaf

    $zipFileName = Join-Path -Path $directoryRootToBackup -ChildPath "$leafName.zip" 
    CompressManager -pathToFileExe $global:sevenZipLocationPath -sourceToArchiveDirectory $sourceToArchiveDirectory -destinationArchiveFile $zipFileName

    Get-ChildItem -Path "$sourceToArchiveDirectory\\*" -Recurse | Remove-Item -Force -Recurse -Confirm:$false
    Remove-Item $sourceToArchiveDirectory -Force -Recurse -Confirm:$false
}