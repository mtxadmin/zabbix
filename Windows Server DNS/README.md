# Windows Server DNS

Zabbix template for monitoring DNS parameters of Windows Server DNS

Format: zabbix 5.0 xml. It should also work on 5.2 (see [docs](https://www.zabbix.com/documentation/current/manual/xml_export_import/media) about template formats)

Tested on Windows Server 2016

Apply the template to Windows DNS hosts (typically, AD DCs)

The template initially was based on "Template Windows 2008 R2 DNS Server.xml" by (Stephen.e.fritz)[stephenfritz.blogspot.com], but contains much more parameters - all of Windows Server 2016 DNS. (And it temporally does not contain zabbix screens - there was a [bug](https://support.zabbix.com/browse/ZBX-18588) in 5.0 version, now patched)
