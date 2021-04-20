
## Zabbix template to monitor USB Anywhere devices

Format: zabbix 5.0 xml. It should also work on 5.2 (see [docs](https://www.zabbix.com/documentation/current/manual/xml_export_import/media) about template formats)

Apply the template to USB Anywhere hosts. There must be SNMP agents on them with correct community for reading data.


USB Anywhere is a popular solution to present USB devices, such as crypto keys etc, to servers and PCs via local network<br>
https://www.digi.com/products/browse/anywhereusb

Sometimes these devices hang and/or glitch :-) But it is still one of the best USB-over-network solution
