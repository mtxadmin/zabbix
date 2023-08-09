USE master
GO
--мониторит перегрузку дисковой подсистемы через подвисание checkpoint process
declare @pastMinutes int = 20;
declare @ErrorLog as table( [LogDate] datetime null, [ProcessInfo] nvarchar(20) null, [Text] nvarchar(MAX) null) ;
-- Command will insert the errorlog data into temporary table
INSERT INTO @ErrorLog ([LogDate], [ProcessInfo], [Text])
EXEC sys.xp_readerrorlog 0, 1, N'FlushCache'

INSERT INTO @ErrorLog ([LogDate], [ProcessInfo], [Text])
EXEC sys.xp_readerrorlog 0, 1, N'I/O saturation'

if exists(select * from @ErrorLog where LogDate > DateAdd(minute,-@pastMinutes, GETDATE()))
select 1 as CheckpointStall
	else 
select 0 as CheckpointStall
