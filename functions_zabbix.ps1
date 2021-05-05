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
    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc" -UseBasicParsing
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

    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc" -UseBasicParsing
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
    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc" -UseBasicParsing
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
    if (Zabbix-CheckItem -ItemKey $ItemKey -HostId $HostId -Token $Token) {
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
    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc" -UseBasicParsing

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

    # and recheck
    Write-Host "Rechecking created item..."
    Zabbix-CheckItem -ItemKey $ItemKey -HostId $HostId -Token $Token

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

    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc" -UseBasicParsing

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

    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc" -UseBasicParsing

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


function Zabbix-AddOrSendKey ([String]$HostName,[String]$ItemName,[String]$ItemKey,[int]$ItemType=2,[int]$ItemValueType,$ItemValue,[String]$Token,[String]$Mode) {
    # meta-function to add key or send it to zabbix proxy

    Write-Host "Host: " -ForegroundColor Green -NoNewline; Write-Host $HostName
    Write-Host "Item name: " -ForegroundColor Green -NoNewline; Write-Host $ItemName
    Write-Host "Item key: "  -ForegroundColor Green -NoNewline; Write-Host $ItemKey
    Write-Host ("Value: " + $ItemValue)

    switch ($Mode) {
        "Setup" {
            $hostid = Zabbix-GetHostIdByName -HostName $HostName -Token $Token
            Zabbix-CreateItem -HostId $hostid -ItemName $ItemName -ItemKey $ItemKey -ItemValueType $ItemValueType -Token $Token
            break
        }

        "Scheduler" {
            # Keys should be added to zabbix already by setup mode.
            $zabbix_proxy = Zabbix-GetProxyByHostname -Hostname $HostName
            C:\zabbix\bin\zabbix_sender.exe -z $zabbix_proxy -s $HostName -k $ItemKey -o $ItemValue
            break
        }
    }
}


function Zabbix-CheckTrigger([String]$Description,[String]$Hostname,[String]$Token) {
    # Checking existense of a trigger
    # https://www.zabbix.com/documentation/current/manual/api/reference/trigger/get
$post_params = @"
{
    "jsonrpc": "2.0",
    "method": "trigger.get",
    "params": {
        "output": "extend",
        "host": "$Hostname",
        "search": {
            "description": "$Description"
        }
    },
    "auth": "$Token",
    "id": 1
}
"@
    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc" -UseBasicParsing
    if (-not ((ConvertFrom-Json $answer).result)) {
        Write-Host "Trigger is absent"
        return $false
    } else {
        Write-Host "Trigger is present"
        return $true
    }
}


function Zabbix-CreateTrigger([String]$Description,[String]$Expression,[int]$Priority=0,[String]$Token) {
    # Function to create zabbix triggers via API
    # https://www.zabbix.com/documentation/current/manual/api/reference/trigger/create
    # Yes, it is correct, hostname is omitted. Host is detected from expression - see API manual

    # Todo: return trigger id - for dependencies
    # Todo: make dependencies mechanism. It seems in my test it was way too overcomplex. 
    # ConvertTo-Json -AsArray can transform data to zabbix API format, but it exists only in PS 7.0

    # But for checking we need hostname. Ok.
    $host_name = $Expression -replace "^{" -replace ":.*"

    # Checking item
    if (Zabbix-CheckTrigger -Hostname $host_name -Description $Description -Token $Token) {
        Write-Host "Trigger is already present"
        return 1
    }

    # Creating a trigger
$post_params = @"
{
    "jsonrpc": "2.0",
    "method": "trigger.create",
    "params": [
        {
            "description": "$Description",
            "expression": "$Expression",
            "priority": "$Priority"
        }
    ],
    "auth": "$Token",
    "id": 1
}
"@
    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc" -UseBasicParsing

    if (-not ((ConvertFrom-Json $answer).result.triggerids)) {
        # Trigger is absent
        Write-Host "Error while creating the trigger" -ForegroundColor Yellow
        Write-Host (ConvertFrom-Json $answer).error.message -ForegroundColor Yellow
        Write-Host (ConvertFrom-Json $answer).error.data -ForegroundColor Yellow
        return -1
    } else {
        # Trigger is present
        Write-Host "The trigger was successfully created"
        return 0
    }
}


function Zabbix-CheckMacro([String]$HostId,[String]$MacroName,[String]$Token) {
    # Checking existense of a host macro
    # https://www.zabbix.com/documentation/current/manual/api/reference/usermacro/get
$post_params = @"
{
    "jsonrpc": "2.0",
    "method": "usermacro.get",
    "params": {
        "output": "extend",
        "hostids": "$HostId"
    },
    "auth": "$Token",
    "id": 1
}
"@
    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc" -UseBasicParsing
    if (-not ((ConvertFrom-Json $answer).result)) {
        Write-Host "Macro is absent"
        return $false
    } else {
        Write-Host "Some macro is present. Checking name..."
        if ((ConvertFrom-Json $answer).result.macro -eq $MacroName) {
            Write-Host "Macro is present"
            return $true
        } else {
            Write-Host "Macro is absent"
            return $false
        }
    }
}


function Zabbix-CreateMacro([String]$HostId,[String]$MacroName,[String]$MacroValue,[String]$MacroDescription,[String]$Token) {
    # Function to create zabbix host macro via API
    # https://www.zabbix.com/documentation/current/manual/api/reference/usermacro/create

    # Checking macro
    if (Zabbix-CheckMacro -HostId $HostId -MacroName "$MacroName" -Token $token) {
        Write-Host "Macro is already present"
        return 1
    }

    # Creating an item
$post_params = @"
{
    "jsonrpc": "2.0",
    "method": "usermacro.create",
    "params": {
        "hostid": "$HostId",
        "macro": "$MacroName",
        "value": "$MacroValue",
        "description": "$MacroDescription"
    },
    "auth": "$Token",
    "id": 1
}
"@
    $answer = Invoke-WebRequest -Uri "$zabbix_server_url/api_jsonrpc.php" -Method POST -Body $post_params -ContentType "application/json-rpc" -UseBasicParsing

    if (-not ((ConvertFrom-Json $answer).result.hostmacroids)) {
        # Macro is absent
        Write-Host "Error while creating the macro" -ForegroundColor Yellow
        Write-Host (ConvertFrom-Json $answer).error.message -ForegroundColor Yellow
        Write-Host (ConvertFrom-Json $answer).error.data -ForegroundColor Yellow
        return -1
    } else {
        # Macro is present
        Write-Host "The macro was successfully created"
        return 0
    }

}


function Check-ElevatedPermissions () {
    # For scripts those must be run in elevated session
    # http://woshub.com/check-powershell-script-running-elevated/
    Write-Host "Checking for elevated permissions..."
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
        Break
    } else {
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


