param( [string]$ScriptName, [string]$Prm )
#$prm = $args[3]
if ($ScriptName -and $ScriptName.Length -gt 0) {
    $scriptpath = "C:\zabbix\sql\$ScriptName"
    $nc         = "C:\zabbix\sql\setnocount.sql"
    if (Test-Path $scriptpath) {
        if ($prm) {
            $result = sqlcmd -m 1 -h -1 -W -v param=$prm -i $nc,$scriptpath
        } else {
            $result = sqlcmd -m 1 -h -1 -W -i $nc,$scriptpath
        }
    }
    Write-Output $result
}
