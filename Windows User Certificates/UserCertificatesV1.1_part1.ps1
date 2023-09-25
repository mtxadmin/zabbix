# Скрипт для мониторинга сертификатов - из Windows, но теперь с закрытой частью.
# Единственно что, для этого нужно запускать скрипт из-под целевой учетки. При смене пароля нужно не забывать об этом, поскольку вход в систему там очень нечастый и нерегулярный.

# Ответ там быстрый, так что делить скрипт на две части с кэшированием (как в V2) не нужно.
# И параметры не нужны - всё скидываем в заббикс JSON'ом, а там разбираем через дискавери из него
#
# Update: А, нет, всё-таки нужно. Чтобы увидеть нужные сертификаты, этот скрипт нужно запускать от имени системной учётки
# Поэтому, первая часть (от системного юзера) скидывает json в файл, а вторая (от любого юзера) отдает json заббиксу

param ([string]$User)
#$User = "svc-user"  # просто для справки. Ну и в конце он нужен

$cachePath = "C:\zabbix\scripts\UserCertificatesV1.1.txt"


# Note: assuming system drive is C:

class Certificate {
    [string]$NotBefore
    [string]$NotAfter
    [string]$Active
    [int]$certDays
    [string]$Thumbprint
    [string]$Issuer
    [string]$Subject
    [string]$displayName
    [string]$PrivateKeyNotBefore
    [string]$PrivateKeyNotAfter
    [string]$privateKeyActive
    [string]$privateKeyDays
}


function Convert-ToTranslit ([CmdletBinding()][parameter(Position=0)][string]$String) {
    # Если отправлять в заббикс русские буквы, они пишутся туда вопросами
    # Заббиксы пишут, что они исправили это в третьей версии, а у нас пятая, но что-то как-то не заметно
    # https://support.zabbix.com/browse/ZBX-10540
    # Там толковое обсуждение по параметрам. Вроде вот это должно исправить дело:
    # As a temporary workaround try to set character_set_connection, character_set_result and character_set_client to utf8 in MySQL server settings ("[client]" section).
    # 
    # А пока вот временный костыль с транслитом
    $String = $String -creplace "А","A"   -creplace "а","a"
    $String = $String -creplace "Б","B"   -creplace "б","b"
    $String = $String -creplace "В","V"   -creplace "в","v"
    $String = $String -creplace "Г","G"   -creplace "г","g"
    $String = $String -creplace "Д","D"   -creplace "д","d"
    $String = $String -creplace "Е","E"   -creplace "е","e"
    $String = $String -creplace "Ё","E"   -creplace "ё","e"
    $String = $String -creplace "Ж","ZH"  -creplace "ж","zh"
    $String = $String -creplace "З","Z"   -creplace "з","z"
    $String = $String -creplace "И","I"   -creplace "и","i"
    $String = $String -creplace "К","K"   -creplace "к","k"
    $String = $String -creplace "Л","L"   -creplace "л","l"
    $String = $String -creplace "М","M"   -creplace "м","m"
    $String = $String -creplace "Н","N"   -creplace "н","n"
    $String = $String -creplace "О","O"   -creplace "о","o"
    $String = $String -creplace "П","P"   -creplace "п","p"
    $String = $String -creplace "Р","R"   -creplace "р","r"
    $String = $String -creplace "С","S"   -creplace "с","s"
    $String = $String -creplace "Т","T"   -creplace "т","t"
    $String = $String -creplace "У","U"   -creplace "у","u"
    $String = $String -creplace "Ф","F"   -creplace "ф","f"
    $String = $String -creplace "Х","H"   -creplace "х","h"
    $String = $String -creplace "Ц","TS"  -creplace "ц","ts"
    $String = $String -creplace "Ч","CH"  -creplace "ч","ch"
    $String = $String -creplace "Ш","SH"  -creplace "ш","sh"
    $String = $String -creplace "Щ","SCH" -creplace "щ","sch"
    $String = $String -creplace "Ъ",""   -creplace "ъ",""
    $String = $String -creplace "Ы","Y"   -creplace "ы","y"
    $String = $String -creplace "Ь",""   -creplace "ь",""
    $String = $String -creplace "Э","E"   -creplace "э","e"
    $String = $String -creplace "Ю","YU"  -creplace "ю","yu"
    $String = $String -creplace "Я","YA"  -creplace "я","ya"

    $String
}


$usercerts = @()

# Getting  all user certificates (from user's session)
#Get-ChildItem -Path "Cert:\LocalMachine\My" | % { # неправильно! Надо CurrentUser. Нужно только для отладки.
Get-ChildItem -Path "Cert:\CurrentUser\My" | % {

    # Getting current certificate
    $cert = $_

    # Making an object
    $usercert = New-Object -TypeName Certificate

    $today = Get-Date -Format "yyyy-MM-dd HH:mm"

    # Looking for dates...
    $usercert.NotBefore = $cert.NotBefore | Get-Date -Format "yyyy-MM-dd HH:mm"
    if ([datetime]$usercert.NotBefore -lt $today) {$usercert.Active = "True"} else {$usercert.Active = "False"}
    $usercert.NotAfter = $cert.NotAfter | Get-Date -Format "yyyy-MM-dd HH:mm"
    $usercert.certDays = (New-TimeSpan -Start $today -End $usercert.NotAfter).Days

    # And all other propeties
    $usercert.Thumbprint = $cert.Thumbprint
    $usercert.Issuer = Convert-ToTranslit $cert.Issuer
    $usercert.Subject = Convert-ToTranslit $cert.Subject


    ## И вот, ради чего всё изменяли - докапываемся до даты закрытой части
    ## ближе всего наметки здесь (но очень частично): https://adamtheautomator.com/windows-certificate-manager/
    # Сначала берем даты закрытого ключа
    # И, да, закрытой части может не быть. На данный момент закрытые части есть у двух из пяти сертификатов.
    $privatekeysdates = $null
    try {
        $privatekeysdates = ($cert.Extensions | Where-Object {$_.Oid.FriendlyName -match "Private"}).format($true)
    } catch {
        # просто чтобы не было сбивающих с толку ошибок про недоступность закрытых ключей, где их нет
    }
    if ($privatekeysdates) {
        # Это будет строка с переносами такого вида:
        # Valid from 19 ноября 2020 г. 17:53:30
        # Valid to 19 февраля 2022 г. 17:53:30
        # Теперь парсим из неё даты и приводим к нормальному виду
        $usercert.PrivateKeyNotBefore = $privatekeysdates -replace "(?ms)Valid from ([^\n]*).*",'$1' | Get-Date -Format "yyyy-MM-dd HH:mm"
        $usercert.PrivateKeyNotAfter  = $privatekeysdates -replace ".*\n(?ms)Valid to ([^\n]*)",'$1' | Get-Date -Format "yyyy-MM-dd HH:mm"
        $usercert.privateKeyDays = (New-TimeSpan -Start (Get-Date) -End ($usercert.privateKeyNotAfter -replace "\s[0-9]{4}\s"," ")).Days
    }

    # Plus custom display name. See note 122
    # issuer (измененный кусок из V2)
    $usercert.displayName += ($usercert.Issuer -replace ".* O=([^,\(]+).*",'$1' -replace "CN=([^,\(]+).*",'$1' -replace "\`"" `
            -replace "(JSC|ПАО|ООО|ОАО) " -replace " $") `
            -replace "Газпромбанк","Gazprombank" -replace "Сбербанк","Sberbank"
    # Добавим еще subject c ФИО
    $usercert.displayName += " - " + ($usercert.Subject -replace ".*?CN=" -replace ",.*")

    # и дату добавим для читаемости. Только дату, без времени
    # Update: Две даты, ага
    $usercert.DisplayName += "  Cert:" + ($usercert.NotAfter -replace " .*")
    if ($privatekeysdates) {
        $usercert.DisplayName += " PrivateKey:" + ($usercert.PrivateKeyNotAfter -replace " .*")
    }

    <# Это нужно было в ранней версии, с другим дискавери. Пусть будет для истории
    if ($usercert.SerialNumber -match $SerialNumber) {
        $usercerts += $usercert
    }#>

    $usercerts += $usercert
}

# Forming JSON for LLD
$json = $usercerts | ConvertTo-Json

# And replacing names there to LLD macros
# Update: this is wrong :-)
<#
$json -replace "`"Filename`"",     "`"{#CERT.FILENAME}`""`
      -replace "`"FullFilename`"", "`"{#CERT.FULL_FILENAME}`""`
      -replace "`"StartDate`"",    "`"{#CERT.START_DATE}`"" `
      -replace "`"EndDate`"",      "`"{#CERT.END_DATE}`"" `
      -replace "`"Active`"",       "`"{#CERT.ACTIVE}`"" `
      -replace "`"Days`"",         "`"{#CERT.DAYS}`""`
      -replace "`"SerialNumber`"", "`"{#CERT.SERIAL_NUMBER}`""`
      -replace "`"Issuer`"",       "`"{#CERT.ISSUER}`""`
      -replace "`"Subject`"",      "`"{#CERT.SUBJECT}`""`
      -replace "`"Container`"",    "`"{#CERT.CONTAINER}`""`
      -replace "`"Provider`"",     "`"{#CERT.PROVIDER}`""
#>

# Теперь внимание. Чтобы в мониторинге не сделать кашу, отдаём результат, ТОЛЬКО если юзер системный. Иначе там всё может поперепутаться.
# Для отладки никто не мешает смотреть $json руками. 
# (Сталкивался с тем, что даже Write-Host, казалось бы, отдающий результат только на экран, почему-то отдает его и в output. Перестраховываемся.)
if ($env:USERNAME -eq $User) {
    $json | Out-File -FilePath $cachePath -Encoding utf8 -Force
}
