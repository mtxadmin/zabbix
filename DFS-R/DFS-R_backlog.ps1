param ([CmdletBinding()][ValidateSet("Setup","Scheduler")][String]$Mode="Setup")
# By default, script adds keys to zabbix. This can be done in manual mode
# When adding the script to scheduler, add parameter -Mode Scheduler

$zabbix_server_url = "http://zabbix.domain.local"

<# Only for example. Do not enter real credentials in saved script! Enter them in temporarily session in setup process.
$user = "Admin"
$password = "zabbix"
#>

function Zabbix-GetProxyByHostname ([String]$Hostname) {
    # Custom function

    # You can tailor rule block for your infrastructure here. Example:
    if ($Hostname.StartsWith("HQ-"))  {$zabbix_proxy = "10.1.0.100"}
    if ($Hostname.StartsWith("BR1-")) {$zabbix_proxy = "10.2.0.100"}
    if ($Hostname.StartsWith("BR2-")) {$zabbix_proxy = "10.3.0.100"}
    if ($Hostname.StartsWith("BR3-")) {$zabbix_proxy = "10.4.0.100"}

    return $zabbix_proxy
}

$root = $PSScriptRoot  # also for debug
. $root\functions_zabbix.ps1  # include general zabbix functions

# It seems, hosts ids and proxy ids are different and these will not work. So... proxy is has to be hardcoded...
#$proxyid = Zabbix-GetProxyIdByHostId -HostId $hostid -Token $token
#$proxy_name = Zabbix-GetHostnameById -HostId $proxyid -Token $token


Clear-Host


# This script must be run in elevated session (due to Get-DfsReplicatedFolder cmdlet)
Check-ElevatedPermissions

switch ($Mode) {
    "Setup" {
    #$token = Zabbix-GetAuthToken -User $user -Password $password
    break
    }
}


$folders = Get-DfsReplicatedFolder

$folders | % {
    $folder = $_
    $members = Get-DfsrMember -GroupName $folder.GroupName

    $members | % {
        $member = $_
        Write-Host ("Checking " + $member.ComputerName)

        $members | ? {$_ -ne $member} | % {
            
            # Backlog content is temporarily disabled
            $backlog = Get-DfsrBacklog -FolderName $folder.FolderName -SourceComputerName $member.DnsName -DestinationComputerName $_.DnsName -ErrorVariable ProcessError -ErrorAction SilentlyContinue
            if ($backlog) {
                $backlog_count = $backlog.Count
                #$backlog_content = $backlog.FullPathName
            } else {
                $backlog_count = 0
                #$backlog_content = "-"
            }

            if (-not $ProcessError) {

                $folder_name = Translit-Text $folder.FolderName

                $host_name = $member.ComputerName
                $item_name = "DFS-R Backlog count " + $member.DnsName + " -> " + $_.DnsName + " (Folder: " + $folder_name + ")"
                $item_key  = "DFS-R_Backlog_count_" + $_.DnsName + "_" + $folder_name
                Write-Host "Host: " -ForegroundColor Green -NoNewline; Write-Host $host_name
                Write-Host "Item name: " -ForegroundColor Green -NoNewline; Write-Host $item_name
                Write-Host "Item key: "  -ForegroundColor Green -NoNewline; Write-Host $item_key
                Write-Host ("Count: " + $backlog_count)
                
                $item_value_type = 3
                <#
                value_type:
                0 - numeric float;
                1 - character;
                2 - log;
                3 - numeric unsigned;
                4 - text.
                #>

                switch ($Mode) {
                    "Setup" {
                        if (-not $token) { $token = Zabbix-GetAuthToken -User $user -Password $password }
                        $hostid = Zabbix-GetHostIdByName -HostName $host_name -Token $token
                        Zabbix-CreateItem -HostId $hostid -ItemName $item_name -ItemKey $item_key -ItemValueType $item_value_type -Token $token
                        Zabbix-CheckItem -ItemKey $item_key -HostId $hostid -Token $token
                        break
                    }

                    "Scheduler" {
                        # Keys should be added to zabbix already by setup mode.
                        $log_filename = "$root\DFS.log"
                        $zabbix_proxy = Zabbix-GetProxyByHostname -Hostname $host_name
                        "C:\zabbix\bin\zabbix_sender.exe -z $zabbix_proxy -s $host_name -k $item_key -o $backlog_count -vv" > "$root\DFS.log"
                        C:\zabbix\bin\zabbix_sender.exe -z $zabbix_proxy -s $host_name -k $item_key -o $backlog_count -vv > "$root\DFS.log"
                        break
                    }
                }



                <#
                $item_name = "DFS-R Backlog content " + $member.DnsName + " -> " + $_.DnsName + " (Folder: " + $folder_name + ")"
                $item_key  = "DFS-R_Backlog_content_" + $_.DnsName + "_" + $folder_name
                Write-Host "Item name: " -ForegroundColor Green -NoNewline; Write-Host $item_name
                Write-Host "Item key: "  -ForegroundColor Green -NoNewline; Write-Host $item_key
                Write-Host $backlog_content
                # Keys should be added to zabbix already
                C:\zabbix\bin\zabbix_sender.exe -z $zabbix_proxy -s $host_name -k $item_key -o $backlog_content -vv
                #>

                Write-Host "`n"
            } else {
                # Error
                # Some percent of errors is normal.
                Write-Host "Error in Get-DfsrBacklog" -ForegroundColor Yellow
            }
        }
    }
}

