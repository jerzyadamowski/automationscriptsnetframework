$global:msbuildLocationPath = [string]$null
$global:gitLocationPath = [string]$null
$global:nugetLocationPath = [string]$null
$global:sevenZipLocationPath = [string]$null

#include internal modules
. .\Scripts\internal\msbuildSetup.ps1
. .\Scripts\internal\gitSetup.ps1
. .\Scripts\internal\nugetSetup.ps1
. .\Scripts\internal\compressSetup.ps1


function ToolsStatusAnalyzerCheckRoutines {
    Param()
    Write-Console "Tools Status Analyzer " -ForegroundColor Green
    Write-Console "if you don't have any of these things you have to install required packages." -ForegroundColor Green
    IsGitToolInstalled
    Write-Console "Git Tools [OK]" -ForegroundColor Green -BackgroundColor Black
    IsMsBuildInstalled
    Write-Console "Ms Build Tools [OK]" -ForegroundColor Green -BackgroundColor Black
    IsNugetInstalled
    Write-Console "Nuget Tools [OK]" -ForegroundColor Green -BackgroundColor Black
    Is7ZipInstalled
    Write-Console "7zip Tools [OK]" -ForegroundColor Green -BackgroundColor Black

    KillProcess
}

function IsGitToolInstalled {
    $global:gitLocationPath = GetValueCachedConfiguration "gitLocationPath"
    if ([string]::IsNullOrWhiteSpace($global:gitLocationPath)) {
        $global:gitLocationPath = FindGitLocationPath
    } else {
        Write-Console "Git Location Path - retrieved from cache"
    }
    
    VersionGit $global:gitLocationPath
    SetValueCachedConfiguration -parameter "gitLocationPath" -newValue $global:gitLocationPath
}

function IsMsBuildInstalled {
    $global:msbuildLocationPath = GetValueCachedConfiguration "msbuildLocationPath"
    $global:msbuildVersionActive = GetValueCachedConfiguration "msbuildVersionActive"
    if ([string]::IsNullOrWhiteSpace($global:msbuildLocationPath)) {
        $global:msbuildLocationPath = FindMsBuildLocationPath
    } else {
        Write-Console "Msbuild Location Path - retrieved from cache"
    }
    VersionMsBuild $global:msbuildLocationPath
    SetValueCachedConfiguration -parameter "msbuildLocationPath" -newValue $global:msbuildLocationPath
    SetValueCachedConfiguration -parameter "msbuildVersionActive" -newValue $global:msbuildVersionActive
}

function IsNugetInstalled {
    $global:nugetLocationPath = GetValueCachedConfiguration "nugetLocationPath"
    if ([string]::IsNullOrWhiteSpace($global:nugetLocationPath)) {
        $global:nugetLocationPath = FindNugetLocationPath 
    } else {
        Write-Console "Nuget Location Path - retrieved from cache"
    }
    VersionNuget $global:nugetLocationPath
    SetValueCachedConfiguration -parameter "nugetLocationPath" -newValue $global:nugetLocationPath
}

function Is7ZipInstalled {
    $global:sevenZipLocationPath = GetValueCachedConfiguration "sevenZipLocationPath"
    if ([string]::IsNullOrWhiteSpace($global:sevenZipLocationPath)) {
        $global:sevenZipLocationPath = Find7ZipLocationPath
    } else {
        Write-Console "7zip Location Path - retrieved from cache"
    }
    Version7zip $global:sevenZipLocationPath
    SetValueCachedConfiguration -parameter "sevenZipLocationPath" -newValue $global:sevenZipLocationPath  
}

