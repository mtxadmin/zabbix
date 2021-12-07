USE master
GO
set quoted_identifier on
declare @pastMinutes int = 20;
declare @ts_now  bigint = (select  ms_ticks from sys.dm_os_sys_info)
SELECT top (1)
xr.value('(MemoryRecord/AvailablePhysicalMemory)[1]','bigint')/1024 AS AvailablePhysicalMemoryMB
FROM (	
SELECT CAST(record AS XML) AS record, timestamp FROM sys.dm_os_ring_buffers WHERE ring_buffer_type = N'RING_BUFFER_RESOURCE_MONITOR'
) AS rb
CROSS APPLY record.nodes('Record') record (xr)
where 
xr.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint') =2	-- SYSTEM low memory
and
dateadd (ms, [timestamp] - @ts_now, GETDATE()) > dateadd(minute, -@pastMinutes, GETDATE())	-- @past N minutes
ORDER BY 1 asc 
if @@ROWCOUNT = 0
select 0 as All_right
