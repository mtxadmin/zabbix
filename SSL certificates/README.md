## Script to monitor dates of HTTPS certificates.

The script sends dates of HTTPS certificates to Zabbix.

Script lists all urls from text file, and automatically makes all items on Zabbix server through API. You don't have to make them manually.


## Installation:

1. Copy files **check_ssl_certs.ps1**, **check_ssl_certs_urls_list.txt**, **functions_zabbix.ps1** to any folder on any server (its host must be exist in zabbix)

2. Edit **check_ssl_certs_urls_list.txt** and write there all needed urls for monitoring

3. Run script check_ssl_certs.ps1 and check for errors.<br>
    - Login to server
    - Run Powershell ISE
    - Open check_ssl_certs.ps1
    - Edit first line of script with $zabbix_server_url variable. Save script.
    - Tailor function Zabbix-GetProxyByHostname for your infrastructure and naming conventions.
    - Set $user and $password variables in command line. They only need in setup run, do not add them to script for security reasons. 
    - Run check_ssl_certs.ps1
    - Check for errors
    - Script will list all HTTPS urls from text file and add appropriate keys in zabbix (via Zabbix API)

4. Add script to Windows task scheduler:<br>
    "Create Task.."

    - In General tab:<br>
	Name: enter any task name as you wish. For instance: "HTTPS certificates monitoring"

	"When running the task, use the following user account:"<br>
	Enter some account. You don't have to enter account with Admin rights here<br>
	DO NOT set chechbox "Do not store password"<br>
	I suppose NT AUTHORITY/SYSTEM will work fine
	
	- "Run whether user is logged on or not"

	- Configure for: set latest version


    - In Triggers tab:<br>
        "New..."
	
        Begin task: On a schedule (default)<br>
        Daily<br>
        Recur every 1 days<br>
        Stop task if it runs longer than: 30 minutes (this is optional parameter, just in case)<br>
        Enabled (default)

    - In Actions tab:<br>
        "New..."

        Action: Start a program<br>
        Program/script: Powershell.exe<br>
        (or: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe)<br>
        Add arguments (optional): -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "c:\zabbix\scripts\check_ssl_certs.ps1" -Mode "Scheduler"<br>
        (edit path to script here. And this is NOT optional :-) )<br>

    - In Settings tab:<br>
	Stop the task if it runs longer than: 1 hour (this is optional parameter, just in case)

    After clicking OK don't forget to enter (correct!) password to account, if you didn't enter SYSTEM account.

4. Run created task and see that status changed to Ready and Last Run Result is (0x0)

5. Check that zabbix server correctly receives data (see Latest data, Hosts: your host, Name: Cert)

