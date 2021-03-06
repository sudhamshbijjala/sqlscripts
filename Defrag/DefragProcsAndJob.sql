/*
	Step 1	Execute one of two sp_add_operators below
	Step 2	Execute one of two @job_notify_email below
	Step 3	Set @step_output_file to appropriate path
	Step 4	YOU NEED TO GO TO STEP 1 OF THE DEFRAG JOB AND SPECIFY THE DATABASES TO DEFRAG
			search for "list,databases,here" to help you find it
*/

declare @step_output_file sysname, @job_notify_email sysname

--------------------- STEP 1 ----------------------------

/* IF THIS IS A PRODUCTION INSTANCE, notify should be to operators and dba
USE [msdb]
GO
IF NOT EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'ProdOperator')
EXEC msdb.dbo.sp_add_operator @name=N'ProdOperator', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'ProductionControlOperators@amsa.com;DBA@amsa.com', 
		@cateGOry_name=N'[UncateGOrized]'
GO

*/

/* IF THIS IS A NON-PRODUCTION INSTANCE, notify should be to dba
USE [msdb]
GO
IF NOT EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'DBA')
EXEC msdb.dbo.sp_add_operator @name=N'DBA', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'DBA@amsa.com', 
		@cateGOry_name=N'[UncateGOrized]'
GO

*/
--------------------- STEP 2 ----------------------------
set @job_notify_email = 'ProdOperator'
set @job_notify_email = 'DBA'

--------------------- STEP 3 ----------------------------
-- Specify the output file for each step of the defrag job
set @step_output_file = 'M:\Microsoft SQL Server\MSSQL.2\MSSQL\LOG\Defrag_Databases.txt'


USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_SQLDefrag_BuildList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_SQLDefrag_BuildList]
GO

CREATE PROCEDURE [dbo].[sp_SQLDefrag_BuildList]
(
@minFragPercent TINYINT = 10,
@maxAttempts TINYINT = 25,
@databaseExcludeList VARCHAR(1000) = NULL,
@databaseIncludeList VARCHAR(1000) = NULL,
@tableExcludeList VARCHAR(1000) = NULL
)
/*
exec master.dbo.sp_SQLDefrag_BuildList @databaseIncludeList = 'Security,DBA'
*/

/*************************************************************************
**************************PARAMETERS EXPLAINED****************************
**************************************************************************/
/*
@minFragPercent		  - Minimum fragementation percentage to consider an 
						index
@maxAttempts		  - Maximum ammount of attempts to re-try the processing
						of an index if it is killed for blocking
@databaseExcludeList  - Databases to exclude from indexing
@databaseIncludeList  - Databases to include for indexing.  Only necissary
						to specify if you want to target one or two databases
						and exclude the rest
@tableExcludeList	  - Exclude certain tables from index operations
*/

AS

SET NOCOUNT ON

DECLARE @sqlCmd NVARCHAR(2000)
DECLARE @listlen INT
DECLARE @curpos INT
DECLARE @startloc INT
DECLARE @endloc INT
DECLARE @namelen INT
DECLARE @indexId TINYINT
DECLARE @objectId INT
DECLARE @indexName sysname
DECLARE @dbName sysname
DECLARE @invalidOnlineRowCount INT
DECLARE @dbNameCursor sysname
DECLARE @dbList TABLE(dbname sysname)
DECLARE @dbExclusions TABLE(dbname sysname)
DECLARE @excludedTableList TABLE(tablename sysname)
DECLARE	@ProductVersion NVARCHAR(128)
DECLARE	@ProductVersionNumber TINYINT

/*************************************************************************
****************************PREPARE VARIABLES*****************************
**************************************************************************/
/*As a global hardset, we do not wish to look at an index that is 
below 10% logical fragmentation*/

IF (@minFragPercent < 10)
BEGIN
	SET @minFragPercent = 10
END

SET @databaseExcludeList = NULLIF(LTRIM(RTRIM(@databaseExcludeList)), '')
SET @databaseIncludeList = NULLIF(LTRIM(RTRIM(@databaseIncludeList)), '')
SET @tableExcludeList = NULLIF(LTRIM(RTRIM(@tableExcludeList)), '')

SET @ProductVersion = CONVERT(NVARCHAR(128), SERVERPROPERTY('ProductVersion'))
SET @ProductVersionNumber = SUBSTRING(@ProductVersion, 1, (CHARINDEX('.', @ProductVersion) - 1))



/*************************************************************************
************************CREATE TRACKING TABLE*****************************
**************************************************************************/
/*Creates a table used by sp_SQLDefrag_ProcessList to perform index operations*/

IF (EXISTS (SELECT 1 FROM tempDB.sys.objects WITH (NOLOCK) WHERE name = 'SQLDefrag_List' AND type = 'U'))
BEGIN
	/*If you wish to do historical tracking, you can stop the truncate*/
	TRUNCATE TABLE tempDB.dbo.SQLDefrag_List
END
ELSE
BEGIN
	CREATE TABLE tempDB.dbo.SQLDefrag_List
	(
		RowID INT NOT NULL IDENTITY (1, 1),
		DatabaseName sysname NOT NULL,
		IndexID TINYINT NOT NULL,
		PartitionNumber TINYINT NOT NULL,
		ObjectID INT NOT NULL,
		SchemaName sysname NOT NULL,
		TableName sysname NOT NULL,
		IndexName sysname NOT NULL,
		FragPercentBefore FLOAT(3) NOT NULL,
		FragPercentAfter FLOAT(3) NOT NULL,
		IndexOnline BIT NOT NULL,
		SPID SMALLINT NULL,
		AttemptsLeft TINYINT NOT NULL,
		JobStatus VARCHAR(2) NOT NULL,
		BlockingMins TINYINT NOT NULL,
		StartTime DATETIME NULL,
		EndTime DATETIME NULL,
		Duration FLOAT NOT NULL
	) 
	
	ALTER TABLE tempDB.dbo.SQLDefrag_List ADD CONSTRAINT
	PK_SQLDefrag_List_RowID PRIMARY KEY CLUSTERED 
	(
		RowID
	) 	
END

/*************************************************************************
******************BUILD LIST OF DATABSES TO PROCESS***********************
**************************************************************************/
/*Uses @databaseExcludeList and @databaseIncludeList to determine which
databases are in scope for processing.
If you have multiple databases and wish to include only one or two, use
the includes.  If you have multiple database and wish to exclude only one
or two, use the excludes*/
IF ((@databaseExcludeList IS NOT NULL) AND (@databaseIncludeList IS NOT NULL))
BEGIN
	RAISERROR ('You must specify either an inclusion or exclusion list', 16, 1) WITH LOG
END

IF ((@databaseExcludeList IS NOT NULL) AND (@databaseIncludeList IS NULL))
BEGIN    
	
	SET @listlen = LEN(@databaseExcludeList)
	SET @curpos = 1
	WHILE @curpos <= @listlen
	BEGIN
		SET @startloc = @curpos		
		IF SUBSTRING(@databaseExcludeList, @curpos, 1) = '[' 
		BEGIN
			SET @endloc = CHARINDEX(']',@databaseExcludeList,@startloc) + 1
			IF @endloc = 0 
			BEGIN
				SET @endloc = @listlen
			END

			SET @namelen = @endloc-@startloc

			SET @curpos = CHARINDEX(',',@databaseExcludeList,@endloc) 
			IF @curpos = 0 
			BEGIN
				SET @curpos = @listlen + 1
			END
			ELSE
			BEGIN
				SET @curpos = @curpos + 1
			END
		END
		ELSE
		BEGIN 
			SET @endloc = CHARINDEX(',',@databaseExcludeList,@startloc)
			IF @endloc = 0 
			BEGIN
				SET @endloc = @listlen + 1
			END
			
			SET @namelen = @endloc-@startloc
			SET @curpos = @endloc + 1
		END
		
		INSERT INTO @dbExclusions (dbname)
		VALUES(LTRIM(RTRIM(SUBSTRING(@databaseExcludeList, @startloc, @namelen))))
	END

	INSERT INTO @dbList (dbname)
		SELECT	sd.name
		FROM	master.sys.databases sd WITH (NOLOCK)
		LEFT JOIN	@dbExclusions dbs
				ON	dbs.dbname = sd.name
		WHERE	sd.state_desc = 'ONLINE'
		AND		sd.is_read_only = 0
		AND		sd.user_access_desc = 'MULTI_USER'
		AND		sd.name NOT IN ('master', 'model', 'msdb', 'tempdb', 'distribution')
		AND		dbs.dbname IS NULL
		ORDER BY sd.name

END

ELSE IF (@databaseIncludeList IS NOT NULL)
BEGIN
	
	SET @listlen = LEN(@databaseIncludeList)
	SET @curpos = 1
	
	WHILE @curpos <= @listlen
	BEGIN
		SET @startloc = @curpos
				
		IF SUBSTRING(@databaseIncludeList, @curpos, 1) = '[' 
		BEGIN
			SET @endloc = CHARINDEX(']',@databaseIncludeList,@startloc) + 1
			IF @endloc = 0 
			BEGIN
				SET @endloc = @listlen
			END
			
			SET @namelen = @endloc-@startloc

			SET @curpos = CHARINDEX(',',@databaseIncludeList,@endloc) 
			IF @curpos = 0 
			BEGIN
				SET @curpos = @listlen + 1
			END
			ELSE
			BEGIN
				SET @curpos = @curpos + 1
			END
		END
		ELSE
		BEGIN
			SET @endloc = CHARINDEX(',',@databaseIncludeList,@startloc)
			IF @endloc = 0 
			BEGIN
				SET @endloc = @listlen + 1
			END
			
			SET @namelen = @endloc-@startloc
			SET @curpos = @endloc + 1
		END
		
		INSERT INTO @dbList (dbname)
		VALUES(LTRIM(RTRIM(SUBSTRING(@databaseIncludeList, @startloc, @namelen))))
	END
END
ELSE
BEGIN
	INSERT INTO @dbList (dbname)
		SELECT	sd.name
		FROM	master.sys.databases sd WITH (NOLOCK)
		WHERE	sd.state_desc = 'ONLINE'
		AND		sd.is_read_only = 0
		AND		sd.user_access_desc = 'MULTI_USER'
		AND		sd.name NOT IN ('master', 'model', 'msdb', 'tempdb', 'distribution')
		ORDER BY sd.name
END


/*************************************************************************
*******************EXCLUDE TABLE FROM INDEX OPERATIONS********************
**************************************************************************/

IF (@tableExcludeList IS NOT NULL)
BEGIN
 
	SET @listlen = LEN(@tableExcludeList)
	SET @curpos = 1
	
	WHILE @curpos <= @listlen
	BEGIN
		SET @startloc = @curpos
				
		IF SUBSTRING (@tableExcludeList, @curpos, 1) = '[' 
		BEGIN
			SET @endloc = CHARINDEX(']',@tableExcludeList,@startloc) + 1
			IF @endloc = 0 
			BEGIN
				SET @endloc = @listlen
			END
			
			SET @namelen = @endloc-@startloc

			SET @curpos = CHARINDEX(',',@tableExcludeList,@endloc) 
			IF @curpos = 0 
			BEGIN
				SET @curpos = @listlen + 1
			END
			ELSE
			BEGIN
				SET @curpos = @curpos + 1
			END
		END
		ELSE
		BEGIN
			SET @endloc = CHARINDEX(',',@tableExcludeList,@startloc)
			IF @endloc = 0 
			BEGIN
				SET @endloc = @listlen + 1
			END
			
			SET @namelen = @endloc-@startloc
			SET @curpos = @endloc + 1
		END

		INSERT INTO @excludedTableList (tablename)
		VALUES(LTRIM(RTRIM(SUBSTRING(@tableExcludeList, @startloc, @namelen))))
	END
END


/*************************************************************************
*******************DATABASE CURSOR AND SYNONYMS***************************
**************************************************************************/

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD 
FOR 
	SELECT dbname FROM @dbList

OPEN db_cursor
FETCH	NEXT	
FROM	db_cursor
INTO	@dbNameCursor

WHILE (@@FETCH_STATUS = 0)
BEGIN

	IF EXISTS (SELECT 1 FROM master.sys.synonyms WHERE name = 'syn_indexjob_db_sysindexes')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysindexes
	END
	
	IF EXISTS (SELECT 1 FROM master.sys.synonyms WHERE name = 'syn_indexjob_db_sysobjects')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysobjects
	END
	
	IF EXISTS (SELECT 1 FROM master.sys.synonyms WHERE name = 'syn_indexjob_db_sysschemas')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysschemas
	END
		
	IF EXISTS (SELECT 1 FROM master.sys.synonyms WHERE name = 'syn_indexjob_db_syscolumns')
	BEGIN
		DROP SYNONYM syn_indexjob_db_syscolumns
	END
		
	IF EXISTS (SELECT 1 FROM master.sys.synonyms WHERE name = 'syn_indexjob_db_sysindex_columns')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysindex_columns
	END
	
	SET @sqlCmd = 'CREATE SYNONYM syn_indexjob_db_sysindexes FOR ' + @dbNameCursor + '.sys.indexes'
	EXEC (@sqlCmd)

	SET @sqlCmd = 'CREATE SYNONYM syn_indexjob_db_sysobjects FOR ' + @dbNameCursor + '.sys.objects'
	EXEC (@sqlCmd)

	SET @sqlCmd = 'CREATE SYNONYM syn_indexjob_db_sysschemas FOR ' + @dbNameCursor + '.sys.schemas'
	EXEC (@sqlCmd)
	
	SET @sqlCmd = 'CREATE SYNONYM syn_indexjob_db_syscolumns FOR ' + @dbNameCursor + '.sys.columns'
	EXEC (@sqlCmd)
	
	SET @sqlCmd = 'CREATE SYNONYM syn_indexjob_db_sysindex_columns FOR ' + @dbNameCursor + '.sys.index_columns'
	EXEC (@sqlCmd)

/*************************************************************************
*********** POPULATE TEMP TABLE TO TRACK ITEMS TO BE INDEXED**************
**************************************************************************/
	--DatabaseName 
	--IndexID
	--PartitionNumber
	--ObjectID
	--SchemaName
	--TableName
	--IndexName
	--FragPercentBefore
	--FragPercentAfter
	--IndexOnline
	--SPID
	--AttemptsLeft
	--JobStatus
	--BlockingMins
	--Duration
	

	INSERT INTO tempDB.dbo.SQLDefrag_List (DatabaseName, IndexID, PartitionNumber, ObjectID,
		SchemaName, TableName, IndexName, FragPercentBefore, FragPercentAfter, IndexOnline, SPID,
		AttemptsLeft, JobStatus, BlockingMins, Duration) 
		SELECT	@dbNameCursor AS 'DatabaseName', ri.index_id AS 'IndexID',
				partition_number AS 'PartitionNumber', ro.object_id AS 'ObjectID',
				rs.name AS 'SchemaName', ro.name AS 'TableName', ri.name AS 'IndexName',
				avg_fragmentation_in_percent AS 'FragPercentBefore', 0 AS 'FragPercentAfter',
				0 AS 'IndexOnline', 0 AS 'SPID', @maxAttempts AS 'AttemptsLeft', 'U' AS 'JobStatus',
				0 AS 'BlockingMins', 0 AS 'Duration'
		FROM sys.dm_db_index_physical_stats (DB_ID(@dbNameCursor), NULL, NULL, NULL, 'LIMITED')
		INNER JOIN master.dbo.syn_indexjob_db_sysindexes ri
				ON sys.dm_db_index_physical_stats.object_id = ri.object_id
				AND sys.dm_db_index_physical_stats.index_id = ri.index_id
		INNER JOIN master.dbo.syn_indexjob_db_sysobjects ro
				ON sys.dm_db_index_physical_stats.object_id = ro.object_id
		INNER JOIN master.dbo.syn_indexjob_db_sysschemas rs
				ON ro.schema_id = rs.schema_id
		LEFT JOIN @excludedTableList tab
				ON tab.tablename = ro.name
		WHERE	ro.type_desc = 'USER_TABLE'
		AND		partition_number < 2 --remove this AND if you want to reindex/reorg based on partition
		AND		avg_fragmentation_in_percent >= @minFragPercent 
		AND		ri.index_id > 0
		AND		index_depth > 0
		AND		alloc_unit_type_desc <> 'LOB_DATA'
		AND		tab.tablename IS NULL

	/*********************************************
	**************variables explained*************
	**********************************************/
	/* -- (NOTE: some of this taken from SQL Server Booksonline and MSDN)
	index_depth: 
		Number of index levels. 
		1 = Heap, or LOB_DATA or ROW_OVERFLOW_DATA allocation unit.

	partition_number:
		This was added in as a scalability feature.  Note, you can NOT
		index a partition online in 2005.  You can index a partition tabled online.
		If we simply returned and processed all results, two things could happen.
		We would issue index commands multiple times per table because of the partiitons, 
		or perform an offline operation when we don't want to by issuing an index
		command to one of the partitions.  I am leaving it up to the user to extend
		this proc and Index_ProcessIndexes to perform operation on individual partitions
		if their shop requires the functionality.    
		
	Description of the allocation unit type:
		IN_ROW_DATA
		LOB_DATA
		ROW_OVERFLOW_DATA
		
		The LOB_DATA allocation unit contains the data that is 
		stored in columns of type text, ntext, image, varchar(max), nvarchar(max), 
		varbinary(max), and xml. For more information, see Data Types (Transact-SQL).
		
		By default, the ALTER INDEX REORGANIZE statement compacts pages that contain
		large object (LOB) data. Because LOB pages are not deallocated when empty, 
		compacting this data can improve disk space use if lots of LOB data have been 
		deleted, or a LOB column is dropped. 
		
		Reorganizing a specified clustered index compacts all LOB columns that are 
		contained in the clustered index. Reorganizing a nonclustered index compacts 
		all LOB columns that are nonkey (included) columns in the index. When ALL is 
		specified in the statement, all indexes that are associated with the specified 
		table or view are reorganized. Additionally, all LOB columns that are associated 
		with the clustered index, underlying table, or nonclustered index with included 
		columns are compacted.*/
		
		/*************************************************************************
		*********** DETERMIN IF WE CAN REBUILD ONLINE OR NOT *********************
		**************************************************************************/
		/*Yes I know an ugly embeded cursor.  It was this or creating 6 synonyms 
		over and over again or dynamic sql*/
		DECLARE online_cur CURSOR LOCAL FAST_FORWARD 
		FOR
			SELECT	DatabaseName, IndexName, IndexID, ObjectID
			FROM	tempDB.dbo.SQLDefrag_List
			WHERE	DatabaseName = @dbNameCursor

		OPEN online_cur

		FETCH	NEXT
		FROM	online_cur
		INTO	@dbName, @indexName, @indexId, @objectId


		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			/*Initialize to 1 to default to non-online operations*/
			SET @invalidOnlineRowCount = 1
			/*We only need to do this check if engine edition is Enterprise/Developer
			you can't use online indexing in anything but Enterprise/Developer
			I check product version number just in case someone decides to run this in 2000*/
			IF ((SERVERPROPERTY('EngineEdition') = 3 ) AND (@ProductVersionNumber >= 9))
			BEGIN
				/*Checks for 'text', 'ntext', 'image', 'varchar(max)', 'nvarchar(max)', 'varbinary(max)', 'xml' 
				  These types cant be indexed online*/
				
				/*If index is clustered, any column of the above type in the table (even if not in the index)
				means we can not perform an online operation*/
				
				/*If clustered, check all columns*/
				IF (@indexId = 1)
				BEGIN
					--SELECT 'CLUSTERED'
					SELECT @invalidOnlineRowCount = COUNT(*) 
					FROM master.dbo.syn_indexjob_db_sysobjects so WITH (NOLOCK)
					INNER JOIN master.dbo.syn_indexjob_db_syscolumns sc 
						ON so.Object_id = sc.object_id 
					INNER JOIN sys.types st 
						ON sc.system_type_id = st.system_type_id 
						AND (
								st.name IN ('text', 'ntext', 'image', 'xml')
							OR	(
									st.name IN ('varchar', 'nvarchar', 'varbinary')
								AND sc.max_length = -1
								)
							)
					WHERE so.Object_ID = @objectID 
				/*If non-clustered, check the cols in the index for the specific types*/  
				END
				ELSE
				BEGIN
					--SELECT 'NONCLUSTERED'
					SELECT @invalidOnlineRowCount = COUNT(*)
					FROM master.dbo.syn_indexjob_db_sysobjects so WITH (NOLOCK)
					INNER JOIN master.dbo.syn_indexjob_db_sysindex_columns sic 
						ON so.Object_ID = sic.object_id 
					INNER JOIN master.dbo.syn_indexjob_db_sysindexes si 
						ON so.Object_ID = si.Object_ID 
						and sic.index_id = si.index_id 
					INNER JOIN master.dbo.syn_indexjob_db_syscolumns sc 
						ON so.Object_id = sc.object_id 
						and sic.Column_id = sc.column_id 
					INNER JOIN sys.types st 
						ON sc.system_type_id = st.system_type_id 
						AND (
								st.name IN ('text', 'ntext', 'image', 'xml')
							OR	(
										st.name IN ('varchar', 'nvarchar', 'varbinary')
								AND		sc.max_length = -1
								)
							)
					WHERE so.Object_ID = @objectID 
				END
			END
			
			/*To add partition separation we would add AND PartitionNumber = @partitionID (have to define in cursor above)
			but since we have partition_id < 2 we are only getting the primary partition so it is not needed*/
			UPDATE	tempDB.dbo.SQLDefrag_List
			SET		IndexOnline = CASE @invalidOnlineRowCount WHEN 0 THEN 1 ELSE 0 END
			WHERE	IndexID = @indexId
			AND		ObjectID = @objectId
			AND		DatabaseName = @dbName
			AND		IndexName = @indexName

			FETCH	NEXT
			FROM	online_cur
			INTO	@dbName, @indexName, @indexId, @objectId
		END

		CLOSE online_cur
		DEALLOCATE online_cur

	FETCH	NEXT
	FROM	db_cursor
	INTO	@dbNameCursor
END
CLOSE db_cursor
DEALLOCATE db_cursor



BEGIN
	IF EXISTS (SELECT 1 FROM master.sys.synonyms WITH (NOLOCK) WHERE name = 'syn_indexjob_db_sysindexes')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysindexes
	END
	
	IF EXISTS (SELECT 1 FROM master.sys.synonyms WITH (NOLOCK) WHERE name = 'syn_indexjob_db_sysobjects')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysobjects
	END
	
	IF EXISTS (SELECT 1 FROM master.sys.synonyms WITH (NOLOCK) WHERE name = 'syn_indexjob_db_sysschemas')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysschemas
	END
		
	IF EXISTS (SELECT 1 FROM master.sys.synonyms WITH (NOLOCK) WHERE name = 'syn_indexjob_db_syscolumns')
	BEGIN
		DROP SYNONYM syn_indexjob_db_syscolumns
	END
		
	IF EXISTS (SELECT 1 FROM master.sys.synonyms WITH (NOLOCK) WHERE name = 'syn_indexjob_db_sysindex_columns')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysindex_columns
	END
END

GO

USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

USE [master]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_SQLDefrag_ProcessList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_SQLDefrag_ProcessList]
GO

CREATE PROCEDURE [dbo].[sp_SQLDefrag_ProcessList]
(
@reorgMinFragPercent TINYINT = 10,
@rebuildMinFragPercent TINYINT = 20,
@onlineOnly BIT = 0,
@reorgNonOnlines BIT = 0, 
@globalAllowReorgs BIT = 1
)
/*
exec master.dbo.sp_SQLDefrag_ProcessList @onlineOnly = 1
*/

/*************************************************************************
**************************PARAMETERS EXPLAINED****************************
**************************************************************************/
/*
@reorgMinFragPercent	- Minimum fragmentation percentage to be considered for
						  a reorg
@rebuildMinFragPercent  - Minimum fragmentation percentage to be considered for
						  a reorg
	NOTE: If you set @reorgMinFragPercent and @rebuildMinFragPercent equal,
		  only index rebuilds will occur (unless you change the below options)	  
							  
@onlineOnly				- BIT to specify only perform online index rebuilds. 
						  If this is set to 0, indexes above the @rebuildMinFragPercent
						  will be rebuilt offline
						  
@reorgNonOnlines BIT	- BIT to specify the handling of indexes which cannot be
						  rebuilt online.  If @onlineOnly set to 0, they will be
						  rebuilt offline.  If @reorgNonOnlines set to 1, they
						  will be reorganized.
						  
	NOTE: If @onlineOnly is set to 1 and @reorgNonOnlines is set to 0, all indexes
		  which can not be rebuilt online will be ignored
				 
@globalAllowReorgs			- Global bit trigger to turn on reorganizing. Just a
						  safety check.

*/
AS

SET NOCOUNT ON

DECLARE @databaseName VARCHAR(255)
DECLARE @schemaName VARCHAR(255)
DECLARE @objectName VARCHAR(255)
DECLARE @indexName VARCHAR(255)
DECLARE @fragPercent DECIMAL
DECLARE @sqlCmd VARCHAR(500)
DECLARE @indexId TINYINT
DECLARE @partitionNumber TINYINT
DECLARE @objectId INT
DECLARE @indexOnline BIT
DECLARE @spid SMALLINT 
DECLARE	@attemptsLeft TINYINT
DECLARE @jobStatus VARCHAR(2) -- can be 1 or 2 chars (see Status Key below)
DECLARE @emessage VARCHAR(5000)
DECLARE @retryCount SMALLINT 
DECLARE @beforeTimeStamp DATETIME
DECLARE @afterTimeStamp DATETIME
DECLARE @jobDuration FLOAT(2)
DECLARE @finalJobStatus varchar(2)
DECLARE @currentJobStatus varchar(2)

/*******************
*****STATUS KEY*****
********************/
--U		= Unprocessed
--I		= Ignore (used if we want to ignore non-online indexable items)
--DR	= Reorg Running/Retry
--RR	= Rebuild Running/Retry
--F		= Failed
--PR	= Processed Rebuild
--PD	= Processed Reorg/Defrag
--D		= Defrag/reorg


/*No point to start this job if there are no indexes to process*/
IF (EXISTS(SELECT 1 FROM tempdb.dbo.SQLDefrag_List WITH (NOLOCK) WHERE JobStatus = 'U'))
BEGIN

	/*Just in case someone happens to update the SQLDefrag_List for whatever
	reason and sets the FragPercentBefore at a lower number than 
	@reorgMinFragPercent*/
	UPDATE	tempdb.dbo.SQLDefrag_List 
	SET		JobStatus = 'P'
	WHERE	FragPercentBefore < @reorgMinFragPercent


	/*************************************************************************
	**************SET JOBS TO IGNORE IF ONLINE ONLY BIT ENABLED***************
	**************************************************************************/
	/*This only applies to rebuild scenarios*/
	IF (@onlineOnly = 1)
	/*We dont add AND @reorgNonOnlines = 1 as a double check to ensure
	JobStatus is always set to I regardless of @reorgNonOnlines*/
	BEGIN
		UPDATE	tempdb.dbo.SQLDefrag_List 
		SET		JobStatus = 'I'
		WHERE	IndexOnline = 0
		--AND		FragPercentBefore >= @rebuildMinFragPercent
	END
		
	/*************************************************************************
	***********SET JOBS TO DEFRAG IF ONLINE REINDEX CANT BE PERFORMED*********
	**************************************************************************/
	/*This only applies to rebuild scenarios*/
	IF ((@onlineOnly = 1) AND (@reorgNonOnlines = 1) AND (@globalAllowReorgs = 1))
	BEGIN
		UPDATE	tempdb.dbo.SQLDefrag_List 
		SET		JobStatus = 'D'
		WHERE	IndexOnline = 0
		AND		JobStatus = 'I'
		AND		FragPercentBefore >= @rebuildMinFragPercent
	END
		
	/*************************************************************************
	***********TRIPLE CHECK TO ENSURE DEFRAGS ARE NOT GOING TO HAPPEN*********
	**************************************************************************/
	IF (@globalAllowReorgs = 0)
	BEGIN
		UPDATE	tempdb.dbo.SQLDefrag_List 
		SET		JobStatus = 'I'
		WHERE	(JobStatus = 'D')
				OR (FragPercentBefore < @rebuildMinFragPercent)
	END

	/*************************************************************************
	************SELECT AN EXISTING INDEX IF IT IS MARKED AS RETRY*************
	**************************************************************************/
	WHILE (EXISTS(SELECT 1 FROM tempdb.dbo.SQLDefrag_List WITH (NOLOCK) WHERE JobStatus IN ('U', 'R', 'D')))
	BEGIN
	
		/*************************************************************************
		**************FAIL ALL JOBS WITH 0 ATTEMPTS LEFT**************************
		**************************************************************************/
		/*Put here to avoid any type of infinite loop*/
		UPDATE	tempdb.dbo.SQLDefrag_List 
		SET		JobStatus = 'F'
		WHERE	AttemptsLeft <= 0 

		/*If we have a job in retry status, we want to retry it 
		instead of starting a new index operation*/
		SELECT	@retryCount = COUNT(*)
		FROM	tempdb.dbo.SQLDefrag_List WITH (NOLOCK)
		WHERE	JobStatus = 'DR'


		IF (@retryCount > 0)
		BEGIN
			DECLARE index_list CURSOR LOCAL FAST_FORWARD 
			FOR
				SELECT	DatabaseName, IndexID, PartitionNumber, ObjectID, SchemaName, TableName, IndexName, FragPercentBefore, IndexOnline, SPID, AttemptsLeft, JobStatus
				FROM	tempdb.dbo.SQLDefrag_List WITH (NOLOCK)
				WHERE	JobStatus = 'DR'
				ORDER BY AttemptsLeft ASC
		END
		ELSE
		BEGIN
			IF ((@onlineOnly = 1) AND ((@reorgNonOnlines = 0 OR @globalAllowReorgs = 0)))
			BEGIN
				DECLARE index_list CURSOR LOCAL FAST_FORWARD 
					FOR
					SELECT	DatabaseName, IndexID, PartitionNumber, ObjectID, SchemaName, TableName, IndexName, FragPercentBefore, IndexOnline, SPID, AttemptsLeft, JobStatus
					FROM	tempdb.dbo.SQLDefrag_List WITH (NOLOCK)
					WHERE	JobStatus = 'U'
					/*indexOnline is a double check as we set JobStatus to I above to ignore
					operations that can not be done online*/
					AND		IndexOnline = 1
					/*Let's hit the online operations first so we don't get tied up with lengthy reorgs*/
					ORDER BY IndexOnline DESC, IndexID, DatabaseName, TableName ASC
					/*Important to hit clustered indexes first*/
			END
			ELSE IF @onlineOnly = 1 AND @reorgNonOnlines = 1 AND @globalAllowReorgs = 1
			BEGIN
				DECLARE index_list CURSOR LOCAL FAST_FORWARD  
					FOR
					SELECT	DatabaseName, IndexID, PartitionNumber, ObjectID, SchemaName, TableName, IndexName, FragPercentBefore, IndexOnline, SPID, AttemptsLeft, JobStatus
					FROM	tempdb.dbo.SQLDefrag_List WITH (NOLOCK)
					WHERE	JobStatus IN ('U','D')
					ORDER BY IndexOnline DESC, IndexID, DatabaseName, TableName ASC
			END
			ELSE
			BEGIN
				DECLARE index_list CURSOR LOCAL FAST_FORWARD  
					FOR
					SELECT	DatabaseName, IndexID, PartitionNumber, ObjectID, SchemaName, TableName, IndexName, FragPercentBefore, IndexOnline, SPID, AttemptsLeft, JobStatus
					FROM	tempdb.dbo.SQLDefrag_List WITH (NOLOCK)
					WHERE	JobStatus IN ('U','D')
					ORDER BY IndexOnline DESC, IndexID, DatabaseName, TableName ASC
			END
		END

	/*************************************************************************
	*******************************INDEX JOB**********************************
	**************************************************************************/

		OPEN index_list
	
		FETCH	NEXT
		FROM	index_list
		INTO	@databaseName, @indexId, @partitionNumber, @objectId, @schemaName, @objectName, @indexName, @fragPercent, @indexOnline, @spid, @attemptsLeft, @jobStatus
	    
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			/*Reorganize if lower than @rebuildMinFragPercent yet greater than @reorgMinFragPercent
			If lower than @reorgMinFragPercent we do nothing
			If greater than @rebuildMinFragPercent yet jobstatus is D, we want to reorg because it can't be rebuilt online*/
			IF (@fragPercent >= @reorgMinFragPercent AND @fragPercent < @rebuildMinFragPercent) OR (@jobStatus = 'D' AND @indexOnline = 0)
			BEGIN
				SET @finalJobStatus = 'PD'
				SET @currentJobStatus = 'DR'
				SET @sqlCmd = 'ALTER INDEX [' + @indexName + '] ON [' + @databaseName + '].[' + @schemaName + '].[' + @objectName + '] REORGANIZE' --Partition = ' + CAST(@partitionNumber AS varchar(2))
			END
			/*If frag percentage is greater than the @rebuildMinFragPercent, we rebuild
			online if we can*/
			ELSE IF @fragPercent >= @rebuildMinFragPercent
				BEGIN
					SET @finalJobStatus = 'PR'
					SET @currentJobStatus = 'RR'
					SET @sqlCmd = 'ALTER INDEX [' + @indexName + '] ON [' + @databaseName + '].[' + @schemaName + '].[' + @objectName + '] REBUILD' --Partition = ' + CAST(@partitionNumber AS varchar(2))

						/*I like to sort in tempdb, but if you don't have the space or don't 
						want to I suggest adding a BIT trigger to control this*/
						IF @indexOnline = 0
								 Set @sqlCmd = @sqlCmd + ' WITH (SORT_IN_TEMPDB = ON) ' 
						ELSE
								 Set @sqlCmd = @sqlCmd + ' WITH (ONLINE = ON, SORT_IN_TEMPDB = ON) ' 
					   
					
				END	
					
				BEGIN TRY
					UPDATE	tempdb.dbo.SQLDefrag_List
					SET		AttemptsLeft = @attemptsLeft - 1, SPID = @@spid, JobStatus = @currentJobStatus
					WHERE	IndexName = @indexName
					AND		TableName = @objectName
					AND		PartitionNumber = @partitionNumber

					--SELECT convert(char(20) ,getdate()) + 'Executing Command ' + @sqlCmd
					SET @beforeTimeStamp = GETDATE()
					
					print @sqlCmd
					EXEC (@sqlCmd)
					
					SET @afterTimeStamp = GETDATE()
					
					SET @jobDuration = (CAST(DATEDIFF(SECOND, @beforeTimeStamp, @afterTimeStamp) AS FLOAT(2))) / 60

					UPDATE	tempdb.dbo.SQLDefrag_List
					SET		JobStatus = @finalJobStatus,
							StartTime = @beforeTimeStamp,
							EndTime = @afterTimeStamp,
							Duration = @jobDuration
					WHERE	DatabaseName = @databaseName
					AND		IndexName = @indexName
					AND		TableName = @objectName
					AND		PartitionNumber = @partitionNumber

				END TRY
				BEGIN CATCH
					UPDATE	tempdb.dbo.SQLDefrag_List
					SET		JobStatus = 'F',
							Duration = @jobDuration
					WHERE	DatabaseName = @databaseName
					AND		IndexName = @indexName
					AND		TableName = @objectName
					AND		PartitionNumber = @partitionNumber
					
					SET @emessage = 'The following command failed to execute: ' + @sqlCmd + ' ' + ERROR_MESSAGE()
					EXEC master.dbo.xp_logevent 99999, @emessage, informational
				END CATCH
					
			FETCH	NEXT
			FROM	index_list
			INTO	@databaseName, @indexId, @partitionNumber, @objectId, @schemaName, @objectName, @indexName, @fragPercent, @indexOnline, @spid, @attemptsLeft, @jobStatus

		END /* @@FETCH_STATUS = 0 */
		CLOSE index_list
		DEALLOCATE index_list
	    
	END /* WHILE EXISTS(SELECT FROM SQLDefrag_List */

END /* IF (EXISTS(SELECT FROM SQLDefrag_List WHERE JobStatus = 'U')) */

GO

USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

USE [master]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_SQLDefrag_PostUpdate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_SQLDefrag_PostUpdate]
GO

CREATE PROCEDURE [dbo].[sp_SQLDefrag_PostUpdate] 
AS

SET NOCOUNT ON

DECLARE @sqlCmd VARCHAR(500)
DECLARE @dbNameCursor sysname


/*************************************************************************
************************CREATE TRACKING TABLE*****************************
**************************************************************************/
/*Create a temp table to gather only the necessary information*/

IF (OBJECT_ID('tempdb.dbo.#IndexPostProcessList') IS NOT NULL)
BEGIN
   DROP TABLE #IndexPostProcessList
END

BEGIN
	CREATE TABLE #IndexPostProcessList
	(
		DatabaseName VARCHAR(255),
		IndexID TINYINT,
		PartitionNumber TINYINT,
		ObjectID INT,
		TableName VARCHAR(255),
		IndexName VARCHAR(255),
		FragPercentAfter FLOAT(3)
	)
END


/*************************************************************************
*******************DATABASE CURSOR AND SYNONYMS***************************
**************************************************************************/

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD  
FOR 
	SELECT		DISTINCT DatabaseName 
	FROM		tempdb.dbo.SQLDefrag_List WITH (NOLOCK)
	ORDER BY	DatabaseName ASC

OPEN	db_cursor

FETCH	NEXT
FROM	db_cursor 
INTO	@dbNameCursor

WHILE (@@FETCH_STATUS = 0)
BEGIN

	IF EXISTS (SELECT 1 FROM master.sys.synonyms WITH (NOLOCK) WHERE name = 'syn_indexjob_db_sysindexes')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysindexes
	END
	
	IF EXISTS (SELECT 1 FROM master.sys.synonyms WITH (NOLOCK) WHERE name = 'syn_indexjob_db_sysobjects')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysobjects
	END
	
	IF EXISTS (SELECT 1 FROM master.sys.synonyms WITH (NOLOCK) WHERE name = 'syn_indexjob_db_sysschemas')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysschemas
	END
		
	--create new
	SET @sqlCmd = 'CREATE SYNONYM syn_indexjob_db_sysindexes FOR ' + @dbNameCursor + '.sys.indexes'
	EXEC (@sqlCmd)

	SET @sqlCmd = 'CREATE SYNONYM syn_indexjob_db_sysobjects FOR ' + @dbNameCursor + '.sys.objects'
	EXEC (@sqlCmd)

	SET @sqlCmd = 'CREATE SYNONYM syn_indexjob_db_sysschemas FOR ' + @dbNameCursor + '.sys.schemas'
	EXEC (@sqlCmd)


	INSERT INTO #IndexPostProcessList (DatabaseName, IndexID, PartitionNumber, ObjectID, TableName,
					IndexName, FragPercentAfter)
	SELECT	@dbNameCursor AS 'DatabaseName', ri.index_id AS 'IndexID', 
			partition_number AS 'PartitionNumber', ro.object_id AS 'ObjectID',
			ro.name AS 'TableName',	ri.name AS 'IndexName', 
			avg_fragmentation_in_percent AS 'FragPercentAfter'
	FROM sys.dm_db_index_physical_stats (DB_ID(@dbNameCursor),null,null,null,'LIMITED')
	INNER JOIN master.dbo.syn_indexjob_db_sysindexes ri
			ON sys.dm_db_index_physical_stats.object_id = ri.object_id
			AND sys.dm_db_index_physical_stats.index_id = ri.index_id
	INNER JOIN master.dbo.syn_indexjob_db_sysobjects ro
			ON sys.dm_db_index_physical_stats.object_id = ro.object_id
	INNER JOIN master.dbo.syn_indexjob_db_sysschemas rs
			ON ro.schema_id = rs.schema_id
	WHERE	ro.type_desc = 'USER_TABLE'
	AND		partition_number < 2
	AND		ri.index_id > 0
	AND		index_depth > 0
	AND		alloc_unit_type_desc <> 'LOB_DATA'

	FETCH		NEXT
	FROM		db_cursor
	INTO		@dbNameCursor
	
END

CLOSE db_cursor
DEALLOCATE db_cursor

BEGIN

	UPDATE	ijpl
	SET		ijpl.FragPercentAfter = ippl.FragPercentAfter
	FROM	#IndexPostProcessList ippl
	INNER JOIN	tempdb.dbo.SQLDefrag_List ijpl
			ON	ippl.DatabaseName = ijpl.DatabaseName
			AND	ippl.IndexName = ijpl.IndexName
			AND	ippl.IndexID = ijpl.IndexID
			AND	ippl.ObjectID = ijpl.ObjectID
			AND	ippl.TableName = ijpl.TableName
			AND	ippl.PartitionNumber = ijpl.PartitionNumber
			
END	 

BEGIN

	IF EXISTS (SELECT 1 FROM master.sys.synonyms WITH (NOLOCK) WHERE name = 'syn_indexjob_db_sysindexes')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysindexes
	END
	
	IF EXISTS (SELECT 1 FROM master.sys.synonyms WITH (NOLOCK) WHERE name = 'syn_indexjob_db_sysobjects')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysobjects
	END
	
	IF EXISTS (SELECT 1 FROM master.sys.synonyms WITH (NOLOCK) WHERE name = 'syn_indexjob_db_sysschemas')
	BEGIN
		DROP SYNONYM syn_indexjob_db_sysschemas
	END

END

GO

USE [msdb]
GO
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscateGOries WHERE name=N'[UncateGOrized (Local)]' AND cateGOry_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_cateGOry @class=N'JOB', @type=N'LOCAL', @name=N'[UncateGOrized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Database Defrag', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This jobs defrags user databases.', 
		@cateGOry_name=N'[UncateGOrized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=@job_notify_email, @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Build list to defrag', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec master.dbo.sp_SQLDefrag_BuildList @databaseIncludeList = ''list,databases,here''

', 
		@database_name=N'master', 
		@output_file_name=@step_output_file, 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Defragging', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec master.dbo.sp_SQLDefrag_ProcessList @onlineOnly = 1
', 
		@database_name=N'master', 
		@output_file_name=@step_output_file, 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Capture new fragmentation', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec master.dbo.sp_SQLDefrag_PostUpdate
', 
		@database_name=N'master', 
		@output_file_name=@step_output_file, 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Report on Defragging', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'select * from tempdb.dbo.SQLDefrag_List
', 
		@database_name=N'master', 
		@output_file_name=@step_output_file, 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every Tuesday @10AM', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=4, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20090529, 
		@active_end_date=99991231, 
		@active_start_time=100000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

