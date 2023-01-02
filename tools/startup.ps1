<#
    .LINK
        https://powershell.one/tricks/filesystem/filesystemwatcher
#>

param(
    [string]$Source,
    [string]$Destination
)

function Invoke-Robocopy {
    param(
        [string]$Source,
        [string]$Destination
    )

    $event
    robocopy $Source $Destination /mir /nfl /ndl /njh /njs /nc /ns /np
}

Invoke-Robocopy -Source $Source -Destination $Destination > $null

try {
    Write-Host "Configuring filewatcher from $($Source) to $($Destination)"
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $Source
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName, [System.IO.NotifyFilters]::LastWrite
    $watcher.Filter = "*"
    $watcher.EnableRaisingEvents = $true
    $watcher.IncludeSubdirectories = $true

    $handlers = . {
        Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier File.Created -Action { Invoke-Robocopy -Source $Source -Destination $Destination }
        Register-ObjectEvent -InputObject $watcher -EventName Deleted -SourceIdentifier File.Deleted -Action { Invoke-Robocopy -Source $Source -Destination $Destination }
        Register-ObjectEvent -InputObject $watcher -EventName Changed -SourceIdentifier File.Changed -Action { Invoke-Robocopy -Source $Source -Destination $Destination }
        Register-ObjectEvent -InputObject $watcher -EventName Renamed -SourceIdentifier File.Renamed -Action { Invoke-Robocopy -Source $Source -Destination $Destination }
    }
    do
    {
        Wait-Event -Timeout 10
        $handlers | Receive-Job > $null
    } while ($true)
} finally {
    Write-Host "Shutting down filewatcher"
    $watcher.EnableRaisingEvents = $false
    $handlers | ForEach-Object {
        Unregister-Event -SourceIdentifier $_.Name
    }
    $handlers | Receive-Job
    $handlers | Remove-Job
    $watcher.Dispose()
}