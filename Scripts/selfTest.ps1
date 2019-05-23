function SelfTestCheckRoutines  {
    Param()
    Write-Console "We are doing self-test check for test your environment objects" -ForegroundColor Green
    Write-Console "if you don't have any of these things you have to install required packages." -ForegroundColor Green

    $ignoreCheckIsAdministratorMode = GetValueMainConfiguration "IgnoreCheckIsAdministratorMode"
    if ([System.Convert]::ToBoolean($ignoreCheckIsAdministratorMode) -ne $true) {
        IsAdministratorMode
    }
    IsPowershellVersionCorrect
    IsToFlushedCachedConfiguration
}

function IsAdministratorMode {
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    
        [Security.Principal.WindowsBuiltInRole] "Administrator"))
    
    {
        Write-Error "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
        throw "You aren't administrator. Please evelate current window to administrator. eg:> Start-Process powershell -verb runas"
    } 
    
    Write-Console "Administrator Mode [OK]" -ForegroundColor Green -BackgroundColor Black
}

function IsPowershellVersionCorrect {
    $mainConfig = GetMainConfiguration 
    $tmplocalVersion = [string]$PSVersionTable.PSVersion;
    $localVersion = $tmplocalVersion.Substring(0, ([string]$PSVersionTable.PSVersion).IndexOf("."))

    if ( [decimal]($localVersion) -lt [decimal]($mainConfig."PSVersionMinimumRequired")) {
        $errorMessage = "Your Powershell version doesn't meet minimum version required. Required: $($mainConfig.PSVersionMinimumRequired) Actual: $($PSVersionTable.PSVersion)"
        Write-Error $errorMessage
        throw $errorMessage
    }

    $tmplocalVersion = [string]$PSVersionTable.PSVersion;
    $localVersion = $tmplocalVersion.Substring(0, ([string]$PSVersionTable.PSVersion).IndexOf("."))


    Write-Console "Powershell vesion [OK]" -ForegroundColor Green -BackgroundColor Black
}

function IsToFlushedCachedConfiguration {
    $rawAlwaysCleanStart = GetValueVariantConfiguration "AlwaysCleanStart"
    $alwaysCleanStart = [System.Convert]::ToBoolean($rawAlwaysCleanStart)
    if ($alwaysCleanStart -eq $true) {
        $path = "$StartDirectory\Config\cached.json"
        New-Object PSObject -Property @{ } | ConvertTo-Json -Depth 1 | Out-File -FilePath $path -Force
        $global:cachedConfiguration = LoadCachedConfiguration
    }
}

