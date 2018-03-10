USE [master]
GO

/****** Object:  UserDefinedFunction [dbo].[DatabaseSelect]    Script Date: 07/09/2013 23:29:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE FUNCTION [dbo].[DatabaseSelect] (@DatabaseList varchar(max))

RETURNS @Database TABLE(DatabaseName varchar(max) NOT NULL)

AS

BEGIN

	DECLARE @Database01 TABLE(	DatabaseName varchar(max),
								DatabaseStatus bit)

	DECLARE @Database02 TABLE(	DatabaseName varchar(max),
								DatabaseStatus bit)
	
	DECLARE @DatabaseItem varchar(max)
	DECLARE @Position int
	
	SET @DatabaseList = LTRIM(RTRIM(@DatabaseList))
	SET @DatabaseList = REPLACE(@DatabaseList,' ','')
	SET @DatabaseList = REPLACE(@DatabaseList,'[','')
	SET @DatabaseList = REPLACE(@DatabaseList,']','')
	SET @DatabaseList = REPLACE(@DatabaseList,'''','')
	SET @DatabaseList = REPLACE(@DatabaseList,'"','')

	WHILE CHARINDEX(',,',@DatabaseList) > 0 SET @DatabaseList = REPLACE(@DatabaseList,',,',',')

	IF RIGHT(@DatabaseList,1) = ',' SET @DatabaseList = LEFT(@DatabaseList,LEN(@DatabaseList) - 1)
	IF LEFT(@DatabaseList,1) = ','	SET @DatabaseList = RIGHT(@DatabaseList,LEN(@DatabaseList) - 1)

	WHILE LEN(@DatabaseList) > 0
	BEGIN
		SET @Position = CHARINDEX(',', @DatabaseList)
		IF @Position = 0
		BEGIN
			SET @DatabaseItem = @DatabaseList
			SET @DatabaseList = ''
		END
		ELSE
		BEGIN
			SET @DatabaseItem = LEFT(@DatabaseList, @Position - 1) 
			SET @DatabaseList = RIGHT(@DatabaseList, LEN(@DatabaseList) - @Position)
		END
		INSERT INTO @Database01 (DatabaseName) VALUES(@DatabaseItem)
	END
	
	UPDATE @Database01
	SET DatabaseStatus = 1
	WHERE DatabaseName NOT LIKE '-%'

	UPDATE @Database01
	SET	DatabaseName = RIGHT(DatabaseName,LEN(DatabaseName) - 1), DatabaseStatus = 0
	WHERE DatabaseName LIKE '-%'

	INSERT INTO @Database02 (DatabaseName, DatabaseStatus)
	SELECT DISTINCT DatabaseName, DatabaseStatus
	FROM @Database01
	WHERE DatabaseName NOT IN('SYSTEM_DATABASES','USER_DATABASES')

	IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'SYSTEM_DATABASES' AND DatabaseStatus = 0)
	BEGIN
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('master', 0)
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('model', 0)
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('msdb', 0)
	END

	IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'SYSTEM_DATABASES' AND DatabaseStatus = 1)
	BEGIN
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('master', 1)
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('model', 1)
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('msdb', 1)
	END

	IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'USER_DATABASES' AND DatabaseStatus = 0)
	BEGIN
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus)
		SELECT [name], 0
		FROM sys.databases
		WHERE database_id > 4
	END

	IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'USER_DATABASES' AND DatabaseStatus = 1)
	BEGIN
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus)
		SELECT [name], 1
		FROM sys.databases
		WHERE database_id > 4
	END
				
	INSERT INTO @Database (DatabaseName)
	SELECT [name]
	FROM sys.databases
	WHERE [name] <> 'tempdb'
	INTERSECT
	SELECT DatabaseName
	FROM @Database02
	WHERE DatabaseStatus = 1
	EXCEPT
	SELECT DatabaseName
	FROM @Database02
	WHERE DatabaseStatus = 0
		
	RETURN

END


GO

USE [master]
GO

/****** Object:  StoredProcedure [dbo].[CommandExecute]    Script Date: 07/09/2013 23:32:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[CommandExecute]

@Command varchar(max),
@Comment varchar(max),
@Mode int

AS

SET NOCOUNT ON

SET LOCK_TIMEOUT 3600000

----------------------------------------------------------------------------------------------------
--// Declare variables                                                                          //--
----------------------------------------------------------------------------------------------------

DECLARE @StartMessage varchar(max)
DECLARE @EndMessage varchar(max)
DECLARE @ErrorMessage varchar(max)

DECLARE @Error int

SET @Error = 0

----------------------------------------------------------------------------------------------------
--// Check input parameters                                                                     //--
----------------------------------------------------------------------------------------------------

IF @Command IS NULL OR @Command = ''
BEGIN
	SET @ErrorMessage = 'The value for parameter @Command is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

IF @Comment IS NULL
BEGIN
	SET @ErrorMessage = 'The value for parameter @Comment is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

IF @Mode NOT IN(1,2) OR @Mode IS NULL
BEGIN
	SET @ErrorMessage = 'The value for parameter @Mode is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

----------------------------------------------------------------------------------------------------
--// Check error variable                                                                       //--
----------------------------------------------------------------------------------------------------

IF @Error <> 0 GOTO ReturnCode

----------------------------------------------------------------------------------------------------
--// Log initial information                                                                    //--
----------------------------------------------------------------------------------------------------

SET @StartMessage = 'DateTime: ' + CONVERT(varchar,GETDATE(),120) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Command: ' + @Command + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Comment: ' + @Comment

RAISERROR(@StartMessage,10,1) WITH NOWAIT

----------------------------------------------------------------------------------------------------
--// Execute command                                                                            //--
----------------------------------------------------------------------------------------------------

IF @Mode = 1
BEGIN
	EXECUTE(@Command)
	SET @Error = @@ERROR
END

IF @Mode = 2
BEGIN
	BEGIN TRY
		EXECUTE(@Command)
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = 'Msg ' + CAST(ERROR_NUMBER() AS varchar) + ', ' + ISNULL(ERROR_MESSAGE(),'')
		RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	END CATCH
END

----------------------------------------------------------------------------------------------------
--// Log completing information                                                                 //--
----------------------------------------------------------------------------------------------------

SET @EndMessage = 'DateTime: ' + CONVERT(varchar,GETDATE(),120) + CHAR(13) + CHAR(10)

RAISERROR(@EndMessage,10,1) WITH NOWAIT

----------------------------------------------------------------------------------------------------
--// Return code                                                                                //--
----------------------------------------------------------------------------------------------------

ReturnCode:

RETURN @Error

----------------------------------------------------------------------------------------------------




GO

USE [master]
GO

/****** Object:  StoredProcedure [dbo].[IndexOptimize]    Script Date: 07/09/2013 23:25:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
		AND o.name NOT IN (''co_address_change_log'', ''co_address_change_log_ext'', ''fw_change_log'', ''client_asa_web_activity'', ''client_asa_mass_communication_batch_detail'')
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

USE [msdb]
GO

/****** Object:  Job [ASA IndexOptimize - User Databases]    Script Date: 07/11/2013 12:41:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 07/11/2013 12:41:28 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ASA IndexOptimize - User Databases', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'ASASA', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ASA IndexOptimize - User Databases]    Script Date: 07/11/2013 12:41:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ASA IndexOptimize - User Databases', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'sqlcmd -E -S $(ESCAPE_SQUOTE(SRVR)) -d master -Q "EXECUTE [dbo].[IndexOptimize] @Databases = ''USER_DATABASES''" -b', 
		@output_file_name=N'M:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Log\ASA_USER_INDEX_$(ESCAPE_SQUOTE(JOBID))_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt', 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly Saturday at 12 pm', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20130413, 
		@active_end_date=99991231, 
		@active_start_time=120000, 
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






