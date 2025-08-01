## Script to monitor availability domain controllers from all servers

The task was to control availability of DCs - ports on DCs - directly from servers, not from Zabbix server. Client-like probing.

### Ports

TCP 53 - DNS<br>
TCP 88 - Kerberos authentication<br>
TCP 135 - RPC<br>
TCP 137 - NetBIOS, disabled<br>
TCP 138 - NetBIOS, disabled<br>
TCP 389 - LDAP<br>
TCP 445 - SMB<br>
TCP 464 - Kerberos password change<br>
TCP 636 - LDAP SSL<br>
TCP 3268 - Global catalog<br>
TCP 3269 - Global catalog<br>
TCP 9369 - ADWS

### AD structure

Domain names and controllers names definded in the scripts. Structure of Contoso corp is:

**branch.corp.local**<br>
dcbr01.branch.corp.local<br>
dcbr02.branch.corp.local<br>
dcbr03.branch.corp.local<br>
dcbr04.branch.corp.local<br>
dcbr05.branch.corp.local<br>
dcbr06.branch.corp.local<br>

**dmz.local**<br>
dcdmz01.dmz.local<br>
dcdmz02.dmz.local<br>

**headoffice.corp.local**<br>
dcho01.headoffice.corp.local<br>
dcho02.headoffice.corp.local<br>
dcho03.headoffice.corp.local<br>
dcho04.headoffice.corp.local<br>
dcho05.headoffice.corp.local<br>
dcho06.headoffice.corp.local<br>
dcho07.headoffice.corp.local<br>
dcho08.headoffice.corp.local<br>
dcho09.headoffice.corp.local<br>
dcho10.headoffice.corp.local<br>
dcho11.headoffice.corp.local<br>
dcho12.headoffice.corp.local<br>

**datacenter.corp.local**<br>
dc-d01.datacenter.corp.local<br>
dc-d02.datacenter.corp.local<br>
dc-d03.datacenter.corp.local<br>

**ms.ru**<br>
ms-dc01.ms.ru<br>
ms-dc02.ms.ru<br>

**sw.corp.local**<br>
dcsw01.sw.corp.local<br>
dcsw02.sw.corp.local<br>

**ds.local**<br>
dsmain.ds.local<br>
dsres.ds.local<br>

