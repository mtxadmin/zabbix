# Functions implementing Zabbix API ( https://www.zabbix.com/documentation/current/manual/api ) and some linked


function Zabbix-GetAuthToken ([String]$User,[String]$Password) {
    # Authentication
    # https://stackoverflow.com/questions/17325293/invoke-webrequest-post-with-parameters
$post_params = @"
{
    "jsonrpc": "2.0",
    "method": `"user.login",
    "params": {
        "user": "$User",
        "password": "$Password"
    },
    "id": 1,
    "auth": null
}
"@
    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc"
    if ((ConvertFrom-Json $answer).result) {
        $token = (ConvertFrom-Json $answer).result
        return $token
    } else {
        Write-Host -ForegroundColor Yellow (ConvertFrom-Json $answer).error.message
        Write-Host -ForegroundColor Yellow (ConvertFrom-Json $answer).error.data
        break
    }
    
}


function Zabbix-GetHostIdByName([String]$HostName,[String]$Token) {
    # Retrieving host
    # https://www.zabbix.com/documentation/current/manual/api/reference/host/get
$post_params = @"
{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
        "filter": {
            "host": [
                "$HostName"
            ]
        }
    },
    "auth": "$Token",
    "id": 1
}
"@

    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc"
    if ((ConvertFrom-Json $answer).result) {
        $hostid = (ConvertFrom-Json $answer).result.hostid
        return $hostid
    } else {
        Write-Host -ForegroundColor Yellow (ConvertFrom-Json $answer).error.message
        Write-Host -ForegroundColor Yellow (ConvertFrom-Json $answer).error.data
        return $false
    }

}


function Zabbix-CheckItem([String]$ItemKey,[String]$HostId,[String]$Token) {
    # Checking item
    # https://www.zabbix.com/documentation/current/manual/api/reference/item/get
$post_params = @"
{
    "jsonrpc": "2.0",
    "method": "item.get",
    "params": {
        "output": "extend",
        "hostids": "$HostId",
        "search": {
            "key_": "$ItemKey"
        },
        "sortfield": "name"
    },
    "auth": "$Token",
    "id": 1
}
"@
    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc"
    if (-not ((ConvertFrom-Json $answer).result)) {
        Write-Host "Item is absent"
        return $false
    } else {
        Write-Host "Item is present"
        return $true
    }

}


function Zabbix-CreateItem([String]$ItemName,[String]$ItemKey,[int]$ItemType=2,[int]$ItemValueType,[String]$Token,[String]$HostId) {
    # Non-ASCII names of DFS folders are not supported. Temporary solution is to translit them.

    # https://www.zabbix.com/documentation/current/manual/api/reference/item/create
    <# type: 
    0 - Zabbix agent;
    2 - Zabbix trapper;
    3 - simple check;
    5 - Zabbix internal;
    7 - Zabbix agent (active);
    8 - Zabbix aggregate;
    9 - web item;
    10 - external check;
    11 - database monitor;
    12 - IPMI agent;
    13 - SSH agent;
    14 - TELNET agent;
    15 - calculated;
    16 - JMX agent;
    17 - SNMP trap;
    18 - Dependent item;
    19 - HTTP agent;
    20 - SNMP agent;
    21 - Script. 

    value_type:
    0 - numeric float;
    1 - character;
    2 - log;
    3 - numeric unsigned;
    4 - text.
    #>



    # Checking item
    if (Zabbix-CheckItem -ItemKey $ItemKey) {
        Write-Host "Item is already present"
        return 1
    }


    # Creating an item
$post_params = @"
{
    "jsonrpc": "2.0",
    "method": "item.create",
    "params": {
        "name": "$ItemName",
        "key_": "$ItemKey",
        "hostid": "$HostId",
        "type": 2,
        "value_type": $ItemValueType
    },
    "auth": "$Token",
    "id": 1
}
"@
    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc" 

    if (-not ((ConvertFrom-Json $answer).result.itemids)) {
        # Item is absent
        Write-Host "Error while creating the item" -ForegroundColor Yellow
        Write-Host (ConvertFrom-Json $answer).error.message -ForegroundColor Yellow
        Write-Host (ConvertFrom-Json $answer).error.data -ForegroundColor Yellow
        return -1
    } else {
        # Item is present
        Write-Host "The item was successfully created"
        return 0
    }

}


function Zabbix-GetHostnameById ([String]$HostId,[String]$Token) {
    # https://www.zabbix.com/documentation/current/manual/api/reference/host/get

$post_params = @"
{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
        "hostids": [
            $HostId
        ]
    },
    "auth": "$Token",
    "id": 1
}
"@

    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc" 

    if (-not ((ConvertFrom-Json $answer).result.hostid)) {
        # Error
        Write-Host "Error while getting the host name by id" -ForegroundColor Yellow
        Write-Host (ConvertFrom-Json $answer).error.message -ForegroundColor Yellow
        Write-Host (ConvertFrom-Json $answer).error.data -ForegroundColor Yellow
        return -1
    } else {
        # Ok
        return (ConvertFrom-Json $answer).result.host
    }
}


function Zabbix-GetProxyIdByHostId ([String]$HostId,[String]$Token) {
    # https://www.zabbix.com/documentation/current/manual/api/reference/host/get

$post_params = @"
{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
        "hostids": [
            $HostId
        ]
    },
    "auth": "$Token",
    "id": 1
}
"@

    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc" 

    if (-not ((ConvertFrom-Json $answer).result.hostid)) {
        # Error
        Write-Host "Error while getting the proxy id by host id" -ForegroundColor Yellow
        Write-Host (ConvertFrom-Json $answer).error.message -ForegroundColor Yellow
        Write-Host (ConvertFrom-Json $answer).error.data -ForegroundColor Yellow
        return -1
    } else {
        # Ok
        return (ConvertFrom-Json $answer).result.proxy_hostid
    }
}


function Check-ElevatedPermissions () {
    # For scripts those must be run in elevated session
    # http://woshub.com/check-powershell-script-running-elevated/
    Write-Host "Checking for elevated permissions..."
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
        Break
    }
    else {
        Write-Host "Code is running as administrator — go on executing the script..." -ForegroundColor Green
    }
}

function Translit-Text ([String]$String) {
    # This functions converts Russian symbols to ASCII
    # Many systems, including Zabbix, does not recognize non-ASCII characters

    # https://ru.wikipedia.org/wiki/Транслитерация_русского_алфавита_латиницей :
    # "Существует большое количество несовместимых между собой стандартов транслитерации, но фактически ни один из них не получил большой популярности и в действительности транслитерация чаще всего проводится без каких-либо единых стандартов"
    
    $String = $String -replace "А","A" -replace "а","a"
    $String = $String -replace "Б","B" -replace "б","b"
    $String = $String -replace "В","V" -replace "в","v"
    $String = $String -replace "Г","G" -replace "г","g"
    $String = $String -replace "Д","D" -replace "д","d"
    $String = $String -replace "Е","E" -replace "е","e"
    $String = $String -replace "Ё","E" -replace "ё","e"
    $String = $String -replace "Ж","ZH" -replace "ж","zh"
    $String = $String -replace "З","Z" -replace "з","z"
    $String = $String -replace "И","I" -replace "и","i"
    $String = $String -replace "Й","I" -replace "й","i"
    $String = $String -replace "К","K" -replace "к","k"
    $String = $String -replace "Л","L" -replace "л","l"
    $String = $String -replace "М","M" -replace "м","m"
    $String = $String -replace "Н","N" -replace "н","n"
    $String = $String -replace "О","O" -replace "о","o"
    $String = $String -replace "П","P" -replace "п","p"
    $String = $String -replace "Р","R" -replace "р","r"
    $String = $String -replace "С","S" -replace "с","s"
    $String = $String -replace "Т","T" -replace "т","t"
    $String = $String -replace "У","U" -replace "у","u"
    $String = $String -replace "Ф","F" -replace "ф","f"
    $String = $String -replace "Х","KH" -replace "х","kh"
    $String = $String -replace "Ц","TS" -replace "ц","ts"
    $String = $String -replace "Ч","CH" -replace "ч","ch"
    $String = $String -replace "Ш","SH" -replace "ш",""
    $String = $String -replace "Щ","SHCH" -replace "щ","shch"
    $String = $String -replace "Ъ","" -replace "ъ",""
    $String = $String -replace "Ы","Y" -replace "ы","y"
    $String = $String -replace "Ь","" -replace "ь",""
    $String = $String -replace "Э","E" -replace "э","e"
    $String = $String -replace "Ю","YU" -replace "ю","yu"
    $String = $String -replace "Я","YA" -replace "я","ya"

    return $String
}


