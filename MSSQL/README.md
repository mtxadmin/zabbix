# Microsoft SQL Server

Zabbix template for monitoring parameters of MS SQL Server

Format: zabbix 5.0 xml. It should also work on 5.2 and above (see [docs](https://www.zabbix.com/documentation/current/manual/xml_export_import/media) about template formats)

Mostly tested on Microsoft SQL Server 2017, but should work on other versions.

Most SQL scripts and some parameters are found on various MSSQL-oriented forums. Thanks to their authors.

## Installation:

1. Import the template to Zabbix web interface
2. Go to MS SQL server console (RDP, typically)
3. Make **sql** subfolder in Zabbix agent folder on needed server - not Zabbix server, but MSSQL monitored server, every. For instance, c:\zabbix\sql\
4. Copy all *.sql scripts to that **sql** subfolder
5. Copy pslaunch.cmd and run_sql_script.ps1 files to Zabbix agent folder (c:\zabbix\ )
6. Edit zabbix_agentd.conf :
-  find **Server:** string and add there **,127.0.0.1,::1** to the end of line.<br>
For instance, if there was **Server=10.0.0.100,10.0.0.101** , it should be **Server=10.0.0.100,10.0.0.101,127.0.0.1,::1**
-  add parameters to the end of file:<br>
   UserParameter=sql.script[*],"c:\zabbix\pslaunch.cmd" "C:\zabbix\run_sql_script.ps1" -script $1 -prm $2<br>
   Timeout=20<br>
7. Restart Zabbix agent service on this server
8. In Zabbix web interface, apply the imported template **Template DB MSSQL** to the host

### Technical notes:

This template is intended for single DB instance on a server. Some servers may contain several instances with non-default names (MSSQL$MEGABASE, MSSQL$SUPERBASE, etc). For every such server, you have to make a different template and edit all the names - SQL Server service name, SQL Agent service name, performance counters. (Maybe there is a better way, with discoveries?)
