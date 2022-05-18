# Script based on https://github.com/romainsi/zabbix-scheduledtask/blob/master/Zabbix v3.4/DiscoverScheduledTasks.ps1


# Script: DiscoverSchelduledTasks
# Author: Romain Si
# Revision: Isaac de Moraes
# Update: mtxadmin


# This script is intended for use with Zabbix > 3.x
#
#
# Add to Zabbix Agent
#   UserParameter=TaskSchedulerMonitoring[*],powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\DiscoverScheduledTasks.ps1" "$1" "$2"
#
## Change the $path variable to indicate the Scheduled Tasks subfolder to be processed as "\nameFolder\","\nameFolder2\subfolder\" see (Get-ScheduledTask -TaskPath )
## For discovery task to the root folder use "\"


# Script parameters:
$Mode = [string]$args[0]
$TaskName = [string]$args[1]
# They are not named, just positional. It is comfortable from Zabbix perspective:  TaskSchedulerMonitoring[TaskLastRunTime,"Adobe Acrobat Update Task"]



# Path - where to search for custom tasks. Typically, in the root.
$CustomTasksPath="\"


# Seeing dates in millions of a seconds is very bad solution. Function here just for information
function Convert-ToUnixDate ($Date) {
   $epoch = [timezone]::CurrentTimeZone.ToLocalTime([datetime]'1/1/1970')
   (New-TimeSpan -Start $epoch -End $Date).TotalSeconds
}


# Human-readable dates like 2022-03-30 04:59
function Convert-Date ($Date) {
    if ($Date) {
        if ($Date -ne "Never") {
            $Date = Get-Date -Format "yyyy-MM-dd HH:mm" -Date $Date
            # to avoid different time formats
            if ($Date -ne "1999-11-30 00:00") {  # "Never" too. We can also detect this by status 0x41303
                $Date
            } else {
                "Never"
            }
        } else {
            "Never"
        }
    } else {
        "-"  # for non-periodic tasks. For instance, BGinfo
    }
}


 
function Convert-UnicodeSymbolsToHtml ([string]$String) {
    # Here must be type [string]. Or else there will be error on taskname 1 or similar.
    # Also, it is only one string and not a massive - else it will merged with " " and converted to string - that's not very good.
    $string1 = $String.replace('â','&acirc;').replace('à','&agrave;').replace('ç','&ccedil;').replace('é','&eacute;').replace('è','&egrave;').replace('ê','&ecirc;')
    
    # Output. Again, string
    [string]$string1
}

$TaskName = Convert-UnicodeSymbolsToHtml -String $TaskName



# Mode of operaton:
# DiscoverCustomTasks - get all the tasks in the custom folder (root by default). 
switch ($Mode) {
    "DiscoverCustomTasks" {
        # Get all non-disabled tasks. Statuses: Ready and Running
        # Update: we need Disabled state as well
        $apptasks_all = (Get-ScheduledTask -TaskPath $CustomTasksPath | where {$_.state -in "Ready","Running","Disabled"}).TaskName

        # Correcting non-ASCII symbols in names
        $apptasks = @()   # Yes, by default it should be a massive
        $apptasks_all | % {
            $apptasks += Convert-UnicodeSymbolsToHtml -String $_  # add converted string from source massive to destination massive
        }

        # This block forms JSON output for Zabbix discovery. Of course, it can be better, but, hey, it works
        $idx = 1
        write-host "{"
        write-host " `"data`":[`n"
        foreach ($currentapptasks in $apptasks) {
            if ($idx -lt $apptasks.count) {
                $line= "{ `"{#APPTASKS}`" : `"" + $currentapptasks + "`" },"
                write-host $line
            } elseif ($idx -ge $apptasks.count) {
                $line= "{ `"{#APPTASKS}`" : `"" + $currentapptasks + "`" }"
                write-host $line
            }
            $idx++;
        } 
        write-host
        write-host " ]"
        write-host "}"
    }
    "TaskLastResult" {  # for easier googling the error code and the correcting methods
        $taskPath = (Get-ScheduledTask -TaskPath "*" -TaskName (Convert-UnicodeSymbolsToHtml -String $TaskName)).TaskPath
        $taskResult = Get-ScheduledTaskInfo -TaskPath $taskPath -TaskName $TaskName
        if ($taskResult.LastTaskResult -ge 0 -and $taskResult.LastTaskResult -lt 10) {
            $taskResult.LastTaskResult
        } else {
            # Convert dec output of $taskResult.LastTaskResult to hex form (more standard and more searchable)
            "0x" + ("{0:X}" -f $taskResult.LastTaskResult)
        }
    }
    "TaskLastRunTime" {
        $taskPath = (Get-ScheduledTask -TaskPath "*" -TaskName (Convert-UnicodeSymbolsToHtml -String $TaskName)).TaskPath
        $taskLastRunTime = Get-ScheduledTaskInfo -TaskPath $taskPath -TaskName $TaskName
        Convert-Date -Date $taskLastRunTime.LastRunTime
    }
    "TaskNextRunTime" {
        $taskPath = (Get-ScheduledTask -TaskPath "*" -TaskName (Convert-UnicodeSymbolsToHtml -String $TaskName)).TaskPath
        $taskNextRunTime = Get-ScheduledTaskInfo -TaskPath $taskPath -TaskName $TaskName
        Convert-Date -Date $taskNextRunTime.NextRunTime
    }
    "TaskState" {
        $task = Get-ScheduledTask -TaskPath "*" -TaskName (Convert-UnicodeSymbolsToHtml -String $TaskName)
        $task.State
    }
}
