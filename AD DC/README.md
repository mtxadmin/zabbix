## Script to monitor Active Directory Domain Controller (AD DC)

The script sends results of AD DC diagnostic tests to Zabbix.

Script automatically makes all items on Zabbix server through API. You don't have to make them manually.

This solution based on Microsoft dcdiag.exe utility which exists on a server with Domain Controller role and Microsoft Powershell which embedded in Windows.


## Installation:

1. Copy files AD DC diag.ps1 and functions_zabbix.ps1 to any folder on AD DC. And don't forget functions_zabbix.ps1

2. Run script AD DC diag.ps1 with elevated permissions and check for errors.<br>
    - Login to server with account which has sufficient permissions
    - Run Powershell ISE "as administrator" (from context menu)
    - Open AD DC diag.ps1
    - Edit first line of script with $zabbix_server_url variable. Save script.
    - Tailor function Zabbix-GetProxyByHostname for your infrastructure and naming conventions.
    - Set $user and $password variables in command line. They only need in setup run, do not add them to script for security reasons. 
    - Run AD DC diag.ps1
    - Check for errors

    Script will add all appropriate keys to zabbix (via Zabbix API)
    
    Now let's configure regular sending of monitoring data to these keys

3. Add script to Windows task scheduler:<br>
   Import task from "AD DC diad monitoring.xml" file
<details>
    <summary>
        OR Create it manually (there is a caveat here if you want use SYSTEM account)
    </summary>
    "Create Task.."

   - In General tab:<br>
	Name: enter any task name as you wish. For instance: "AD DC diag monitoring"

   "When running the task, use the following user account:"<br>
	Enter account with sufficient permissions for reading AD DC data<br>
	DO NOT set chechbox "Do not store password"<br>
	Just for information, NT AUTHORITY/SYSTEM will work ok, but you cannot choose it from task scheduler on AD DCs
	
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

   After clicking OK don't forget to enter (correct!) password to account. (Of course, if you entered NT AUTHORITY/SYSTEM, you will not be prompted for password)
</details>
<br>

4. Run created task and see that status changed to Ready and Last Run Result is (0x0)

5. Check that zabbix server correctly receives data (see Latest data, Hosts: your host, Name: AD)

6. Repeat for every DC in your infrastructure

### Technical notes

In general, this diagnostics cannot be made as a template. Dcdiag.exe returns most results with DC name, but some with domain name, which cannot be known in general.

Also, there are two similar results in dcdiag.exe output:
<DC> passed test DNS
and
<DOMAIN> passed test DNS

<details>
    <summary>
        Full output of dcdiag.exe (only strings with test results)
    </summary>
         <pre>	
         ......................... &ltDC> passed test Connectivity
         ......................... &ltDC> passed test Advertising
         ......................... &ltDC> passed test CheckSecurityError
         ......................... &ltDC> passed test CutoffServers
         ......................... &ltDC> passed test FrsEvent
         ......................... &ltDC> passed test DFSREvent
         ......................... &ltDC> passed test SysVolCheck
         ......................... &ltDC> passed test FrsSysVol
         ......................... &ltDC> passed test KccEvent
         ......................... &ltDC> passed test KnowsOfRoleHolders
         ......................... &ltDC> passed test MachineAccount
         ......................... &ltDC> passed test NCSecDesc
         ......................... &ltDC> passed test NetLogons
         ......................... &ltDC> passed test ObjectsReplicated
         ......................... &ltDC> passed test Replications
         ......................... &ltDC> passed test RidManager
         ......................... &ltDC> passed test Services
         ......................... &ltDC> passed test SystemLog
         ......................... &ltDC> passed test Topology
         ......................... &ltDC> passed test VerifyReferences
         ......................... &ltDC> passed test VerifyReplicas
         ......................... &ltDC> passed test DNS
         ......................... ForestDnsZones passed test CheckSDRefDom
         ......................... DomainDnsZones passed test CheckSDRefDom
         ......................... Schema passed test CheckSDRefDom
         ......................... Schema passed test CrossRefValidation
         ......................... Configuration passed test CheckSDRefDom
         ......................... Configuration passed test CrossRefValidation
         ......................... &ltDOMAIN> passed test CheckSDRefDom
         ......................... &ltDOMAIN> passed test CrossRefValidation
         ......................... &ltDOMAIN> passed test DNS
         ......................... &ltDOMAIN> passed test LocatorCheck
         ......................... &ltDOMAIN> passed test FsmoCheck
         ......................... &ltDOMAIN> passed test Intersite
	 </pre>
</details>

