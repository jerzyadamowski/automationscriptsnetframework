function HasNoteProperty(
    [object]$testObject,
    [string]$propertyName
)
{
    $members = Get-Member -InputObject $testObject 
    if ($members -ne $null -and $members.count -gt 0) 
    { 
        foreach($member in $members) 
        { 
            if ( ($member.MemberType -eq "NoteProperty" )  -and `
                 ($member.Name       -eq $propertyName) ) 
            { 
                return $true 
            } 
        } 
        return $false 
    } 
    else 
    { 
        return $false; 
    }
}

function StartProcessGetReturnCode {
    param(
        [string]$process,
        [string]$argument,
        [bool]$hideOutput,
        [string]$workingDirectory)

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "$process"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = "$argument"
    if ([string]::IsNullOrWhiteSpace($workingDirectory) -ne $true) {
        $pinfo.WorkingDirectory = $workingDirectory
    }
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    #$p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $errcode = $p.ExitCode
    if ($hideOutput -ne $true) {
        Write-Console -ForegroundColor DarkGreen "$stdout"
    }
    if ([string]::IsNullOrWhiteSpace($stderr) -ne $true) {
        Write-Console -ForegroundColor Red "$stderr"
    }
    Write-Console -ForegroundColor DarkGray "exit code: $errcode" 
    
    return $errcode
}

function FindFilePaths {
param(
    [string]$filter,
    [string]$path,
    [string]$errorifnotfound,
    [boolean]$verbose = $true
    )

    Write-Console "Searching for files: $filter in $path"
    Write-Progress -Activity "Searching Files" -Status "Progress:" -PercentComplete 50
    $filepath = Get-ChildItem -Verbose -Path $path -Filter $filter -Recurse -ErrorAction SilentlyContinue -Force | % { $_.FullName }
    Write-Progress -Activity "Searching Files" -Status "Progress:" -PercentComplete 100 -Completed
    if ($filepath -eq $null -and [string]::IsNullOrWhiteSpace($errorifnotfound) -ne $true) 
    {
        throw "$errorifnotfound" 
    } 
    else 
    {
        foreach($p in $filepath)
        {
            if($verbose -eq $true)
            {
                Write-Console -ForegroundColor DarkYellow "Found $filter path: $p"
            }
        }
    }
    
    return $filepath
}

function IsNull($objectToCheck) {
    if ($objectToCheck -eq $null) {
        return $true
    }

    if ($objectToCheck -is [String] -and $objectToCheck -eq [String]::Empty) {
        return $true
    }

    if ($objectToCheck -is [DBNull] -or $objectToCheck -is [System.Management.Automation.Language.NullString]) {
        return $true
    }

    return $false
}

function KillProcess {
    Write-Console "Kill all parallel processes for git.exe, nuget.exe or msbuild.exe - this prevents from the blocking scripts" -ForegroundColor DarkGreen

    get-process | where { $_.FileName -eq "git" } | stop-process -Force
    get-process | where { $_.FileName -eq "msbuild" } | stop-process -Force
    get-process | where { $_.FileName -eq "nuget" } | stop-process -Force
    get-process | where { $_.FileName -eq "7z" } | stop-process -Force
} 
    
    