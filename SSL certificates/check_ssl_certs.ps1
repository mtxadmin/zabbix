param ([CmdletBinding()][ValidateSet("Setup","Scheduler")][String]$Mode="Setup")
# By default, script adds keys to zabbix. This can be done in manual mode
# When adding the script to scheduler, add parameter -Mode Scheduler


# Script for monitoring SSL certificates expiring


# http://woshub.com/check-ssl-tls-certificate-expiration-date-powershell/
# https://www.tutorialspoint.com/how-to-get-website-ssl-certificate-validity-dates-with-powershell
# https://stackoverflow.com/questions/39253055/powershell-script-to-get-certificate-expiry-for-a-website-remotely-for-multiple


$zabbix_server_url = "http://zabbix.domain.local"

<# Only for example. Do not enter real credentials in saved script! Enter them in temporarily session in setup process.
$user = "Admin"
$password = "zabbix"
#>

$root = $PSScriptRoot
. $root\functions_zabbix.ps1  # include general zabbix functions

function Zabbix-GetProxyByHostname ([String]$Hostname) {
    # Custom function

    # You can tailor rule block for your infrastructure here. Example:
    if ($Hostname.StartsWith("HQ-"))  {$zabbix_proxy = "10.1.0.100"}
    if ($Hostname.StartsWith("BR1-")) {$zabbix_proxy = "10.2.0.100"}
    if ($Hostname.StartsWith("BR2-")) {$zabbix_proxy = "10.3.0.100"}
    if ($Hostname.StartsWith("BR3-")) {$zabbix_proxy = "10.4.0.100"}

    return $zabbix_proxy
}

Clear-Host

# Importing URLs from text file, removing empty spaces and comments
$urls = Get-Content (Join-Path -Path $root -ChildPath "check_ssl_certs_urls_list.txt") | ? {$_} | ? {$_ -notmatch "^#"}


# Disable certificate validations
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'  # to avoid error "The request was aborted: Could not create SSL/TLS secure channel."

$urls | ? {$_} | ? {$_ -notmatch "^#"} |? {$_.trim() -replace ".*https://","https://" -match "^https://"} | % {
    $url = $_.Trim() -replace "[^\x00-\x7F]"  # here are may be some non-printable symbols, let's remove them. And trim() alone doesn't work
    Write-Host $url
    $req = [Net.HttpWebRequest]::Create($url)
    try {$req.GetResponse() |Out-Null} catch {}  # some 401 errors are normal, let's hide them. We need only certificate from connection.
    if (-not $req.ServicePoint.Certificate) {
        Write-Host URL cert check error: $url -ForegroundColor Red
    } else {
        $cert = $req.ServicePoint.Certificate
        #$cert

        # Days to certificate expire
        $cert_end_date = $req.ServicePoint.Certificate.GetExpirationDateString()
        $cert_days = (New-TimeSpan -Start (Get-Date) -End $cert_end_date).Days
        $cert_days

        # Other properties
        $cert_issuer = $cert.Issuer
        $cert_subject = $cert.Subject -replace "`""

        # Domain, just domain
        # If URL contains port (http://server.local:8080) then we need two vars - human-readable "displayname" and one for zabbix keys
        $domain_name = $url -replace "http(s|)://" -replace "/.*"
        $domain_key  = $url -replace "http(s|)://" -replace "/.*" -replace ":","_"

        switch ($Mode) {
            "Setup" {
                if (-not $token) { $token = Zabbix-GetAuthToken -User $user -Password $password }
            }
        }

        $host_name = $env:ComputerName
        


        # Block: send/create certificate days to expire
        $item_name = "Cert " + $domain_name + " expiring days"
        $item_key  = "Cert_" + $domain_key  + "_expiring_days"
        $item_value_type = 0  # don't set it to 3 (numeric unsigned) - when overdue it will be negative number and "unsupported"
        <#  value_type:
            0 - numeric float;
            1 - character;
            2 - log;
            3 - numeric unsigned;
            4 - text. #>
        Zabbix-AddOrSendKey -HostName $host_name -ItemName $item_name -ItemKey $item_key -ItemValueType $item_value_type -ItemValue $cert_days -Token $token -Mode $Mode
        
        switch ($Mode) {
            "Setup" {
                $host_id = Zabbix-GetHostIdByName $host_name -Token $token

                $cert_days_warn = "{`$CERT_EXPIRING_DAYS_WARN}"
                $cert_days_avg  = "{`$CERT_EXPIRING_DAYS_AVG}"
                $cert_days_high = "{`$CERT_EXPIRING_DAYS_HIGH}"

                # Only numbers, without "d"
                $cert_days_warn_value = "90"
                $cert_days_avg_value  = "60"
                $cert_days_high_value = "30"

                # Block: create cert macros
                Zabbix-CreateMacro -HostId $host_id -MacroName $cert_days_warn -MacroValue $cert_days_warn_value -Token $token -MacroDescription "Warning threshold: remaining number of days of HTTPS certificates"
                Zabbix-CreateMacro -HostId $host_id -MacroName $cert_days_avg  -MacroValue $cert_days_avg_value  -Token $token -MacroDescription "Average threshold: remaining number of days of HTTPS certificates"
                Zabbix-CreateMacro -HostId $host_id -MacroName $cert_days_high -MacroValue $cert_days_high_value -Token $token -MacroDescription "High threshold: remaining number of days of HTTPS certificates"


                # Block: create cert triggers
                <#  Priority/severity:
                    0 - (default) not classified;
                    1 - information;
                    2 - warning;
                    3 - average;
                    4 - high;
                    5 - disaster. #>
                $priority = 2
                $description = "Cert $domain_name is expriring in $cert_days_warn"
                $expression  = "{$host_name`:Cert_$domain_key`_expiring_days.last()}<{`$CERT_EXPIRING_DAYS_WARN}"
                Zabbix-CreateTrigger -Description $description -Expression $expression -Priority $priority -Token $token
                $priority = 3
                $description = "Cert $domain_name is expriring in $cert_days_avg"
                $expression  = "{$host_name`:Cert_$domain_key`_expiring_days.last()}<{`$CERT_EXPIRING_DAYS_AVG}"
                Zabbix-CreateTrigger -Description $description -Expression $expression -Priority $priority -Token $token
                $priority = 4
                $description = "Cert $domain_name is expriring in $cert_days_high"
                $expression  = "{$host_name`:Cert_$domain_key`_expiring_days.last()}<{`$CERT_EXPIRING_DAYS_HIGH}"
                Zabbix-CreateTrigger -Description $description -Expression $expression -Priority $priority -Token $token
            }
        }


        # Block: send/create certificate date of expiring
        $item_name = "Cert " + $domain_name + " expiring date"
        $item_key  = "Cert_" + $domain_key  + "_expiring_date"
        $item_value_type = 4
        Zabbix-AddOrSendKey -HostName $host_name -ItemName $item_name -ItemKey $item_key -ItemValueType $item_value_type -ItemValue $cert_end_date -Token $token -Mode $Mode


        # Block: send/create certificate issuer
        $item_name = "Cert " + $domain_name + " issuer"
        $item_key  = "Cert_" + $domain_key  + "_issuer"
        $item_value_type = 4
        Zabbix-AddOrSendKey -HostName $host_name -ItemName $item_name -ItemKey $item_key -ItemValueType $item_value_type -ItemValue $cert_issuer -Token $token -Mode $Mode


        # Block: send/create certificate subject
        $item_name = "Cert " + $domain_name + " subject"
        $item_key  = "Cert_" + $domain_key  + "_subject"
        $item_value_type = 4
        Zabbix-AddOrSendKey -HostName $host_name -ItemName $item_name -ItemKey $item_key -ItemValueType $item_value_type -ItemValue $cert_subject -Token $token -Mode $Mode
    }
}
