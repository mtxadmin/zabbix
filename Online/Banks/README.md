Template to monitor several Russian banks' entrypoints for [online banking](https://en.wikipedia.org/wiki/Online_banking) (for client-banks apps)

Monitored banks:
- [Sberbank](https://en.wikipedia.org/wiki/Sberbank)
- [GazPromBank](https://en.wikipedia.org/wiki/Gazprombank) (GPB)
- [VneshTorgBank](https://en.wikipedia.org/wiki/VTB_Bank) (VTB)
- [PromSvyazBank](https://en.wikipedia.org/wiki/Promsvyazbank) (PSB)

Monitored points:
- Ports<br>
  Simple availability checks
- Services<br>
  - "Service" here in terms of Zabbix means net.tcp.service - see details [here](https://www.zabbix.com/documentation/current/en/manual/appendix/items/service_check_details)
  - Https service checks are processing only if available. It turned out, that some "https" cannot be monitored because Zabbix cannot recognize https responses. It happens either because of propriethary protocols or because of [GOST encryption](https://en.wikipedia.org/wiki/GOST_(block_cipher)) in the standard https. Don't know, but in fact, we cannot monitor availability of such services.
  - Checking of LDAP and HTTPS on Windows [is only supported by Zabbix agent 2](https://www.zabbix.com/documentation/5.0/en/manual/config/items/itemtypes/zabbix_agent)
