function FindNugetLocationPath {
    Param()
    $directoriesFromConfig = GetValueMainConfiguration "LookingForNugetDirectoriesToScan"
    if (IsNull($directoriesFromConfig)) {
        $directories = @("/")
    } else {
        $directories = $directoriesFromConfig
    }
    $pathNuget = $null
    $resultPaths = [System.Collections.ArrayList]@()

    foreach($directory in $directories) {
        $pathToScan = $ExecutionContext.InvokeCommand.ExpandString($directory)

        $pathNugets = FindFilePaths -filter "nuget.exe" -path "$pathToScan" -verbose $false
        if ($pathNugets -ne $null) {
            if ($pathNugets.Count -le 2) {
                $resultPaths.Add($pathNugets) | Out-Null
            } else {
                $resultPaths.AddRange($pathNugets) | Out-Null
            }
        }
    }

    if ($resultPaths.Count -lt 1) {
        throw "nuget.exe file not found - install Nuget client"
    }
    
    $pathNugets = $resultPaths

    for ($i = 1; $i -le $pathNugets.Count; $i++) {
        $showPathNugets = $pathNugets[$i-1]

        Write-Console -ForegroundColor DarkYellow "$i. Found Nuget path: $showPathNugets"
    }

    $defaultAnswers = (GetValueMainConfiguration "AllPromptSelectDefaultAnswer")
    if ($pathNugets.Count -gt 1 -and [System.Convert]::ToBoolean($defaultAnswers) -eq $false ) {
        [bool]$testSelected = $false
        do {
            try {
                Write-Console -ForegroundColor DarkBlue "Select Nuget configuration:"
                [int]$selected = Read-Host
                if ($selected -gt 0 -and $selected -le $pathNugets.Count) {
                    $testSelected = $true
                    $pathNuget = $pathNugets[$selected-1]
                } else {
                    Write-Console -ForegroundColor DarkRed "Selected configuration out of range"    
                }
            }
            catch {
                Write-Console -ForegroundColor DarkRed "Wrong selected format"
            }
        } while ($testSelected -eq $false) 
    } else {
        $pathNuget = $pathNugets[0]
    }

    Write-Console -ForegroundColor DarkYellow "Selected Nuget path: $pathNuget"

    return $pathNuget
}

function VersionNuget {
    param(
        [Parameter(Mandatory=$true)][string]$pathToFileExe
    )

    #& "$pathToFileExe" help | select -First 1 
    $errorCode = StartProcessGetReturnCode -process "$pathToFileExe" -argument "help" -hideOutput $true
    if ($errorCode -ne 0) {
       throw "Nuget version check returns error - process will stop here"
    }
}

function RestorePackages {
    Param(
        [Parameter(Mandatory=$true)][string]$pathToFileExe,
        [Parameter(Mandatory=$true)][string]$workingDirectory
    )

    $errorCode = StartProcessGetReturnCode -process "$pathToFileExe" -argument "sources -Source http://oc-ec-app1.lan/nuget/nuget" -workingDirectory $workingDirectory 
    if ($errorCode -ne 0) {
        throw "Nuget sources update check returns error - process will stop here"
    }
    $errorCode = StartProcessGetReturnCode -process "$pathToFileExe" -argument "restore" -workingDirectory $workingDirectory
    if ($errorCode -ne 0) {
        throw "Nuget restore check returns error - process will stop here"
    }
}