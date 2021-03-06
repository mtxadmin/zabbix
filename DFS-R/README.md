## Script to monitor DFS-R queues

The script sends length of replication queues (Microsoft: "DFS-R backlog count") to Zabbix.

Script detects all DFS-R folders on server, and automatically makes all items on Zabbix server through API. You don't have to make them manually.

This solution based on Microsoft Powershell which embedded in Windows.

*(Note: Shown backlog count can be maximum of 100, while on server it can be much more. This is Microsoft restriction, see https://docs.microsoft.com/en-us/powershell/module/dfsr/get-dfsrbacklog)*


## Installation:

1. Copy files DFS-R_backlog.ps1 and functions_zabbix.ps1 to any folder on DFS-R server (one of). And don't forget functions_zabbix.ps1

2. Run script DFS-R_backlog.ps1 with elevated permissions and check for errors.<br>
    - Login to server with account which has sufficient permissions for reading DFS-R data
    - Run Powershell ISE "as administrator" (from context menu)
    - Open DFS-R_backlog.ps1
    - Edit first line of script with $zabbix_server_url variable. Save script.
    - Tailor function Zabbix-GetProxyByHostname for your infrastructure and naming conventions.
    - Set $user and $password variables in command line (they are case-sensitive!). They only need in setup run, do not add them to script for security reasons. 
    - Run DFS-R_backlog.ps1
    - Check for errors

    Script will detect all DFS-R folders and add appropriate keys to zabbix (via Zabbix API)
    
    Now let's configure regular sending of monitoring data to these keys

3. Add script to Windows task scheduler:<br>
    "Create Task.."

    - In General tab:<br>
	Name: enter any task name as you wish. For instance: "AD DC diag monitoring"

	"When running the task, use the following user account:"<br>
	Enter account with sufficient permissions for reading AD DC data<br>
	DO NOT set chechbox "Do not store password"<br>
	Please note that NT AUTHORITY/SYSTEM will not work
	
	- "Run whether user is logged on or not"

	- "Run with highest privileges"

	- Configure for: set latest version


    - In Triggers tab:<br>
        "New..."
	
        Begin task: On a schedule (default)<br>
        One time (default)<br>
        Repeat task every: 5 minutes (it is the minimum. You can set another value if you like)<br>
        For a duration of: Indefinitely<br>
        Stop task if it runs longer than: 30 minutes (this is optional parameter, just in case)<br>
        Enabled (default)

    - In Actions tab:<br>
        "New..."

        Action: Start a program<br>
        Program/script: Powershell.exe<br>
        (or: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe)<br>
        Add arguments (optional): -NoProfile -ExecutionPolicy Bypass -File "c:\zabbix\scripts\AD DC diag.ps1" -Mode "Scheduler"<br>
        (edit path to script here. And this is NOT optional :-) )<br>

    - In Settings tab:<br>
	Stop the task if it runs longer than: 1 hour (this is optional parameter, just in case)

    After clicking OK don't forget to enter (correct!) password to account

4. Run created task and see that status changed to Ready and Last Run Result is (0x0)

5. Check that zabbix server correctly receives data (see Latest data, Hosts: your host, Name: DFS)
