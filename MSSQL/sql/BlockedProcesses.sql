select count(*) from sys.sysprocesses where spid>50  /* exclude system processes */ and blocked<>0

--https://dba.stackexchange.com/questions/165143/how-to-get-the-sql-server-activity-monitors-output-using-t-sql
