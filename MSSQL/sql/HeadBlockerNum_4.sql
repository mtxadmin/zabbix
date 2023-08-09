-- Script from https://dba.stackexchange.com/questions/165143/how-to-get-the-sql-server-activity-monitors-output-using-t-sql 
-- or better https://stackoverflow.com/questions/42134924/getting-sql-server-activity-monitors-output-using-t-sql
-- modified to exclude false positive head blockers

/* ACTIVITY MONITOR'S OUTPUT along with statement_text and command_text */ /* Processes */ 
with activitymonitor as (
SELECT [Session ID] = s.session_id, 
       [User Process] = CONVERT(CHAR(1), s.is_user_process), 
       [Login] = s.login_name, 
       [Blocked By] = ISNULL(CONVERT (varchar, w.blocking_session_id), ''), 
         [Head Blocker]  =
    CASE
        -- session has an active request, is blocked, but is blocking others or session is idle but has an open tran and is blocking others
        WHEN r2.session_id IS NOT NULL AND (r.blocking_session_id = 0 OR r.session_id IS NULL) AND (s.session_id != w.blocking_session_id) THEN '1'
        -- session is either not blocking someone, or is blocking someone but is blocked by another party
        ELSE ''
    END,
                        [DatabaseName] = ISNULL(db_name(r.database_id), N''), 
                        [Task State] = ISNULL(t.task_state, N''), 
                        [Command] = ISNULL(r.command, N''), 
                        [statement_text] = Substring(st.TEXT, (r.statement_start_offset / 2) + 1, 
                                            ( ( CASE r.statement_end_offset WHEN - 1 THEN Datalength(st.TEXT)
                                            ELSE r.statement_end_offset 
                                            END - r.statement_start_offset ) / 2 ) + 1), ----It will display the statement which is being executed presently.

 [command_text] =Coalesce(Quotename(Db_name(st.dbid)) + N'.' + Quotename(Object_schema_name(st.objectid, st.dbid)) + N'.' + Quotename(Object_name(st.objectid, st.dbid)), ''), -- It will display the Stored Procedure's Name.

 [Total CPU (ms)] = r.cpu_time,
 r.total_elapsed_time / (1000.0) 'Elapsed Time (in Sec)',
                                 [Wait Time (ms)] = ISNULL(w.wait_duration_ms, 0),
                                 [Wait Type] = ISNULL(w.wait_type, N''),
                                 [Wait Resource] = ISNULL(w.resource_description, N''),
                                 [Total Physical I/O (MB)] = (s.reads + s.writes) * 8 / 1024,
                                 [Memory Use (KB)] = s.memory_usage * 8192 / 1024, 
 --[Open Transactions Count] = ISNULL(r.open_transaction_count,0),
 --[Login Time]    = s.login_time,
 --[Last Request Start Time] = s.last_request_start_time,

 [Host Name] = ISNULL(s.host_name, N''),
 [Net Address] = ISNULL(c.client_net_address, N''), 

 -- [Execution Context ID] = ISNULL(t.exec_context_id, 0),
 -- [Request ID] = ISNULL(r.request_id, 0),
 [Workload Group] = N'',
                     [Application] = ISNULL(s.program_name, N'')
FROM sys.dm_exec_sessions s
LEFT OUTER JOIN sys.dm_exec_connections c ON (s.session_id = c.session_id)
LEFT OUTER JOIN sys.dm_exec_requests r ON (s.session_id = r.session_id)
LEFT OUTER JOIN sys.dm_os_tasks t ON (r.session_id = t.session_id
                                      AND r.request_id = t.request_id)
LEFT OUTER JOIN
  ( -- In some cases (e.g. parallel queries, also waiting for a worker), one thread can be flagged as
 -- waiting for several different threads.  This will cause that thread to show up in multiple rows
 -- in our grid, which we don't want.  Use ROW_NUMBER to select the longest wait for each thread,
 -- and use it as representative of the other wait relationships this thread is involved in.
 SELECT *, 
        ROW_NUMBER() OVER (PARTITION BY waiting_task_address
                           ORDER BY wait_duration_ms DESC) AS row_num 
   FROM sys.dm_os_waiting_tasks ) w ON (t.session_id = w.session_id)
AND w.row_num = 1 
LEFT OUTER JOIN sys.dm_exec_requests r2 ON (r.session_id = r2.blocking_session_id) OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS st 

WHERE s.session_Id > 50 -- Ignore system spids.

--ORDER BY s.session_id --,[Total CPU (ms)] desc ;
)
--https://stackoverflow.com/questions/54889377/sql-select-from-a-select-query
select count(*) from activitymonitor where [Head Blocker]<>''
