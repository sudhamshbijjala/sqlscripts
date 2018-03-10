use master 
go
grant create any database to [amsa\sql_dev_reader]
go
grant alter any database to [amsa\sql_dev_reader]
go
grant ADMINISTER BULK OPERATIONS to [amsa\sql_dev_reader]
go
grant VIEW SERVER STATE to [amsa\sql_dev_reader]
go
grant VIEW ANY DEFINITION to [amsa\sql_dev_reader]
go
grant ALTER ANY CONNECTION to [amsa\sql_dev_reader]
go
grant ALTER TRACE to [amsa\sql_dev_reader]
go

use msdb 
go
CREATE USER [amsa\sql_dev_reader] FOR LOGIN [amsa\sql_dev_reader]
go
grant connect to [amsa\sql_dev_reader]
go
grant execute on sp_delete_database_backuphistory to [amsa\sql_dev_reader]
go
EXEC sp_addrolemember N'SQLAgentOperatorRole', N'amsa\sql_dev_reader'
go
