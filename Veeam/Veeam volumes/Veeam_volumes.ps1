# Script that counts disk space of Veeam backups in terms of systems (groups of servers)
# Collected data are sent to Zabbix

# In the first version I thought to list folders.
#$Backups_folders = "V:\Veeam\Backup", "Y:\Veeam\Backup"
# But it turned out that disk letters can change. Ok, let's make some sort of autodetection
$Backups_folders = @()
# https://www.thewindowsclub.com/list-drives-using-command-prompt-powershell-windows
$disks = wmic logicaldisk get name | ? {$_} | ? {$_ -match ":"}
$disks | % {
    $disk = $_.trim()  # data is not very clean, there are spaces in the end
    if (Get-Item "$disk\Veeam\Backup" -ErrorAction SilentlyContinue) {
        $Backups_folders += "$disk\Veeam\Backup"
    }
}

$Results = @()  # init of result array
# our Veeam server has Powershell 4.0 installed. PS classes need 5.0, so no classes for now


cls

# In PS, there is no native way to convert data from YAML format.
# There are two community projects for that. The first one was not working for me because of PS5 needed, but the second one is working and working well enough. See PSYaml.
Import-Module C:\zabbix\scripts\PSYaml\PSYaml


# Ok, first of all, let's look at backup files
# In Veeam, backup files have names "SERVERNAME.vm-[0-9A-Z_-]+.(vbk|vib)"
# And sometimes *.vbm, but they are small and don't contain server names
#
# https://helpcenter.veeam.com/docs/agentforwindows/userguide/backup_files.html :
#   VBK — full backup file
#   VIB — incremental backup file
#   VBM — backup metadata file. The backup metadata file is updated with every backup job session. 
#     It contains information about the computer on which the backup was created, every restore point in the backup chain, how restore points are linked to each other and so on. 
#     The backup metadata file is required for performing file-level and volume-level restore operations.
#   For backup jobs with database log backup options enabled, Veeam Agent for Microsoft Windows additionally produces backup files of the following types:
#     VLB, VSM and VLM files — for Microsoft SQL Server transaction log backups
#     VLB, VOM and VLM files — for Oracle archived log backups
#
# Also, *.bco - it's backups of the Veeam config:
# https://forums.veeam.com/veeam-backup-replication-f2/what-is-folder-veeamconfigbackup-in-repository-bco-files-t14067.html
# They fall in the name convention, but server name is of Veeam server itself

$Backups = $null
$Backups_folders | % {
    $Backups += Get-ChildItem -Path $_ -File -Recurse 
}

# Initially, I intended to make and edit systems/servers list on local Gitlab, on the central point.
# But it turned out, that the https access is restricted on the network level.
# So, for now it will be a local file on each servers. Sorry, guys, I know, it is not a very good solution.
#
#$gitlab_list_address = "https://.../corp_systems.txt"
#Invoke-WebRequest -UseBasicParsing -Uri $gitlab_list_address
#
$gitlab_list_table = (Get-Content -Path "C:\zabbix\scripts\corp_systems.txt") -join "`n" | ? {$_}
$gitlab_list = ConvertFrom-YAML $gitlab_list_table  # PSYaml function


# Something unusual here with that hashtable.
# I wanted to make a cycle like  $gitlab_list | % { ... }
# It turned out, it doesn't work. But $gitlab_list[0], $gitlab_list[1]... is working. Weird. Ok, let's do a cycle in this way:
#for ($i=0;$i -lt 2;$i++) {
#    echo $i
#    echo $gitlab_list[$i]
#    echo "================="
#}

# Better way:
$gitlab_list.Keys | % {
    $system_name = $_
    $servers_array = $gitlab_list.$system_name
    

    # Now, let's look at every filename and add the size to corresponding system's size (current one)
    # Note: I suppose, this structure is not very optimal in terms of performance, but it is clear and relatively easy to implement
    # Update: There is no need to worry about performance, at least in our scale. This structure works blazing fast
    #
    # Note: it is more convenient to make cycles first on systems and second on backup files.
    #
    # First cycle: servers of the current system
    $system_size = 0  # size of backups, initially 0
    $flag_filename_is_matched = $false  # flag: we matched the current file to YAML structrure. If not, we should know it

    $servers_array | % {
        $current_server_name = $_

        # Second cycle: backups files
        $Backups | % {
            $file = $_
            $file_name = $file.BaseName
            $file_size = $file.Length

            if ($file_name -match $current_server_name) {
                # Just for debug. Feel free to comment/uncomment this string
                Write-Host ("$file_name -> matches $current_server_name, size=" + ([math]::ceiling($file_size / 1GB)) + " GB")
                # Adding the file size to corresponding system. Update: in gigabytes
                $system_size += $file_size

                $flag_filename_is_matched = $true
            }

            # And adding this to total size of all backups
            $total_size += $file_size
        }
    }
    $system_size = ([math]::ceiling($system_size / 1GB))  # Update: in gigabytes, rounded up
    # Note: do not directly transfer to gigabytes backup files' sizes, it will be too large round error

    if ($system_size -gt 1) {  # don't get empty entities
        # No classes for now (see above), so adding properties. Implementation may vary
        $result = New-Object PSCustomObject
        $result | add-member –membertype NoteProperty -Name "Name" -Value $system_name
        $result | add-member –membertype NoteProperty -Name "Backup_size" -Value $system_size

        $Results += $result

        Write-Host "------------------------------------------------------"
        Write-Host "System: $system_name, Size: $system_size GB"
        Write-Host "======================================================"
    }
}

# And just calculating total size
# Yes, it can be done within a cycle above (with some flag), but let's do a different cycle, it's easier to read
$total_size = 0  # total size of backups
$Backups | % {
    $file = $_
    $file_name = $file.BaseName
    $file_size = $file.Length

    # Adding this to total size of all backups
    $total_size += $file_size
}

$total_size = ([math]::ceiling($total_size / 1GB))  # Update: in gigabytes, rounded up


# Results are in $Results. let's convert them to JSON and send/return them to Zabbix

# Variant 1. You have full access to the Veeam server
# 1. Add to Zabbix agent config: UserParameter=veeam_volumes,powershell -NoProfile -ExecutionPolicy Bypass -File "c:\zabbix\scripts\Veeam_volumes.ps1" "$1" "$2" "$3"
# 2. Restart Zabbix agent
# 3. Use  ConvertTo-Json $Results  to return value (for Zabbix agent or Zabbix agent Active types)

# Variant 2. You have limited access to the Veeam server
# 1. Do not alter Zabbix agent config (since you can't edit it or can't restart the service)
# 2. Use traps to send result to Zabbix (for Zabbix trapper type)

# Here is implemented Variant 2 with limited access and Zabbix trappers

C:\zabbix\bin\zabbix_sender.exe -c C:\zabbix\zabbix_agentd.conf -k veeam_volumes_json -o ((ConvertTo-Json $Results) -replace '\n' -replace "\`"","`"`"")
  # -replace '\n'  - removing new lines is just for smooth display of latest data
  # -replace "\`"","`"`""  - double quotes to prevent their disappearing. See:
     # https://www.zabbix.com/forum/zabbix-help/437446-zabbix-sender-removes-double-quotes
     # https://www.reddit.com/r/zabbix/comments/rp1juo/zabbix_sender_removes_quotes/


# And in the end, let's send free space and total size of backups

# backups disk
# There are standard items for total space, free space and % of used
# vfs.fs.size[{#FSNAME},total]
# vfs.fs.size[{#FSNAME},used]
# vfs.fs.size[{#FSNAME},pused]
# vfs.fs.size[{#FSNAME},free] - calculated item from my custom template
# Of course, we can make duplicate items, but this is not very convenient.
# Update: these standard items for free space only exist for local drives formatted in NTFS.
# In case of ReFS disks (or, maybe, mounted?), we don't see anything
# So, let's take already made $Backups_folders and make cycle through disks
$Backups_disks = @()
$Backups_folders | % {
    $disk = $_ -replace ":.*"  # Get-Volume needs letter only

    $result = New-Object PSCustomObject
    $result | add-member –membertype NoteProperty -Name "Name" -Value $disk
    $result | add-member –membertype NoteProperty -Name "Total_size" -Value ([math]::floor((Get-Volume -DriveLetter $disk).Size / 1GB))
    $result | add-member –membertype NoteProperty -Name "Free_space" -Value ([math]::floor((Get-Volume -DriveLetter $disk).SizeRemaining / 1GB))

    $Backups_disks += $result

}
# Send disks data to Zabbix. See comments about json above
C:\zabbix\bin\zabbix_sender.exe -c C:\zabbix\zabbix_agentd.conf -k veeam_disks_json -o ((ConvertTo-Json $Backups_disks) -replace '\n' -replace "\`"","`"`"")

# And let's calculate and send folder size on this server. See $total_size above in the cycle
# Of course, it will be kind of duplicate of the data above. But just for convenience
C:\zabbix\bin\zabbix_sender.exe -c C:\zabbix\zabbix_agentd.conf -k ("veeam_total_size[$env:computername]") -o $total_size


# Just for convenience: size of backups which do not belong to any system. Non-zero size indicates that YAML file with systems needs correcting
# Another cycle through systems. We cannot add it to previous because we don't have total size at that moment
# Moreover, we can use above-formed $Results for that, instead of cycle through $gitlab_list.Keys
$marked_size = 0
$Results | % {
   $marked_size += $_.Backup_size
   # Just for debug
   Write-Host ("Size of system " + $_.Name + " : " + $_.Backup_size + " GB")
}
Write-Host ("Total size of systems : $marked_size GB" )
$unmarked_size = $total_size - $marked_size
Write-Host ("Unmarked size : $unmarked_size GB" )
if ($unmarked_size -gt 500) {
    Write-Host "Unmarked size is big, please see and correct YAML file of systems"
}

# Results as a table. You can send the file by mail, instead of looking to Grafana dashboard
$Results | ConvertTo-Csv -Delimiter ";" -NoTypeInformation | Out-File "C:\zabbix\Veeam_volumes.csv"
