$global:sourceRepositoriesLocation = [string]$null
$global:repositoryRetrieved = [System.Collections.ArrayList]@()
$global:applicationsCached = [psobject]$null
$global:backupPublishLocationLocal = [string]$null
$global:backupPublishLocationRemote = [string]$null
$global:publishProfilesLocation = [string]$null

. .\Scripts\internal\gitSetup.ps1
. .\Scripts\internal\nugetSetup.ps1
. .\Scripts\internal\msbuildSetup.ps1

function SetupRepositoryEnvironment {
    Param()
    GetCachedConfig
    ProvideDirectoryToDeployGitRepositories
    ProvideDirectoryToBackupEnvironment
    ProvideDirectoryToPublishProfiles
    GetApplicationsToDirectory
    RestoreNugetPackages
    MsBuildAllProjects
    PostPublishingScriptExecute
}

function ProvideDirectoryToDeployGitRepositories {
    Param()

    $pathToDirectory = GetValueMainConfiguration "SourceDirectoryEntry"
    $currentVariant = $global:currentVariant
    $version = GetValueVariantConfiguration "Version"
    $global:sourceRepositoriesLocation = $pathToDirectory -f $version, $currentVariant 

    if (Test-Path $global:sourceRepositoriesLocation) {
        #exist: maybe clean or do nothing
        if (IsNull($global:applicationsCached)) {
            #not always work??? strange.
            #rd -Path $global:sourceRepositoriesLocation -Force -Confirm:$false -Recurse:$true -ErrorAction Stop | out-null 
            Get-ChildItem -Path "$global:sourceRepositoriesLocation\\*" -Recurse | Remove-Item -Force -Recurse -Confirm:$false
            Remove-Item $global:sourceRepositoriesLocation -Force -Recurse -Confirm:$false

            md -Path $global:sourceRepositoriesLocation -ErrorAction Stop | out-null
        }
    } else {
        #create not existing path
        md -Path $global:sourceRepositoriesLocation -ErrorAction Stop | out-null
    }
}

function ProvideDirectoryToBackupEnvironment {
    Param()

    $currentVariant = $global:currentVariant
    $version = GetValueVariantConfiguration "Version"
    $pathToDirectoryLocal = GetValueMainConfiguration "PublishBackupDirectoryEntryLocal"
    $pathToDirectoryRemote = GetValueMainConfiguration "PublishBackupDirectoryEntryRemote"
    $global:backupPublishLocationLocal = $pathToDirectoryLocal
    $global:backupPublishLocationRemote = $pathToDirectoryRemote -f $version, $currentVariant 
    if (Test-Path $global:backupPublishLocationLocal) {
        #backup directory don't clean
    } else {
        #create not existing path
        md -Path $global:backupPublishLocationLocal -ErrorAction Stop | out-null
    }

    if (Test-Path $global:backupPublishLocationRemote) {
        #backup directory don't clean
    } else {
        #create not existing path
        md -Path $global:backupPublishLocationRemote -ErrorAction Stop | out-null
    }
}

function ProvideDirectoryToPublishProfiles {
    Param()

    $pathToDirectory = GetValueMainConfiguration "PublishDirectoryEntry"
    $currentVariant = $global:currentVariant
    $version = GetValueVariantConfiguration "Version"
    $global:publishProfilesLocation = $pathToDirectory -f $version,$currentVariant

    if (Test-Path $global:publishProfilesLocation) {
        #exist: maybe clean or do nothing
        if (IsNull($global:applicationsCached)) {
            #rd -Path $global:publishProfilesLocation -Force -Confirm:$false -Recurse:$true -ErrorAction Stop | out-null
            Get-ChildItem -Path "$global:publishProfilesLocation\\*" -Recurse | Remove-Item -Force -Recurse -Confirm:$false
            Remove-Item $global:publishProfilesLocation -Force -Recurse -Confirm:$false
            md -Path $global:publishProfilesLocation -ErrorAction Stop | out-null
        }
    } else {
        #create not existing path
        md -Path $global:publishProfilesLocation -ErrorAction Stop | out-null
    }
}

function GetApplicationsToDirectory {
    Param()

    $variantConfiguration = GetVariantConfiguration
    $applications = $variantConfiguration.Applications
    
    foreach($app in $applications) {
        $gitRepoLocationApplication = Join-Path $global:sourceRepositoriesLocation -ChildPath $app.Name
        if ([System.Convert]::ToBoolean($app.IsActive) -ne $true) {
            #rd -Path $gitRepoLocationApplication -Force -Confirm:$false -Recurse:$true -ErrorAction Stop | out-null
            if (Test-Path $gitRepoLocationApplication) {
                Get-ChildItem -Path "$gitRepoLocationApplication\\*" -Recurse | Remove-Item -Force -Recurse -Confirm:$false
                Remove-Item $gitRepoLocationApplication -Force -Recurse -Confirm:$false
            }
            continue
        }
        
        if ((Test-Path $gitRepoLocationApplication) -and (CheckAlreadyRetrivedRepository $app.GitRepository)) {
            #do pull
            PullingChangesForRepo -appName $app.Name
        } else {
            #do clone/checkout
            if (Test-Path $gitRepoLocationApplication) {
                #rd -Path $gitRepoLocationApplication -Force -Confirm:$false -Recurse:$true -ErrorAction Stop | out-null
                Get-ChildItem -Path "$gitRepoLocationApplication\\*" -Recurse | Remove-Item -Force -Recurse -Confirm:$false
                Remove-Item $gitRepoLocationApplication -Force -Recurse -Confirm:$false
            }
            CloningDirectoryForRepo -gitRepo $app.GitRepository -appName $app.Name -appBranch $app.BranchToCheckout
        }

        $global:repositoryRetrieved.Add($app) | Out-Null
    }

    SetValueCachedConfiguration -parameter "Applications" -newValue $global:repositoryRetrieved
}

function CloningDirectoryForRepo {
    Param([string]$gitRepo,
    [string]$appName,
    [string]$appBranch)

    Write-Console "Cloning for files: $gitRepo for $appName"
    Write-Progress -Activity "Cloning Files" -Status "Progress:" -PercentComplete 50
    GitClone -pathToFileExe $global:gitLocationPath -workingDirectory $global:sourceRepositoriesLocation `
    -applicationName $appName -repositoryLocation $gitRepo -branch $appBranch
    Write-Progress -Activity "Cloning Files" -Status "Progress:" -PercentComplete 100 -Completed
}

function PullingChangesForRepo {
    Param([string]$appName)

    Write-Console "Pulling for files: $appName"
    Write-Progress -Activity "Pulling Files" -Status "Progress:" -PercentComplete 50
    GitPull -pathToFileExe $global:gitLocationPath -workingDirectory $global:sourceRepositoriesLocation -applicationName $appName
    Write-Progress -Activity "Pulling Files" -Status "Progress:" -PercentComplete 100 -Completed
}

function CheckAlreadyRetrivedRepository {
    Param([string]$gitRepositoryCheck)
    
    foreach($application in $global:applicationsCached) {
        if ($application.GitRepository -eq $gitRepositoryCheck) {
            $gitRepo = $application.GitRepository 
            $appName = $application.Name

            Write-Console "Repository from cache: $gitRepo for $appName"
            return $true
        } 
    }

    return $false
}

function GetCachedConfig {
    $global:applicationsCached = GetValueCachedConfiguration "Applications"
}

function RestoreNugetPackages {
    $variantConfiguration = GetVariantConfiguration
    $applications = $variantConfiguration.Applications
    
    foreach($app in $applications) {
        $nugetRepoLocationApplication = Join-Path $global:sourceRepositoriesLocation -ChildPath $app.Name
        $solutionLocationApplication = Join-Path $nugetRepoLocationApplication -ChildPath $app.SolutionFileRelativeLocation
        if ([System.Convert]::ToBoolean($app.IsActive) -ne $true) {
            continue
        }

        $appName = $app.Name
        Write-Console "Restoring nuget files: $solutionLocationApplication for $appName"
        Write-Progress -Activity "Restoring Files" -Status "Progress:" -PercentComplete 50
        Write-Console -ForegroundColor DarkYellow "Restoring Nuget packages for path: $solutionLocationApplication"
        RestorePackages -pathToFileExe $global:nugetLocationPath -workingDirectory $solutionLocationApplication
        Write-Progress -Activity "Restoring Files" -Status "Progress:" -PercentComplete 100 -Completed
    }
}

function MsBuildAllProjects {

    $variantConfiguration = GetVariantConfiguration
    $applications = $variantConfiguration.Applications
    $mainConfiguration = GetMainConfiguration
        
    foreach($app in $applications) {
        if ([System.Convert]::ToBoolean($app.IsActive) -ne $true) {
            continue
        }

        $repoLocationApplication = Join-Path $global:sourceRepositoriesLocation -ChildPath $app.Name
        $solutionLocationApplication = Join-Path  $repoLocationApplication -ChildPath $app.SolutionFileRelativeLocation

        $appName = $app.Name

        foreach($project in $app.Projects) {
            if ([System.Convert]::ToBoolean($project.IsActive) -ne $true) {
                continue
            }
            $csprojLocationApplication = Join-Path $repoLocationApplication -ChildPath $project.PathCsProj
            $csprojDirectoryLocation = Join-Path (Split-Path -Path $csprojLocationApplication) -ChildPath ""
            $publishProfileDirectoryLocation = Join-Path $global:publishProfilesLocation -ChildPath $project.Name

            if ([string]::IsNullOrWhiteSpace($project.Configuration)) {
                $projectConfiguration = $variantConfiguration.DefaultBuildConfiguration
            } else {
                $projectConfiguration = $project.Configuration
            }

            Write-Console "Remove old files in $publishProfileDirectoryLocation for upcoming msbuild process"
            if (Test-Path $publishProfileDirectoryLocation) {
                #rd -Path $publishProfileDirectoryLocation -Force -Confirm:$false -Recurse:$true -ErrorAction Stop | out-null
                Get-ChildItem -Path "$publishProfileDirectoryLocation\\*" -Recurse | Remove-Item -Force -Recurse -Confirm:$false
                Remove-Item $publishProfileDirectoryLocation -Force -Recurse -Confirm:$false
            }

            Write-Console "Msbuild processing for $csprojLocationApplication"
            Write-Progress -Activity "Building Files" -Status "Progress:" -PercentComplete 50
            if ([string]::IsNullOrWhiteSpace($project.ProfileDeploy) -ne $true) {
                PublishProject -pathToFileExe $global:msbuildLocationPath `
                -pathToCsProj $csprojLocationApplication `
                -publishProfile $project.ProfileDeploy `
                -workingDirectory $solutionLocationApplication `
                -solutionDirectory $solutionLocationApplication `
                -configuration $projectConfiguration `
                -verboseOutput $mainConfiguration.MsBuildVerbose `
                -publishDirectory $publishProfileDirectoryLocation `
                -projectDirectory $csprojDirectoryLocation
            } else {
                OnlyBuildProject -pathToFileExe $global:msbuildLocationPath `
                -pathToCsProj $csprojLocationApplication `
                -workingDirectory $csprojDirectoryLocation `
                -solutionDirectory $solutionLocationApplication `
                -configuration $projectConfiguration `
                -verboseOutput $mainConfiguration.MsBuildVerbose `
                -publishDirectory $publishProfileDirectoryLocation `
                -projectDirectory $csprojDirectoryLocation
            }
            
            Write-Progress -Activity "Building Files" -Status "Progress:" -PercentComplete 100 -Completed
        }
    }

    #SetValueCachedConfiguration -parameter "Applications" -newValue $applications
}

function PostPublishingScriptExecute {
    Param()

    #1. If you'd use more than 1 application for migrator in applicationSetting you have to randomize LockHost for every server
}