function FindGitLocationPath {
    Param()
    $directoriesFromConfig = GetValueMainConfiguration "LookingForGitDirectoriesToScan"
    if (IsNull($directoriesFromConfig)) {
        $directories = @("${env:ProgramFiles(x86)}", "${env:ProgramFiles}")
    } else {
        $directories = $directoriesFromConfig
    }
    
    $pathGit = $null
    $resultPaths = [System.Collections.ArrayList]@()

    foreach($directory in $directories) {
        $pathToScan = $ExecutionContext.InvokeCommand.ExpandString($directory)

        $pathGits = FindFilePaths -filter "git.exe" -path "$pathToScan" -verbose $false
        if ($pathGits -ne $null) {
            if ($pathGits.Count -lt 2 ) {
                $resultPaths.Add($pathGits) | Out-Null
            } else {
                $resultPaths.AddRange($pathGits) | Out-Null
            }
        }
    }

    if ($resultPaths.Count -lt 1) {
        throw "Git.exe file not found - install git client"
    }
    
    $pathGits = $resultPaths

    for ($i = 1; $i -le $pathGits.Count; $i++) {
        $showPathGits = $pathGits[$i-1]

        Write-Console -ForegroundColor DarkYellow "$i. Found Git path: $showPathGits"
    }

    $defaultAnswers = (GetValueMainConfiguration "AllPromptSelectDefaultAnswer")
    if ($pathGits.Count -gt 1 -and [System.Convert]::ToBoolean($defaultAnswers) -eq $false ) {
        [bool]$testSelected = $false
        do {
            try {
                Write-Console -ForegroundColor DarkBlue "Select git configuration:"
                [int]$selected = Read-Host
                if ($selected -gt 0 -and $selected -le $pathGits.Count) {
                    $testSelected = $true
                    $pathGit = $pathGits[$selected-1]
                } else {
                    Write-Console -ForegroundColor DarkRed "Selected configuration out of range"    
                }
            }
            catch {
                Write-Console -ForegroundColor DarkRed "Wrong selected format"
            }
        } while ($testSelected -eq $false) 
    } else {
        $pathGit = $pathGits[0]
    }

    Write-Console -ForegroundColor DarkYellow "Selected Git path: $pathGit"

    return $pathGit
}

function VersionGit {
    param(
        [string]$pathToFileExe
    )
    
    $errorCode = StartProcessGetReturnCode -process "$pathToFileExe" -argument "--version"
    if ($errorCode -ne 0) {
        throw "Git version check returns error - process will stop here"
    }
}

function GitClone {
    Param([Parameter(Mandatory=$true)][string]$pathToFileExe,
    [Parameter(Mandatory=$true)][string]$workingDirectory,
    [Parameter(Mandatory=$true)][string]$applicationName,
    [Parameter(Mandatory=$true)][string]$repositoryLocation,
    [Parameter(Mandatory=$true)][string]$branch)

    $checkoutPath = join-path $workingDirectory -childPath $applicationName
    $errorCode = StartProcessGetReturnCode -process "$pathToFileExe" -argument "clone -q $repositoryLocation $applicationName" -workingDirectory "$workingDirectory"
    if ($errorCode -ne 0) {
        throw "Git Clone returns error"
    }
    $errorCode = StartProcessGetReturnCode -process "$pathToFileExe" -argument "checkout $branch" -workingDirectory "$checkoutPath"
    if ($errorCode -ne 0) {
        throw "Git checkout returns error"
    }
}

function GitPull {
    Param([Parameter(Mandatory=$true)][string]$pathToFileExe,
    [Parameter(Mandatory=$true)][string]$workingDirectory,
    [Parameter(Mandatory=$true)][string]$applicationName)

    $pullPath = join-path $workingDirectory -childPath $applicationName
    $errorCode = StartProcessGetReturnCode -process "$pathToFileExe" -argument "pull" -workingDirectory "$pullPath"
    if ($errorCode -ne 0) {
        throw "Git pull returns error"
    }
}