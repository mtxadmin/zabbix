# Veeam volumes

This is a Zabbix template for making stats by systems' backups size

## Description

Systems: in this context, a group of servers, providing some separate service. For instance:
  - File servers. It can be a big cluster of servers, but they can be grouped and treated as a united system
  - Web servers. Application servers, database servers, cache servers, balancers, etc. All these servers can be grouped too
  - SAP or another soft. Purpose of many different servers, working together, is to provide some service for user

This template answers to the question "How much backup data do we have for system X?"

The template is made for backups made by Veeam.

## Configuration

Systems and their servers are listed in a text file corp_systems.txt in [YAML](https://en.wikipedia.org/wiki/YAML) format. See the comments and example configuration there and list your own config.

## Installation

1. Import the template to Zabbix web interface

2. Copy Veeam_volumes.ps1 to Zabbix agent folder (for instance, c:\zabbix\scripts\) 

3. Install YAML Powershell module<br>
For parsing YAML config the template uses [PSYaml](https://github.com/Phil-Factor/PSYaml) Powershell module. Just download project file, unzip, and copy the folder to c:\zabbix\scripts\PSYaml - you don't have to have admin rights on the server for that.
If you want to change the module folder or install the module to the system, edit Install-Module string in Veeam_volumes.ps1<br>
PSYaml module needs at least Powershell 4.0

4. In Veeam_volumes.ps1 edit path of backups.<br>
See the string "$disk\Veeam\Backup"

5. Edit corp_systems.txt configuration file (this can be boring)

6. Open Veeam_volumes.ps1 in Powershell ISE, run and see results and absence of errors.
Just to be sure everything works fine

7. Make a task in Windows Task Scheduler<br>
Action: start a program<br>
Program: powershell.exe<br>
Add arguments: -NoProfile -ExecutionPolicy Bypass -File "c:\zabbix\scripts\Veeam_volumes.ps1"

8. In the Zabbix web interface, apply the imported template **Veeam volumes** to the host

9. Alter server names in Zabbix: BKP-Server1, BKP-Server2, BKP-Server3, etc. to your actual ones.

10. After starting of the scheduled task, see the results ("Size of backups" in Latest data)

11. Optionally, you can visualize these data in Grafana<br>
Plain graphs: Graph, Metrics, add Veeam hosts, add item "/Size of backups/"
