## A template with several custom additions to standard Zabbix IIS template

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

{$IIS_REQUEST_EXECUTION_TIME_US_AVG} = 10000
In ms (milliseconds). 10000ms = 10 s

{$IIS_REQUEST_EXECUTION_TIME_US_HIGH} = 110000
In us (microseconds). 110000 ms = 110 s

### Technical notes

There are no graphs because I use Grafana for visualization. But feel free to add some :-)
