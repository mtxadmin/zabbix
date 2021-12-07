SELECT count(*) FROM sys.dm_os_waiting_tasks WHERE blocking_session_id IS NOT NULL; 
--https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-waiting-tasks-transact-sql?view=sql-server-ver15
