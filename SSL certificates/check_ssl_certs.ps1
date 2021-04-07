param ([CmdletBinding()][ValidateSet("Setup","Scheduler")][String]$Mode="Setup")
# By default, script adds keys to zabbix. This can be done in manual mode
# When adding the script to scheduler, add parameter -Mode Scheduler


# Script for monitoring SSL certificates expiring


# http://woshub.com/check-ssl-tls-certificate-expiration-date-powershell/
# https://www.tutorialspoint.com/how-to-get-website-ssl-certificate-validity-dates-with-powershell
# https://stackoverflow.com/questions/39253055/powershell-script-to-get-certificate-expiry-for-a-website-remotely-for-multiple


<# Only for example. Do not enter real credentials in saved script! Enter them in temporarily session in setup process.
$user = "Admin"
$password = "zabbix"
#>

$root = $PSScriptRoot
. $root\functions_zabbix.ps1  # include general zabbix functions

Clear-Host

# Importing URLs from text file, removing empty spaces and comments
$urls = Get-Content (Join-Path -Path $root -ChildPath "check_ssl_certs_urls_list.txt") | ? {$_} | ? {$_ -notmatch "^#"}


# Disable certificate validations
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }


$urls | ? {$_} | % {
    $url = $_
    Write-Host $url
    $req = [Net.HttpWebRequest]::Create($url)
    try {$req.GetResponse() |Out-Null} catch {Write-Host URL check error $site`: $_ -f Red}

    $cert = $req.ServicePoint.Certificate
    #$cert

    # Days to certificate expire
    $cert_end_date = $req.ServicePoint.Certificate.GetExpirationDateString()
    $cert_days = (New-TimeSpan -Start (get-date) -End $expDate).Days
    $cert_days

    # Other properties
    $cert_issuer = $cert.Issuer
    $cert_subject = $cert.Subject

    # Domain, just domain
    $domain = $url -replace "http(s|)://" -replace "/.*"

    $host_name = $env:ComputerName


    switch ($Mode) {
        "Setup" {
            if (-not $token) { $token = Zabbix-GetAuthToken -User $user -Password $password }
        }
    }


    # Block: send/create certificate days to expire
    $item_name = "Cert " + $domain + " expiring days"
    $item_key  = "Cert_" + $domain + "_expiring_days"
    $item_value_type = 3
    <#
    value_type:
    0 - numeric float;
    1 - character;
    2 - log;
    3 - numeric unsigned;
    4 - text.
    #>
    Zabbix-AddOrSendKey -HostName $host_name -ItemName $item_name -ItemKey $item_key -ItemValueType 3 -ItemValue $cert_days -Token $token -Mode $Mode


    # Block: send/create certificate date of expiring
    $item_name = "Cert " + $domain + " expiring date"
    $item_key  = "Cert_" + $domain + "_expiring_date"
    $item_value_type = 4
    Zabbix-AddOrSendKey -HostName $host_name -ItemName $item_name -ItemKey $item_key -ItemValueType 3 -ItemValue $cert_end_date -Token $token -Mode $Mode


    # Block: send/create certificate date of expiring
    $item_name = "Cert " + $domain + " issuer"
    $item_key  = "Cert_" + $domain + "_issuer"
    $item_value_type = 4
    Zabbix-AddOrSendKey -HostName $host_name -ItemName $item_name -ItemKey $item_key -ItemValueType 3 -ItemValue $cert_issuer -Token $token -Mode $Mode


    # Block: send/create certificate date of expiring
    $item_name = "Cert " + $domain + " subject"
    $item_key  = "Cert_" + $domain + "_subject"
    $item_value_type = 4
    Zabbix-AddOrSendKey -HostName $host_name -ItemName $item_name -ItemKey $item_key -ItemValueType 3 -ItemValue $cert_subject -Token $token -Mode $Mode

}

