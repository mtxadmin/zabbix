use master
go
set quoted_identifier on
-- detects SQL memory pressure
declare @pastMinutes int = 20;
declare @ts_now  bigint = (select  ms_ticks from sys.dm_os_sys_info)
if not exists (
SELECT 
top (1) 1
FROM (
SELECT CAST(record AS XML) AS record, timestamp FROM sys.dm_os_ring_buffers WHERE ring_buffer_type = N'RING_BUFFER_RESOURCE_MONITOR'
) AS rb
CROSS APPLY record.nodes('Record') record (xr)
where
xr.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint') =2 -- SQL memory pressure
and
dateadd (ms, [timestamp] - @ts_now, GETDATE()) > dateadd(minute, -@pastMinutes, GETDATE()) -- @past N minutes
)
select 0 as SQL_memory
	else
select 1 as SQL_Memory
