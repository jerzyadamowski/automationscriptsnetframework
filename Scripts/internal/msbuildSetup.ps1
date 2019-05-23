$global:msbuildVersionActive = [string]$null

function FindMsBuildLocationPath {
    Param()
    ###### MS BUILD VERSION ACCEPTED #####
    $directoriesFromConfig = GetValueMainConfiguration "LookingForMsBuildDirectoriesToScan"
    if (IsNull($directoriesFromConfig)) {
        $directories = @("${env:ProgramFiles(x86)}", "${env:ProgramFiles}")
    } else {
        $directories = $directoriesFromConfig
    }
    [string[]]$msbuildversions = GetValueMainConfiguration "MsBuildAcceptedVersions"
    $msbuilddiscovered = $false
    $msbuildversiondiscovered = ""

    $collectionMsbuild = [System.Collections.ArrayList]@()
    $collectionMsbuildVersionDiscovered = [System.Collections.ArrayList]@()

    $msbuild = [string]$null
    $msbuildversiondiscovered = [string]$null

    foreach($directory in $directories)
    {
        $pathToScan = $ExecutionContext.InvokeCommand.ExpandString($directory)
        if (test-path "$pathToScan") 
        {
            foreach($ver in $msbuildversions)  
            {
                $path = join-path "$pathToScan" "MSBuild\$ver\bin\MSBuild.exe"
                if (test-path $path) 
                { 
                    $msbuild = $path
                    $msbuilddiscovered = $true
                    $msbuildversiondiscovered = $ver

                    $collectionMsbuild.Add($msbuild) | Out-Null
                    $collectionMsbuildVersionDiscovered.Add($msbuildversiondiscovered) | Out-Null
                }
            }
        }
        else
        {
            Write "Not found $pathToScan"
        }
    }

    if ($collectionMsbuild.Count -lt 1) {
        throw "msbuild.exe file not found - install msbuild client"
    }

    if ($msbuild -eq $null) 
    {
        throw "Could not find MSBuild. Please install it. Accepted version: $msbuildversions" 
    } 
    else 
    {
        for ($i = 1; $i -le $collectionMsbuild.Count; $i++) {
            $showMsBuild = $collectionMsbuild[$i-1]
            $showVersionDiscovered = $collectionMsbuildVersionDiscovered[$i-1]

            Write-Console -ForegroundColor DarkYellow "$i. Found MsBuild path: $showMsBuild"
            Write-Console -ForegroundColor DarkYellow "$i. Found MsBuild version: $showVersionDiscovered"                
        }

        $defaultAnswers = (GetValueMainConfiguration "AllPromptSelectDefaultAnswer")
        if ($collectionMsbuild.Count -gt 1 -and [System.Convert]::ToBoolean($defaultAnswers) -eq $false ) {
            [bool]$testSelected = $false
            do {
                try {
                    Write-Console -ForegroundColor DarkBlue "Select msbuild configuration:"
                    [int]$selected = Read-Host
                    if ($selected -gt 0 -and $selected -le $collectionMsbuild.Count) {
                        $testSelected = $true
                        $msbuild = $collectionMsbuild[$selected-1]
                        $sbuildversiondiscovered = $collectionMsbuildVersionDiscovered[$selected-1]
                    } else {
                        Write-Console -ForegroundColor DarkRed "Selected configuration out of range"    
                    }
                }
                catch {
                    Write-Console -ForegroundColor DarkRed "Wrong selected format"
                }
            } while ($testSelected -eq $false) 
        } else {
            #here we have only 1 version of msbuild
            $msbuild = $collectionMsbuild[0]
            $msbuildversiondiscovered = $collectionMsbuildVersionDiscovered[0]
        }
    }

    Write-Console -ForegroundColor DarkYellow "Selected MsBuild path: $msbuild"
    Write-Console -ForegroundColor DarkYellow "Selected MsBuild version: $msbuildversiondiscovered"   

    $global:msbuildVersionActive = $msbuildversiondiscovered

    return [string]$msbuild
}

function VersionMsBuild {
    param(
        [string]$pathToFileExe
    )

    $errorCode = StartProcessGetReturnCode -process "$pathToFileExe" -argument "/version"
    if ($errorCode -ne 0) {
        throw "MsBuild Version check returns error - process will stop here"
    }
}

function PublishProject {
    #to only build without publish profile
    #msbuild myproject.csproj /p:DeployOnBuild=true /p:PublishProfile=myprofile.
    Param(
        [Parameter(Mandatory=$true)][string]$pathToFileExe,
        [Parameter(Mandatory=$true)][string]$pathToCsProj,
        [Parameter(Mandatory=$true)][string]$projectDirectory,
        [Parameter(Mandatory=$true)][string]$publishProfile,
        [Parameter(Mandatory=$true)][string]$workingDirectory,
        [Parameter(Mandatory=$true)][string]$solutionDirectory,
        [Parameter(Mandatory=$true)][string]$configuration,
        [Parameter(Mandatory=$true)][string]$verboseOutput,
        [Parameter(Mandatory=$true)][string]$publishDirectory
        )

    $argument = "$pathToCsProj /nologo /m /p:DeployOnBuild=true /p:PublishProfile=$publishProfile /p:VisualStudioVersion=$global:msbuildVersionActive /p:SolutionDir=$solutionDirectory /t:Build /p:Configuration=$configuration /v:$verboseOutput /p:PublishUrl=$publishDirectory /ds /p:ProjectDir=$projectDirectory /p:DebugType=None /p:AllowedReferenceRelatedFileExtensions=None /p:DebugSymbols=false"
    
    $errorCode = StartProcessGetReturnCode -process "$pathToFileExe" -argument $argument -workingDirectory $workingDirectory
    if ($errorCode -ne 0) {
        throw "MsBuild build check returns error - process will stop here"
    }
}

function OnlyBuildProject {
    #to only build without publish profile
    #msbuild myproject.csproj /p:DeployOnBuild=true /p:PublishProfile=myprofile.
    Param(
        [Parameter(Mandatory=$true)][string]$pathToFileExe,
        [Parameter(Mandatory=$true)][string]$pathToCsProj,
        [Parameter(Mandatory=$true)][string]$projectDirectory,
        [Parameter(Mandatory=$true)][string]$workingDirectory,
        [Parameter(Mandatory=$true)][string]$solutionDirectory,
        [Parameter(Mandatory=$true)][string]$configuration,
        [Parameter(Mandatory=$true)][string]$verboseOutput,
        [Parameter(Mandatory=$true)][string]$publishDirectory
        )
        $argument = "$pathToCsProj /nologo /m /p:DeployOnBuild=true /p:VisualStudioVersion=$global:msbuildVersionActive /p:SolutionDir=$solutionDirectory /t:Build /p:Configuration=$configuration /v:$verboseOutput /p:OutDir=$publishDirectory /ds /p:ProjectDir=$projectDirectory /p:DebugType=None /p:AllowedReferenceRelatedFileExtensions=None /p:DebugSymbols=false"
        
    $errorCode = StartProcessGetReturnCode -process "$pathToFileExe" -argument $argument -workingDirectory $workingDirectory
    if ($errorCode -ne 0) {
        throw "MsBuild build check returns error - process will stop here"
    }
}