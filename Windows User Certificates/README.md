## Attention: this is an old and not very tidy solution. Sorry. Use it as is.

Maybe sometimes I return to this, but now it is not production-ready at all. I even don't remember which version of three is more or less working. I think, this, but I could be wrong


## User certificates

Script for monitoring Windows user certificates.


### Description in Russian:

#### V1
Скрипт для мониторинга сертификатов - из Windows, но теперь с закрытой частью.<br>
Единственно что, для этого нужно запускать скрипт из-под целевой учетки. При смене пароля нужно не забывать об этом, поскольку вход в систему там очень нечастый и нерегулярный.<br>
Ответ там быстрый, так что делить скрипт на две части с кэшированием (как в V2) не нужно.<br>
И параметры не нужны - всё скидываем в заббикс JSON'ом, а там разбираем через дискавери из него<br>
Update: А, нет, всё-таки нужно. Чтобы увидеть нужные сертификаты, этот скрипт нужно запускать от имени системной учётки<br>
Поэтому, первая часть (от системного юзера) скидывает json в файл, а вторая (от любого юзера) отдает json заббиксу

#### V1.1
То же, но скрипт всё же поделён на две части.

