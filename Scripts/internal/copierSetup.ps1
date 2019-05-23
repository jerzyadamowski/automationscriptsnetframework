function DeployManager {
    Param(
        [Parameter(Mandatory=$true)][string]$sourceDirectory,
        [Parameter(Mandatory=$true)][string]$destinationDirectory)

    #todo: implements
    CopyManager -pathToFileExe "Robocopy.exe" -copyArguments "/e /NFL /NDL /TEE /PURGE /MIR /R:30 /W:1 /XF stop.application" -sourceDirectory $sourceDirectory -destinationDirectory $destinationDirectory
}

function BackupRemoteManager {
    Param(
        [Parameter(Mandatory=$true)][string]$sourceDirectory,
        [Parameter(Mandatory=$true)][string]$destinationDirectory)

    CopyManager -pathToFileExe "Robocopy.exe" -copyArguments "/e /NFL /NDL /TEE /PURGE /MIR /R:30 /W:1" -sourceDirectory $sourceDirectory -destinationDirectory $destinationDirectory
}

function CopyManager {
    Param([Parameter(Mandatory=$true)][string]$pathToFileExe,
    [Parameter(Mandatory=$true)][string]$sourceDirectory,
    [Parameter(Mandatory=$true)][string]$destinationDirectory,
    [Parameter(Mandatory=$true)][string]$copyArguments)

    $errorCode = StartProcessGetReturnCode -process "$pathToFileExe" -argument "`"$sourceDirectory`" `"$destinationDirectory`" $copyArguments"
    if ($errorCode -gt 15) {
        throw "Robocopy returns error"
    }
}