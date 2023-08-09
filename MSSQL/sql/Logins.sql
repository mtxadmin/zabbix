SELECT @@SERVERNAME AS ServerName,
Name AS LoginName,
LOGINPROPERTY(name, 'DaysUntilExpiration') AS 'DaysUntilExpiration',
  --https://learn.microsoft.com/en-us/sql/t-sql/functions/loginproperty-transact-sql :
  -- 0 if the login is expired or if it will expire on the day when queried.
  -- -1 if the local security policy in Windows never expires the password.
  -- NULL if the CHECK_POLICY or CHECK_EXPIRATION is OFF for a login, or if the operating system does not support the password policy.
LOGINPROPERTY(name, 'IsExpired') AS 'IsExpired',
LOGINPROPERTY(name, 'IsLocked') AS 'IsLocked',
LOGINPROPERTY(name, 'IsMustChange') AS 'IsMustChange',
is_expiration_checked	AS 'is_expiration_checked',
is_policy_checked  AS 'is_policy_checked',
  --The only way to get the password policy information is to get it from the OS. You can use NET ACCOUNTS and NET ACCOUNTS /DOMAIN
LOGINPROPERTY(name, 'LockoutTime') AS 'LockoutTime',
LOGINPROPERTY(name, 'DefaultDatabase') AS 'DefaultDatabase',
LOGINPROPERTY(name, 'DefaultLanguage') AS 'DefaultLanguage',
    -- https://learn.microsoft.com/en-us/sql/t-sql/functions/loginproperty-transact-sql :
    -- Returns NULL for non-SQL Server provisioned users, for example, Windows authenticated users.
--LOGINPROPERTY(name, 'HistoryLength') AS 'HistoryLength',
--LOGINPROPERTY(name, 'PasswordHash') AS 'PasswordHash',
LOGINPROPERTY(name, 'PasswordLastSetTime') AS 'PasswordLastSetTime',
  --for those using windows integrated authentication, it will return NULL
--LOGINPROPERTY(name, 'PasswordHashAlgorithm') AS 'PasswordHashAlgorithm',
LOGINPROPERTY(name, 'BadPasswordCount') AS 'BadPasswordCount',
LOGINPROPERTY(name, 'BadPasswordTime') AS 'BadPasswordTime'
FROM    sys.sql_logins
WHERE	is_expiration_checked = 1 AND
  NOT (LEFT([name], 2) = '##' AND RIGHT([name], 2) = '##');
    -- if you're running this against a SQL Server 2008 or higher installation, there are two logins that will show up that you can basically ignore. They are:
    --##MS_PolicyTsqlExecutionLogin##
    --##MS_PolicyEventProcessingLogin##
