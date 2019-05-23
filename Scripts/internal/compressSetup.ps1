function Find7ZipLocationPath {
    Param()
    $directoriesFromConfig = GetValueMainConfiguration "LookingFor7ZipDirectoriesToScan"
    if (IsNull($directoriesFromConfig)) {
        $directories = @("${env:ProgramFiles(x86)}", "${env:ProgramFiles}")
    } else {
        $directories = $directoriesFromConfig
    }
    $pathZip = $null
    $resultPaths = [System.Collections.ArrayList]@()

    foreach($directory in $directories) {
        $pathToScan = $ExecutionContext.InvokeCommand.ExpandString($directory)

        $pathZips = FindFilePaths -filter "7z.exe" -path "$pathToScan" -verbose $false
        if ($pathZips -ne $null) {
            if ($pathZips.Count -lt 2) {
                $resultPaths.Add($pathZips) | Out-Null
            } else {
                $resultPaths.AddRange($pathZips) | Out-Null
            }
        }
    }

    if ($resultPaths.Count -lt 1) {
        throw "7z.exe file not found - install 7zip client"
    }
    
    $pathZips = $resultPaths

    for ($i = 1; $i -le $pathZips.Count; $i++) {
        $showPathNugets = $pathZips[$i-1]

        Write-Console -ForegroundColor DarkYellow "$i. Found 7zip path: $showPathNugets"
    }

    $defaultAnswers = (GetValueMainConfiguration "AllPromptSelectDefaultAnswer")
    if ($pathZips.Count -gt 1 -and [System.Convert]::ToBoolean($defaultAnswers) -eq $false ) {
        [bool]$testSelected = $false
        do {
            try {
                Write-Console -ForegroundColor DarkBlue "Select 7zip configuration:"
                [int]$selected = Read-Host
                if ($selected -gt 0 -and $selected -le $pathZips.Count) {
                    $testSelected = $true
                    $pathZip = $pathZips[$selected-1]
                } else {
                    Write-Console -ForegroundColor DarkRed "Selected configuration out of range"    
                }
            }
            catch {
                Write-Console -ForegroundColor DarkRed "Wrong selected format"
            }
        } while ($testSelected -eq $false) 
    } else {
        $pathZip = $pathZips[0]
    }

    Write-Console -ForegroundColor DarkYellow "Selected 7zip path: $pathZip"

    return $pathZip
}

function Version7zip {
    param(
        [Parameter(Mandatory=$true)][string]$pathToFileExe
    )

    #& "$pathToFileExe" help | select -First 1 
    $errorCode = StartProcessGetReturnCode -process "$pathToFileExe" -argument "" -hideOutput $true
    if ($errorCode -ne 0) {
       throw "7zip version check returns error - process will stop here"
    }
}

function CompressManager {
    param(
        [Parameter(Mandatory=$true)][string]$pathToFileExe,
        [Parameter(Mandatory=$true)][string]$sourceToArchiveDirectory,
        [Parameter(Mandatory=$true)][string]$destinationArchiveFile
    )
    
    $errorCode = StartProcessGetReturnCode -process "$pathToFileExe" -argument "a -tzip $destinationArchiveFile $sourceToArchiveDirectory -r"
    if ($errorCode -ne 0) {
        throw "7zip version check returns error - process will stop here"
    }
}

