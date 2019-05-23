#warning this version is MVP.
#it would only replace data in remote environment

function SimpleRelease {
    $variantConfiguration = GetVariantConfiguration
    if ([System.Convert]::ToBoolean($variantConfiguration.DoRelease) -eq $true) {
        IterateThroughProjects
    } else {
        Write-Console "Skipped publish according 'DoRelease' parameter" -ForegroundColor DarkRed -BackgroundColor Black
    }
}

function IterateThroughProjects {
    Param()

    $variantConfiguration = GetVariantConfiguration
    $applications = $variantConfiguration.Applications
    $mainConfiguration = GetMainConfiguration

    Write-Progress -Activity "Deploy Files" -Status "Progress:" -PercentComplete 50 
    foreach($app in $applications) {
        if ([System.Convert]::ToBoolean($app.IsActive) -ne $true) {
            continue
        }
        foreach($project in $app.Projects) {
            if ([System.Convert]::ToBoolean($project.IsActive) -ne $true) {
                continue
            }
            $publishProfileDirectoryLocation = Join-Path $global:publishProfilesLocation -ChildPath $project.Name

            foreach($projectLocation in $project.RealLocationProject) {
                Write-Console "Deploy to path: $projectLocation" -ForegroundColor DarkGreen -BackgroundColor White
                DeployManager -sourceDirectory $publishProfileDirectoryLocation -destinationDirectory $projectLocation 
                Write-Console "Warring: robocopy exit codes exceptions: https://ss64.com/nt/robocopy-exit.html" -ForegroundColor DarkYellow -BackgroundColor Black
            }
        }
    }
    Write-Progress -Activity "Deploy Files" -Status "Progress:" -PercentComplete 100 -Completed    
}