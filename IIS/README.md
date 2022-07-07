## A template with several custom additions to standard Zabbix IIS template

Format: zabbix 5.0 xml. It should also work on 5.2 and above (see [docs](https://www.zabbix.com/documentation/current/manual/xml_export_import/media) about template formats)

Apply the template to IIS servers hosts. It is compartible with standard "Template App IIS by Zabbix agent active". 

You can change the type of most of the items, they should work as passive type - but not EventLog one

### Additions:

- IIS: % Processor Time
- IIS: RAM Private Bytes
- IIS: RAM Working Set
- IIS: .NET CLR Exceptions# of Exceps Thrown / sec
- IIS: ASP.NET Applications\Requests/sec
- IIS: ASP.NET\Request Execution Time (ms)  (+triggers on slow execution and on session timeout)
- IIS: ASP.NET\Requests Current
- IIS: ASP.NET\Requests Queued  (+trigger)
- IIS: W3SVC_W3WP\% 401 HTTP Response Sent
- IIS: W3SVC_W3WP\% 403 HTTP Response Sent
- IIS: W3SVC_W3WP\% 404 HTTP Response Sent
- IIS: W3SVC_W3WP\% 500 HTTP Response Sent
- IIS: Current NonAnonymous Users

- IIS restarting events  (+trigger)

#### Macros:

- {$IIS_REQUEST_EXECUTION_TIME_US_AVG} = 10000<br>
In ms (milliseconds). 10000ms = 10 s

- {$IIS_REQUEST_EXECUTION_TIME_US_HIGH} = 110000<br>
In us (microseconds). 110000 ms = 110 s (as far as I know, this is absolute maximum of wait time before timeout occurs)

You can override these values freely - just set macros with such names for corresponding hosts in your infrastructure

### Technical notes

There are no graphs because I use Grafana for visualization. But feel free to add some :-)

#### And don't forget to make actions to receive alerts (template cannot make actions automatically, you have to make them by hands):
... (some conditions) ...<br>
Trigger name contains IIS:<br>
OR
Trigger name contains Eventlog: IIS<br>
... (some conditions) ...
