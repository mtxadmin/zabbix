# Windows Scheduled Tasks

Zabbix template for monitoring scheduled tasks in Windows (including Windows Server)

Format: zabbix 5.0 xml. It should also work on 5.2 and above (see [docs](https://www.zabbix.com/documentation/current/manual/xml_export_import/media) about template formats)

Tested with agent1 and agent2 as well

## Using

Use cases:
- Detecting of failing of a tasks (with technical exclusions, see below)
- Detecting of disabling of a task
- If you want to detect enabling of a task, add a trigger prototype for that

Task are searched in the root of Task Scheduler folders. If you want, you can change search folder in the script

## Installation:

1. Import the template to Zabbix web interface
2. Copy DiscoverScheduledTasks.ps1 to to Zabbix agent subfolder (c:\zabbix\scripts )
3. Edit zabbix_agentd.conf :
-  find **Server:** string and add there **,127.0.0.1,::1** to the end of line.<br>
For instance, if there was **Server=10.0.0.100,10.0.0.101** , it should be **Server=10.0.0.100,10.0.0.101,127.0.0.1,::1**
-  add parameters to the end of file:<br>
   UserParameter=TaskSchedulerMonitoring[*], powershell -Noprofile -ExecutionPolicy Bypass -File "C:\zabbix\scripts\DiscoverScheduledTasks.ps1" "$1" "$2"<br>
   Timeout=20<br>
4. Restart Zabbix agent service on this server
5. In Zabbix web interface, apply the imported template **Windows Scheduled Tasks** to the host
6. Wait several minutes for the discovery
7. See items on the host - with names with "Task:" or application "Scheduled tasks", and their triggers
8. Enable or disable these items or triggers.
9. Don't forget to make **action** as well for triggers with names "Scheduled task"


### Technical notes:

Powershell script based on:<br>
https://github.com/Iakim/zabbix-scheduledtask<br>
https://github.com/romainsi/zabbix-scheduledtask<br>
First one is a fork of the second one, but they have defferences in both ways. So I have to make the upgraded and refactored version. For instance, this version can safely operate with non-ASCII task names

Task Scheduler error codes:<br>
https://docs.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-error-and-success-constants

Excluded task status codes:<br>
0 - Success<br>
0x41300 - Ready<br>
0x41301 - Running<br>
0x41302 - Disabled<br>
0x41303 - The task has not yet run

Triggers for detecting disabling tasks are discovering with Disabled initial state. Disable and/or Enable them as you need.
