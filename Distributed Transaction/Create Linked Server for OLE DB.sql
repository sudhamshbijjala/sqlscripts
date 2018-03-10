/*********  this script automatically creates a linked server against OLE DB data source  ************/

--  It maps current login to a read-only account "TempLinkedServerUser" in remote server.


--  Step 1. Run this part on remote server
--  replace @targetDB !!
CREATE LOGIN [TempLinkedServerUser] WITH PASSWORD=N'A1b2c3d4' MUST_CHANGE, DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=ON, CHECK_POLICY=ON
GO
ALTER LOGIN [TempLinkedServerUser] ENABLE
GO

USE WellnessODS
GO

CREATE USER [TempLinkedServerUser] FOR LOGIN [TempLinkedServerUser] WITH DEFAULT_SCHEMA=[dbo]
GO

EXEC dbo.sp_addrolemember 'db_datareader', 'TempLinkedServerUser'
GO

--  Step 2. Use SSMS Query Editor to login using this account and change the password


--  Step 3. Run this part on local server
--  Change variables as appropriate.
Declare @LinkedServerName sysname, 
        @RemoteServerName sysname, 
        @DatabaseName sysname, 
        @RemoteLogin sysname,
        @RemotePassword sysname

SELECT @LinkedServerName = 'MCDBDATASOURCE', 
       @RemoteServerName = 'ADEVDBS001', 
       @DatabaseName = 'MCDB',
       @RemoteLogin = 'TempLinkedServerUser',
       @RemotePassword = '########'  --  pswd is masked !!


EXEC master.dbo.sp_addlinkedserver @server = @LinkedServerName, @srvproduct=N'Any', @provider=N'SQLNCLI', @datasrc=@RemoteServerName, @catalog=@DatabaseName
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname= @LinkedServerName,@useself=N'False',@locallogin=NULL,@rmtuser=@RemoteLogin,@rmtpassword=@RemotePassword

EXEC master.dbo.sp_serveroption @server= @LinkedServerName, @optname=N'collation compatible', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server= @LinkedServerName, @optname=N'data access', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server= @LinkedServerName, @optname=N'dist', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server= @LinkedServerName, @optname=N'pub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server= @LinkedServerName, @optname=N'rpc', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server= @LinkedServerName, @optname=N'rpc out', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server= @LinkedServerName, @optname=N'sub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server= @LinkedServerName, @optname=N'connect timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server= @LinkedServerName, @optname=N'collation name', @optvalue=null
EXEC master.dbo.sp_serveroption @server= @LinkedServerName, @optname=N'lazy schema validation', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server= @LinkedServerName, @optname=N'query timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server= @LinkedServerName, @optname=N'use remote collation', @optvalue=N'true'

--  To test 
EXEC ('SELECT TOP 10 * FROM ' + @LinkedServerName + '.master.sys.tables' )

