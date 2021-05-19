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

Clear-Host



# Let's take all dcdiag output
#$output     = dcdiag
$output_dcdiag_full = dcdiag /c

# dcdiag / c : Comprehensive, runs all tests, including non-default tests but excluding DcPromo and RegisterInDNS. Can use with /skip
# 
#  /a: Test all the servers in this site
#
#  /e: Test all the servers in the entire enterprise.  Overrides /a

# Running tests on distant DCs can be slow, so we run test on every DC locally


# https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/cc731968(v=ws.11)
# "DCDIAG requires Enterprise Admin credentials to run all the tests."



$output_dcdiag_full -match "(failed|passed) test "  # the space is needed
<#
         ......................... <DC> passed test Connectivity
         ......................... <DC> passed test Advertising
         ......................... <DC> passed test CheckSecurityError
         ......................... <DC> passed test CutoffServers
         ......................... <DC> passed test FrsEvent
         ......................... <DC> passed test DFSREvent
         ......................... <DC> passed test SysVolCheck
         ......................... <DC> passed test FrsSysVol
         ......................... <DC> passed test KccEvent
         ......................... <DC> passed test KnowsOfRoleHolders
         ......................... <DC> passed test MachineAccount
         ......................... <DC> passed test NCSecDesc
         ......................... <DC> failed test NetLogons
         ......................... <DC> passed test ObjectsReplicated
         ......................... <DC> failed test Replications
         ......................... <DC> passed test RidManager
         ......................... <DC> failed test Services
         ......................... <DC> failed test SystemLog
         ......................... <DC> passed test Topology
         ......................... <DC> passed test VerifyReferences
         ......................... <DC> passed test VerifyReplicas
         ......................... <DC> failed test DNS
         ......................... ForestDnsZones passed test CheckSDRefDom
         ......................... DomainDnsZones passed test CheckSDRefDom
         ......................... Schema passed test CheckSDRefDom
         ......................... Schema passed test CrossRefValidation
         ......................... Configuration passed test CheckSDRefDom
         ......................... Configuration passed test CrossRefValidation
         ......................... <DOMAIN> passed test CheckSDRefDom
         ......................... <DOMAIN> passed test CrossRefValidation
         ......................... <DOMAIN> passed test DNS
         ......................... <DOMAIN> passed test LocatorCheck
         ......................... <DOMAIN> passed test FsmoCheck
         ......................... <DOMAIN> passed test Intersite
#>

$output_dcdiag_full -match "(failed|passed) test " -replace "\s+\.+\s+" | % {
    $string_src = $_

    if ($string_src -notmatch $env:COMPUTERNAME) {
        $string_src = $env:COMPUTERNAME + " $string_src"
    }
    
    $result = $false
    if ($string_src -match "passed test ") {
        $result = 1
    } elseif ($string_src -match "failed test ") {
        $result = 0
    }
    $string = $string_src -replace "(failed|passed) test "
    $string


    $item_value_type = 3
    <#
    value_type:
    0 - numeric float;
    1 - character;
    2 - log;
    3 - numeric unsigned;
    4 - text.
    #>


    # Now when we have the results, let's send them to zabbix
    $item_name = "AD DC $string" 
    $item_key  = $item_name -replace " ","_"
    Write-Host "Item name: " -ForegroundColor Green -NoNewline; Write-Host $item_name
    Write-Host "Item key: "  -ForegroundColor Green -NoNewline; Write-Host $item_key

    switch ($Mode) {
        "Setup" {
            # Preparing
            if (-not $token) { $token = Zabbix-GetAuthToken -User $user -Password $password }
            $hostid = Zabbix-GetHostIdByName -HostName $env:COMPUTERNAME -Token $token
            
            # Creating item
            Zabbix-CreateItem -HostId $hostid -ItemName $item_name -ItemKey $item_key -ItemValueType $item_value_type -Token $token
            
            # Block: create trigger for that item
                <#  Priority/severity:
                    0 - (default) not classified;
                    1 - information;
                    2 - warning;
                    3 - average;
                    4 - high;
                    5 - disaster. #>
            $priority = 4
            $description = ("AD DC $env:COMPUTERNAME - dcdiag check error: " + $string_src -replace "passed","failed")
            $expression  = "{$env:COMPUTERNAME`:$item_key.last()}<>1"
            if ($string -notmatch "SystemLog") {  # SystemLog check detects if whether exist any events in EventLog. In my experience, it is not very critical. Let's make a warning trigger for it.
                Zabbix-CreateTrigger -Description $description -Expression $expression -Priority $priority -Token $token
            } else {
                $priority = 2
                Zabbix-CreateTrigger -Description $description -Expression $expression -Priority $priority -Token $token
            }
            
            break
        }

        "Scheduler" {
            # Keys should be added to zabbix already by setup mode.
            $log_filename = "$root\AD DC.log"
            $zabbix_proxy = Zabbix-GetProxyByHostname -Hostname $env:COMPUTERNAME
            "C:\zabbix\bin\zabbix_sender.exe -z $zabbix_proxy -s $env:COMPUTERNAME -k $item_key -o $result -vv" > "$root\AD DC.log"
            C:\zabbix\bin\zabbix_sender.exe -z $zabbix_proxy -s $env:COMPUTERNAME -k $item_key -o $result -vv > "$root\AD DC.log"
            break
        }
    }
}


# Testing for replication errors
# https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/cc770963(v=ws.11)
$output_repadmin = repadmin -replsummary     

<#
Experienced the following operational errors trying to retrieve replication information:

          58 - <DC FQDN>

# https://social.technet.microsoft.com/Forums/windowsserver/en-US/69690286-7493-44bd-98df-7dead5fae680/repadmin-check-sshows-replication-error-58
# https://serverfault.com/questions/475774/repadmin-gives-operational-error-58
#>

$repadmin_status = 1; $repadmin_error = "Ok"  # 1=ok, 0=error
if ($output_repadmin -join "`n" -match "Experienced the following operational errors trying to retrieve replication information:") {
    $repadmin_error = "Experienced the following operational errors trying to retrieve replication information: " + (($output_repadmin -join "`n" -split "Experienced the following operational errors trying to retrieve replication information:")[1]).Trim()
    $repadmin_status = 0
}

$item_name  = "AD DC $env:computername repadmin status"
$item_key   = $item_name -replace " ","_"
$item_name2 = "AD DC $env:computername repadmin error"
$item_key2  = $item_name2 -replace " ","_"
Write-Host "Item name: " -ForegroundColor Green -NoNewline; Write-Host $item_name
Write-Host "Item key: "  -ForegroundColor Green -NoNewline; Write-Host $item_key

switch ($Mode) {
    "Setup" {
        # Preparing
        if (-not $token) { $token = Zabbix-GetAuthToken -User $user -Password $password }
        $hostid = Zabbix-GetHostIdByName -HostName $env:COMPUTERNAME -Token $token
            
        # Creating item
        Zabbix-CreateItem -HostId $hostid -ItemName $item_name -ItemKey $item_key -ItemValueType 3 -Token $token
        # and text
        Zabbix-CreateItem -HostId $hostid -ItemName $item_name2 -ItemKey $item_key2 -ItemValueType 4 -Token $token

        # Creating trigger for that item
            <#  Priority/severity:
                0 - (default) not classified;
                1 - information;
                2 - warning;
                3 - average;
                4 - high;
                5 - disaster. #>
        $priority = 3
        $description = ("AD DC $env:COMPUTERNAME - repadmin check error")
        $expression  = "{$env:COMPUTERNAME`:$item_key.last()}<>1"
        Zabbix-CreateTrigger -Description $description -Expression $expression -Priority $priority -Token $token

        break
    }

    "Scheduler" {
        # Keys should be added to zabbix already by setup mode.
        $log_filename = "$root\AD DC.log"
        $zabbix_proxy = Zabbix-GetProxyByHostname -Hostname $env:COMPUTERNAME
        "C:\zabbix\bin\zabbix_sender.exe -z $zabbix_proxy -s $env:COMPUTERNAME -k $item_key -o $repadmin_status -vv"  > "$root\AD DC.log"
        C:\zabbix\bin\zabbix_sender.exe -z $zabbix_proxy -s $env:COMPUTERNAME -k $item_key  -o $repadmin_status -vv > "$root\AD DC.log"
        C:\zabbix\bin\zabbix_sender.exe -z $zabbix_proxy -s $env:COMPUTERNAME -k $item_key2 -o $repadmin_error -vv > "$root\AD DC.log"
        break
    }
}

