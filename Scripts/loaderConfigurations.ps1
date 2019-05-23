# configurations loaders
# If you want have clean start - delete file: /Config/cached.json
# You should always start at new machine with clean configuration

$global:mainConfiguration = $null
$global:variantConfiguration = $null
$global:cachedConfiguration = $null
$global:currentVariant = $CurrentVariant

function LoadConfiguration {
    Param (
    [parameter(Mandatory=$true)][string]$file
    )
    $path = "$StartDirectory\Config\$file"
    if (test-path $path) 
    {
        return (Get-Content -Raw -Path $path | ConvertFrom-Json)
    } else {
        return New-Object PSObject -Property @{ }
    }
  }

function LoadMainConfiguration {
    return LoadConfiguration "main.json"
}

function LoadVariantConfiguration {
    $variant = GetMainConfiguration
    
    #$variant.AvailableVariants.GetEnumerator() | % { $_.Value }
    foreach($item in $variant.AvailableVariants) {
        $itemName = $($item | Get-Member -MemberType *Property).Name
        if ($itemName -eq $global:currentVariant) {
            return LoadConfiguration $item."$($global:currentVariant)"
        }
    }
}

function LoadCachedConfiguration {
    return LoadConfiguration "cached.json"
}

function GetMainConfiguration {
    return $global:mainConfiguration
}

function GetVariantConfiguration {
    return $global:variantConfiguration
}

function GetCachedConfiguration {
    return $global:cachedConfiguration
}

function GetValueConfiguration {
    Param(
        $entireConfig,
        [string]$parameter)

    if ([bool]($entireConfig.PSobject.Properties.name -match $parameter)){
        return $entireConfig."$parameter" 
    } else {
        return $null
    }
}

function GetValueMainConfiguration {
    Param([string]$parameter)
    $config = GetMainConfiguration
    return GetValueConfiguration $config $parameter
}

function GetValueVariantConfiguration {
    Param([string]$parameter)
    $config = GetVariantConfiguration
    return GetValueConfiguration $config $parameter
}

function GetValueCachedConfiguration {
    Param([string]$parameter)
    $config = GetCachedConfiguration
    return GetValueConfiguration $config $parameter
}

function SetValueConfiguration {
    Param($entireConfig,
    [string]$fileName,
    [string]$parameter,
    [psobject]$newValue)
    
    # if (IsNull($entireConfig) -eq $true) {
    #     $entireConfig = New-Object PSObject
    #     $entireConfig | Add-Member -memberType NoteProperty -name $parameter -value $newValue
    # } else {
        $properties = ($($entireConfig | Get-Member -MemberType *Property).Name)
        $resultFindProperty = $false
        foreach($property in $properties) {
            if ($property -eq $parameter) {
                $resultFindProperty = $true
            }
        }

        if ($resultFindProperty -eq $false) {
            $entireConfig | Add-Member -memberType NoteProperty -name $parameter -value $newValue
        } else {
            $entireConfig."$parameter" = $newValue
        }
    # }
    $path = "$StartDirectory\Config\$fileName"

    $entireConfig | ConvertTo-Json -Depth 32 | Out-File -FilePath $path -Force
}

function SetValueCachedConfiguration {
    Param(
        [string]$parameter,
        [psobject]$newValue
    )
    $config = LoadCachedConfiguration
    SetValueConfiguration -entireConfig $config -fileName "cached.json" -parameter $parameter -newValue $newValue
}


#begin of loaderConfigurations.ps1
Write-Console "Read configurations" -ForegroundColor Green -BackgroundColor White
$global:mainConfiguration = LoadMainConfiguration
Write-Console "Main configuration" -ForegroundColor Green -BackgroundColor Black
$global:variantConfiguration = LoadVariantConfiguration
Write-Console "Variant configuration" -ForegroundColor Green -BackgroundColor Black
$global:cachedConfiguration = LoadCachedConfiguration
Write-Console "Cached configuration" -ForegroundColor Green -BackgroundColor Black
#end of loaderConfigurations.ps1




