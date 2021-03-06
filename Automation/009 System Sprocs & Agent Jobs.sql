--**************  IMPORTANT  *******************
--  You must manually create backup folder on the RIGHT drive !!
--  Replace Z:\ with the right dirve letter.
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
**  author: Richard Ding
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
		@owner_login_name=N'AMSA\svDEVSQLAgentExec', 
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
		@owner_login_name=N'AMSA\svDEVSQLAgentExec', 
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
		@owner_login_name=N'AMSA\svDEVSQLAgentExec', 
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
		@output_file_name=N'M:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\CheckDB.log', 
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
		@owner_login_name=N'AMSA\svDEVSQLAgentExec', 
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
		@output_file_name=N'M:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\Backup_Full.txt', 
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
		@owner_login_name=N'AMSA\svDEVSQLAgentExec', 
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
insert into #t select name, database_id from sys.databases where name not like (''%tempdb%'') and recovery_model = 1

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
		@output_file_name=N'M:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\Backup_Log.txt', 
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
		@owner_login_name=N'AMSA\svDEVSQLAgentExec', 
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


