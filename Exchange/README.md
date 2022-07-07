
## Zabbix template to monitor Microsoft Exchange transport queues

Format: zabbix 5.0 xml. It should also work on 5.2 and above (see [docs](https://www.zabbix.com/documentation/current/manual/xml_export_import/media) about template formats)

Tested on Exchange 2016

Apply the template to Exchange servers hosts with Transport and Edge roles.

### Monitored queues

<!--
|Name |Source  | Trigger avg | Trigger high|
--- | --- | --- | ---
Active Mailbox Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Active Mailbox Delivery Queue Length"]|{$EXCHANGE_TRANSPORT_QUEUES_AVG}|{$EXCHANGE_TRANSPORT_QUEUES_HIGH}|
Active Non-Smtp Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Active Non-Smtp Delivery Queue Length"]|{$EXCHANGE_TRANSPORT_QUEUES_AVG}|{$EXCHANGE_TRANSPORT_QUEUES_HIGH}|
|data1|data2|data3|
|data11|data12|data13|
-->

Queues are discovered for Exchange 2016. On earlier versions some of them may be absent, it is ok and the template will work normally.

And some more queues may be added in 2019 and future versions. (If you have 2019+ version and see some unlisted queue, feel free to make an issue about it)

Name | Source | Triggers | Comments
--- | --- | --- | ---
Active Mailbox Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Active Mailbox Delivery Queue Length"]| Avg, High | Mentioned in many posts about Exchange
Active Non-Smtp Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Active Non-Smtp Delivery Queue Length"]| Avg, High
Active Remote Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Active Remote Delivery Queue Length"]| Avg, High
Aggregate Delivery Queue Length (All Queues)|perf_counter["\MSExchangeTransport Queues(_total)\Aggregate Delivery Queue Length (All Queues)"]| Avg, High
Aggregate Shadow Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Aggregate Shadow Queue Length"]| Avg, High |Thresholds are ok. In case of relay breakdown this queue grows significantly
Delay Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Delay Queue Length"]| Avg, High
External Active Remote Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\External Active Remote Delivery Queue Length"]| Avg, High |Thresholds are ok. In case of relay breakdown this queue grows significantly
External Aggregate Delivery Queue Length (All External Queues)|perf_counter["\MSExchangeTransport Queues(_total)\External Aggregate Delivery Queue Length (All External Queues)"]| Avg, High |Thresholds are ok. In case of relay breakdown this queue grows significantly
External Largest Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\External Largest Delivery Queue Length"]| Avg, High |Thresholds are ok. In case of relay breakdown this queue grows significantly
External Largest Unlocked Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\External Largest Unlocked Delivery Queue Length"]|Avg, High |Thresholds are ok. In case of relay breakdown this queue grows significantly
External Retry Remote Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\External Retry Remote Delivery Queue Length"]|Avg, High |Thresholds are ok. In case of relay breakdown this queue grows significantly
Internal Active Remote Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Internal Active Remote Delivery Queue Length"]| Avg, High |
Internal Aggregate Delivery Queue Length (All Internal Queues)|perf_counter["\MSExchangeTransport Queues(_total)\Internal Aggregate Delivery Queue Length (All Internal Queues)"]| Avg, High |
Internal Largest Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Internal Largest Delivery Queue Length"]| Avg, High |
Internal Largest Unlocked Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Internal Largest Unlocked Delivery Queue Length"]| Avg, High |
Internal Retry Remote Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Internal Retry Remote Delivery Queue Length"]| Avg, High |
Largest Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Largest Delivery Queue Length"]| Avg, High | Mentioned in many posts about Exchange
Poison Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Poison Queue Length"]| Avg, High | Mentioned in many posts about Exchange.
Retry Mailbox Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Retry Mailbox Delivery Queue Length"]| Avg, High | Mentioned in many posts about Exchange
Retry Non-Smtp Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Retry Non-Smtp Delivery Queue Length"]| Avg, High | Mentioned in many posts about Exchange
Retry Remote Delivery Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Retry Remote Delivery Queue Length"]| Avg, High | Mentioned in many posts about Exchange
Shadow Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Shadow Queue Length"]||I've seen this somewhere, but it is absent in 2016. Maybe, it was transformed to Aggregate Shadow Queue Length? Or maybe it was initially misspelled?
Submission Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Submission Queue Length"]| Avg, High | Mentioned in many posts about Exchange
Unreachable Queue Length|perf_counter["\MSExchangeTransport Queues(_total)\Unreachable Queue Length"]| Avg, High | Mentioned in many posts about Exchange


### Macros

| Macros | Default value |
--- | ---
|{$EXCHANGE_TRANSPORT_QUEUES_AVG} | 250 |
|{$EXCHANGE_TRANSPORT_QUEUES_HIGH}| 1000 |

You can override these values freely - just set macros with such names for corresponding hosts in your infrastructure


### Triggers

On every queue, there are two dependent triggers, average and high respectively. Triggers are made with .min(#2) functions to exclude short narrow peaks. For thresholds, see the macros above

### Notes

All items configured as active checks. I you want, you can change most of them to passive type, but not Backpressure events (this is [by design](https://www.zabbix.com/documentation/2.0/en/manual/config/items/itemtypes/zabbix_agent/win_keys))

#### And don't forget to make actions to receive alerts (template cannot make actions automatically, you have to make them by hands):
... (some conditions) ...<br>
Trigger name contains Queue Length<br>
... (some conditions) ...
