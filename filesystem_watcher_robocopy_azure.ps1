$folderSource = 'C:\source' # Enter the source root path you want to monitor.
$folderDestination = 'C:\destination' # Enter the destination root path you want to monitor.This can be a local directory or a directory mapped to the Azure StorageAccount drive.
$filter = '*.*'  # Enter a wildcard filter here.
$logs = 'C:\logs\robocopy.txt'
$logsfilewatcher= 'C:\logs\filewatcher.txt'
$fsw = New-Object IO.FileSystemWatcher $folderSource, $filter -Property @{IncludeSubdirectories = $true;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'}
$fswBack = New-Object IO.FileSystemWatcher $folderDestination, $filter -Property @{IncludeSubdirectories = $true;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'}

function FileGo {
    $name = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType
    $timeStamp = $Event.TimeGenerated
    net use Z: \\directory /u:AZURE\account public_key_password # Drive Mapping in Windows for an Azure StorageAccount (Optional).
    robocopy $folderSource $folderDestination /MIR /DST /FFT /XO /XJ /MT:8 /R:3 /W:10 /Z /NP /NDL /XF ~* *.TMP /LOG:"$logs"
    Write-Host "The file '$name' was $changeType at $timeStamp" -fore green
    Out-File -FilePath $logsfilewatcher -Append -InputObject "The file '$name' was $changeType at $timeStamp"
    }

function FileBack {
    $nameBack = $Event.SourceEventArgs.Name
    $changeTypeBack = $Event.SourceEventArgs.ChangeType
    $timeStampBack = $Event.TimeGenerated
    net use Z: \\directory /u:AZURE\account public_key_password # Drive Mapping in Windows for an Azure StorageAccount (Optional).
    robocopy $folderSource $folderDestination /MIR /DST /FFT /XO /XJ /MT:8 /R:3 /W:10 /Z /NP /NDL /XF ~* *.TMP /LOG:"$logs"
    Write-Host "The file '$nameBack' was $changeTypeBack at $timeStampBack" -fore green
    Out-File -FilePath $logsfilewatcher -Append -InputObject "The file '$nameBack' was $changeTypeBack at $timeStampBack"
    }

#Go
Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action {
    FileGo
    }

Register-ObjectEvent $fsw Deleted -SourceIdentifier FileDeleted -Action {
    FileGo
    }

Register-ObjectEvent $fsw Changed -SourceIdentifier FileChanged -Action {
    FileGo
    }

Register-ObjectEvent $fsw Renamed -SourceIdentifier FileRenamed -Action {
   FileGo
    }
    
#Back
Register-ObjectEvent $fswBack Created -SourceIdentifier FileCreatedBack -Action {
    FileBack
    }

Register-ObjectEvent $fswBack Deleted -SourceIdentifier FileDeletedBack -Action {
      FileBack
    }

Register-ObjectEvent $fswBack Changed -SourceIdentifier FileChangedBack -Action {
      FileBack
    }

Register-ObjectEvent $fswBack Renamed -SourceIdentifier FileRenamedBack -Action {
     FileBack
    }

#To stop the monitoring, run the following commands:
#Unregister-Event FileDeleted
#Unregister-Event FileCreated
#Unregister-Event FileChanged
#Unregister-Event FileRenamed
#Unregister-Event FileDeletedBack
#Unregister-Event FileCreatedBack
#Unregister-Event FileChangedBack
#Unregister-Event FileRenamedBack
