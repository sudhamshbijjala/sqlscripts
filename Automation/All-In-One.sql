--SQL Server 2000    M:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER
--SQL Server 2008 
--SQL Server 2008 R2 M:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER
--SQLServer 2012     M:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER


-- 012 Standardize system database size.sql

--  Only need to modify variable @SQLInstance

USE [msdb]
GO
EXEC master.dbo.sp_MSsetalertinfo @failsafeoperator=N'DBA', @notificationmethod=1
GO


EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail', N'REG_DWORD', 1
GO

DECLARE @SQLInstance NVARCHAR(255)

-- CHANGE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- CHANGE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- CHANGE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

SET @SQLInstance = N'AOPSDBS048'

-- CHANGE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- CHANGE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- CHANGE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', @SQLInstance
GO

-- Default path for database creation
USE [master]
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', REG_SZ, N'F:\SQL\Data'
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', REG_SZ, N'L:\SQL\LOG'
GO

-- 004 Move Tempdb.sql

--  Change tempdb files for small or vendor dbs
use master
go


--  Step 1. Change file path. Do not change other things as it may break it

USE [master]
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdev2', FILENAME = N'T:\SQL\Data\tempdev2.ndf' , SIZE = 1024MB , MAXSIZE = 2050MB , FILEGROWTH = 512MB )
GO

USE [master]
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdev', SIZE = 1024MB , MAXSIZE = 2050MB , FILEGROWTH = 512MB)
GO

USE [master]
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'templog', SIZE = 512MB , MAXSIZE = 1030MB , FILEGROWTH = 512MB)
GO

/*
Alter database tempdb modify file 
(	name = tempdev, 
	filename = 'T:\TEMPDB\tempdb.mdf')
go

Alter database tempdb add file 
(	name = tempdev2, 
	filename = 'T:\TEMPDB\tempdb_2.mdf')
go
Alter database tempdb add file 
(	name = tempdev3, 
	filename = 'T:\TEMPDB\tempdb_3.mdf')
go
Alter database tempdb add file 
(	name = tempdev4, 
	filename = 'T:\TEMPDB\tempdb_4.mdf')
go

--Alter database tempdb modify file 
--(	name = tempdev2, 
--	filename = 'T:\TEMPDB\tempdev2.mdf')
--go

Alter database tempdb modify file 
(	name = templog, 
	filename = 'T:\TEMPDB\templog.ldf')
go
*/

USE [master]
GO
ALTER DATABASE [model] SET RECOVERY SIMPLE WITH NO_WAIT
GO

--  Step 2. Restart MSSQL Server service

-- CHANGE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
/*
--  Step 3. Change other attributes
Alter database tempdb modify file 
(	name = tempdev, 
	size = 130GB,
	filegrowth = 0)
go

Alter database tempdb modify file 
(	name = templog, 
	size = 20GB,
	filegrowth = 0)
go
*/

--001 Security standard.sql

--  This script handles login security
--  based on DBA's << SQL Server and Database Standard >>

--  Grant DBA group access to all SQL Servers
if not exists (select * from sys.server_principals where name = 'AMSA\prodDBA')
  create login [AMSA\prodDBA] from windows;

exec dbo.sp_addsrvrolemember 'AMSA\prodDBA', 'sysadmin';

--  Delete builtin administrator account
if exists (select * from sys.server_principals where name = 'BUILTIN\Administrators')
  drop login [BUILTIN\Administrators];

--  Rename SA account, password protect it and disable it
if exists (select * from sys.server_principals where name = 'sa')
  begin
    ALTER LOGIN sa WITH 
		NAME = ASASA, 
		PASSWORD = '3u3hnnd%#ED' MUST_CHANGE, 
		CHECK_EXPIRATION = ON, 
		CHECK_POLICY = ON, 
		DEFAULT_DATABASE=[master], 
		DEFAULT_LANGUAGE=[us_english];
	ALTER LOGIN ASASA DISABLE;
  end

--  Choose which access to grant
/*
if not exists (select * from sys.server_principals where name = 'AMSA\SQL_DEV_Reader')
  create login [AMSA\SQL_DEV_Reader] from windows;
*/
/*
if not exists (select * from sys.server_principals where name = 'AMSA\SQL_TST_Reader')
  create login [AMSA\SQL_TST_Reader] from windows;

if not exists (select * from sys.server_principals where name = 'AMSA\SQL_STG_Reader')
  create login [AMSA\SQL_STG_Reader] from windows;
*/
if not exists (select * from sys.server_principals where name = 'AMSA\SQL_PRD_Reader')
  create login [AMSA\SQL_PRD_Reader] from windows;

  
-- 002 sp_configure.sql

exec sp_configure 'show advanced options', 1;
RECONFIGURE;

exec sp_configure 'Agent XPs', 1;

exec sp_configure 'Database Mail XPs', 1;

exec sp_configure 'Ole Automation Procedures', 1;

exec sp_configure 'remote admin connections', 1;

exec sp_configure 'scan for startup procs', 1;

exec sp_configure 'backup compression default', 1;

RECONFIGURE WITH OVERRIDE;

----------------------------------------

--  Memory configuration:
declare @MSVersion table
( [Index] varchar(5), 
  [Name] varchar(20), 
  Internal_Value varchar(10), 
  Character_Value varchar(120));    

insert into @MSVersion exec ('master.dbo.xp_msver');

declare @Memory varchar(6);
select @Memory = (select Internal_Value from @MSVersion where Name = 'PhysicalMemory');

/*
--  Based on DBA's << SQL and Database Standard >>
RAM installed	Available Memory for OS		Max Memory for SQL
< 4 GB			512 MB – 1 GB				< 3 GB – 3.5 GB
4 - 32 GB		1 GB – 2 GB					3 GB – 30 GB
32 – 128 GB		2 GB – 4 GB					30 GB – 124 GB
128 GB			4 GB						124 GB
*/

if @Memory <= 2048
  set @Memory = @Memory - 512;
if @Memory <= 8192 and @Memory > 2048
  set @Memory = @Memory - 1024;
if @Memory <= 32768 and @Memory > 8192
  set @Memory = @Memory - 2048;

exec dbo.sp_configure 'max server memory (MB)', @Memory;
RECONFIGURE WITH OVERRIDE;
----------------------------------------


-- 003 revoke guest account.sql

declare @name sysname, @sql nvarchar(1000)
select @name = min(name) from sys.sysdatabases where name not in ('master','tempdb')
while @name is not null
begin
	set @sql = 'use [' + @name + ']; revoke connect from guest;'
	exec sp_executesql @sql
	select @name = min(name) from sys.sysdatabases where name not in ('master','tempdb') and name > @name
end

-- 004 missing.sql

-- 005 log enum.sql

USE [master]
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', REG_DWORD, 50
GO


-- 006 job history.sql

USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=10000, 
		@jobhistory_max_rows_per_job=1000
GO


-- 007 database mail script.sql

--  This script creates Database Mail using T-SQL stored procedures
--  Modify the variables as necessary in Section 4.
--  Run the whole script. If everything works, you should get a test email

/*********** You only need to manually polulate the variables ***********/


/* Section 1 - Enable Database Mail on the SQL Server */
use master
exec sp_configure 'Show Advanced Options', 1
reconfigure with override
exec sp_configure 'Database Mail XPs', 1
reconfigure with override


/* Section 2 - Set up security for users who can send database mails */
use msdb
if not exists (select * from sys.server_principals where name = 'AMSA\ProdDBA')
  begin
    create login [amsa\ProdDBA] from windows;
    exec sp_addsrvrolemember 'AMSA\ProdDBA', 'sysadmin'
  end
if not exists (select * from sys.database_principals where name = 'AMSA\ProdDBA')
  create user [amsa\ProdDBA] for login [amsa\ProdDBA]
exec sp_addrolemember 'DatabaseMailUserRole', 'amsa\ProdDBA'


/* Section 3 - Set up an opertor */
USE [msdb]
GO
IF  EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'DBA')
EXEC msdb.dbo.sp_delete_operator @name=N'DBA'
GO

EXEC msdb.dbo.sp_add_operator @name=N'DBA', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'rpatel@asa.org; tsuryadevara@asa.org; obatraeva@asa.org', 
		@category_name=N'[Uncategorized]'
GO

/* Section 4 - Populate variables as needed */
declare @ProfileName sysname,
        @PrincipalName sysname,
        @AcctName sysname, 
        @EmailAddr sysname, 
        @DisplayName varchar(50), 
        @ReplyToAddr sysname, 
        @Desc varchar(255), 
        @SMTPServer sysname,
        @RecipientName sysname,
        @SubjectLine varchar(255),
        @BodyText varchar(max)

select  @ProfileName = @@servername,
        @PrincipalName = 'amsa\ProdDBA',
        @AcctName = 'DBA', 
        @EmailAddr = 'DBA@amsa.com', 
        @DisplayName = 'SQL Alert (' + @@servername + ')', 
        @ReplyToAddr = 'DBA@amsa.com', 
        @Desc = 'db mail account for DBA', 
        @SMTPServer = 'mailhost.amsa.com',
        @RecipientName = 'DBA@amsa.com',
        @SubjectLine = 'database mail test from ' + @@servername + '',
        @BodyText = 'Please ignore.'
--  select  @ProfileName, @AcctName, @EmailAddr, @DisplayName, @ReplyToAddr, @Desc, @SMTPServer

/* Section 5 - Create a Database Mail account */
exec msdb.dbo.sysmail_add_account_sp   
  @account_name = @AcctName,                 
  @email_address = @EmailAddr,        
  @display_name = @DisplayName,               
  @replyto_address = @ReplyToAddr,      
  @description = @Desc,     
  @mailserver_name = @SMTPServer,            
  @mailserver_type = 'SMTP',                
  @port = 25,                               
  @use_default_credentials = 1,                          
  @enable_ssl = 0;

/* Section 6 - Create a Database Mail profile */
exec msdb.dbo.sysmail_add_profile_sp
  @profile_name = @ProfileName,
  @description = 'Profile A used for database mail.' ;

/* Section 7 - Adds a Database Mail account to a profile */
exec msdb.dbo.sysmail_add_profileaccount_sp 
  @profile_name = @ProfileName, 
  @account_name = @AcctName,
  @sequence_number = 1; 

/* Section 8 - Grants permission for an msdb user or public to use Database Mail profile */
EXEC msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = @ProfileName,
    @principal_name = @PrincipalName,
    @is_default = 1; 


/* Section 9 - Test sending Database Mail message */
declare @rtn int
exec msdb.dbo.sp_send_dbmail   
  @profile_name = @profileName,
  @recipients = @RecipientName,
  @subject = @SubjectLine, 
  @body = @BodyText,
  @mailitem_id = @rtn
select @rtn


-- 008 database mail for Job Agent.sql


USE [msdb]
GO
EXEC master.dbo.sp_MSsetalertinfo @failsafeoperator=N'DBA', @notificationmethod=1
GO


EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail', N'REG_DWORD', 1
GO


DECLARE @SQLInstance NVARCHAR(255)
SET @SQLInstance = @@SERVERNAME
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', @SQLInstance
GO

-- 009 System Sprocs & Agent Jobs.sql

--**************  IMPORTANT  *******************
--  You must manually create backup folder on the RIGHT drive !!
--  Replace Z:\ with the right drive letter.
--  You should check to see if the sql agent service account is correct (QA, TST, STG, etc)

USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_CreateTempDBUserOnStartup]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
create procedure [dbo].[sp_CreateTempDBUserOnStartup]
as

declare @sql nvarchar(2000)
set @sql = ''
-- If the login exists
IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N''''DBAMonitoring'''')
begin
	USE [tempdb]
	-- But the user does not exist
	IF  NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N''''DBAMonitoring'''')
	begin
		-- then create the user
		CREATE USER [DBAMonitoring] FOR LOGIN [DBAMonitoring]
		-- and give it read access
		EXEC sp_addrolemember N''''db_datareader'''', N''''DBAMonitoring''''
	end
end
''

exec sp_executesql @sql
' 
END
GO

EXEC sp_procoption N'[dbo].[sp_CreateTempDBUserOnStartup]', 'startup', '1'

GO


USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_SQLDBBackup]    Script Date: 06/11/2009 16:43:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_SQLDBBackup]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_SQLDBBackup]
GO

CREATE procedure [dbo].[sp_SQLDBBackup] 
			(@database   nvarchar(100) = null,
			 @backupType nvarchar(4)   = null,
			 @backupPath nvarchar(256) = null,
			 @backupRetentionInHours int = 72)
as

/*
	Author: Tom Flaherty - Platform Support
	Date:	11/04/2008
	Change:	Original Version

	Author: Tom Flaherty - Platform Support
	Date:	11/10/2008
	Change:	Allow parameter @backupRetentionInHours to be 0
			If zero, don't keep any log backups

	Author: 
	Date:	
	Change:	

	Example of calling procedure:

	-- Use Default Retention Period of 3 days
	Exec dbo.sp_SQLDBBackup @database = 'VirtualCenter', 
							@backupType = 'full', 
							@backupPath = '\\E1SRV\SQL_BACKUPS\AOPSDBS701\'

	-- Specify Retention Period in hours
	Exec dbo.sp_SQLDBBackup @database = 'VirtualCenter', 
							@backupType = 'diff', 
							@backupPath = '\\E1SRV\SQL_BACKUPS\AOPSDBS701\', 
							@backupRetentionInHours = 168

*/

if @database is null or @backupType is null or @backupPath is null or @backupRetentionInHours is null
begin
	Print ''
	Print 'Invalid Parameter(s) were passed into stored procedure [sp_SQLDBBackup]'
	Print ''
	Print 'Valid parameters are:'
	Print ''
	Print '@database   nvarchar(100)'
	Print '@backupType nvarchar(4)'
	Print '@backupPath nvarchar(256)'
	Print '@backupRetentionInHours int'
	return
end

if upper(@backupType) not in ('FULL', 'DIFF', 'TRN')
begin
	Print ''
	Print 'Invalid Value for parameter @backupType'
	Print ''
	Print 'Valid values are:'
	Print ''
	Print 'FULL'
	Print 'DIFF'
	Print 'TRN'
	return
end

if (select count(name) from sys.databases where name = @database) = 0
begin
	Print ''
	Print 'Database ' + upper(@database) + ' does not exist on ' + @@servername
	Print ''
	return
end

DECLARE @sql nvarchar(2000), @id int, @timeStamp varchar(14), @purgeDate datetime

if @backupRetentionInHours = 0
begin
	select @purgeDate = dateadd(mi,-1,current_timestamp)
end
else
begin
	select @purgeDate = dateadd(hh,-@backupRetentionInHours,current_timestamp)
end
-- If path does not include trailing backslash (\) then add one
if substring(@backupPath,len(@backupPath),1) != '\' set @backupPath = @backupPath + '\'

if @backupType = 'FULL'
begin
	select @timeStamp = CONVERT(char(8), CURRENT_TIMESTAMP, 112)+
	substring(CONVERT(char(8), CURRENT_TIMESTAMP, 108),1,2)+
	substring(CONVERT(char(8), CURRENT_TIMESTAMP, 108),4,2)

	set @sql = 'BACKUP DATABASE ' + @database + ' TO DISK = ''' + upper(@backupPath) + upper(@database) 
				+ '_' + @timeStamp + '.BAK'' WITH INIT, NOUNLOAD, NAME = N''' + upper(@database) 
				+ ' Full Backup'', NOSKIP, STATS = 30, NOFORMAT'

	--SELECT @sql
	exec sp_executesql @sql

	EXECUTE master.dbo.xp_delete_file 0, @backupPath, N'bak', @purgeDate, 0
end

if @backupType = 'DIFF'
begin
	select @timeStamp = CONVERT(char(8), CURRENT_TIMESTAMP, 112)+
	substring(CONVERT(char(8), CURRENT_TIMESTAMP, 108),1,2)+
	substring(CONVERT(char(8), CURRENT_TIMESTAMP, 108),4,2)

	set @sql = 'BACKUP DATABASE ' + upper(@database) + ' TO DISK = ''' + upper(@backupPath) + upper(@database) 
				+ '_' + @timeStamp + '.DIFF'' WITH DIFFERENTIAL, INIT, NOUNLOAD, NAME = N''' + upper(@database) 
				+ ' Differential Backup'', NOSKIP, STATS = 30, NOFORMAT'

	--SELECT @sql
	exec sp_executesql @sql

	EXECUTE master.dbo.xp_delete_file 0, @backupPath, N'diff', @purgeDate, 0
end

if @backupType = 'TRN'
begin
	select @timeStamp = CONVERT(char(8), CURRENT_TIMESTAMP, 112)+
	substring(CONVERT(char(8), CURRENT_TIMESTAMP, 108),1,2)+
	substring(CONVERT(char(8), CURRENT_TIMESTAMP, 108),4,2)+
	substring(CONVERT(char(8), CURRENT_TIMESTAMP, 108),7,2)

	set @sql = 'BACKUP LOG ' + upper(@database) + ' TO DISK = ''' + upper(@backupPath) + upper(@database) 
				+ '_' + @timeStamp + '.TRN'' WITH INIT, NOUNLOAD, NAME = N''' + upper(@database) 
				+ ' Transaction Log Backup'', NOSKIP, STATS = 30, NOFORMAT'

	--SELECT @sql
	exec sp_executesql @sql

	EXECUTE master.dbo.xp_delete_file 0, @backupPath, N'trn', @purgeDate, 0
end

GO

USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_SQLDBSpace]    Script Date: 06/11/2009 16:17:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_SQLDBSpace]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_SQLDBSpace]
GO

CREATE PROCEDURE [dbo].[sp_SQLDBSpace] 
  @TargetDatabase sysname = NULL,     --  NULL: all dbs
  @Level varchar(10) = 'Database',    --  or "File"
  @UpdateUsage bit = 0,               --  default no update
  @Unit char(2) = 'MB'                --  Megabytes, Kilobytes or Gigabytes
AS

/**************************************************************************************************
**
**  date:   6/4/2008
**  usage:  list db size AND path w/o summary. Compatible with SQL 2000 / 2005 / 2008
**  test code: sp_SQLDBSpace   --  default behavior
**             sp_SQLDBSpace 'maAster'
**             sp_SQLDBSpace NULL, NULL, 0
**             sp_SQLDBSpace NULL, 'file', 1, 'GB'
**             sp_SQLDBSpace 'Test_snapshot', 'Database', 1
**             sp_SQLDBSpace 'Test', 'File', 0, 'kb'
**             sp_SQLDBSpace 'tempdb', 'Database', 0, 'gb'
**             sp_SQLDBSpace 'tempdb', NULL, 1, 'kb'
**   
**************************************************************************************************/

SET NOCOUNT ON;

IF @TargetDatabase IS NOT NULL AND DB_ID(@TargetDatabase) IS NULL
  BEGIN
    RAISERROR(15010, -1, -1, @TargetDatabase);
    RETURN (-1)
  END

IF OBJECT_ID('tempdb.dbo.##Tbl_CombinedInfo', 'U') IS NOT NULL
  DROP TABLE dbo.##Tbl_CombinedInfo;
  
IF OBJECT_ID('tempdb.dbo.##Tbl_DbFileStats', 'U') IS NOT NULL
  DROP TABLE dbo.##Tbl_DbFileStats;
  
IF OBJECT_ID('tempdb.dbo.##Tbl_ValidDbs', 'U') IS NOT NULL
  DROP TABLE dbo.##Tbl_ValidDbs;
  
IF OBJECT_ID('tempdb.dbo.##Tbl_Logs', 'U') IS NOT NULL
  DROP TABLE dbo.##Tbl_Logs;
  
CREATE TABLE dbo.##Tbl_CombinedInfo (
  DatabaseName sysname NULL, 
  [type] VARCHAR(10) NULL, 
  LogicalName sysname NULL,
  T dec(10, 2) NULL,
  U dec(10, 2) NULL,
  [U(%)] dec(5, 2) NULL,
  F dec(10, 2) NULL,
  [F(%)] dec(5, 2) NULL,
  PhysicalName sysname NULL );

CREATE TABLE dbo.##Tbl_DbFileStats (
  Id int identity, 
  DatabaseName sysname NULL, 
  FileId int NULL, 
  FileGroup int NULL, 
  TotalExtents bigint NULL, 
  UsedExtents bigint NULL, 
  Name sysname NULL, 
  FileName varchar(255) NULL );
  
CREATE TABLE dbo.##Tbl_ValidDbs (
  Id int identity, 
  Dbname sysname NULL );
  
CREATE TABLE dbo.##Tbl_Logs (
  DatabaseName sysname NULL, 
  LogSize dec (10, 2) NULL, 
  LogSpaceUsedPercent dec (5, 2) NULL,
  Status int NULL );

DECLARE @Ver varchar(10), 
        @DatabaseName sysname, 
        @Ident_last int, 
        @String varchar(2000),
        @BaseString varchar(2000);
        
SELECT @DatabaseName = '', 
       @Ident_last = 0, 
       @String = '', 
       @Ver = CASE WHEN @@VERSION LIKE '%9.0%' THEN 'SQL 2005' 
                   WHEN @@VERSION LIKE '%8.0%' THEN 'SQL 2000' 
                   WHEN @@VERSION LIKE '%10.0%' THEN 'SQL 2008' 
              END;
              
SELECT @BaseString = 
' SELECT DB_NAME(), ' + 
CASE WHEN @Ver = 'SQL 2000' THEN 'CASE WHEN status & 0x40 = 0x40 THEN ''Log''  ELSE ''Data'' END' 
  ELSE ' CASE type WHEN 0 THEN ''Data'' WHEN 1 THEN ''Log'' WHEN 4 THEN ''Full-text'' ELSE ''reserved'' END' END + 
', name, ' + 
CASE WHEN @Ver = 'SQL 2000' THEN 'filename' ELSE 'physical_name' END + 
', size*8.0/1024.0 FROM ' + 
CASE WHEN @Ver = 'SQL 2000' THEN 'sysfiles' ELSE 'sys.database_files' END + 
' WHERE '
+ CASE WHEN @Ver = 'SQL 2000' THEN ' HAS_DBACCESS(DB_NAME()) = 1' ELSE 'state_desc = ''ONLINE''' END + '';

SELECT @String = 'INSERT INTO dbo.##Tbl_ValidDbs SELECT name FROM ' + 
                 CASE WHEN @Ver = 'SQL 2000' THEN 'master.dbo.sysdatabases' 
                      WHEN @Ver IN ('SQL 2005', 'SQL 2008') THEN 'master.sys.databases' 
                 END + ' WHERE HAS_DBACCESS(name) = 1 ORDER BY name ASC';
EXEC (@String);

INSERT INTO dbo.##Tbl_Logs EXEC ('DBCC SQLPERF (LOGSPACE) WITH NO_INFOMSGS');

--  For data part
IF @TargetDatabase IS NOT NULL
  BEGIN
    SELECT @DatabaseName = @TargetDatabase;
    IF @UpdateUsage <> 0 AND DATABASEPROPERTYEX (@DatabaseName,'Status') = 'ONLINE' 
          AND DATABASEPROPERTYEX (@DatabaseName, 'Updateability') <> 'READ_ONLY'
      BEGIN
        SELECT @String = 'USE [' + @DatabaseName + '] DBCC UPDATEUSAGE (0)';
        PRINT '*** ' + @String + ' *** ';
        EXEC (@String);
        PRINT '';
      END
      
    SELECT @String = 'INSERT INTO dbo.##Tbl_CombinedInfo (DatabaseName, type, LogicalName, PhysicalName, T) ' + @BaseString; 

    INSERT INTO dbo.##Tbl_DbFileStats (FileId, FileGroup, TotalExtents, UsedExtents, Name, FileName)
          EXEC ('USE [' + @DatabaseName + '] DBCC SHOWFILESTATS WITH NO_INFOMSGS');
    EXEC ('USE [' + @DatabaseName + '] ' + @String);
        
    UPDATE dbo.##Tbl_DbFileStats SET DatabaseName = @DatabaseName; 
  END
ELSE
  BEGIN
    WHILE 1 = 1
      BEGIN
        SELECT TOP 1 @DatabaseName = Dbname FROM dbo.##Tbl_ValidDbs WHERE Dbname > @DatabaseName ORDER BY Dbname ASC;
        IF @@ROWCOUNT = 0
          BREAK;
        IF @UpdateUsage <> 0 AND DATABASEPROPERTYEX (@DatabaseName, 'Status') = 'ONLINE' 
              AND DATABASEPROPERTYEX (@DatabaseName, 'Updateability') <> 'READ_ONLY'
          BEGIN
            SELECT @String = 'DBCC UPDATEUSAGE (''' + @DatabaseName + ''') ';
            PRINT '*** ' + @String + '*** ';
            EXEC (@String);
            PRINT '';
          END
    
        SELECT @Ident_last = ISNULL(MAX(Id), 0) FROM dbo.##Tbl_DbFileStats;

        SELECT @String = 'INSERT INTO dbo.##Tbl_CombinedInfo (DatabaseName, type, LogicalName, PhysicalName, T) ' + @BaseString; 

        EXEC ('USE [' + @DatabaseName + '] ' + @String);
      
        INSERT INTO dbo.##Tbl_DbFileStats (FileId, FileGroup, TotalExtents, UsedExtents, Name, FileName)
          EXEC ('USE [' + @DatabaseName + '] DBCC SHOWFILESTATS WITH NO_INFOMSGS');

        UPDATE dbo.##Tbl_DbFileStats SET DatabaseName = @DatabaseName WHERE Id BETWEEN @Ident_last + 1 AND @@IDENTITY;
      END
  END

--  set used size for data files, do not change total obtained from sys.database_files as it has for log files
UPDATE dbo.##Tbl_CombinedInfo 
SET U = s.UsedExtents*8*8/1024.0 
FROM dbo.##Tbl_CombinedInfo t JOIN dbo.##Tbl_DbFileStats s 
ON t.LogicalName = s.Name AND s.DatabaseName = t.DatabaseName;

--  set used size and % values for log files:
UPDATE dbo.##Tbl_CombinedInfo 
SET [U(%)] = LogSpaceUsedPercent, 
U = T * LogSpaceUsedPercent/100.0
FROM dbo.##Tbl_CombinedInfo t JOIN dbo.##Tbl_Logs l 
ON l.DatabaseName = t.DatabaseName 
WHERE t.type = 'Log';

UPDATE dbo.##Tbl_CombinedInfo SET F = T - U, [U(%)] = U*100.0/T;

UPDATE dbo.##Tbl_CombinedInfo SET [F(%)] = F*100.0/T;

IF UPPER(ISNULL(@Level, 'DATABASE')) = 'FILE'
  BEGIN
    IF @Unit = 'KB'
      UPDATE dbo.##Tbl_CombinedInfo
      SET T = T * 1024, U = U * 1024, F = F * 1024;
      
    IF @Unit = 'GB'
      UPDATE dbo.##Tbl_CombinedInfo
      SET T = T / 1024, U = U / 1024, F = F / 1024;
      
    SELECT DatabaseName AS 'Database',
      type AS 'Type',
      LogicalName,
      T AS 'Total',
      U AS 'Used',
      [U(%)] AS 'Used (%)',
      F AS 'Free',
      [F(%)] AS 'Free (%)',
      PhysicalName
      FROM dbo.##Tbl_CombinedInfo 
      WHERE DatabaseName LIKE ISNULL(@TargetDatabase, '%') 
      ORDER BY DatabaseName ASC, type ASC;

    SELECT CASE WHEN @Unit = 'GB' THEN 'GB' WHEN @Unit = 'KB' THEN 'KB' ELSE 'MB' END AS 'SUM',
        SUM (T) AS 'TOTAL', SUM (U) AS 'USED', SUM (F) AS 'FREE' FROM dbo.##Tbl_CombinedInfo;
  END

IF UPPER(ISNULL(@Level, 'DATABASE')) = 'DATABASE'
  BEGIN
    DECLARE @Tbl_Final TABLE (
      DatabaseName sysname NULL,
      TOTAL dec (10, 2),
      Used dec (10, 2),
      [Used (%)] dec (5, 2),
      Free dec (10, 2),
      [Free (%)] dec (5, 2),
      Data dec (10, 2),
      Data_Used dec (10, 2),
      [Data_Used (%)] dec (5, 2),
      Data_Free dec (10, 2),
      [Data_Free (%)] dec (5, 2),
      Log dec (10, 2),
      Log_Used dec (10, 2),
      [Log_Used (%)] dec (5, 2),
      Log_Free dec (10, 2),
      [Log_Free (%)] dec (5, 2) );

    INSERT INTO @Tbl_Final
      SELECT x.DatabaseName, 
           x.Data + y.Log AS 'TOTAL', 
           x.Data_Used + y.Log_Used AS 'U',
           (x.Data_Used + y.Log_Used)*100.0 / (x.Data + y.Log)  AS 'U(%)',
           x.Data_Free + y.Log_Free AS 'F',
           (x.Data_Free + y.Log_Free)*100.0 / (x.Data + y.Log)  AS 'F(%)',
           x.Data, 
           x.Data_Used, 
           x.Data_Used*100/x.Data AS 'D_U(%)',
           x.Data_Free, 
           x.Data_Free*100/x.Data AS 'D_F(%)',
           y.Log, 
           y.Log_Used, 
           y.Log_Used*100/y.Log AS 'L_U(%)',
           y.Log_Free, 
           y.Log_Free*100/y.Log AS 'L_F(%)'
      FROM 
      ( SELECT d.DatabaseName, 
               SUM(d.T) AS 'Data', 
               SUM(d.U) AS 'Data_Used', 
               SUM(d.F) AS 'Data_Free' 
          FROM dbo.##Tbl_CombinedInfo d WHERE d.type = 'Data' GROUP BY d.DatabaseName ) AS x
      JOIN 
      ( SELECT l.DatabaseName, 
               SUM(l.T) AS 'Log', 
               SUM(l.U) AS 'Log_Used', 
               SUM(l.F) AS 'Log_Free' 
          FROM dbo.##Tbl_CombinedInfo l WHERE l.type = 'Log' GROUP BY l.DatabaseName ) AS y
      ON x.DatabaseName = y.DatabaseName;
    
    IF @Unit = 'KB'
      UPDATE @Tbl_Final SET TOTAL = TOTAL * 1024,
      Used = Used * 1024,
      Free = Free * 1024,
      Data = Data * 1024,
      Data_Used = Data_Used * 1024,
      Data_Free = Data_Free * 1024,
      Log = Log * 1024,
      Log_Used = Log_Used * 1024,
      Log_Free = Log_Free * 1024;
      
    IF @Unit = 'GB'
      UPDATE @Tbl_Final SET TOTAL = TOTAL / 1024,
      Used = Used / 1024,
      Free = Free / 1024,
      Data = Data / 1024,
      Data_Used = Data_Used / 1024,
      Data_Free = Data_Free / 1024,
      Log = Log / 1024,
      Log_Used = Log_Used / 1024,
      Log_Free = Log_Free / 1024;
      
      DECLARE @GrantTotal dec(11, 2);
      SELECT @GrantTotal = SUM(TOTAL) FROM @Tbl_Final;

    IF object_id('tempdb.dbo.DBA_DBSpace', 'U') IS NOT NULL
      DROP TABLE tempdb.dbo.DBA_DBSpace

    CREATE TABLE tempdb.dbo.DBA_DBSpace (
	  [Id] [int] IDENTITY(1,1) NOT NULL,
	  [DatabaseName] [sysname] NULL,
	  [TOTAL] [decimal](10, 2) NULL,
	  [Used] [decimal](10, 2) NULL,
	  [Used (%)] [decimal](5, 2) NULL,
	  [Free] [decimal](10, 2) NULL,
	  [Free (%)] [decimal](5, 2) NULL,
	  [Data] [decimal](10, 2) NULL,
	  [Data_Used] [decimal](10, 2) NULL,
	  [Data_Used (%)] [decimal](5, 2) NULL,
	  [Data_Free] [decimal](10, 2) NULL,
	  [Data_Free (%)] [decimal](5, 2) NULL,
	  [Log] [decimal](10, 2) NULL,
	  [Log_Used] [decimal](10, 2) NULL,
	  [Log_Used (%)] [decimal](5, 2) NULL,
	  [Log_Free] [decimal](10, 2) NULL,
	  [Log_Free (%)] [decimal](5, 2) NULL,
	  [EventTime] [datetime] NULL DEFAULT (CURRENT_TIMESTAMP),
    PRIMARY KEY CLUSTERED ([Id] ASC) )

    INSERT INTO tempdb.dbo.DBA_DBSpace (
      DatabaseName,
      TOTAL,
      Used,
      [Used (%)],
      Free,
      [Free (%)],
      Data,
      Data_Used,
      [Data_Used (%)],
      Data_Free,
      [Data_Free (%)],
      Log ,
      Log_Used,
      [Log_Used (%)],
      Log_Free,
      [Log_Free (%)],
      EventTime )
  
    SELECT *, current_timestamp FROM @Tbl_Final ORDER BY DatabaseName ASC;
  END
  
RETURN (0)
GO

USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_SQLDefrag]    Script Date: 06/11/2009 16:17:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_SQLDefrag]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_SQLDefrag]
GO

create procedure [dbo].[sp_SQLDefrag]
as

set nocount on

DECLARE @command varchar(8000), @duration datetime, @id int, @frag int,
		@indexname sysname, @schemaname sysname, @objectname sysname

	-- order page count ascending so the smallest table is first to be rebuilt
	-- saving the largest table for last so all available space is free from smaller tables
	SELECT	row_number() over (order by Page_Count asc) as Row, object_name(stat.object_id) as TableName,
			i.name as IndexName, avg_fragmentation_in_percent as Frag, page_count as PageCnt, 'dbo' as SchemaName
	into #t
	FROM sys.dm_db_index_physical_stats (db_id(),  NULL, NULL, NULL, 'DETAILED') stat, sys.indexes i
	where avg_fragmentation_in_percent > 10 
	and stat.object_id = i.object_id 
	and stat.index_id = i.index_id

	-- remove duplicate tablename, indexname combo's and retain the smallest pagecount to largest pagecount
	select t1.* 
	into #tt
	from #t t1, (select distinct TableName, IndexName, row from #t) as t2
	where t1.TableName = t2.TableName
	and t1.IndexName = t2.IndexName
	and t1.row > t2.row
	order by t1.row

select @id = min(row) from #tt

while @id is not null
begin

	select
	@frag = Frag,
	@indexName = IndexName,
	@schemaname = SchemaName,
	@objectname = TableName
	from #tt
	where row = @id

	IF @frag < 30.0
		BEGIN
		SELECT @command = 'ALTER INDEX ' + @indexname + ' ON ' + @schemaname + '.' + @objectname + ' REORGANIZE'; -- WITH (SORT_IN_TEMPDB = ON, ONLINE = ON, MAXDOP = 1)';
		print @command
	    EXEC (@command);
	END

	IF @frag >= 30.0
		BEGIN
		SELECT @command = 'ALTER INDEX ' + @indexname +' ON ' + @schemaname + '.' + @objectname + ' REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON, MAXDOP = 1)';
		print @command
		EXEC (@command);
	END

	select @id = min(row) from #tt where row > @id

end

drop table #t
drop table #tt

GO

USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_SQLFragmentation]    Script Date: 06/11/2009 16:18:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_SQLFragmentation]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_SQLFragmentation]
GO

CREATE PROCEDURE [dbo].[sp_SQLFragmentation] 
AS

SET NOCOUNT ON;

IF OBJECT_ID('tempdb.dbo.DBA_Fragmentation', 'U') IS NOT NULL
	DROP TABLE tempdb.dbo.DBA_Fragmentation;

CREATE TABLE tempdb.dbo.DBA_Fragmentation
	([DBName] [nvarchar](128) NULL,	[TableName] [nvarchar](128) NULL, [IndexName] [sysname] NULL,
	[IndexLevel] [tinyint] NULL, [IndexTypeDesc] [nvarchar](60) NULL, 
	[AllocUnitTypeDesc] [nvarchar](60) NULL, [AvgFragmentationInPercent] [float] NULL,
	[FragmentCount] [bigint] NULL, [AvgFragmentSizeInPages] [float] NULL, [PageFullness] [float] NULL,
	[PageCount] [bigint] NULL, [EventTime] [datetime] NULL DEFAULT (CURRENT_TIMESTAMP))

declare @DBName sysname, @TBLName sysname, @sql nvarchar(4000)
set @DBName = ''

SELECT @DBName = min(name) FROM sys.databases 
WHERE name NOT IN ('master', 'model', 'tempdb', 'msdb', 'distribution', 'pubs', 'northwind')
AND DATABASEPROPERTY(name, 'IsOffline') = 0 
AND DATABASEPROPERTY(name, 'IsSuspect') = 0 

while @DBName is not null
begin

	set @sql = 'USE [' + @DBName + ']
			insert into tempdb.dbo.DBA_Fragmentation
			SELECT db_name(database_id) as DBName, object_name(stat.object_id) as TableName,
			i.name as IndexName, index_level, index_type_desc, alloc_unit_type_desc,
			avg_fragmentation_in_percent, fragment_count, avg_fragment_size_in_pages, 
			avg_page_space_used_in_percent, page_count, current_timestamp
			FROM sys.dm_db_index_physical_stats (db_id(),  NULL, NULL, NULL, ''DETAILED'') stat, sys.indexes i
			where stat.object_id = i.object_id and
			stat.index_id = i.index_id'

	exec sp_executesql @sql

	SELECT @DBName = min(name) FROM sys.databases 
	WHERE name NOT IN ('master', 'model', 'tempdb', 'msdb', 'distribution', 'pubs', 'northwind')
	AND DATABASEPROPERTY(name, 'IsOffline') = 0 
	AND DATABASEPROPERTY(name, 'IsSuspect') = 0 
	AND name > @DBName
end

  
RETURN (0)

GO


USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_SQLTableSize]    Script Date: 06/11/2009 16:18:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_SQLTableSize]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_SQLTableSize]
GO

CREATE PROCEDURE [dbo].[sp_SQLTableSize] 
AS

SET NOCOUNT ON;

IF OBJECT_ID('tempdb.dbo.##temp_table_size', 'U') IS NOT NULL
  DROP TABLE dbo.##temp_table_size;
  
IF OBJECT_ID('tempdb.dbo.DBA_TableSize', 'U') IS NOT NULL
  DROP TABLE tempdb.dbo.DBA_TableSize;
  
CREATE TABLE ##temp_table_size (DatabaseName NVARCHAR (128), TableName NVARCHAR (128), RowsCnt VARCHAR (11), ReservedSpace VARCHAR(18), 
					DataSpace VARCHAR(18), CombinedIndexSpace VARCHAR(18), UnusedSpace VARCHAR(18))
CREATE TABLE tempdb.dbo.DBA_TableSize (DatabaseName NVARCHAR (128), TableName NVARCHAR (128), RowsCnt int, ReservedSpaceKB int, 
					DataSpaceKB int, CombinedIndexSpaceKB int, UnusedSpaceKB int, [EventTime] [datetime] NULL DEFAULT (CURRENT_TIMESTAMP))

declare @DBName sysname, @TBLName sysname, @sql nvarchar(4000)
set @DBName = ''

SELECT @DBName = min(name) FROM sys.databases 
WHERE name NOT IN ('master', 'model', 'tempdb', 'msdb', 'distribution', 'pubs', 'northwind')
AND DATABASEPROPERTY(name, 'IsOffline') = 0 
AND DATABASEPROPERTY(name, 'IsSuspect') = 0 

while @DBName is not null
begin

	set @sql = 'USE [' + @DBName + ']
	declare @TBLName sysname
	select @TBLName = min(''[''+s.name+''].[''+t.name+'']'') from sys.tables t, sys.schemas s 
	where t.schema_id = s.schema_id

	while @TBLName is not null
	begin
		INSERT INTO ##temp_table_size (TableName, RowsCnt, ReservedSpace, DataSpace, CombinedIndexSpace, UnusedSpace) 
				EXEC sp_spaceused @TBLName	
		select @TBLName = min(''[''+s.name+''].[''+t.name+'']'') from sys.tables t, sys.schemas s 
		where t.schema_id = s.schema_id and ''[''+s.name+''].[''+t.name+'']'' > @tblname
	end'

	exec sp_executesql @sql

	insert into tempdb.dbo.DBA_TableSize
	SELECT @DBName, TableName, 
			cast(RowsCnt as int), 
			cast(substring(ReservedSpace, 1, len(ReservedSpace)-3) as int),
			cast(substring(DataSpace, 1, len(DataSpace)-3) as int), 
			cast(substring(CombinedIndexSpace, 1, len(CombinedIndexSpace)-3) as int),
			cast(substring(UnusedSpace, 1, len(UnusedSpace)-3) as int),
			CURRENT_TIMESTAMP
	FROM ##temp_table_size
	delete from ##temp_table_size

	SELECT @DBName = min(name) FROM sys.databases 
	WHERE name NOT IN ('master', 'model', 'tempdb', 'msdb', 'distribution', 'pubs', 'northwind')
	AND DATABASEPROPERTY(name, 'IsOffline') = 0 
	AND DATABASEPROPERTY(name, 'IsSuspect') = 0 
	AND name > @DBName
end

IF OBJECT_ID('tempdb.dbo.##temp_table_size', 'U') IS NOT NULL
  DROP TABLE dbo.##temp_table_size;
  
RETURN (0)


GO

USE [msdb]
GO
IF  NOT EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'DBA')
	EXEC msdb.dbo.sp_add_operator @name=N'DBA', 
			@enabled=1, 
			@weekday_pager_start_time=90000, 
			@weekday_pager_end_time=180000, 
			@saturday_pager_start_time=90000, 
			@saturday_pager_end_time=180000, 
			@sunday_pager_start_time=90000, 
			@sunday_pager_end_time=180000, 
			@pager_days=0, 
			@email_address=N'dba@asa.org', 
			@category_name=N'[Uncategorized]'
GO

USE [msdb]
GO
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Client - DBA Monitoring')
EXEC msdb.dbo.sp_delete_job @job_name=N'Client - DBA Monitoring', @delete_unused_schedule=1
GO

/****** Object:  Job [Client - DBA Monitoring]    Script Date: 06/11/2009 16:19:07 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 06/11/2009 16:19:07 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Client - DBA Monitoring', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
-- CHANGE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		@owner_login_name=N'ASASA', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp_SQLDBSpace]    Script Date: 06/11/2009 16:19:08 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run sp_SQLDBSpace', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.sp_SQLDBSpace', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Disk Space]    Script Date: 06/11/2009 16:19:08 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Disk Space', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--  This script monitors disk space (total, free, and free%)
--  Added on 6/30/2008 by Richard D.

SET NOCOUNT ON

IF OBJECT_ID (''tempdb.dbo.Drive'', ''U'') IS NOT NULL
  DROP TABLE tempdb.dbo.Drive

CREATE TABLE tempdb.dbo.Drive (
  Drive char(1) PRIMARY KEY, 
  [FreeSpace (GB)] dec(8,2) NULL, 
  [TotalSize (GB)] dec(8,2) NULL, 
  [Free (%)] AS CONVERT(dec(4,1), ([FreeSpace (GB)]/[TotalSize (GB)] * 100)),
  EventTime datetime NULL DEFAULT CURRENT_TIMESTAMP
)
  
INSERT tempdb.dbo.Drive (Drive, [FreeSpace (GB)]) EXEC master.dbo.xp_fixedDrives

DECLARE @hr int, @fso int, @Drive char(1), @oDrive int, @TotalSize varchar(20)

EXEC @hr=sp_OACreate ''Scripting.FileSystemObject'',@fso OUT
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso

DECLARE dcur CURSOR LOCAL FAST_FORWARD FOR 
  SELECT Drive FROM tempdb.dbo.Drive ORDER BY Drive ASC
OPEN dcur
FETCH NEXT FROM dcur INTO @Drive

WHILE @@FETCH_STATUS=0
  BEGIN
    EXEC @hr = sp_OAMethod @fso, ''GetDrive'', @oDrive OUT, @Drive
    IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso
    
    EXEC @hr = sp_OAGetProperty @oDrive, ''TotalSize'', @TotalSize OUT
    IF @hr <> 0 EXEC sp_OAGetErrorInfo @oDrive
                    
    UPDATE tempdb.dbo.Drive
    SET [TotalSize (GB)] = @TotalSize / (1024.0 * 1024.0 * 1024.0),
        [FreeSpace (GB)] = [FreeSpace (GB)] / 1024.0
    WHERE Drive = @Drive
    
    FETCH NEXT FROM dcur INTO @Drive
  END

CLOSE dcur
DEALLOCATE dcur

EXEC @hr=sp_OADestroy @fso
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso

--  select * from tempdb.dbo.Drive order by Drive asc', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp_SQLTableSize]    Script Date: 06/11/2009 16:19:08 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run sp_SQLTableSize', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbo.sp_SQLTableSize', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp_SQLFragmentation]    Script Date: 06/11/2009 16:19:08 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run sp_SQLFragmentation', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbo.sp_SQLFragmentation', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily @ 0600', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080630, 
		@active_end_date=99991231, 
		@active_start_time=60000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

USE [msdb]
GO
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Cycle Error Log')
EXEC msdb.dbo.sp_delete_job @job_name=N'Cycle Error Log', @delete_unused_schedule=1
GO

/****** Object:  Job [Cycle Error Log]    Script Date: 06/11/2009 16:19:54 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 06/11/2009 16:19:54 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Cycle Error Log', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Cycles the SQL Server Error Log', 
		@category_name=N'Database Maintenance', 
-- CHANGE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		@owner_login_name=N'ASASA', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Cycle Error Log - Step 1]    Script Date: 06/11/2009 16:19:55 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Cycle Error Log - Step 1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec sp_cycle_errorlog;
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every Other Wednesday @ 12AM', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=8, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=2, 
		@active_start_date=20080721, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

USE [msdb]
GO
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Integrity Check')
EXEC msdb.dbo.sp_delete_job @job_name=N'Integrity Check', @delete_unused_schedule=1
GO

/****** Object:  Job [Integrity Check]    Script Date: 06/11/2009 16:38:33 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 06/11/2009 16:38:34 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Integrity Check', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0,	 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
-- CHANGE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		@owner_login_name=N'ASASA', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DBCC CheckDB]    Script Date: 06/11/2009 16:38:34 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBCC CheckDB', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Exec SP_MSForEachDB ''Use [?] DBCC CheckDB (?)''
', 
		@database_name=N'master', 
		@output_file_name=N'M:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\LOG\CheckDB.log', 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily at 0630', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080819, 
		@active_end_date=99991231, 
		@active_start_time=63000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

USE [msdb]
GO
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Backup FULL')
EXEC msdb.dbo.sp_delete_job @job_name=N'Backup FULL', @delete_unused_schedule=1
GO

/****** Object:  Job [Backup FULL]    Script Date: 06/11/2009 16:45:34 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 06/11/2009 16:45:34 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Backup FULL', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
-- CHANGE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		@owner_login_name=N'ASASA', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Full Backups]    Script Date: 06/11/2009 16:45:34 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Full Backups', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @id int, @database nvarchar(100), @backupPath nvarchar(256)
create table #t (name varchar(512), id int)

-- Exclude temp databases
insert into #t select name, database_id from sys.databases where name not like (''%tempdb%'')

set @backupPath = ''Z:\'' + @@servername + ''\''

select @id = min(id) from #t

while @id is not null
begin
	select @database = name from #t where id = @id

	Exec master.dbo.sp_SQLDBBackup 
		@database = @database, 
		@backupType = ''FULL'', 
		@backupPath = @backupPath, 
		@backupRetentionInHours = 25 -- 1 day 

	select @id = min(id) from #t where id > @id
end
drop table #t
', 
		@database_name=N'master', 
		@output_file_name=N'M:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\LOG\Backup_Full.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily at 0530', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080819, 
		@active_end_date=99991231, 
		@active_start_time=53000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

USE [msdb]
GO
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Backup LOG')
EXEC msdb.dbo.sp_delete_job @job_name=N'Backup LOG', @delete_unused_schedule=1
GO

/****** Object:  Job [Backup LOG]    Script Date: 06/11/2009 16:58:31 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 06/11/2009 16:58:31 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Backup LOG', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
-- CHANGE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		@owner_login_name=N'ASASA', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Log Backups]    Script Date: 06/11/2009 16:58:32 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log Backups', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @id int, @database nvarchar(100), @backupPath nvarchar(256)
create table #t (name varchar(512), id int)

-- Exclude temp databases and include recovery model = full
insert into #t 
select d.name, database_id from sys.databases d
where d.name not like (''%tempdb%'') and d.recovery_model = 1
and d.name in (select distinct b.database_name from msdb.dbo.backupset b where b.type = ''D'')

set @backupPath = ''Z:\'' + @@servername + ''\''

select @id = min(id) from #t

while @id is not null
begin
	select @database = name from #t where id = @id

	Exec master.dbo.sp_SQLDBBackup 
		@database = @database, 
		@backupType = ''TRN'', 
		@backupPath = @backupPath, 
		@backupRetentionInHours = 3 -- Don''t keep many logs on disk. We''re only managing log growth

	select @id = min(id) from #t where id > @id
end
drop table #t', 
		@database_name=N'master', 
		@output_file_name=N'M:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\LOG\Backup_Log.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'1 Hour Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20081106, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

USE [msdb]
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Purge Backup/Restore History', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
-- CHANGE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		@owner_login_name=N'ASASA', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge Backup/Restore History', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @deleteBeforeThisDate datetime
set @deleteBeforeThisDate = getdate() - 30
select @deleteBeforeThisDate

exec SP_DELETE_BACKUPHISTORY @oldest_Date = @deleteBeforeThisDate
', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

if not exists (select schedule_id from msdb.dbo.sysschedules where name = 'Daily at 0630')
begin
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily at 0630', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=0, 
			@active_start_date=20080819, 
			@active_end_date=99991231, 
			@active_start_time=63000, 
			@active_end_time=235959
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
end
else
begin
	EXEC @ReturnCode = msdb.dbo.sp_attach_schedule
	   @job_id = @jobid,
	   @schedule_name = N'Daily at 0630' ;
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
end

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO



-- 010 Startup Sprocs.sql

USE [master]
GO

IF OBJECT_ID('dbo.sp_ScriptDBSecurity', 'P') IS NOT NULL
  DROP PROCEDURE dbo.sp_ScriptDBSecurity;
GO

create procedure [dbo].[sp_ScriptDBSecurity] (@DBName sysname)

as
/*
	exec sp_ScriptDBSecurity 'WellnessODS'
*/

set nocount on

declare @string varchar(max)--, @dbname sysname
select @string = ''--, @dbname = db_name()


if OBJECT_ID ('tempdb.dbo.UserAccountToKeep', 'U') is not null
  drop table tempdb.dbo.UserAccountToKeep;

create table tempdb.dbo.UserAccountToKeep
( Id int identity primary key clustered,
  Name sysname NULL,
  Type varchar(10) NULL,
  DefaultSchema sysname NULL,
  OwnerName sysname null, 
  Script varchar(1000) NULL,
  ScriptTime datetime not null default current_timestamp);
  
if OBJECT_ID ('tempdb.dbo.RoleMemberMapping', 'U') is not null
  drop table tempdb.dbo.RoleMemberMapping;
  
create table tempdb.dbo.RoleMemberMapping
( MappingId int identity,
  RoleType sysname NULL,
  RoleName sysname NULL,
  RoleMember sysname NULL,
  Script varchar(1000) null default '');

if OBJECT_ID ('tempdb.dbo.UserPermission', 'U') is not null
  drop table tempdb.dbo.UserPermission;
  
create table tempdb.dbo.UserPermission
( UserPermissionId int identity,
  Grantor sysname NULL,
  Status varchar(25) NULL,
  Permission varchar(255) NULL,
  [ON] varchar(3) NULL,
  [Schema] sysname NULL,
  [Object] varchar(255) NULL,
  [TO] varchar(3) NULL,
  Grantee sysname NULL,
  Scope varchar(20) NULL,
  Script varchar(1000));

/************  Save user account information from @DBName ***********/

set @string = '
	use ['+ @DBName + '];
	insert into tempdb.dbo.UserAccountToKeep (Name, Type, DefaultSchema, OwnerName)
	select d.name, d.type, d.default_schema_name, p.name from sys.database_principals d
	left outer join sys.database_principals p on p.principal_id = d.owning_principal_id
	where d.principal_id between 5 and 16383
	and d.type in (''G'', ''U'', ''S'')
	'
--print @string
exec (@string)

update tempdb.dbo.UserAccountToKeep 
set Script = 'USE [' + @dbname + ']; CREATE ' + 
case when [Type] = 'R' then 'ROLE ' when [Type] IN ('G', 'U', 'S') then 'USER ' end 
+ '[' + Name + ']'
+ case when [Type] = 'G' then ' FROM LOGIN [' + name + '];' 
       when [Type] = 'R' then ' AUTHORIZATION [' + OwnerName + '];' 
       when [Type] = 'U' then ' FROM LOGIN [' + name + '] WITH DEFAULT_SCHEMA = [' + DefaultSchema + '];'
       when [Type] = 'S' then ' FOR LOGIN [' + name + '] WITH DEFAULT_SCHEMA = [' + DefaultSchema + '];' 
end 

--select Script from tempdb.dbo.UserAccountToKeep order by name asc;


/************  Save roles and role membership from @DBName  ***********/

--  User created database roles
set @string = '
	use ['+ @DBName + '];
	insert into tempdb.dbo.RoleMemberMapping
	select ''DB Role'', name, null,  
	''IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''''''+ name + '''''') CREATE ROLE ['' + name + ''];''
	from sys.database_principals where type = ''R'' and is_fixed_role <> 1
	and principal_id > 4
	'
--print @string
exec (@string)

--  Role membership
set @string = '
	use ['+ @DBName + '];
	insert into tempdb.dbo.RoleMemberMapping
	select ''DB Role'' as ''RoleType'', c.name as ''RoleName'', c2.name as ''RoleMember'', null 
	from sys.database_role_members r  
	join sys.database_principals c
	on r.role_principal_id = c.principal_id
	join sys.database_principals c2
	on r.member_principal_id = c2.principal_id
	where c2.name not in (''dbo'')
	'
--print @string
exec (@string)

  update tempdb.dbo.RoleMemberMapping set Script = 
    case when RoleType = 'DB Role' then 'EXEC [' + @dbname + '].dbo.sp_addrolemember ''' + RoleName + ''', ''' + RoleMember + ''';'
    else Script end
  where Script is null

update tempdb.dbo.RoleMemberMapping set Script = '--' where Script is null 

--select script from tempdb.dbo.RoleMemberMapping order by MappingId asc, RoleName asc, RoleMember asc


/************  Save permissions from @DBName  ***********/

set @string = '
	use ['+ @DBName + '];
	insert into tempdb.dbo.UserPermission
	select c2.name as ''Grantor'', m.state_desc as ''Status'', m.permission_name as ''Explicit permission'',
	  '''', '''', '''', ''TO'', c.name as ''Grantee'', ''-- '' + m.class_desc as ''Scope'', null 
	from  sys.server_permissions m  
	join sys.server_principals c
	on m.Grantee_principal_id = c.principal_id
	join sys.server_principals c2
	on m.Grantor_principal_id = c2.principal_id
	where c.type not in (''C'', ''K'')  
	UNION
	select USER_NAME(grantor_principal_id) as ''Grantor'', state_desc as ''Status'', permission_name as ''Explicit permissio'', 
	case when class in (1, 3) then ''ON '' else '''' end, 
	case when m.major_id < 0 THEN ''sys'' when class = 3 then schema_name(m.major_id) else schema_name(o.schema_id) end as ''Schema'', --o.schema_id,
	case when m.major_id <> 1 then object_name(m.major_id) else '''' end as ''Object'', ''TO'', 
	user_name(m.grantee_principal_id) as ''Grantee'', ''-- '' + m.class_desc as ''Scope'', null 
	from sys.database_permissions m 
	left outer JOIN SYS.OBJECTS o
	on o.object_id = m.major_id
	'

--print @string
exec (@string)

update tempdb.dbo.UserPermission 
	set Script =
	case 
	when Scope like '%SCHEMA' then 'USE [' + @dbname + ']; ' + [Status] + ' ' + Permission + ' ON SCHEMA::' + [Schema] + ' TO ' + quotename(Grantee, '[') + ';'
	when Scope like '%OBJECT_OR_COLUMN%' then 'USE [' + @dbname + ']; ' + [Status] + ' ' + Permission + ' ON ' + [Schema] + '.' + [Object] + ' TO ' + quotename(Grantee, '[') + ';'
	when Scope like '%SERVER' OR Scope like '%ENDPOINT' then 'USE master; ' + [Status] + ' ' + Permission + ' TO ' + quotename(Grantee, '[')+ ';'
	--NULLIF(quotename(Grantee, '['), '[public]') + ';'
	when (Scope like '%DATABASE' AND Grantee <> 'dbo') OR Scope like '%SERVER' OR Scope like '%ENDPOINT' then 'USE [' + @dbname + ']; ' + [Status] + ' ' + Permission + ' TO ' + quotename(Grantee, '[') + ';' END

update tempdb.dbo.UserPermission 
	set Script = '--' where Script is null 
	or Script like 'USE master;%'
	  --or Script = 'USE master; GRANT CONNECT SQL TO [sa];'
	  --or Script = 'USE master; GRANT CONNECT SQL TO [ASASA];'
	  --or Script = 'USE master; GRANT CONNECT TO [public];'

delete from tempdb.dbo.UserAccountToKeep where script = '--';
delete from tempdb.dbo.RoleMemberMapping where script = '--';
delete from tempdb.dbo.UserPermission where script = '--';

-- Remove previous permissions for @DBName
delete from [DatabaseServices].[dbo].[ReApplySecurity] where DBName = @DBName

-- Insert current permissions for @DBName
insert into [DatabaseServices].[dbo].[ReApplySecurity] 
(DBName, SQLStatement)
select @DBName, Script from tempdb.dbo.UserAccountToKeep order by name asc;

insert into [DatabaseServices].[dbo].[ReApplySecurity] 
(DBName, SQLStatement)
select @DBName, script from tempdb.dbo.RoleMemberMapping order by MappingId asc, RoleName asc, RoleMember asc

insert into [DatabaseServices].[dbo].[ReApplySecurity] 
(DBName, SQLStatement)
select @DBName, script from tempdb.dbo.UserPermission 
where grantee != 'public'
--where permission = 'administer bulk operations' 
ORDER BY UserPermissionId asc

declare @id int, @SQL nvarchar(max)
select @id = min(PKId) from [DatabaseServices].[dbo].[ReApplySecurity]  where DBName = @DBName
while @id is not null
begin
	select @SQL = SQLStatement from [DatabaseServices].[dbo].[ReApplySecurity] where PKId = @id
	print @SQL
	--exec @SQL
	select @id = min(PKId) from [DatabaseServices].[dbo].[ReApplySecurity]  where DBName = @DBName and PKId > @id
end

--select * from [DatabaseServices].[dbo].[ReApplySecurity] 
--where DBName = 'BOPS'
--order by PKId

-- Cleanup
if OBJECT_ID ('tempdb.dbo.UserAccountToKeep', 'U') is not null
  drop table tempdb.dbo.UserAccountToKeep;
if OBJECT_ID ('tempdb.dbo.RoleMemberMapping', 'U') is not null
  drop table tempdb.dbo.RoleMemberMapping;
if OBJECT_ID ('tempdb.dbo.UserPermission', 'U') is not null
  drop table tempdb.dbo.UserPermission;

GO

IF OBJECT_ID('dbo.IndexOptimize', 'P') IS NOT NULL
  DROP PROCEDURE dbo.IndexOptimize;
GO

CREATE PROCEDURE [dbo].[IndexOptimize]

@Databases varchar(max),
@FragmentationHigh_LOB varchar(max) = 'INDEX_REBUILD_OFFLINE',
@FragmentationHigh_NonLOB varchar(max) = 'INDEX_REBUILD_ONLINE',
@FragmentationMedium_LOB varchar(max) = 'INDEX_REORGANIZE',
@FragmentationMedium_NonLOB varchar(max) = 'INDEX_REORGANIZE',
@FragmentationLow_LOB varchar(max) = 'NOTHING',
@FragmentationLow_NonLOB varchar(max) = 'NOTHING',
@FragmentationLevel1 tinyint = 5,
@FragmentationLevel2 tinyint = 30,
@PageCountLevel int = 1

AS

SET NOCOUNT ON

----------------------------------------------------------------------------------------------------
--// Declare variables                                                                          //--
----------------------------------------------------------------------------------------------------

DECLARE @StartMessage varchar(max)
DECLARE @EndMessage varchar(max)
DECLARE @DatabaseMessage varchar(max)
DECLARE @ErrorMessage varchar(max)

DECLARE @CurrentID int
DECLARE @CurrentDatabase varchar(max)

DECLARE @CurrentCommandSelect01 varchar(max)
DECLARE @CurrentCommandSelect02 varchar(max)
DECLARE @CurrentCommandSelect03 varchar(max)

DECLARE @CurrentCommand01 varchar(max)
DECLARE @CurrentCommand02 varchar(max)

DECLARE @CurrentCommandOutput01 int
DECLARE @CurrentCommandOutput02 int

DECLARE @CurrentIxID int
DECLARE @CurrentSchemaID int
DECLARE @CurrentSchemaName varchar(max)
DECLARE @CurrentObjectID int
DECLARE @CurrentObjectName varchar(max)
DECLARE @CurrentIndexID int
DECLARE @CurrentIndexName varchar(max)
DECLARE @CurrentIndexType int
DECLARE @CurrentIndexExists bit
DECLARE @CurrentIsLOB bit
DECLARE @CurrentFragmentationLevel float
DECLARE @CurrentPageCount bigint
DECLARE @CurrentAction varchar(max)
DECLARE @CurrentComment varchar(max)

DECLARE @tmpDatabases TABLE (	ID int IDENTITY PRIMARY KEY,
								DatabaseName varchar(max),
								Completed bit)

DECLARE @tmpIndexes TABLE (		IxID int IDENTITY PRIMARY KEY,
								SchemaID int,
								SchemaName varchar(max),
								ObjectID int,
								ObjectName varchar(max),
								IndexID int,
								IndexName varchar(max),
								IndexType int,
								Completed bit)

DECLARE @tmpIndexExists TABLE ([Count] int)

DECLARE @tmpIsLOB TABLE ([Count] int)

DECLARE @Actions TABLE ([Action] varchar(max))

INSERT INTO @Actions([Action]) VALUES('INDEX_REBUILD_ONLINE')
INSERT INTO @Actions([Action]) VALUES('INDEX_REBUILD_OFFLINE')
INSERT INTO @Actions([Action]) VALUES('INDEX_REORGANIZE')
INSERT INTO @Actions([Action]) VALUES('STATISTICS_UPDATE')
INSERT INTO @Actions([Action]) VALUES('INDEX_REORGANIZE_STATISTICS_UPDATE')
INSERT INTO @Actions([Action]) VALUES('NOTHING')

DECLARE @Error int

SET @Error = 0

----------------------------------------------------------------------------------------------------
--// Log initial information                                                                    //--
----------------------------------------------------------------------------------------------------

SET @StartMessage =	'DateTime: ' + CONVERT(varchar,GETDATE(),120) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Procedure: ' + QUOTENAME(DB_NAME(DB_ID())) + '.' + QUOTENAME(OBJECT_SCHEMA_NAME(@@PROCID)) + '.' + QUOTENAME(OBJECT_NAME(@@PROCID)) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Parameters: @Databases = ' + ISNULL('''' + @Databases + '''','NULL')
SET @StartMessage = @StartMessage + ', @FragmentationHigh_LOB = ' + ISNULL('''' + @FragmentationHigh_LOB + '''','NULL')
SET @StartMessage = @StartMessage + ', @FragmentationHigh_NonLOB = ' + ISNULL('''' + @FragmentationHigh_NonLOB + '''','NULL')
SET @StartMessage = @StartMessage + ', @FragmentationMedium_LOB = ' + ISNULL('''' + @FragmentationMedium_LOB + '''','NULL')
SET @StartMessage = @StartMessage + ', @FragmentationMedium_NonLOB = ' + ISNULL('''' + @FragmentationMedium_NonLOB + '''','NULL')
SET @StartMessage = @StartMessage + ', @FragmentationLow_LOB = ' + ISNULL('''' + @FragmentationLow_LOB + '''','NULL')
SET @StartMessage = @StartMessage + ', @FragmentationLow_NonLOB = ' + ISNULL('''' + @FragmentationLow_NonLOB + '''','NULL')
SET @StartMessage = @StartMessage + ', @FragmentationLevel1 = ' + ISNULL(CAST(@FragmentationLevel1 AS varchar),'NULL')
SET @StartMessage = @StartMessage + ', @FragmentationLevel2 = ' + ISNULL(CAST(@FragmentationLevel2 AS varchar),'NULL')
SET @StartMessage = @StartMessage + ', @PageCountLevel = ' + ISNULL(CAST(@PageCountLevel AS varchar),'NULL')
SET @StartMessage = @StartMessage + CHAR(13) + CHAR(10)

RAISERROR(@StartMessage,10,1) WITH NOWAIT

----------------------------------------------------------------------------------------------------
--// Select databases                                                                           //--
----------------------------------------------------------------------------------------------------

IF @Databases IS NULL OR @Databases = ''
BEGIN
	SET @ErrorMessage = 'The value for parameter @Databases is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

INSERT INTO @tmpDatabases (DatabaseName, Completed)
SELECT	DatabaseName AS DatabaseName,
		0 AS Completed
FROM dbo.DatabaseSelect (@Databases)
ORDER BY DatabaseName ASC

IF @@ERROR <> 0 OR @@ROWCOUNT = 0
BEGIN
	SET @ErrorMessage = 'Error selecting databases.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

----------------------------------------------------------------------------------------------------
--// Check input parameters                                                                     //--
----------------------------------------------------------------------------------------------------

IF @FragmentationHigh_LOB NOT IN(SELECT [Action] FROM @Actions)
BEGIN
	SET @ErrorMessage = 'The value for parameter @FragmentationHigh_LOB is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

IF @FragmentationHigh_NonLOB NOT IN(SELECT [Action] FROM @Actions)
BEGIN
	SET @ErrorMessage = 'The value for parameter @FragmentationHigh_NonLOB is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

IF @FragmentationMedium_LOB NOT IN(SELECT [Action] FROM @Actions)
BEGIN
	SET @ErrorMessage = 'The value for parameter @FragmentationMedium_LOB is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

IF @FragmentationMedium_NonLOB NOT IN(SELECT [Action] FROM @Actions)
BEGIN
	SET @ErrorMessage = 'The value for parameter @FragmentationMedium_NonLOB is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

IF @FragmentationLow_LOB NOT IN(SELECT [Action] FROM @Actions)
BEGIN
	SET @ErrorMessage = 'The value for parameter @FragmentationLow_LOB is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

IF @FragmentationLow_NonLOB NOT IN(SELECT [Action] FROM @Actions)
BEGIN
	SET @ErrorMessage = 'The value for parameter @FragmentationLow_NonLOB is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

IF @FragmentationLevel1 <= 0 OR @FragmentationLevel1 >= 100 OR @FragmentationLevel1 >= @FragmentationLevel2 OR @FragmentationLevel1 IS NULL
BEGIN
	SET @ErrorMessage = 'The value for parameter @FragmentationLevel1 is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

IF @FragmentationLevel2 <= 0 OR @FragmentationLevel2 >= 100 OR @FragmentationLevel2 <= @FragmentationLevel1 OR @FragmentationLevel2 IS NULL 
BEGIN
	SET @ErrorMessage = 'The value for parameter @FragmentationLevel2 is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

IF @PageCountLevel < 0 OR @PageCountLevel IS NULL
BEGIN
	SET @ErrorMessage = 'The value for parameter @PageCountLevel is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

----------------------------------------------------------------------------------------------------
--// Check error variable                                                                       //--
----------------------------------------------------------------------------------------------------

IF @Error <> 0 GOTO Logging

----------------------------------------------------------------------------------------------------
--// Execute commands                                                                           //--
----------------------------------------------------------------------------------------------------

WHILE EXISTS (SELECT * FROM @tmpDatabases WHERE Completed = 0)
BEGIN

	SELECT TOP 1	@CurrentID = ID,
					@CurrentDatabase = DatabaseName
	FROM @tmpDatabases
	WHERE Completed = 0
	ORDER BY ID ASC

	-- Set database message
	SET @DatabaseMessage = 'DateTime: ' + CONVERT(varchar,GETDATE(),120) + CHAR(13) + CHAR(10)
	SET @DatabaseMessage = @DatabaseMessage + 'Database: ' + QUOTENAME(@CurrentDatabase) + CHAR(13) + CHAR(10)
	SET @DatabaseMessage = @DatabaseMessage + 'Status: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabase,'status') AS varchar) + CHAR(13) + CHAR(10)
	RAISERROR(@DatabaseMessage,10,1) WITH NOWAIT

	IF DATABASEPROPERTYEX(@CurrentDatabase,'status') = 'ONLINE'
	BEGIN
		
		-- Select indexes in the current database
		SET @CurrentCommandSelect01 = 'SELECT s.[schema_id], s.[name], o.[object_id],	o.[name], i.index_id, 
		i.[name], i.[type], 0 FROM ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes i INNER JOIN ' + 
		QUOTENAME(@CurrentDatabase) + '.sys.objects o ON i.[object_id] = o.[object_id] INNER JOIN ' + 
		QUOTENAME(@CurrentDatabase) + '.sys.schemas s ON o.[schema_id] = s.[schema_id] 
		WHERE o.type = ''U'' AND o.is_ms_shipped = 0 AND i.[type] IN(1,2) 
		ORDER BY s.[schema_id] ASC, o.[object_id] ASC, i.index_id ASC'

		INSERT INTO @tmpIndexes (SchemaID, SchemaName, ObjectID, ObjectName, IndexID, IndexName, IndexType, Completed)
		EXECUTE(@CurrentCommandSelect01)

		WHILE EXISTS (SELECT * FROM @tmpIndexes WHERE Completed = 0)
		BEGIN

			SELECT TOP 1	@CurrentIxID = IxID,
							@CurrentSchemaID = SchemaID,
							@CurrentSchemaName = SchemaName,
							@CurrentObjectID = ObjectID,
							@CurrentObjectName = ObjectName,
							@CurrentIndexID = IndexID,
							@CurrentIndexName = IndexName,
							@CurrentIndexType = IndexType
			FROM @tmpIndexes
			WHERE Completed = 0
			ORDER BY IxID ASC

			-- Does the index exist?
			SET @CurrentCommandSelect02 = 'SELECT COUNT(*) FROM ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes i INNER JOIN ' + 
			QUOTENAME(@CurrentDatabase) + '.sys.objects o ON i.[object_id] = o.[object_id] INNER JOIN ' + 
			QUOTENAME(@CurrentDatabase) + '.sys.schemas s ON o.[schema_id] = s.[schema_id] 
			WHERE o.type = ''U'' AND i.index_id > 0 
			AND s.[schema_id] = ' + CAST(@CurrentSchemaID AS varchar) + ' AND s.[name] = ''' + @CurrentSchemaName + ''' 
			AND o.[object_id] = ' + CAST(@CurrentObjectID AS varchar) + ' AND o.[name] = ''' + @CurrentObjectName + ''' 
			AND i.index_id = ' + CAST(@CurrentIndexID AS varchar) + ' AND i.[name] = ''' + @CurrentIndexName + ''' 
			AND i.[type] = ' + CAST(@CurrentIndexType AS varchar)

			INSERT INTO @tmpIndexExists ([Count])
			EXECUTE(@CurrentCommandSelect02)

			IF (SELECT [Count] FROM @tmpIndexExists) > 0 BEGIN SET @CurrentIndexExists = 1 END ELSE BEGIN SET @CurrentIndexExists = 0 END

			IF @CurrentIndexExists = 0 GOTO NoAction

			-- Does the index contain a LOB?
			IF @CurrentIndexType = 1 SET @CurrentCommandSelect03 = 'SELECT COUNT(*) FROM ' + QUOTENAME(@CurrentDatabase) + 
			'.sys.columns c INNER JOIN ' + QUOTENAME(@CurrentDatabase) + '.sys.types t ON c.system_type_id = t.user_type_id 
			WHERE c.[object_id] = ' + CAST(@CurrentObjectID AS varchar) + ' AND (t.name IN(''xml'',''image'',''text'',''ntext'') 
			OR (t.name IN(''varchar'',''nvarchar'',''varbinary'',''nvarbinary'') AND c.max_length = -1))'	
				
			IF @CurrentIndexType = 2 SET @CurrentCommandSelect03 = 'SELECT COUNT(*) FROM ' + QUOTENAME(@CurrentDatabase) + 
			'.sys.index_columns ic INNER JOIN ' + QUOTENAME(@CurrentDatabase) + '.sys.columns c ON ic.[object_id] = c.[object_id] 
			AND ic.column_id = c.column_id INNER JOIN ' + QUOTENAME(@CurrentDatabase) + '.sys.types t 
			ON c.system_type_id = t.user_type_id WHERE ic.[object_id] = ' + CAST(@CurrentObjectID AS varchar) + 
			' AND ic.index_id = ' + CAST(@CurrentIndexID AS varchar) + ' AND (t.[name] IN(''xml'',''image'',''text'',''ntext'') 
			OR (t.[name] IN(''varchar'',''nvarchar'',''varbinary'',''nvarbinary'') AND t.max_length = -1))'

			INSERT INTO @tmpIsLOB ([Count])
			EXECUTE(@CurrentCommandSelect03)

			IF (SELECT [Count] FROM @tmpIsLOB) > 0 BEGIN SET @CurrentIsLOB = 1 END ELSE BEGIN SET @CurrentIsLOB = 0 END

			-- Is the index fragmented?
			SELECT	@CurrentFragmentationLevel = avg_fragmentation_in_percent,
					@CurrentPageCount = page_count
			FROM sys.dm_db_index_physical_stats(DB_ID(@CurrentDatabase), @CurrentObjectID, @CurrentIndexID, NULL, 'LIMITED')
			WHERE alloc_unit_type_desc = 'IN_ROW_DATA'
			AND index_level = 0

			-- Decide action
			SELECT @CurrentAction = CASE
			WHEN @CurrentIsLOB = 1 AND @CurrentFragmentationLevel >= @FragmentationLevel2 AND @CurrentPageCount >= @PageCountLevel THEN @FragmentationHigh_LOB
			WHEN @CurrentIsLOB = 0 AND @CurrentFragmentationLevel >= @FragmentationLevel2 AND @CurrentPageCount >= @PageCountLevel THEN @FragmentationHigh_NonLOB
			WHEN @CurrentIsLOB = 1 AND @CurrentFragmentationLevel >= @FragmentationLevel1 AND @CurrentFragmentationLevel < @FragmentationLevel2 AND @CurrentPageCount >= @PageCountLevel THEN @FragmentationMedium_LOB
			WHEN @CurrentIsLOB = 0 AND @CurrentFragmentationLevel >= @FragmentationLevel1 AND @CurrentFragmentationLevel < @FragmentationLevel2 AND @CurrentPageCount >= @PageCountLevel THEN @FragmentationMedium_NonLOB
			WHEN @CurrentIsLOB = 1 AND (@CurrentFragmentationLevel < @FragmentationLevel1 OR @CurrentPageCount < @PageCountLevel) THEN @FragmentationLow_LOB
			WHEN @CurrentIsLOB = 0 AND (@CurrentFragmentationLevel < @FragmentationLevel1 OR @CurrentPageCount < @PageCountLevel) THEN @FragmentationLow_NonLOB
			END

			-- Create comment
			SET @CurrentComment = 'IndexType: ' + CAST(@CurrentIndexType AS varchar) + ', '
			SET @CurrentComment = @CurrentComment + 'LOB: ' + CAST(@CurrentIsLOB AS varchar) + ', '
			SET @CurrentComment = @CurrentComment + 'PageCount: ' + CAST(@CurrentPageCount AS varchar) + ', '
			SET @CurrentComment = @CurrentComment + 'Fragmentation: ' + CAST(@CurrentFragmentationLevel AS varchar)

			IF @CurrentAction IN('INDEX_REBUILD_ONLINE','INDEX_REBUILD_OFFLINE','INDEX_REORGANIZE','INDEX_REORGANIZE_STATISTICS_UPDATE')
			BEGIN
				SELECT @CurrentCommand01 = CASE
				WHEN @CurrentAction = 'INDEX_REBUILD_ONLINE' THEN 'ALTER INDEX ' + QUOTENAME(@CurrentIndexName) + ' ON ' + QUOTENAME(@CurrentDatabase) + '.' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ' REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON)'
				WHEN @CurrentAction = 'INDEX_REBUILD_OFFLINE' THEN 'ALTER INDEX ' + QUOTENAME(@CurrentIndexName) + ' ON ' + QUOTENAME(@CurrentDatabase) + '.' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ' REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = OFF)'
				WHEN @CurrentAction IN('INDEX_REORGANIZE','INDEX_REORGANIZE_STATISTICS_UPDATE') THEN 'ALTER INDEX ' + QUOTENAME(@CurrentIndexName) + ' ON ' + QUOTENAME(@CurrentDatabase) + '.' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ' REORGANIZE'
				END
				EXECUTE @CurrentCommandOutput01 = [dbo].[CommandExecute] @CurrentCommand01, @CurrentComment, 2
				SET @Error = @@ERROR
				IF @ERROR <> 0 SET @CurrentCommandOutput01 = @ERROR
			END

			IF @CurrentAction IN('INDEX_REORGANIZE_STATISTICS_UPDATE','STATISTICS_UPDATE')
			BEGIN
				SET @CurrentCommand02 = 'UPDATE STATISTICS ' + QUOTENAME(@CurrentDatabase) + '.' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ' ' + QUOTENAME(@CurrentIndexName)
				EXECUTE @CurrentCommandOutput02 = [dbo].[CommandExecute] @CurrentCommand02, @CurrentComment, 2
				SET @Error = @@ERROR
				IF @ERROR <> 0 SET @CurrentCommandOutput02 = @ERROR
			END

			NoAction:
			
			-- Update that the index is completed
			UPDATE @tmpIndexes
			SET Completed = 1
			WHERE IxID = @CurrentIxID

			-- Clear variables
			SET @CurrentCommandSelect02 = NULL
			SET @CurrentCommandSelect03 = NULL

			SET @CurrentCommand01 = NULL
			SET @CurrentCommand02 = NULL

			SET @CurrentCommandOutput01 = NULL
			SET @CurrentCommandOutput02 = NULL

			SET @CurrentIxID = NULL
			SET @CurrentSchemaID = NULL
			SET @CurrentSchemaName = NULL
			SET @CurrentObjectID = NULL
			SET @CurrentObjectName = NULL
			SET @CurrentIndexID = NULL
			SET @CurrentIndexName = NULL
			SET @CurrentIndexType = NULL
			SET @CurrentIndexExists = NULL
			SET @CurrentIsLOB = NULL
			SET @CurrentFragmentationLevel = NULL
			SET @CurrentPageCount = NULL
			SET @CurrentAction = NULL
			SET @CurrentComment = NULL

			DELETE FROM @tmpIndexExists
			DELETE FROM @tmpIsLOB

		END

	END

	-- Update that the database is completed
	UPDATE @tmpDatabases
	SET Completed = 1
	WHERE ID = @CurrentID

	-- Clear variables
	SET @CurrentID = NULL
	SET @CurrentDatabase = NULL
	
	SET @CurrentCommandSelect01 = NULL
	
	DELETE FROM @tmpIndexes

END

----------------------------------------------------------------------------------------------------
--// Log completing information                                                                 //--
----------------------------------------------------------------------------------------------------

Logging:

SET @EndMessage = 'DateTime: ' + CONVERT(varchar,GETDATE(),120)

RAISERROR(@EndMessage,10,1) WITH NOWAIT

----------------------------------------------------------------------------------------------------

GO

IF OBJECT_ID('dbo.GetPerfInfo', 'P') IS NOT NULL
  DROP PROCEDURE dbo.GetPerfInfo;
GO

CREATE PROCEDURE [dbo].[GetPerfInfo] @appname sysname='GetPerfInfo', @runtime datetime = NULL AS 
  SET NOCOUNT ON
  DECLARE @msg varchar(100)
  DECLARE @querystarttime datetime
  DECLARE @queryduration int
  DECLARE @qrydurationwarnthreshold int
  DECLARE @servermajorversion int
  DECLARE @cpu_time_start bigint, @elapsed_time_start bigint
  DECLARE @sql nvarchar(max)
  DECLARE @cte nvarchar(max)
  DECLARE @rowcount bigint
  SET @runtime = GETDATE()
  
  SELECT @cpu_time_start = cpu_time, @elapsed_time_start = total_elapsed_time FROM sys.dm_exec_requests WHERE session_id = @@SPID

  IF OBJECT_ID ('tempdb.dbo.#tmp_requests') IS NOT NULL DROP TABLE #tmp_requests
  IF OBJECT_ID ('tempdb.dbo.#tmp_requests2') IS NOT NULL DROP TABLE #tmp_requests2
  
  IF @runtime IS NULL 
  BEGIN 
    SET @runtime = GETDATE()
    SET @msg = 'Start time: ' + CONVERT (varchar(30), @runtime, 126)
    RAISERROR (@msg, 0, 1) WITH NOWAIT
  END
  SET @qrydurationwarnthreshold = 500
  
  -- SERVERPROPERTY ('ProductVersion') returns e.g. "9.00.2198.00" --> 9
  SET @servermajorversion = REPLACE (LEFT (CONVERT (varchar, SERVERPROPERTY ('ProductVersion')), 2), '.', '')

  RAISERROR (@msg, 0, 1) WITH NOWAIT
  SET @querystarttime = GETDATE()
  SELECT
    sess.session_id, req.request_id, tasks.exec_context_id AS ecid, tasks.task_address, req.blocking_session_id, LEFT (tasks.task_state, 15) AS task_state, 
    tasks.scheduler_id, LEFT (ISNULL (req.wait_type, ''), 50) AS wait_type, LEFT (ISNULL (req.wait_resource, ''), 40) AS wait_resource, 
    LEFT (req.last_wait_type, 50) AS last_wait_type, 
    /* sysprocesses is the only way to get open_tran count for sessions w/o an active request (SQLBUD #487091) */
    CASE 
      WHEN req.open_transaction_count IS NOT NULL THEN req.open_transaction_count 
      ELSE (SELECT open_tran FROM master.dbo.sysprocesses sysproc WHERE sess.session_id = sysproc.spid) 
    END AS open_trans, 
    LEFT (CASE COALESCE(req.transaction_isolation_level, sess.transaction_isolation_level)
      WHEN 0 THEN '0-Read Committed' 
      WHEN 1 THEN '1-Read Uncommitted (NOLOCK)' 
      WHEN 2 THEN '2-Read Committed' 
      WHEN 3 THEN '3-Repeatable Read' 
      WHEN 4 THEN '4-Serializable' 
      WHEN 5 THEN '5-Snapshot' 
      ELSE CONVERT (varchar(30), req.transaction_isolation_level) + '-UNKNOWN' 
    END, 30) AS transaction_isolation_level, 
    sess.is_user_process, req.cpu_time AS request_cpu_time, 
    /* CASE stmts necessary to workaround SQLBUD #438189 (fixed in SP2) */
    CASE WHEN (@servermajorversion > 9) OR (@servermajorversion = 9 AND SERVERPROPERTY ('ProductLevel') >= 'SP2' COLLATE Latin1_General_BIN) 
      THEN req.logical_reads ELSE req.logical_reads - sess.logical_reads END AS request_logical_reads, 
    CASE WHEN (@servermajorversion > 9) OR (@servermajorversion = 9 AND SERVERPROPERTY ('ProductLevel') >= 'SP2' COLLATE Latin1_General_BIN) 
      THEN req.reads ELSE req.reads - sess.reads END AS request_reads, 
    CASE WHEN (@servermajorversion > 9) OR (@servermajorversion = 9 AND SERVERPROPERTY ('ProductLevel') >= 'SP2' COLLATE Latin1_General_BIN)
      THEN req.writes ELSE req.writes - sess.writes END AS request_writes, 
    sess.memory_usage, sess.cpu_time AS session_cpu_time, sess.reads AS session_reads, sess.writes AS session_writes, sess.logical_reads AS session_logical_reads, 
    sess.total_scheduled_time, sess.total_elapsed_time, sess.last_request_start_time, sess.last_request_end_time, sess.row_count AS session_row_count, 
    sess.prev_error, req.open_resultset_count AS open_resultsets, req.total_elapsed_time AS request_total_elapsed_time, 
    CONVERT (decimal(5,2), req.percent_complete) AS percent_complete, req.estimated_completion_time AS est_completion_time, req.transaction_id, 
    req.start_time AS request_start_time, LEFT (req.status, 15) AS request_status, req.command, req.plan_handle, req.sql_handle, req.statement_start_offset, 
    req.statement_end_offset, req.database_id, req.[user_id], req.executing_managed_code, tasks.pending_io_count, sess.login_time, 
    LEFT (sess.[host_name], 20) AS [host_name], LEFT (ISNULL (sess.program_name, ''), 50) AS program_name, ISNULL (sess.host_process_id, 0) AS host_process_id, 
    ISNULL (sess.client_version, 0) AS client_version, LEFT (ISNULL (sess.client_interface_name, ''), 30) AS client_interface_name, 
    LEFT (ISNULL (sess.login_name, ''), 30) AS login_name, LEFT (ISNULL (sess.nt_domain, ''), 30) AS nt_domain, LEFT (ISNULL (sess.nt_user_name, ''), 20) AS nt_user_name, 
    ISNULL (conn.net_packet_size, 0) AS net_packet_size, LEFT (ISNULL (conn.client_net_address, ''), 20) AS client_net_address, conn.most_recent_sql_handle, 
    LEFT (sess.status, 15) AS session_status
    /* sys.dm_os_workers and sys.dm_os_threads removed due to perf impact, no predicate pushdown (SQLBU #488971) */
    --  workers.is_preemptive,
    --  workers.is_sick, 
    --  workers.exception_num AS last_worker_exception, 
    --  convert (varchar (20), master.dbo.fn_varbintohexstr (workers.exception_address)) AS last_exception_address
    --  threads.os_thread_id 
  INTO #tmp_requests
  FROM sys.dm_exec_sessions sess 
  /* Join hints are required here to work around bad QO join order/type decisions (ultimately by-design, caused by the lack of accurate DMV card estimates) */
  LEFT OUTER MERGE JOIN sys.dm_exec_requests req  ON sess.session_id = req.session_id
  LEFT OUTER MERGE JOIN sys.dm_os_tasks tasks ON tasks.session_id = sess.session_id AND tasks.request_id = req.request_id 
  /* The following two DMVs removed due to perf impact, no predicate pushdown (SQLBU #488971) */
  --  LEFT OUTER MERGE JOIN sys.dm_os_workers workers ON tasks.worker_address = workers.worker_address
  --  LEFT OUTER MERGE JOIN sys.dm_os_threads threads ON workers.thread_address = threads.thread_address
  LEFT OUTER MERGE JOIN sys.dm_exec_connections conn on conn.session_id = sess.session_id
  WHERE 
    /* Get execution state for all active queries... */
    (req.session_id IS NOT NULL AND (sess.is_user_process = 1 OR req.status COLLATE Latin1_General_BIN NOT IN ('background', 'sleeping')))
    /* ... and also any head blockers, even though they may not be running a query at the moment. */
    OR (sess.session_id IN (SELECT DISTINCT blocking_session_id FROM sys.dm_exec_requests WHERE blocking_session_id != 0))
  /* redundant due to the use of join hints, but added here to suppress warning message */
  OPTION (FORCE ORDER)  
  SET @rowcount = @@ROWCOUNT
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats qry1 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)

  IF NOT EXISTS (SELECT * FROM #tmp_requests WHERE session_id <> @@SPID AND ISNULL (host_name, '') != @appname) BEGIN
    PRINT 'No active queries'
  END
  ELSE BEGIN
    -- There are active queries (other than this one). 
    -- This query could be collapsed into the query above.  It is broken out here to avoid an excessively 
    -- large memory grant due to poor cardinality estimates (see previous bugs -- ultimate cause is the 
    -- lack of good stats for many DMVs). 
    SET @querystarttime = GETDATE()
    SELECT 
      IDENTITY (int,1,1) AS tmprownum, 
      r.session_id, r.request_id, r.ecid, r.blocking_session_id, ISNULL (waits.blocking_exec_context_id, 0) AS blocking_ecid, 
      r.task_state, r.wait_type, ISNULL (waits.wait_duration_ms, 0) AS wait_duration_ms, r.wait_resource, 
      LEFT (ISNULL (waits.resource_description, ''), 140) AS resource_description, r.last_wait_type, r.open_trans, 
      r.transaction_isolation_level, r.is_user_process, r.request_cpu_time, r.request_logical_reads, r.request_reads, 
      r.request_writes, r.memory_usage, r.session_cpu_time, r.session_reads, r.session_writes, r.session_logical_reads, 
      r.total_scheduled_time, r.total_elapsed_time, r.last_request_start_time, r.last_request_end_time, r.session_row_count, 
      r.prev_error, r.open_resultsets, r.request_total_elapsed_time, r.percent_complete, r.est_completion_time, 
      -- r.tran_name, r.transaction_begin_time, r.tran_type, r.tran_state, 
      LEFT (COALESCE (reqtrans.name, sesstrans.name, ''), 24) AS tran_name, 
      COALESCE (reqtrans.transaction_begin_time, sesstrans.transaction_begin_time) AS transaction_begin_time, 
      LEFT (CASE COALESCE (reqtrans.transaction_type, sesstrans.transaction_type)
        WHEN 1 THEN '1-Read/write'
        WHEN 2 THEN '2-Read only'
        WHEN 3 THEN '3-System'
        WHEN 4 THEN '4-Distributed'
        ELSE CONVERT (varchar(30), COALESCE (reqtrans.transaction_type, sesstrans.transaction_type)) + '-UNKNOWN' 
      END, 15) AS tran_type, 
      LEFT (CASE COALESCE (reqtrans.transaction_state, sesstrans.transaction_state)
        WHEN 0 THEN '0-Initializing'
        WHEN 1 THEN '1-Initialized'
        WHEN 2 THEN '2-Active'
        WHEN 3 THEN '3-Ended'
        WHEN 4 THEN '4-Preparing'
        WHEN 5 THEN '5-Prepared'
        WHEN 6 THEN '6-Committed'
        WHEN 7 THEN '7-Rolling back'
        WHEN 8 THEN '8-Rolled back'
        ELSE CONVERT (varchar(30), COALESCE (reqtrans.transaction_state, sesstrans.transaction_state)) + '-UNKNOWN'
      END, 15) AS tran_state, 
      r.request_start_time, r.request_status, r.command, r.plan_handle, r.sql_handle, r.statement_start_offset, 
      r.statement_end_offset, r.database_id, r.[user_id], r.executing_managed_code, r.pending_io_count, r.login_time, 
      r.[host_name], r.program_name, r.host_process_id, r.client_version, r.client_interface_name, r.login_name, r.nt_domain, 
      r.nt_user_name, r.net_packet_size, r.client_net_address, r.most_recent_sql_handle, r.session_status, r.scheduler_id
      -- r.is_preemptive, r.is_sick, r.last_worker_exception, r.last_exception_address, 
      -- r.os_thread_id
    INTO #tmp_requests2
    FROM #tmp_requests r
    /* Join hints are required here to work around bad QO join order/type decisions (ultimately by-design, caused by the lack of accurate DMV card estimates) */
    /* Perf: no predicate pushdown on sys.dm_tran_active_transactions (SQLBU #489000) */
    LEFT OUTER MERGE JOIN sys.dm_tran_active_transactions reqtrans ON r.transaction_id = reqtrans.transaction_id
    /* No predicate pushdown on sys.dm_tran_session_transactions (SQLBU #489000) */
    LEFT OUTER MERGE JOIN sys.dm_tran_session_transactions sessions_transactions on sessions_transactions.session_id = r.session_id
    /* No predicate pushdown on sys.dm_tran_active_transactions (SQLBU #489000) */
    LEFT OUTER MERGE JOIN sys.dm_tran_active_transactions sesstrans ON sesstrans.transaction_id = sessions_transactions.transaction_id
    /* Suboptimal perf: see SQLBUD #449144. But we have to handle this in qry3 instead of here to avoid SQLBUD #489109. */
    LEFT OUTER MERGE JOIN sys.dm_os_waiting_tasks waits ON waits.waiting_task_address = r.task_address 
    ORDER BY r.session_id, blocking_ecid
    /* redundant due to the use of join hints, but added here to suppress warning message */
    OPTION (FORCE ORDER)  
    SET @rowcount = @@ROWCOUNT
    SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
    IF @queryduration > @qrydurationwarnthreshold
      PRINT 'DebugPrint: perfstats qry2 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)

    /* This index typically takes <10ms to create, and drops the head blocker summary query cost from ~250ms CPU down to ~20ms. */
    CREATE NONCLUSTERED INDEX idx1 ON #tmp_requests2 (blocking_session_id, session_id, wait_type, wait_duration_ms)
    RAISERROR ('-- requests --', 0, 1) WITH NOWAIT
    /* Output Resultset #1: summary of all active requests (and head blockers) */
    /* Dynamic (but explicitly parameterized) SQL used here to allow for (optional) direct-to-database data collection 
    ** without unnecessary code duplication. */
    SET @sql = '
    SELECT TOP 10000 CONVERT (varchar(30), @runtime, 126) AS runtime, 
      session_id, request_id, ecid, blocking_session_id, blocking_ecid, task_state, 
      wait_type, wait_duration_ms, wait_resource, resource_description, last_wait_type, 
      open_trans, transaction_isolation_level, is_user_process, 
      request_cpu_time, request_logical_reads, request_reads, request_writes, memory_usage, 
      session_cpu_time, session_reads, session_writes, session_logical_reads, total_scheduled_time, 
      total_elapsed_time, CONVERT (varchar, last_request_start_time, 126) AS last_request_start_time, 
      CONVERT (varchar, last_request_end_time, 126) AS last_request_end_time, session_row_count, 
      prev_error, open_resultsets, request_total_elapsed_time, percent_complete, 
      est_completion_time, tran_name, 
      CONVERT (varchar, transaction_begin_time, 126) AS transaction_begin_time, tran_type, 
      tran_state, CONVERT (varchar, request_start_time, 126) AS request_start_time, request_status, 
      command, statement_start_offset, statement_end_offset, database_id, [user_id], 
      executing_managed_code, pending_io_count, CONVERT (varchar, login_time, 126) AS login_time, 
      [host_name], program_name, host_process_id, client_version, client_interface_name, login_name, 
      nt_domain, nt_user_name, net_packet_size, client_net_address, session_status, 
      scheduler_id
      -- is_preemptive, is_sick, last_worker_exception, last_exception_address
      -- os_thread_id
    FROM #tmp_requests2 r
    WHERE ISNULL ([host_name], '''') != @appname AND r.session_id != @@SPID 
      /* One EC can have multiple waits in sys.dm_os_waiting_tasks (e.g. parent thread waiting on multiple children, for example 
      ** for parallel create index; or mem grant waits for RES_SEM_FOR_QRY_COMPILE).  This will result in the same EC being listed 
      ** multiple times in the request table, which is counterintuitive for most people.  Instead of showing all wait relationships, 
      ** for each EC we will report the wait relationship that has the longest wait time.  (If there are multiple relationships with 
      ** the same wait time, blocker spid/ecid is used to choose one of them.)  If it were not for SQLBUD #489109, we would do this 
      ** exclusion in the previous query to avoid storing data that will ultimately be filtered out. */
      AND NOT EXISTS 
        (SELECT * FROM #tmp_requests2 r2 
         WHERE r.session_id = r2.session_id AND r.request_id = r2.request_id AND r.ecid = r2.ecid AND r.wait_type = r2.wait_type 
           AND (r2.wait_duration_ms > r.wait_duration_ms OR (r2.wait_duration_ms = r.wait_duration_ms AND r2.tmprownum > r.tmprownum)))
    '
    IF '%runmode%' = 'REALTIME' 
      SET @sql = '
      INSERT INTO tbl_REQUESTS (runtime, session_id, request_id, ecid, blocking_session_id, blocking_ecid, 
        task_state, wait_type, wait_duration_ms, wait_resource, resource_description, last_wait_type, open_trans, 
        transaction_isolation_level, is_user_process, request_cpu_time, request_logical_reads, request_reads, request_writes, memory_usage, 
        session_cpu_time, session_reads, session_writes, session_logical_reads, total_scheduled_time, total_elapsed_time, last_request_start_time, 
        last_request_end_time, session_row_count, prev_error, open_resultsets, request_total_elapsed_time, percent_complete, estimated_completion_time, 
        tran_name, transaction_begin_time, tran_type, tran_state, request_start_time, request_status, command, statement_start_offset, 
        statement_end_offset, database_id, [user_id], executing_managed_code, pending_io_count, login_time, [host_name], program_name, host_process_id, 
        client_version, client_interface_name, login_name, nt_domain, nt_user_name, net_packet_size, client_net_address, session_status, 
        most_recent_sql_handle, scheduler_id) ' + @sql
    SET @querystarttime = GETDATE()
    EXEC sp_executesql @sql, N'@runtime datetime, @appname sysname', @runtime = @runtime, @appname = @appname
    SET @rowcount = @@ROWCOUNT
    SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
    RAISERROR ('', 0, 1) WITH NOWAIT
    IF @queryduration > @qrydurationwarnthreshold
      PRINT 'DebugPrint: perfstats qry3 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)

    /* Resultset #2: Head blocker summary */
    /* Intra-query blocking relationships (parallel query waits) aren't "true" blocking problems that we should report on here. */
    IF NOT EXISTS (SELECT * FROM #tmp_requests2 WHERE blocking_session_id != 0 AND wait_type NOT IN ('WAITFOR', 'EXCHANGE', 'CXPACKET') AND wait_duration_ms > 0) 
    BEGIN 
      PRINT ''
      PRINT '-- No blocking detected --'
      PRINT ''
    END
    ELSE BEGIN
      PRINT ''
      PRINT '-----------------------'
      PRINT '-- BLOCKING DETECTED --'
      PRINT ''
      RAISERROR ('-- headblockersummary --', 0, 1) WITH NOWAIT;
      /* We need stats like the number of spids blocked, max waittime, etc, for each head blocker.  Use a recursive CTE to 
      ** walk the blocking hierarchy. Again, explicitly parameterized dynamic SQL used to allow optional collection direct  
      ** to a database. */
      SET @cte = '
      WITH BlockingHierarchy (head_blocker_session_id, session_id, blocking_session_id, wait_type, wait_duration_ms, 
        wait_resource, statement_start_offset, statement_end_offset, plan_handle, sql_handle, most_recent_sql_handle, [Level]) 
      AS (
        SELECT head.session_id AS head_blocker_session_id, head.session_id AS session_id, head.blocking_session_id, 
          head.wait_type, head.wait_duration_ms, head.wait_resource, head.statement_start_offset, head.statement_end_offset, 
          head.plan_handle, head.sql_handle, head.most_recent_sql_handle, 0 AS [Level]
        FROM #tmp_requests2 head
        WHERE (head.blocking_session_id IS NULL OR head.blocking_session_id = 0) 
          AND head.session_id IN (SELECT DISTINCT blocking_session_id FROM #tmp_requests2 WHERE blocking_session_id != 0) 
        UNION ALL 
        SELECT h.head_blocker_session_id, blocked.session_id, blocked.blocking_session_id, blocked.wait_type, 
          blocked.wait_duration_ms, blocked.wait_resource, h.statement_start_offset, h.statement_end_offset, 
          h.plan_handle, h.sql_handle, h.most_recent_sql_handle, [Level] + 1
        FROM #tmp_requests2 blocked
        INNER JOIN BlockingHierarchy AS h ON h.session_id = blocked.blocking_session_id 
        WHERE h.wait_type COLLATE Latin1_General_BIN NOT IN (''EXCHANGE'', ''CXPACKET'') 
      )'
      SET @sql = '
      SELECT CONVERT (varchar(30), @runtime, 126) AS runtime, 
        head_blocker_session_id, COUNT(*) AS blocked_task_count, SUM (ISNULL (wait_duration_ms, 0)) AS tot_wait_duration_ms, 
        LEFT (CASE 
          WHEN wait_type LIKE ''LCK%'' COLLATE Latin1_General_BIN AND wait_resource LIKE ''%\[COMPILE\]%'' ESCAPE ''\'' COLLATE Latin1_General_BIN 
            THEN ''COMPILE ('' + ISNULL (wait_resource, '''') + '')'' 
          WHEN wait_type LIKE ''LCK%'' COLLATE Latin1_General_BIN THEN ''LOCK BLOCKING'' 
          WHEN wait_type LIKE ''PAGELATCH%'' COLLATE Latin1_General_BIN THEN ''PAGELATCH_* WAITS'' 
          WHEN wait_type LIKE ''PAGEIOLATCH%'' COLLATE Latin1_General_BIN THEN ''PAGEIOLATCH_* WAITS'' 
          ELSE wait_type
        END, 40) AS blocking_resource_wait_type, AVG (ISNULL (wait_duration_ms, 0)) AS avg_wait_duration_ms, MAX(wait_duration_ms) AS max_wait_duration_ms, 
        MAX ([Level]) AS max_blocking_chain_depth, 
        MAX (ISNULL (CONVERT (nvarchar(60), CASE 
          WHEN sql.objectid IS NULL THEN NULL 
          ELSE REPLACE (REPLACE (SUBSTRING (sql.[text], CHARINDEX (''CREATE '', CONVERT (nvarchar(512), SUBSTRING (sql.[text], 1, 1000)) COLLATE Latin1_General_BIN), 50) COLLATE Latin1_General_BIN, CHAR(10), '' ''), CHAR(13), '' '')
        END), '''')) AS head_blocker_proc_name, 
        MAX (ISNULL (sql.objectid, 0)) AS head_blocker_proc_objid, MAX (ISNULL (CONVERT (nvarchar(1000), REPLACE (REPLACE (SUBSTRING (sql.[text], ISNULL (statement_start_offset, 0)/2 + 1, 
          CASE WHEN ISNULL (statement_end_offset, 8192) <= 0 THEN 8192 
          ELSE ISNULL (statement_end_offset, 8192)/2 - ISNULL (statement_start_offset, 0)/2 END + 1) COLLATE Latin1_General_BIN, 
        CHAR(13), '' ''), CHAR(10), '' '')), '''')) AS stmt_text, 
        CONVERT (varbinary (64), MAX (ISNULL (plan_handle, 0x))) AS head_blocker_plan_handle
      FROM BlockingHierarchy
      OUTER APPLY sys.dm_exec_sql_text (ISNULL (sql_handle, most_recent_sql_handle)) AS sql
      WHERE blocking_session_id != 0 AND [Level] > 0
      GROUP BY head_blocker_session_id, 
        LEFT (CASE 
          WHEN wait_type LIKE ''LCK%'' COLLATE Latin1_General_BIN AND wait_resource LIKE ''%\[COMPILE\]%'' ESCAPE ''\'' COLLATE Latin1_General_BIN 
            THEN ''COMPILE ('' + ISNULL (wait_resource, '''') + '')'' 
          WHEN wait_type LIKE ''LCK%'' COLLATE Latin1_General_BIN THEN ''LOCK BLOCKING'' 
          WHEN wait_type LIKE ''PAGELATCH%'' COLLATE Latin1_General_BIN THEN ''PAGELATCH_* WAITS'' 
          WHEN wait_type LIKE ''PAGEIOLATCH%'' COLLATE Latin1_General_BIN THEN ''PAGEIOLATCH_* WAITS'' 
          ELSE wait_type
        END, 40) 
      ORDER BY SUM (wait_duration_ms) DESC'
      IF '%runmode%' = 'REALTIME' SET @sql = @cte + '
        INSERT INTO tbl_HEADBLOCKERSUMMARY (
          runtime, head_blocker_session_id, blocked_task_count, tot_wait_duration_ms, blocking_resource_wait_type, avg_wait_duration_ms, 
          max_wait_duration_ms, max_blocking_chain_depth, head_blocker_proc_name, head_blocker_proc_objid, stmt_text, head_blocker_plan_handle) ' + @sql
      ELSE 
        SET @sql = @cte + @sql
      SET @querystarttime = GETDATE();
      EXEC sp_executesql @sql, N'@runtime datetime', @runtime = @runtime
      SET @rowcount = @@ROWCOUNT
      SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
      RAISERROR ('', 0, 1) WITH NOWAIT
      IF @queryduration > @qrydurationwarnthreshold
        PRINT 'DebugPrint: perfstats qry4 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)
    END

    /* Resultset #3: inputbuffers and query stats for "expensive" queries, head blockers, and "first-tier" blocked spids */
    PRINT ''
    RAISERROR ('-- notableactivequeries --', 0, 1) WITH NOWAIT
    SET @sql = '
    SELECT DISTINCT TOP 500 
      CONVERT (varchar(30), @runtime, 126) AS runtime, r.session_id AS session_id, r.request_id AS request_id, stat.execution_count AS plan_total_exec_count, 
      stat.total_worker_time/1000 AS plan_total_cpu_ms, stat.total_elapsed_time/1000 AS plan_total_duration_ms, stat.total_physical_reads AS plan_total_physical_reads, 
      stat.total_logical_writes AS plan_total_logical_writes, stat.total_logical_reads AS plan_total_logical_reads, 
      LEFT (CASE 
        WHEN pa.value=32767 THEN ''ResourceDb''
        ELSE ISNULL (DB_NAME (CONVERT (sysname, pa.value)), CONVERT (sysname, pa.value))
      END, 40) AS dbname, 
      sql.objectid AS objectid, 
      CONVERT (nvarchar(60), CASE 
        WHEN sql.objectid IS NULL THEN NULL 
        ELSE REPLACE (REPLACE (SUBSTRING (sql.[text] COLLATE Latin1_General_BIN, CHARINDEX (''CREATE '', SUBSTRING (sql.[text] COLLATE Latin1_General_BIN, 1, 1000)), 50), CHAR(10), '' ''), CHAR(13), '' '')
      END) AS procname, 
      CONVERT (nvarchar(300), REPLACE (REPLACE (CONVERT (nvarchar(300), SUBSTRING (sql.[text], ISNULL (r.statement_start_offset, 0)/2 + 1, 
          CASE WHEN ISNULL (r.statement_end_offset, 8192) <= 0 THEN 8192 
          ELSE ISNULL (r.statement_end_offset, 8192)/2 - ISNULL (r.statement_start_offset, 0)/2 END + 1)) COLLATE Latin1_General_BIN, 
        CHAR(13), '' ''), CHAR(10), '' '')) AS stmt_text, 
      CONVERT (varbinary (64), (r.plan_handle)) AS plan_handle
    FROM #tmp_requests2 r
    LEFT OUTER JOIN sys.dm_exec_query_stats stat ON r.plan_handle = stat.plan_handle AND stat.statement_start_offset = r.statement_start_offset
    OUTER APPLY sys.dm_exec_plan_attributes (r.plan_handle) pa
    OUTER APPLY sys.dm_exec_sql_text (ISNULL (r.sql_handle, r.most_recent_sql_handle)) AS sql
    WHERE (pa.attribute = ''dbid'' COLLATE Latin1_General_BIN OR pa.attribute IS NULL) AND ISNULL (host_name, '''') != @appname AND r.session_id != @@SPID 
      AND ( 
        /* We do not want to pull inputbuffers for everyone. The conditions below determine which ones we will fetch. */
        (r.session_id IN (SELECT blocking_session_id FROM #tmp_requests2 WHERE blocking_session_id != 0)) -- head blockers
        OR (r.blocking_session_id IN (SELECT blocking_session_id FROM #tmp_requests2 WHERE blocking_session_id != 0)) -- "first-tier" blocked requests
        OR (LTRIM (r.wait_type) <> '''' OR r.wait_duration_ms > 500) -- waiting for some resource
        OR (r.open_trans > 5) -- possible orphaned transaction
        OR (r.request_total_elapsed_time > 25000) -- long-running query
        OR (r.request_logical_reads > 1000000 OR r.request_cpu_time > 3000) -- expensive (CPU) query
        OR (r.request_reads + r.request_writes > 5000 OR r.pending_io_count > 400) -- expensive (I/O) query
        OR (r.memory_usage > 25600) -- expensive (memory > 200MB) query
        -- OR (r.is_sick > 0) -- spinloop
      )
    ORDER BY stat.total_worker_time/1000 DESC'
    IF '%runmode%' = 'REALTIME' 
      SET @sql = 'INSERT INTO tbl_NOTABLEACTIVEQUERIES (runtime, session_id, request_id, plan_total_exec_count, 
        plan_total_cpu_ms, plan_total_duration_ms, plan_total_physical_reads, plan_total_logical_writes, 
        plan_total_logical_reads, dbname, objectid, procname, stmt_text, plan_handle)' + @sql

    SET @querystarttime = GETDATE()
    EXEC sp_executesql @sql, N'@runtime datetime, @appname sysname', @runtime = @runtime, @appname = @appname
    SET @rowcount = @@ROWCOUNT
    RAISERROR ('', 0, 1) WITH NOWAIT
    SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
    IF @rowcount >= 500 PRINT 'WARNING: notableactivequeries output artificially limited to 500 rows'
    IF @queryduration > @qrydurationwarnthreshold
      PRINT 'DebugPrint: perfstats qry5 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)

    IF '%runmode%' = 'REALTIME' BEGIN 
      -- In near-realtime/direct-to-database mode, we have to maintain tbl_BLOCKING_CHAINS on-the-fly
      -- 1) Insert new blocking chains
      INSERT INTO tbl_BLOCKING_CHAINS (first_rownum, last_rownum, num_snapshots, blocking_start, blocking_end, head_blocker_session_id, 
        blocking_wait_type, max_blocked_task_count, max_total_wait_duration_ms, avg_wait_duration_ms, max_wait_duration_ms, 
        max_blocking_chain_depth, head_blocker_session_id_orig)
      SELECT rownum, NULL, 1, runtime, NULL, 
        CASE WHEN blocking_resource_wait_type LIKE 'COMPILE%' THEN 'COMPILE BLOCKING' ELSE head_blocker_session_id END AS head_blocker_session_id, 
        blocking_resource_wait_type, blocked_task_count, tot_wait_duration_ms, avg_wait_duration_ms, max_wait_duration_ms, 
        max_blocking_chain_depth, head_blocker_session_id
      FROM tbl_HEADBLOCKERSUMMARY b1 
      WHERE b1.runtime = @runtime AND NOT EXISTS (
        SELECT * FROM tbl_BLOCKING_CHAINS b2  
        WHERE b2.blocking_end IS NULL  -- end-of-blocking has not been detected yet
          AND b2.head_blocker_session_id = CASE WHEN blocking_resource_wait_type LIKE 'COMPILE%' THEN 'COMPILE BLOCKING' ELSE head_blocker_session_id END -- same head blocker
          AND b2.blocking_wait_type = b1.blocking_resource_wait_type -- same type of blocking
      )
      PRINT 'Inserted ' + CONVERT (varchar, @@ROWCOUNT) + ' new blocking chains...'

      -- 2) Update statistics for in-progress blocking incidents
      UPDATE tbl_BLOCKING_CHAINS 
      SET last_rownum = b2.rownum, num_snapshots = b1.num_snapshots + 1, 
        max_blocked_task_count = CASE WHEN b1.max_blocked_task_count > b2.blocked_task_count THEN b1.max_blocked_task_count ELSE b2.blocked_task_count END, 
        max_total_wait_duration_ms = CASE WHEN b1.max_total_wait_duration_ms > b2.tot_wait_duration_ms THEN b1.max_total_wait_duration_ms ELSE b2.tot_wait_duration_ms END, 
        avg_wait_duration_ms = (b1.num_snapshots-1) * b1.avg_wait_duration_ms + b2.avg_wait_duration_ms / b1.num_snapshots, 
        max_wait_duration_ms = CASE WHEN b1.max_wait_duration_ms > b2.max_wait_duration_ms THEN b1.max_wait_duration_ms ELSE b2.max_wait_duration_ms END, 
        max_blocking_chain_depth = CASE WHEN b1.max_blocking_chain_depth > b2.max_blocking_chain_depth THEN b1.max_blocking_chain_depth ELSE b2.max_blocking_chain_depth END
      FROM tbl_BLOCKING_CHAINS b1 
      INNER JOIN tbl_HEADBLOCKERSUMMARY b2 ON b1.blocking_end IS NULL -- end-of-blocking has not been detected yet
          AND b2.head_blocker_session_id = b1.head_blocker_session_id -- same head blocker
          AND b1.blocking_wait_type = b2.blocking_resource_wait_type -- same type of blocking
          AND b2.runtime = @runtime
      PRINT 'Updated ' + CONVERT (varchar, @@ROWCOUNT) + ' in-progress blocking chains...'

      -- 3) "Close out" blocking chains that were just resolved
      UPDATE tbl_BLOCKING_CHAINS 
      SET blocking_end = @runtime
      FROM tbl_BLOCKING_CHAINS b1
      WHERE blocking_end IS NULL AND NOT EXISTS (
        SELECT * FROM tbl_HEADBLOCKERSUMMARY b2 WHERE b2.runtime = @runtime 
          AND b2.head_blocker_session_id = b1.head_blocker_session_id -- same head blocker
          AND b1.blocking_wait_type = b2.blocking_resource_wait_type -- same type of blocking
      )
      PRINT + CONVERT (varchar, @@ROWCOUNT) + ' blocking chains have ended.'
    END

    RAISERROR ('', 0, 1) WITH NOWAIT
  END

  -- Raise a diagnostic message if we use much more CPU than normal (a typical execution uses <300ms)
  DECLARE @cpu_time bigint, @elapsed_time bigint
  SELECT @cpu_time = cpu_time - @cpu_time_start, @elapsed_time = total_elapsed_time - @elapsed_time_start FROM sys.dm_exec_requests WHERE session_id = @@SPID
  IF (@elapsed_time > 2000 OR @cpu_time > 750)
    PRINT 'DebugPrint: perfstats tot - ' + CONVERT (varchar, @elapsed_time) + 'ms elapsed, ' + CONVERT (varchar, @cpu_time) + 'ms cpu' + CHAR(13) + CHAR(10)  
GO

IF OBJECT_ID('dbo.DatabaseIntegrityCheck', 'P') IS NOT NULL
  DROP PROCEDURE dbo.DatabaseIntegrityCheck;
GO

CREATE PROCEDURE [dbo].[DatabaseIntegrityCheck]

@Databases varchar(max)

AS

SET NOCOUNT ON

----------------------------------------------------------------------------------------------------
--// Declare variables                                                                          //--
----------------------------------------------------------------------------------------------------

DECLARE @StartMessage varchar(max)
DECLARE @EndMessage varchar(max)
DECLARE @DatabaseMessage varchar(max)
DECLARE @ErrorMessage varchar(max)

DECLARE @CurrentID int
DECLARE @CurrentDatabase varchar(max)
DECLARE @CurrentCommand01 varchar(max)
DECLARE @CurrentCommandOutput01 int

DECLARE @tmpDatabases TABLE (	ID int IDENTITY PRIMARY KEY,
								DatabaseName varchar(max),
								Completed bit)

DECLARE @Error int

SET @Error = 0

----------------------------------------------------------------------------------------------------
--// Log initial information                                                                    //--
----------------------------------------------------------------------------------------------------

SET @StartMessage =	'DateTime: ' + CONVERT(varchar,GETDATE(),120) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Procedure: ' + QUOTENAME(DB_NAME(DB_ID())) + '.' + QUOTENAME(OBJECT_SCHEMA_NAME(@@PROCID)) + '.' + QUOTENAME(OBJECT_NAME(@@PROCID)) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Parameters: @Databases = ' + ISNULL('''' + @Databases + '''','NULL')
SET @StartMessage = @StartMessage + CHAR(13) + CHAR(10)

RAISERROR(@StartMessage,10,1) WITH NOWAIT

----------------------------------------------------------------------------------------------------
--// Select databases                                                                           //--
----------------------------------------------------------------------------------------------------

IF @Databases IS NULL OR @Databases = ''
BEGIN
	SET @ErrorMessage = 'The value for parameter @Databases is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

INSERT INTO @tmpDatabases (DatabaseName, Completed)
SELECT	DatabaseName AS DatabaseName,
		0 AS Completed
FROM dbo.DatabaseSelect (@Databases)
ORDER BY DatabaseName ASC

IF @@ERROR <> 0 OR @@ROWCOUNT = 0
BEGIN
	SET @ErrorMessage = 'Error selecting databases.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

----------------------------------------------------------------------------------------------------
--// Check error variable                                                                       //--
----------------------------------------------------------------------------------------------------

IF @Error <> 0 GOTO Logging

----------------------------------------------------------------------------------------------------
--// Execute commands                                                                           //--
----------------------------------------------------------------------------------------------------

WHILE EXISTS (SELECT * FROM @tmpDatabases WHERE Completed = 0)
BEGIN

	SELECT TOP 1	@CurrentID = ID,
					@CurrentDatabase = DatabaseName
	FROM @tmpDatabases
	WHERE Completed = 0
	ORDER BY ID ASC

	-- Set database message	
	SET @DatabaseMessage = 'DateTime: ' + CONVERT(varchar,GETDATE(),120) + CHAR(13) + CHAR(10)
	SET @DatabaseMessage = @DatabaseMessage + 'Database: ' + QUOTENAME(@CurrentDatabase) + CHAR(13) + CHAR(10)
	SET @DatabaseMessage = @DatabaseMessage + 'Status: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabase,'status') AS varchar) + CHAR(13) + CHAR(10)
	RAISERROR(@DatabaseMessage,10,1) WITH NOWAIT

	IF DATABASEPROPERTYEX(@CurrentDatabase,'status') = 'ONLINE'
	BEGIN
		SET @CurrentCommand01 = 'DBCC CHECKDB (' + QUOTENAME(@CurrentDatabase) + ') WITH DATA_PURITY, NO_INFOMSGS'
		EXECUTE @CurrentCommandOutput01 = [dbo].[CommandExecute] @CurrentCommand01, '', 1
		SET @Error = @@ERROR
		IF @ERROR <> 0 SET @CurrentCommandOutput01 = @ERROR
	END

	-- Update that the database is completed
	UPDATE @tmpDatabases
	SET Completed = 1
	WHERE ID = @CurrentID

	-- Clear variables
	SET @CurrentID = NULL
	SET @CurrentDatabase = NULL
	SET @CurrentCommand01 = NULL
	SET @CurrentCommandOutput01 = NULL

END

----------------------------------------------------------------------------------------------------
--// Log completing information                                                                 //--
----------------------------------------------------------------------------------------------------

Logging:

SET @EndMessage = 'DateTime: ' + CONVERT(varchar,GETDATE(),120)

RAISERROR(@EndMessage,10,1) WITH NOWAIT

----------------------------------------------------------------------------------------------------
GO

IF OBJECT_ID('dbo.sp_track_security_changes', 'P') IS NOT NULL
  DROP PROCEDURE dbo.sp_track_security_changes;
GO

CREATE procedure [dbo].[sp_track_security_changes] 
as

-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
set @maxfilesize = 5 

-- Please replace the text InsertFileNameHere, with an appropriate
-- filename prefixed by a path, e.g., c:\MyFolder\MyTrace. The .trc extension
-- will be appended to the filename automatically. If you are writing from
-- remote server to local drive, please use UNC path and make sure server has
-- write access to your network share

exec @rc = sp_trace_create @TraceID output, 2, N'F:\SQL\TrackSecurityChanges', @maxfilesize, NULL, 5
if (@rc != 0) goto error

-- Client side File and Table cannot be scripted

-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 109, 8, @on
exec sp_trace_setevent @TraceID, 109, 10, @on
exec sp_trace_setevent @TraceID, 109, 26, @on
exec sp_trace_setevent @TraceID, 109, 42, @on
exec sp_trace_setevent @TraceID, 109, 11, @on
exec sp_trace_setevent @TraceID, 109, 35, @on
exec sp_trace_setevent @TraceID, 109, 12, @on
exec sp_trace_setevent @TraceID, 109, 21, @on
exec sp_trace_setevent @TraceID, 109, 37, @on
exec sp_trace_setevent @TraceID, 109, 14, @on
exec sp_trace_setevent @TraceID, 109, 38, @on
exec sp_trace_setevent @TraceID, 109, 23, @on
exec sp_trace_setevent @TraceID, 108, 8, @on
exec sp_trace_setevent @TraceID, 108, 1, @on
exec sp_trace_setevent @TraceID, 108, 10, @on
exec sp_trace_setevent @TraceID, 108, 26, @on
exec sp_trace_setevent @TraceID, 108, 42, @on
exec sp_trace_setevent @TraceID, 108, 11, @on
exec sp_trace_setevent @TraceID, 108, 12, @on
exec sp_trace_setevent @TraceID, 108, 21, @on
exec sp_trace_setevent @TraceID, 108, 37, @on
exec sp_trace_setevent @TraceID, 108, 14, @on
exec sp_trace_setevent @TraceID, 108, 38, @on
exec sp_trace_setevent @TraceID, 108, 23, @on
exec sp_trace_setevent @TraceID, 110, 8, @on
exec sp_trace_setevent @TraceID, 110, 1, @on
exec sp_trace_setevent @TraceID, 110, 10, @on
exec sp_trace_setevent @TraceID, 110, 26, @on
exec sp_trace_setevent @TraceID, 110, 42, @on
exec sp_trace_setevent @TraceID, 110, 11, @on
exec sp_trace_setevent @TraceID, 110, 35, @on
exec sp_trace_setevent @TraceID, 110, 12, @on
exec sp_trace_setevent @TraceID, 110, 21, @on
exec sp_trace_setevent @TraceID, 110, 37, @on
exec sp_trace_setevent @TraceID, 110, 14, @on
exec sp_trace_setevent @TraceID, 110, 38, @on
exec sp_trace_setevent @TraceID, 110, 23, @on
exec sp_trace_setevent @TraceID, 111, 8, @on
exec sp_trace_setevent @TraceID, 111, 10, @on
exec sp_trace_setevent @TraceID, 111, 14, @on
exec sp_trace_setevent @TraceID, 111, 26, @on
exec sp_trace_setevent @TraceID, 111, 38, @on
exec sp_trace_setevent @TraceID, 111, 11, @on
exec sp_trace_setevent @TraceID, 111, 35, @on
exec sp_trace_setevent @TraceID, 111, 12, @on
exec sp_trace_setevent @TraceID, 111, 21, @on
exec sp_trace_setevent @TraceID, 111, 23, @on
exec sp_trace_setevent @TraceID, 104, 8, @on
exec sp_trace_setevent @TraceID, 104, 10, @on
exec sp_trace_setevent @TraceID, 104, 14, @on
exec sp_trace_setevent @TraceID, 104, 26, @on
exec sp_trace_setevent @TraceID, 104, 42, @on
exec sp_trace_setevent @TraceID, 104, 11, @on
exec sp_trace_setevent @TraceID, 104, 12, @on
exec sp_trace_setevent @TraceID, 104, 21, @on
exec sp_trace_setevent @TraceID, 104, 23, @on
exec sp_trace_setevent @TraceID, 107, 8, @on
exec sp_trace_setevent @TraceID, 107, 1, @on
exec sp_trace_setevent @TraceID, 107, 10, @on
exec sp_trace_setevent @TraceID, 107, 26, @on
exec sp_trace_setevent @TraceID, 107, 42, @on
exec sp_trace_setevent @TraceID, 107, 11, @on
exec sp_trace_setevent @TraceID, 107, 35, @on
exec sp_trace_setevent @TraceID, 107, 12, @on
exec sp_trace_setevent @TraceID, 107, 21, @on
exec sp_trace_setevent @TraceID, 107, 37, @on
exec sp_trace_setevent @TraceID, 107, 14, @on
exec sp_trace_setevent @TraceID, 107, 23, @on
exec sp_trace_setevent @TraceID, 106, 8, @on
exec sp_trace_setevent @TraceID, 106, 1, @on
exec sp_trace_setevent @TraceID, 106, 10, @on
exec sp_trace_setevent @TraceID, 106, 26, @on
exec sp_trace_setevent @TraceID, 106, 42, @on
exec sp_trace_setevent @TraceID, 106, 11, @on
exec sp_trace_setevent @TraceID, 106, 35, @on
exec sp_trace_setevent @TraceID, 106, 12, @on
exec sp_trace_setevent @TraceID, 106, 21, @on
exec sp_trace_setevent @TraceID, 106, 37, @on
exec sp_trace_setevent @TraceID, 106, 14, @on
exec sp_trace_setevent @TraceID, 106, 23, @on


-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

exec sp_trace_setfilter @TraceID, 10, 0, 7, N'SQL Server Profiler - e5b07733-f3b7-4a4f-ac67-a552db618c97'
-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 

GO

EXEC sp_procoption N'[dbo].[sp_track_security_changes]', 'startup', '1'

GO


IF OBJECT_ID('dbo.sp_ReportServerOnRestart', 'P') IS NOT NULL
  DROP PROCEDURE dbo.sp_ReportServerOnRestart;
GO

CREATE PROCEDURE dbo.sp_ReportServerOnRestart
AS


  SET NOCOUNT ON;
  
  DECLARE @ServerInfo TABLE (
    ServerName sysname, 
    HostName sysname, 
    ProductVersion varchar(20), 
    SQLServicePack varchar(20)
  );

  DECLARE 
  @ServerName sysname, 
  @HostName sysname, 
  @ProductVersion sysname, 
  @ProductLevel sysname;
  
  SELECT 
  @ServerName = @@servername, 
  @ProductVersion = convert(varchar(20), SERVERPROPERTY('productVersion')), 
  @ProductLevel = convert(varchar(20), SERVERPROPERTY('productlevel'));

  IF SERVERPROPERTY('IsClustered') = 1 
    SELECT @HostName = host_name FROM sys.dm_exec_sessions WHERE [program_name] = 'Microsoft® Windows® Operating System';
  ELSE
    SELECT @HostName = CONVERT(VARCHAR(30), SERVERPROPERTY('ComputerNamePhysicalNetBIOS'));

  INSERT INTO @ServerInfo VALUES (@ServerName, @HostName, @ProductVersion, @ProductLevel);

  DECLARE @p_name varchar(100),
          @r_name varchar(100),
          @sub varchar(100),
          @bo varchar(100);
          
  SELECT @hostname = HostName from @ServerInfo;
  
  SELECT @p_name=@@servername, 
         @r_name='DBA@amsa.com', 
         @sub='SQL Server '+@@servername+' has started on ' + 
                CASE WHEN SERVERPROPERTY ('IsClustered') = 1 THEN 'cluster node ' 
                     WHEN SERVERPROPERTY ('IsClustered') = 0 THEN 'machine ' 
                END + SPACE(1) + @hostname + '...', 
         @bo='This message indicates that the MSSQL Server Service just started...';

  EXEC msdb.dbo.sp_send_dbmail
    @profile_name = @p_name,
    @recipients = @r_name,
    @body = @bo,
    @subject = @sub;

GO

--  MARK IT AUTO EXECUTION
EXEC SP_PROCOPTION 'sp_ReportServerOnRestart', 'STARTUP', 'ON';
GO


IF OBJECT_ID('dbo.sp_SetTraceFlags', 'P') IS NOT NULL
  DROP PROCEDURE dbo.sp_SetTraceFlags;
GO

create procedure [dbo].[sp_SetTraceFlags] 
as

dbcc traceon(3226, -1)	-- Suppress successful log backup message in error log and application log
dbcc traceon(1204, -1)	-- Display deadlock info in log
dbcc traceon(1222, -1)	-- Display deadlock info in log


GO

EXEC sp_procoption N'[dbo].[sp_SetTraceFlags]', 'startup', 'on'

GO

-- 011 sp_hexadecimal & sp_help_revlogin (MS officially updated).sql

--  Officially updated in MS KB918992  http://support.microsoft.com/kb/918992/
--  To transfer the logins and the passwords between instances of SQL Server 2005

USE master
GO
IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
  DROP PROCEDURE sp_hexadecimal
GO
CREATE PROCEDURE sp_hexadecimal
    @binvalue varbinary(256),
    @hexvalue varchar (514) OUTPUT
AS
DECLARE @charvalue varchar (514)
DECLARE @i int
DECLARE @length int
DECLARE @hexstring char(16)
SELECT @charvalue = '0x'
SELECT @i = 1
SELECT @length = DATALENGTH (@binvalue)
SELECT @hexstring = '0123456789ABCDEF'
WHILE (@i <= @length)
BEGIN
  DECLARE @tempint int
  DECLARE @firstint int
  DECLARE @secondint int
  SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
  SELECT @firstint = FLOOR(@tempint/16)
  SELECT @secondint = @tempint - (@firstint*16)
  SELECT @charvalue = @charvalue +
    SUBSTRING(@hexstring, @firstint+1, 1) +
    SUBSTRING(@hexstring, @secondint+1, 1)
  SELECT @i = @i + 1
END

SELECT @hexvalue = @charvalue
GO

IF OBJECT_ID ('sp_help_revlogin') IS NOT NULL
  DROP PROCEDURE sp_help_revlogin
GO
CREATE PROCEDURE sp_help_revlogin @login_name sysname = NULL AS
DECLARE @name sysname
DECLARE @type varchar (1)
DECLARE @hasaccess int
DECLARE @denylogin int
DECLARE @is_disabled int
DECLARE @PWD_varbinary  varbinary (256)
DECLARE @PWD_string  varchar (514)
DECLARE @SID_varbinary varbinary (85)
DECLARE @SID_string varchar (514)
DECLARE @tmpstr  varchar (1024)
DECLARE @is_policy_checked varchar (3)
DECLARE @is_expiration_checked varchar (3)

DECLARE @defaultdb sysname
 
IF (@login_name IS NULL)
  DECLARE login_curs CURSOR FOR

      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name <> 'sa'
ELSE
  DECLARE login_curs CURSOR FOR


      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name = @login_name
OPEN login_curs

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
IF (@@fetch_status = -1)
BEGIN
  PRINT 'No login(s) found.'
  CLOSE login_curs
  DEALLOCATE login_curs
  RETURN -1
END
SET @tmpstr = '/* sp_help_revlogin script '
PRINT @tmpstr
SET @tmpstr = '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @tmpstr
PRINT ''
WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN
    PRINT ''
    SET @tmpstr = '-- Login: ' + @name
    PRINT @tmpstr
    IF (@type IN ( 'G', 'U'))
    BEGIN -- NT authenticated account/group

      SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
    END
    ELSE BEGIN -- SQL Server authentication
        -- obtain password and sid
            SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )
        EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT
        EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT
 
        -- obtain password policy state
        SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
        SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
 
            SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

        IF ( @is_policy_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
        END
        IF ( @is_expiration_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
        END
    END
    IF (@denylogin = 1)
    BEGIN -- login is denied access
      SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )
    END
    ELSE IF (@hasaccess = 0)
    BEGIN -- login exists but does not have access
      SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
    END
    IF (@is_disabled = 1)
    BEGIN -- login is disabled
      SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
    END
    PRINT @tmpstr
  END

  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
   END
CLOSE login_curs
DEALLOCATE login_curs
RETURN 0
GO


-- 012 Standardize system database size.sql
/*
ALTER DATABASE master
  MODIFY FILE (name = 'master', size = 100 MB);
  
ALTER DATABASE master
  MODIFY FILE (name = 'mastlog', size = 50 MB);
  
ALTER DATABASE msdb
  MODIFY FILE (name = 'msdbdata', size = 100 MB);
  
ALTER DATABASE msdb
  MODIFY FILE (name = 'msdblog', size = 50 MB);
*/

  
  