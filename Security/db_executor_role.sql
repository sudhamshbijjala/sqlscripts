
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'db_executor' AND type = 'R')
CREATE ROLE [db_executor] AUTHORIZATION [dbo]
GO

GRANT EXECUTE ON SCHEMA::[dbo] TO [db_executor]
GO
