USE [master]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_CreateTempDBUserOnStartup]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_CreateTempDBUserOnStartup]
GO

USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create procedure [dbo].[sp_CreateTempDBUserOnStartup]
as

declare @sql nvarchar(2000)
set @sql = '
-- If the login exists
IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N''DBAMonitoring'')
begin
	USE [tempdb]
	-- But the user does not exist
	IF  NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N''DBAMonitoring'')
	begin
		-- then create the user
		CREATE USER [DBAMonitoring] FOR LOGIN [DBAMonitoring]
		-- and give it read access
		EXEC sp_addrolemember N''db_datareader'', N''DBAMonitoring''
	end
end
'

exec sp_executesql @sql

GO

EXEC sp_procoption N'[dbo].[sp_CreateTempDBUserOnStartup]', 'startup', '1'

GO


