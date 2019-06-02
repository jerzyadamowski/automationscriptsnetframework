# Autogenerate path for log file
function GetLogFileName () {
    $datetime = Get-Date
    return "$StartDirectory" + "\Logs\" + $datetime.Day +"-"+ $datetime.Month + "-" +$datetime.Year +"_out.txt";
}

# This function check if our log file does exist and if not create new file
function PreserveCreateNewFile() {
    $filePath = GetLogFileName
    if (test-path "$filePath")
    {
        return $true | out-null
    } else {
        New-Item "$filePath" -type file -force | out-null
        return $true | out-null
    }
}
# Our method to write to host and file
function Write-Console {
    Param(
      [String]$params,
      [System.ConsoleColor]$ForegroundColor,
      [System.ConsoleColor]$BackgroundColor
    )

    PreserveCreateNewFile
    $pathFile = GetLogFileName

    if( $ForegroundColor -eq $null)
    {
        $ForegroundColor = [System.ConsoleColor]::DarkYellow
    }

    if( $BackgroundColor -eq $null)
    {
        $BackgroundColor = [System.ConsoleColor]::Black
    }

    $dateTimeStamp = (get-date).GetDateTimeFormats()[23] #26 - simpler format

    $bufferToWrite = "[$dateTimeStamp] " + $params

    #Write-Host "[$dateTimeStamp]" @params -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor | Out-File -FilePath $pathFile
    Write-Host $bufferToWrite -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    $bufferToWrite | Out-File -FilePath $pathFile -Append | Out-Null
}

