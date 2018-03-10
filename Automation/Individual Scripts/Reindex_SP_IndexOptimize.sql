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


