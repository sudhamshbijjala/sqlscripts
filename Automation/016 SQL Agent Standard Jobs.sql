---  016 SQL Agent Standard jobs


/****** Object:  Job [Alert - Data Used Space Exceeds Threshold]    Script Date: 08/08/2013 15:34:41 ******/
/****** Object:  Job [Alert - Disk Space Falls Short]    Script Date: 08/08/2013 15:36:03 ******/
/****** Object:  Job [ASA DBCC UPDATEUSAGE]    Script Date: 08/08/2013 15:37:45 ******/
/****** Object:  Job [ASA Performance Collector]    Script Date: 08/08/2013 15:40:15 ******/
/****** Object:  Job [ASA Update Statistics - User Databases]    Script Date: 08/08/2013 15:43:45 ******/
/****** Object:  Job [Change_Data_Capture]    Script Date: 08/08/2013 15:45:24 ******/
/****** Object:  Job [Client - DBA Monitoring]    Script Date: 08/08/2013 15:46:25 ******/


/*
@output_file_name=N'M:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\dbcc_update_usage.txt',
@output_file_name=N'M:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\sp_update_statistics_result.txt',  

M:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER


Msg 14261, Level 16, State 1, Procedure sp_verify_job, Line 57
The specified @name ('Client - DBA Monitoring') already exists.

*/
USE [msdb]
GO

/****** Object:  Job [Alert - Data Used Space Exceeds Threshold]    Script Date: 08/08/2013 15:34:41 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/08/2013 15:34:41 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Alert - Data Used Space Exceeds Threshold', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'AMSA\svProdSQLAgentExec', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Data Used Space]    Script Date: 08/08/2013 15:34:42 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Data Used Space', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--  Script:    Check used part of a data file
--  Author:    Richard Ding
--  Written:   9/9/2009
--  Use:       Monitor database file usage. Alert DBAs when manual expansion is needed.
--             Currently on threshold of 90% full. Runs job every 15 minutes.

SET NOCOUNT ON;

IF OBJECT_ID(''tempdb.dbo.SHOWFILESTATS'', ''U'') IS NULL
  CREATE TABLE tempdb.dbo.SHOWFILESTATS (
    Id INT IDENTITY, 
    DatabaseName SYSNAME not NULL DEFAULT DB_NAME(), 
    FileId INT NULL, 
    FileGroup INT NULL, 
    TotalExtents BIGINT NULL, 
    UsedExtents BIGINT NULL, 
    UsedPercent DEC(4, 1) NULL,
    Name SYSNAME NULL, 
    PhysicalPath VARCHAR(255) NULL,
    RunTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP );
ELSE
  TRUNCATE TABLE tempdb.dbo.SHOWFILESTATS;

DECLARE @dbname SYSNAME;
SELECT @dbname = '''';

WHILE 1=1
BEGIN
  SELECT TOP 1 @dbname = name FROM sys.databases 
    WHERE name > @dbname AND [state] = 0 AND database_id <> 3 ORDER BY name ASC;
  IF @@ROWCOUNT = 0
    BREAK;   
  EXEC (''USE '' + @dbname + '' INSERT INTO tempdb.dbo.SHOWFILESTATS 
         (FileId,FileGroup,TotalExtents,UsedExtents,Name,PhysicalPath)
         EXEC (''''DBCC SHOWFILESTATS WITH NO_INFOMSGS'''')'');
  UPDATE tempdb.dbo.SHOWFILESTATS SET UsedPercent = UsedExtents*100.0/TotalExtents;
END

IF EXISTS (SELECT * FROM tempdb.dbo.SHOWFILESTATS WHERE UsedPercent > 90.0)
  BEGIN
    DECLARE @p_name VARCHAR(30),
            @r_name VARCHAR(50),
            @sub VARCHAR(100),
            @q VARCHAR(MAX);

    SELECT @p_name=@@SERVERNAME, 
           @r_name=''hjain@asa.org;tflaherty@asa.org'', 
           @sub=''Alert - Data File Used Space > 90 %'', 
           @q = ''SELECT LEFT(DatabaseName, 20) AS ''''Database Name'''',
                 LEFT(Name, 20) AS ''''Logical Name'''',
                 LEFT(PhysicalPath, 50) AS ''''Path'''',
                 UsedPercent AS ''''Data Used %''''
                 FROM tempdb.dbo.SHOWFILESTATS
                 WHERE UsedPercent > 90.0 ORDER BY Id ASC'';
   
    EXEC msdb.dbo.SP_SEND_DBMAIL
      @profile_name = @p_name,
      @recipients = @r_name,
      @query = @q,
      @subject = @sub;
      
  END', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 1 hour', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130406, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'137ca1f4-5cc7-4164-bdc6-c6a576cd5e89'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-------------------------------------------
USE [msdb]
GO

/****** Object:  Job [Alert - Disk Space Falls Short]    Script Date: 08/08/2013 15:36:03 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/08/2013 15:36:03 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Alert - Disk Space Falls Short', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'AMSA\svProdSQLAgentExec', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [check disk drive space]    Script Date: 08/08/2013 15:36:03 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'check disk drive space', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--  Script:     Monitor disk space (total, free, and free%) on all drives and alert DBA
--  Created by: Richard Ding
--  Date:       9/10/2009


SET NOCOUNT ON;

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

DECLARE @hr INT, @fso INT, @Drive CHAR(1), @oDrive INT, @TotalSize VARCHAR(20);
SELECT @hr = 0, @fso = 0, @Drive = '''', @oDrive = 0, @TotalSize = '''';

EXEC @hr=sp_OACreate ''Scripting.FileSystemObject'',@fso OUT;
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso;

WHILE 1 = 1
  BEGIN
    SELECT TOP 1 @Drive = Drive FROM tempdb.dbo.Drive WHERE Drive > @Drive ORDER BY Drive ASC
    IF @@ROWCOUNT = 0
      BREAK;
      
    EXEC @hr = sp_OAMethod @fso, ''GetDrive'', @oDrive OUT, @Drive;
    IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso;
    
    EXEC @hr = sp_OAGetProperty @oDrive, ''TotalSize'', @TotalSize OUT;
    IF @hr <> 0 EXEC sp_OAGetErrorInfo @oDrive;
                    
    UPDATE tempdb.dbo.Drive
    SET [TotalSize (GB)] = @TotalSize / (1024.0 * 1024.0 * 1024.0),
        [FreeSpace (GB)] = [FreeSpace (GB)] / 1024.0
    WHERE Drive = @Drive;
  END

EXEC @hr=sp_OADestroy @fso;
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso;
GO  --  needed to suppress OLE error for sp_send_dbmail

IF EXISTS (SELECT * FROM tempdb.dbo.Drive WHERE ([FreeSpace (GB)] < 1.00 OR [Free (%)] < 10.0) AND Drive <> ''Q'')
  BEGIN
    DECLARE @p_name VARCHAR(30),
            @r_name VARCHAR(50),
            @sub VARCHAR(100),
            @q VARCHAR(MAX);

    SELECT @p_name=@@SERVERNAME, 
           @r_name=''hjain@asa.org;rpatel@asa.org'', 
           @sub=''Alert - Disk Free Space < 1 GB or 10%'', 
           @q = ''SELECT left(@@servername, 25) AS ''''SQL Server'''', * FROM tempdb.dbo.Drive WHERE ([FreeSpace (GB)] < 1.00 OR [Free (%)] < 10.0) AND Drive <> ''''Q'''''';
   
    EXEC msdb.dbo.SP_SEND_DBMAIL
      @profile_name = @p_name,
      @recipients = @r_name,
      @query = @q,
      @subject = @sub;
      
  END      
GO', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 1 hour', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130406, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'137ca1f4-5cc7-4164-bdc6-c6a576cd5e89'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-----------------------------------------------------
USE [msdb]
GO

/****** Object:  Job [ASA DBCC UPDATEUSAGE]    Script Date: 08/08/2013 15:37:45 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/08/2013 15:37:45 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ASA DBCC UPDATEUSAGE', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Reports and corrects pages and row count inaccuracies in the catalog views. These inaccuracies may cause incorrect space usage reports returned by the sp_spaceused system stored procedure.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'ASASA', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DBCC UPDATEUSAGE]    Script Date: 08/08/2013 15:37:45 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBCC UPDATEUSAGE', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @database_name VARCHAR(100)

DECLARE db_cursor CURSOR
FOR
SELECT d.name 
FROM sys.databases d
WHERE state_desc = ''ONLINE''
ORDER BY d.name	

OPEN db_cursor

FETCH NEXT FROM db_cursor INTO @database_name

WHILE @@FETCH_STATUS = 0
BEGIN

	EXECUTE(''DBCC UPDATEUSAGE (['' + @database_name + ''])'')

FETCH NEXT FROM db_cursor INTO @database_name
	
END

CLOSE db_cursor
DEALLOCATE db_cursor', 
		@database_name=N'master', 
		@output_file_name=N'M:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Log\dbcc_update_usage.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily at 8:30 pm', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130406, 
		@active_end_date=99991231, 
		@active_start_time=203000, 
		@active_end_time=235959, 
		@schedule_uid=N'4af4fef4-06ad-458d-8dbc-730f8f8c9bc2'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-----------------------------------------------------
USE [msdb]
GO

/****** Object:  Job [ASA Performance Collector]    Script Date: 08/08/2013 15:40:15 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/08/2013 15:40:15 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ASA Performance Collector', 
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
/****** Object:  Step [Collect Top Waits Information]    Script Date: 08/08/2013 15:40:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect Top Waits Information', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- ******************************************************************************************************/																	*/
-- Purpose: Finding the top 10 wait events (cumulative).							*/ 	
-- *******************************************************************************************************/

IF OBJECT_ID (''DatabaseServices.dbo.TopWaits'', ''U'') IS NULL
  CREATE TABLE DatabaseServices.dbo.TopWaits (
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [WaitType] varchar(250) NULL, 
  [WaitingTasksCount] bigint NULL, 
  [ResourceWaitTime] bigint NULL, 
  MaxWaitTime_ms bigint NULL, 
  [AvgWaitTime_ms] bigint NULL,
  [Percent_TotalWaits] decimal(10,2) NULL,
  [PercentSignalWaits] decimal(10,2) NULL,
   [PercentResourceWaits] decimal(10,2) NULL,
  [DateCollected] DATETIME NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC) )
GO

INSERT INTO DatabaseServices.dbo.TopWaits
SELECT TOP (10)
        wait_type ,
        waiting_tasks_count ,
        ( wait_time_ms - signal_wait_time_ms ) AS resource_wait_time ,
        max_wait_time_ms ,
        CASE waiting_tasks_count
          WHEN 0 THEN 0
          ELSE wait_time_ms / waiting_tasks_count
        END AS avg_wait_time,
        100.0 * wait_time_ms / SUM(wait_time_ms) OVER ( ) AS percent_total_waits ,
        100.0 * signal_wait_time_ms / SUM(signal_wait_time_ms) OVER ( ) AS percent_total_signal_waits ,
        100.0 * ( wait_time_ms - signal_wait_time_ms )
        / SUM(wait_time_ms) OVER ( ) AS percent_total_resource_waits,
        GETDATE() AS [DataCollected]
FROM    sys.dm_os_wait_stats
WHERE   wait_type NOT LIKE ''%SLEEP%'' -- remove eg. SLEEP_TASK and
-- LAZYWRITER_SLEEP waits
        AND wait_type NOT LIKE ''XE%''
        AND wait_type NOT IN -- remove system waits
( ''KSOURCE_WAKEUP'', ''BROKER_TASK_STOP'', ''FT_IFTS_SCHEDULER_IDLE_WAIT'',
  ''SQLTRACE_BUFFER_FLUSH'', ''CLR_AUTO_EVENT'', ''BROKER_EVENTHANDLER'',
  ''BAD_PAGE_PROCESS'', ''BROKER_TRANSMITTER'', ''CHECKPOINT_QUEUE'',
  ''DBMIRROR_EVENTS_QUEUE'', ''SQLTRACE_BUFFER_FLUSH'', ''CLR_MANUAL_EVENT'',
  ''ONDEMAND_TASK_QUEUE'', ''REQUEST_FOR_DEADLOCK_SEARCH'', ''LOGMGR_QUEUE'',
  ''BROKER_RECEIVE_WAITFOR'', ''PREEMPTIVE_OS_GETPROCADDRESS'',
  ''PREEMPTIVE_OS_AUTHENTICATIONOPS'', ''BROKER_TO_FLUSH'' )
ORDER BY wait_time_ms DESC
GO

--SELECT * FROM  DatabaseServices.dbo.TopWaits', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect Virtual File IO Stats]    Script Date: 08/08/2013 15:40:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect Virtual File IO Stats', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
-- ******************************************************************************************************/																	*/
-- Purpose: Virtual file statistics.							*/ 	
-- *******************************************************************************************************/

IF OBJECT_ID (''DatabaseServices.dbo.FileIOStats'', ''U'') IS NULL
  CREATE TABLE DatabaseServices.dbo.FileIOStats (
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [DBName] varchar(250) NULL, 
  [FileName] varchar(500) NULL, 
  [AvgReadLatency] int NULL, 
  [AvgWriteLatency] int NULL, 
  [AvgTotalLatency] int NULL,
  [AvgBytesPerRead] int NULL,
  [AvgBytesPerWrite] int NULL,
  [IOStall] bigint null,
  [NumOfReads] bigint NULL,
  [NumOfBytesRead] bigint NULL,
  [IOStallRead_ms] bigint null,
  [NumOfWrites] bigint NULL,
  [NumOfBytesWritten] bigint NULL,
  [IOStallWrite_ms] bigint NULL,
  [SizeOnDisk_MB] decimal (10, 2) null,
  [DateCollected] datetime null
    PRIMARY KEY CLUSTERED ([Id] ASC) )
GO

INSERT INTO DatabaseServices.dbo.FileIOStats
SELECT  DB_NAME(vfs.database_id) AS database_name ,
        physical_name,
        --vfs.database_id ,
        --vfs.file_id ,
        io_stall_read_ms / NULLIF(num_of_reads, 0) AS avg_read_latency ,
        io_stall_write_ms / NULLIF(num_of_writes, 0) AS avg_write_latency ,
        io_stall_write_ms / NULLIF(num_of_writes + num_of_writes, 0) AS avg_total_latency ,
        num_of_bytes_read / NULLIF(num_of_reads, 0) AS avg_bytes_per_read ,
        num_of_bytes_written / NULLIF(num_of_writes, 0) AS avg_bytes_per_write ,
        vfs.io_stall ,
        vfs.num_of_reads ,
        vfs.num_of_bytes_read ,
        vfs.io_stall_read_ms ,
        vfs.num_of_writes ,
        vfs.num_of_bytes_written ,
        vfs.io_stall_write_ms ,
        size_on_disk_bytes / 1024 / 1024. AS size_on_disk_mbytes,
        GETDATE()
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
        JOIN sys.master_files AS mf ON vfs.database_id = mf.database_id
                                       AND vfs.file_id = mf.file_id
ORDER BY avg_total_latency DESC
GO

--SELECT * FROM DatabaseServices.dbo.FileIOStats', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect Missing Indexes From Query Plans]    Script Date: 08/08/2013 15:40:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect Missing Indexes From Query Plans', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- ******************************************************************************************************/																	*/
-- Purpose: Missing Indexes from Query Plans.							*/ 	
-- *******************************************************************************************************/
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID (''DatabaseServices.dbo.MissingIndexesFromQueryPlans'', ''U'') IS NULL
  CREATE TABLE DatabaseServices.dbo.MissingIndexesFromQueryPlans (
    [QueryPlan] xml NULL, 
    [SQLText] varchar(max) NULL, 
  [Impact] decimal(10,2) NULL, 
  [DBID] int NULL, 
  [ObjectID] int NULL, 
  [Object] varchar(1000) NULL,
  [EqualityColumns] varchar(1000) NULL,
  [InqualityColumns] varchar(1000) NULL,
  [IncludeColumns] varchar(2000) NULL,
  [DateCollected] datetime null
 )
GO

;WITH XMLNAMESPACES  
   (DEFAULT ''http://schemas.microsoft.com/sqlserver/2004/07/showplan'') 
SELECT query_plan, 
       n.value(''(@StatementText)[1]'', ''VARCHAR(4000)'') AS sql_text, 
       --OBJECT_NAME(sub.objectid, sub.dbid) AS calling_object_name ,
       n.value(''(//MissingIndexGroup/@Impact)[1]'', ''FLOAT'') AS impact, 
       DB_ID(REPLACE(REPLACE(n.value(''(//MissingIndex/@Database)[1]'', ''VARCHAR(128)''),''['',''''),'']'','''')) AS database_id, 
       OBJECT_ID(n.value(''(//MissingIndex/@Database)[1]'', ''VARCHAR(128)'') + ''.'' + 
           n.value(''(//MissingIndex/@Schema)[1]'', ''VARCHAR(128)'') + ''.'' + 
           n.value(''(//MissingIndex/@Table)[1]'', ''VARCHAR(128)'')) AS OBJECT_ID, 
       n.value(''(//MissingIndex/@Database)[1]'', ''VARCHAR(128)'') + ''.'' + 
           n.value(''(//MissingIndex/@Schema)[1]'', ''VARCHAR(128)'') + ''.'' + 
           n.value(''(//MissingIndex/@Table)[1]'', ''VARCHAR(128)'')  
       AS statement, 
       (   SELECT DISTINCT c.value(''(@Name)[1]'', ''VARCHAR(128)'') + '', '' 
           FROM n.nodes(''//ColumnGroup'') AS t(cg) 
           CROSS APPLY cg.nodes(''Column'') AS r(c) 
           WHERE cg.value(''(@Usage)[1]'', ''VARCHAR(128)'') = ''EQUALITY'' 
           FOR  XML PATH('''') 
       ) AS equality_columns, 
        (  SELECT DISTINCT c.value(''(@Name)[1]'', ''VARCHAR(128)'') + '', '' 
           FROM n.nodes(''//ColumnGroup'') AS t(cg) 
           CROSS APPLY cg.nodes(''Column'') AS r(c) 
           WHERE cg.value(''(@Usage)[1]'', ''VARCHAR(128)'') = ''INEQUALITY'' 
           FOR  XML PATH('''') 
       ) AS inequality_columns, 
       (   SELECT DISTINCT c.value(''(@Name)[1]'', ''VARCHAR(128)'') + '', '' 
           FROM n.nodes(''//ColumnGroup'') AS t(cg) 
           CROSS APPLY cg.nodes(''Column'') AS r(c) 
           WHERE cg.value(''(@Usage)[1]'', ''VARCHAR(128)'') = ''INCLUDE'' 
           FOR  XML PATH('''') 
       ) AS include_columns,
       GETDATE() AS [DateCollected] 
INTO #MissingIndexInfo 
FROM  
( 
   SELECT query_plan 
   FROM (    
           SELECT DISTINCT plan_handle 
           FROM sys.dm_exec_query_stats WITH(NOLOCK)  
         ) AS qs 
       OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) tp     
   WHERE tp.query_plan.exist(''//MissingIndex'')=1 
) AS tab (query_plan) 
CROSS APPLY query_plan.nodes(''//StmtSimple'') AS q(n) 
WHERE n.exist(''QueryPlan/MissingIndexes'') = 1 

-- Trim trailing comma from lists 
UPDATE #MissingIndexInfo 
SET equality_columns = LEFT(equality_columns,LEN(equality_columns)-1), 
   inequality_columns = LEFT(inequality_columns,LEN(inequality_columns)-1), 
   include_columns = LEFT(include_columns,LEN(include_columns)-1)

INSERT INTO DatabaseServices.dbo.MissingIndexesFromQueryPlans  
SELECT * 
FROM #MissingIndexInfo 
WHERE impact >= 50.0
ORDER BY impact DESC

DROP TABLE #MissingIndexInfo 
GO

--SELECT * FROM DatabaseServices.dbo.MissingIndexesFromQueryPlans', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect Missing Indexes]    Script Date: 08/08/2013 15:40:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect Missing Indexes', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- ******************************************************************************************************/																	*/
-- Purpose: Identifying missing indexes based on query cost benefit.						*/ 	
-- *******************************************************************************************************/

IF OBJECT_ID (''DatabaseServices.dbo.MissingIndexes'', ''U'') IS NULL
  CREATE TABLE DatabaseServices.dbo.MissingIndexes (
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [ImprovementMeasure] decimal(20,2) NULL, 
  [CreateIndexText] varchar(max) NULL, 
  [UniqueCompiles] int NULL, 
  [UserSeeks] int NULL,
  [UserScans] int NULL,
  [LastUserSeeks] datetime NULL,
  [LastUserScan] datetime null,
  [AvgTotalUserCost] decimal(10,2) null,
  [AvgUserImpact] decimal(10,2) null,
  [DBID] int null,
  [ObjectID] int null,
  [DateCollected] DATETIME NULL
    PRIMARY KEY CLUSTERED ([Id] ASC) )
GO

INSERT INTO DatabaseServices.dbo.MissingIndexes
SELECT  migs.avg_total_user_cost * ( migs.avg_user_impact / 100.0 )
        * ( migs.user_seeks + migs.user_scans ) AS improvement_measure ,
        ''CREATE INDEX [missing_index_''
        + CONVERT (VARCHAR, mig.index_group_handle) + ''_''
        + CONVERT (VARCHAR, mid.index_handle) + ''_''
        + LEFT(PARSENAME(mid.statement, 1), 32) + '']'' + '' ON '' + mid.statement
        + '' ('' + ISNULL(mid.equality_columns, '''')
        + CASE WHEN mid.equality_columns IS NOT NULL
                    AND mid.inequality_columns IS NOT NULL THEN '',''
               ELSE ''''
          END + ISNULL(mid.inequality_columns, '''') + '')'' + ISNULL('' INCLUDE (''
                                                              + mid.included_columns
                                                              + '')'', '''') AS create_index_statement ,
        migs.unique_compiles ,
        migs.user_seeks,
        migs.user_scans,
        migs.last_user_seek,
        migs.last_user_scan,
        migs.avg_total_user_cost,
        migs.avg_user_impact,
        mid.database_id ,
        mid.[object_id],
        GETDATE()
FROM    sys.dm_db_missing_index_groups mig
        INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE   migs.avg_total_user_cost * ( migs.avg_user_impact / 100.0 )
        * ( migs.user_seeks + migs.user_scans ) > 10
AND		migs.avg_total_user_cost * ( migs.avg_user_impact / 100.0 )
        * ( migs.user_seeks + migs.user_scans ) > 100.0        
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * ( migs.user_seeks + migs.user_scans ) DESC
GO

--SELECT * FROM DatabaseServices.dbo.MissingIndexes', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect Missing Columns From Nonclustered Indexes]    Script Date: 08/08/2013 15:40:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect Missing Columns From Nonclustered Indexes', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- ******************************************************************************************************/																	*/
-- Purpose: Missing Columns from NonClustered Indexes.							*/ 	
-- *******************************************************************************************************/
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID (''DatabaseServices.dbo.MissingColumnsFromNCIndex'', ''U'') IS NULL
  CREATE TABLE DatabaseServices.dbo.MissingColumnsFromNCIndex (
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [EstimatedRows] bigint NULL, 
  [SQLText] varchar(max) NULL, 
  [DBName] varchar(100) NULL, 
  [SchemaName] varchar(100) NULL, 
  [TableName] varchar(1000) NULL,
  [NonClusteredIdxName] varchar(2000) NULL,
  [OutputColumns] varchar(max) NULL,
  [DateCollected] datetime null
    PRIMARY KEY CLUSTERED ([Id] ASC) )
GO

;WITH XMLNAMESPACES 
   (DEFAULT ''http://schemas.microsoft.com/sqlserver/2004/07/showplan'') 
INSERT INTO DatabaseServices.dbo.MissingColumnsFromNCIndex     
SELECT DISTINCT 
	NestedLoopsOp.value(''(NestedLoops/RelOp[1]/@EstimateRows)[1]'', ''float'') AS EstimatedRows,
    SQL_Text, 
    DatabaseName,
    SchemaName,
    TableName,
    tbl.spc.value(''(@Index)[1]'', ''varchar(128)'') AS NonClusteredIndexName,
    STUFF((    SELECT DISTINCT '','' + cg.value(''(@Column)[1]'', ''VARCHAR(128)'')
            FROM ClusteredIndex.nodes(''IndexScan/DefinedValues/DefinedValue/ColumnReference'') AS t(cg)
            FOR  XML PATH('''') 
        ), 1,1,'''') AS OutputColumns,
     GETDATE() as [DateCollected]
FROM
(  
    SELECT 
            stmt.value(''(@StatementText)[1]'', ''varchar(max)'') AS SQL_Text,
            obj.value(''(@Database)[1]'', ''varchar(128)'') AS DatabaseName,
            obj.value(''(@Schema)[1]'', ''varchar(128)'') AS SchemaName,
            obj.value(''(@Table)[1]'', ''varchar(128)'') AS TableName,
            obj.value(''(@Index)[1]'', ''varchar(128)'') AS IndexName,
            obj.value(''(@IndexKind)[1]'', ''varchar(128)'') AS IndexKind,
            obj.query(''../../..'') AS NestedLoopsOp,
            obj.query(''..'') AS ClusteredIndex
    FROM sys.dm_exec_cached_plans
    CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
    CROSS APPLY query_plan.nodes(''/ShowPlanXML[1]/BatchSequence[1]/Batch[1]/Statements[1]/StmtSimple'') AS batch(stmt)
    CROSS APPLY stmt.nodes(''.//IndexScan[@Lookup=1]/Object[@Schema!="[sys]"]'') AS idx(obj)
    WHERE query_plan.exist(''//IndexScan/@Lookup[.=1]'') = 1
    --  AND obj.exist(''../IndexScan/DefinedValues/DefinedValue/ColumnReference'') = 1
) AS tab
CROSS APPLY NestedLoopsOp.nodes(''//IndexScan[1]/Object[@Database=sql:column("DatabaseName")][@Table=sql:column("TableName")][@Index!=sql:column("IndexName")]'') AS tbl(spc)
WHERE NestedLoopsOp.value(''(NestedLoops/RelOp[1]/@EstimateRows)[1]'', ''float'')  >= 1000
ORDER BY EstimatedRows DESC;
GO

--SELECT * FROM DatabaseServices.dbo.MissingColumnsFromNCIndex', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect Top CPU Consuming Queries]    Script Date: 08/08/2013 15:40:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect Top CPU Consuming Queries', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
-- ******************************************************************************************************/																	*/
-- Purpose: Finding the top ten CPU-consuming queries.						*/ 	
-- *******************************************************************************************************/

IF OBJECT_ID (''DatabaseServices.dbo.TopCPUConsumingQueries'', ''U'') IS NULL
  CREATE TABLE DatabaseServices.dbo.TopCPUConsumingQueries (
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [SQLText] varchar(max) NULL, 
  [ExecutionCount] int NULL, 
  [TotalWorkerTime_ms] bigint NULL, 
  [AvgWorkerTime_ms] bigint NULL, 
  [TotalLogicalReads] bigint NULL,
  [AvgLogicalReads] bigint NULL,
  [TotalElapsedTime_ms] bigint null,
  [AvgElapsedTime_ms] bigint null,
  [QueryPlan] XML null,
  [DateCollected] datetime null
    PRIMARY KEY CLUSTERED ([Id] ASC) )
GO

INSERT INTO DatabaseServices.dbo.TopCPUConsumingQueries
SELECT TOP ( 10 )
        SUBSTRING(ST.text, ( QS.statement_start_offset / 2 ) + 1,
                  ( ( CASE statement_end_offset
                        WHEN -1 THEN DATALENGTH(st.text)
                        ELSE QS.statement_end_offset
                      END - QS.statement_start_offset ) / 2 ) + 1) AS statement_text ,
        execution_count ,
        total_worker_time / 1000 AS total_worker_time_ms ,
        ( total_worker_time / 1000 ) / execution_count AS avg_worker_time_ms ,
        total_logical_reads ,
        total_logical_reads / execution_count AS avg_logical_reads ,
        total_elapsed_time / 1000 AS total_elapsed_time_ms ,
        ( total_elapsed_time / 1000 ) / execution_count AS avg_elapsed_time_ms ,
        qp.query_plan,
        GETDATE() AS [DateCollected]
FROM    sys.dm_exec_query_stats qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
        CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY total_worker_time DESC
GO

--SELECT * FROM DatabaseServices.dbo.TopCPUConsumingQueries', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect Top IO Consuming Queries]    Script Date: 08/08/2013 15:40:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect Top IO Consuming Queries', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- ******************************************************************************************************/																	*/
-- Purpose: SQL Server execution (IO) statistics.					*/ 	
-- *******************************************************************************************************/

IF OBJECT_ID (''DatabaseServices.dbo.TopIOStatistics'', ''U'') IS NULL
  CREATE TABLE DatabaseServices.dbo.TopIOStatistics (
    [Id] [int] IDENTITY(1,1) NOT NULL,
  [ExecutionCount] int NULL, 
  [StatementStartOffset] int NULL, 
  [SQLHandle] varbinary(64) NULL, 
  [PlanHandle] varbinary(64) NULL,
  [AvgLogicalReads] bigint NULL,
  [AvgLogicalWrites] bigint NULL,
	[AvgPhysicalReads] bigint NULL,
    [SQLText] varchar(max) null,
    [DateCollected] datetime null
    PRIMARY KEY CLUSTERED ([Id] ASC) )
GO

INSERT INTO DatabaseServices.dbo.TopIOStatistics
SELECT TOP 10
        execution_count ,
        statement_start_offset AS stmt_start_offset ,
        sql_handle ,
        plan_handle ,
        total_logical_reads / execution_count AS avg_logical_reads ,
        total_logical_writes / execution_count AS avg_logical_writes ,
        total_physical_reads / execution_count AS avg_physical_reads ,
        t.text,
        GETDATE() as [DateCollected]
FROM    sys.dm_exec_query_stats AS s
        CROSS APPLY sys.dm_exec_sql_text(s.sql_handle) AS t
ORDER BY avg_physical_reads DESC

--SELECT * FROM DatabaseServices.dbo.TopIOStatistics', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect Plan Cache Pollution]    Script Date: 08/08/2013 15:40:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect Plan Cache Pollution', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- ******************************************************************************************************/																	*/
-- Purpose: Plan Cache Pollution					*/ 	
-- *******************************************************************************************************/

IF OBJECT_ID (''DatabaseServices.dbo.PlanCachePollution'', ''U'') IS NULL
  CREATE TABLE DatabaseServices.dbo.PlanCachePollution (
    [Id] [int] IDENTITY(1,1) NOT NULL,
  [CacheType] varchar(100) NULL, 
  [TotalPlans] bigint NULL, 
  [TotalMBs] decimal(10,2) NULL, 
  [AvgUseCount] bigint NULL,
  [TotalMBs_USECount1] decimal(10,2) NULL,
  [TotalPlans_USECount1] bigint NULL,
  [DateCollected] datetime null
    PRIMARY KEY CLUSTERED ([Id] ASC) )
GO

-- First, verify the state of your cache... is it filled with "USE Count 1" plans?
-- This will clear all "USE Count 1" plans but is manual
--DBCC FREESYSTEMCACHE(''SQL Plans'')
--go

-- And, if you see this as a regular problem... 
-- in SQL Server 2008

--sp_configure ''optimize for ad hoc workloads'', 1
--go

--reconfigure
--go

INSERT INTO DatabaseServices.dbo.PlanCachePollution
SELECT objtype AS [CacheType]
	, count_big(*) AS [Total Plans]
	, sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 
			AS [TotalMBs]
	, avg(cast(usecounts as bigint)) AS [AvgUseCount]
	, sum(cast((CASE WHEN usecounts = 1 
		THEN size_in_bytes ELSE 0 END) as decimal(12,2)))/1024/1024 AS [TotalMBs_USECount1]
	, sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [TotalPlans_USECount1]
	, GETDATE() AS [DateCollected]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY [TotalMBs_USECount1] DESC
go

--SELECT * FROM DatabaseServices.dbo.PlanCachePollution', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect Unused Indexes]    Script Date: 08/08/2013 15:40:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect Unused Indexes', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
-- ******************************************************************************************************/																	*/
-- Purpose: Unused Indexes					*/ 	
-- *******************************************************************************************************/

IF OBJECT_ID (''DatabaseServices.dbo.UnusedIndexes'', ''U'') IS NULL
  CREATE TABLE DatabaseServices.dbo.UnusedIndexes (
    [Id] [int] IDENTITY(1,1) NOT NULL,
  [DatabaseName] varchar(100) NULL, 
  [TableName] varchar(300) NULL, 
  [IndexName] varchar(500) NULL, 
  [UserUpdates] int NULL,
  [SystemUpdates] int NULL,
  [DateCollected] datetime null
    PRIMARY KEY CLUSTERED ([Id] ASC) )
GO

-- ******************************************************************************************************/																	*/
-- Purpose: Identify which indexes are not being used, for a given database.							*/
-- Notes: 1. These will have a deterimental impact on any updates/deletions.							*/
--		  Remove if possible (can see the updates in user_updates and system_updates fields)			*/
--		  2. Systems means DBCC commands, DDL commands, or update statistics - so can typically ignore.	*/
--		  3. The template below uses the sp_MSForEachDB, this is because joining on sys.databases		*/
--			gives incorrect results (due to sys.indexes taking into account the current database only).	*/ 	
-- *******************************************************************************************************/
-- Create required table structure only.
-- Note: this SQL must be the same as in the Database loop given in following step.
SELECT TOP 1
		DatabaseName = DB_NAME()
		,TableName = OBJECT_NAME(s.[object_id])
		,IndexName = i.name
		,user_updates	
		,system_updates	
		-- Useful fields below:
		--, *
		, [DateCollected] = GETDATE ()
INTO #TempUnusedIndexes
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE  s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
	AND	user_seeks = 0
	AND user_scans = 0 
	AND user_lookups = 0
	-- Below may not be needed, they tend to reflect creation of stats, backups etc...
--	AND	system_seeks = 0
--	AND system_scans = 0
--	AND system_lookups = 0
	AND s.[object_id] = -999  -- Dummy value, just to get table structure.
;

-- Loop around all the databases on the server.
EXEC sp_MSForEachDB	''USE [?]; 
-- Table already exists.
INSERT INTO #TempUnusedIndexes 
SELECT TOP 10	
		DatabaseName = DB_NAME()
		,TableName = OBJECT_NAME(s.[object_id])
		,IndexName = i.name
		,user_updates	
		,system_updates	
		-- Useful fields below:
		--, *
		,GETDATE()
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE  s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.[object_id], ''''IsMsShipped'''') = 0
	AND	user_seeks = 0
	AND user_scans = 0 
	AND user_lookups = 0
    AND i.name IS NOT NULL	-- I.e. Ignore HEAP indexes.
	-- Below may not be needed, they tend to reflect creation of stats, backups etc...
--	AND	system_seeks = 0
--	AND system_scans = 0
--	AND system_lookups = 0
ORDER BY user_updates DESC
;
''

-- Select records.
INSERT INTO DatabaseServices.dbo.UnusedIndexes
SELECT TOP 25 *  FROM #TempUnusedIndexes ORDER BY [user_updates]  DESC
-- Tidy up.
DROP TABLE #TempUnusedIndexes
GO

--select * from DatabaseServices.dbo.UnusedIndexes', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect DB Space]    Script Date: 08/08/2013 15:40:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect DB Space', 
		@step_id=10, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'

SET NOCOUNT ON
GO

IF OBJECT_ID (''DatabaseServices.dbo.DBA_DBSpaceReport'', ''U'') IS NULL
  CREATE TABLE DatabaseServices.dbo.DBA_DBSpaceReport (
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [ServerName] sysname NULL, 
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
GO

USE [master]
GO

DECLARE @TargetDatabase sysname ,		--  NULL: all dbs
  @Level varchar(10) ,					--  or "File"
  @UpdateUsage bit ,					--  default no update
  @Unit char(2)							--  Megabytes, Kilobytes or Gigabytes

SELECT @TargetDatabase  = NULL,  @Level = ''Database'', @UpdateUsage  = 0, @Unit  = ''MB''                

IF @TargetDatabase IS NOT NULL AND DB_ID(@TargetDatabase) IS NULL
  BEGIN
    RAISERROR(15010, -1, -1, @TargetDatabase);
  END

IF OBJECT_ID(''tempdb..#Tbl_CombinedInfo'', ''U'') IS NOT NULL
  DROP TABLE #Tbl_CombinedInfo;
  
IF OBJECT_ID(''tempdb..#Tbl_DbFileStats'', ''U'') IS NOT NULL
  DROP TABLE #Tbl_DbFileStats;
  
IF OBJECT_ID(''tempdb..#Tbl_ValidDbs'', ''U'') IS NOT NULL
  DROP TABLE #Tbl_ValidDbs;
  
IF OBJECT_ID(''tempdb..#Tbl_Logs'', ''U'') IS NOT NULL
  DROP TABLE #Tbl_Logs;

CREATE TABLE #Tbl_CombinedInfo (
  DatabaseName sysname NULL, 
  [type] VARCHAR(10) NULL, 
  LogicalName sysname NULL,
  T dec(10, 2) NULL,
  U dec(10, 2) NULL,
  [U(%)] dec(5, 2) NULL,
  F dec(10, 2) NULL,
  [F(%)] dec(5, 2) NULL,
  PhysicalName sysname NULL );

CREATE TABLE #Tbl_DbFileStats (
  Id int identity, 
  DatabaseName sysname NULL, 
  FileId int NULL, 
  FileGroup int NULL, 
  TotalExtents bigint NULL, 
  UsedExtents bigint NULL, 
  Name sysname NULL, 
  FileName varchar(255) NULL );
  
CREATE TABLE #Tbl_ValidDbs (
  Id int identity, 
  Dbname sysname NULL );
  
CREATE TABLE #Tbl_Logs (
  DatabaseName sysname NULL, 
  LogSize dec (10, 2) NULL, 
  LogSpaceUsedPercent dec (5, 2) NULL,
  Status int NULL );

DECLARE @Ver varchar(20), 
        @DatabaseName sysname, 
        @Ident_last int, 
        @String varchar(2000),
        @BaseString varchar(2000);
        
SELECT @DatabaseName = '''', 
       @Ident_last = 0, 
       @String = '''', 
       @Ver = CASE WHEN @@VERSION LIKE ''%9.0%'' THEN ''SQL 2005'' 
                   WHEN @@VERSION LIKE ''%8.0%'' THEN ''SQL 2000'' 
                   WHEN @@VERSION LIKE ''%10.0%'' THEN ''SQL 2008'' 
				   WHEN @@VERSION LIKE ''%10.5%'' THEN ''SQL 2008 R2''
				   WHEN @@VERSION LIKE ''%11.0%'' THEN ''SQL 2012''
              END;
              
SELECT @BaseString = '' SELECT DB_NAME(), '' 
						+ CASE 
							WHEN @Ver = ''SQL 2000'' THEN ''CASE WHEN status & 0x40 = 0x40 THEN ''''Log''''  ELSE ''''Data'''' END'' 
							ELSE '' CASE type WHEN 0 THEN ''''Data'''' WHEN 1 THEN ''''Log'''' WHEN 4 THEN ''''Full-text'''' ELSE ''''reserved'''' END'' 
						END 
						+ '', name, '' 
						+ CASE 
							WHEN @Ver = ''SQL 2000'' THEN ''filename'' 
							ELSE ''physical_name'' 
						END 
						+ '', size*8.0/1024.0 FROM '' 
						+ CASE 
							WHEN @Ver = ''SQL 2000'' THEN ''sysfiles'' 
							ELSE ''sys.database_files'' 
						END 
						+ '' WHERE '' 
						+ CASE 
							WHEN @Ver = ''SQL 2000'' THEN '' HAS_DBACCESS(DB_NAME()) = 1'' 
							ELSE ''state_desc = ''''ONLINE'''''' 
						END + '''';

SELECT @String = ''INSERT INTO #Tbl_ValidDbs SELECT name FROM '' 
				+ CASE 
					WHEN @Ver = ''SQL 2000'' THEN ''master.dbo.sysdatabases'' 
					WHEN @Ver IN (''SQL 2005'', ''SQL 2008'', ''SQL 2008 R2'', ''SQL 2012'') THEN ''master.sys.databases'' 
				END 
				+ '' WHERE HAS_DBACCESS(name) = 1 ORDER BY name ASC'';

EXECUTE (@String);

INSERT INTO #Tbl_Logs EXEC (''DBCC SQLPERF (LOGSPACE) WITH NO_INFOMSGS'');
 
--  For data part
IF @TargetDatabase IS NOT NULL
  BEGIN
    SELECT @DatabaseName = @TargetDatabase;
    IF @UpdateUsage <> 0 AND DATABASEPROPERTYEX (@DatabaseName,''Status'') = ''ONLINE'' 
          AND DATABASEPROPERTYEX (@DatabaseName, ''Updateability'') <> ''READ_ONLY''
      BEGIN
        SELECT @String = ''USE ['' + @DatabaseName + ''] DBCC UPDATEUSAGE (0)'';
        PRINT ''*** '' + @String + '' *** '';
        EXEC (@String);
        PRINT '''';
      END
      
    SELECT @String = ''INSERT INTO #Tbl_CombinedInfo (DatabaseName, type, LogicalName, PhysicalName, T) '' + @BaseString; 

    INSERT INTO #Tbl_DbFileStats (FileId, FileGroup, TotalExtents, UsedExtents, Name, FileName)
          EXEC (''USE ['' + @DatabaseName + ''] DBCC SHOWFILESTATS WITH NO_INFOMSGS'');
    EXEC (''USE ['' + @DatabaseName + ''] '' + @String);
        
    UPDATE #Tbl_DbFileStats SET DatabaseName = @DatabaseName; 
  END
ELSE
  BEGIN
    WHILE 1 = 1
      BEGIN
        SELECT TOP 1 @DatabaseName = Dbname FROM #Tbl_ValidDbs WHERE Dbname > @DatabaseName ORDER BY Dbname ASC;
        IF @@ROWCOUNT = 0
          BREAK;
        IF @UpdateUsage <> 0 AND DATABASEPROPERTYEX (@DatabaseName, ''Status'') = ''ONLINE'' 
              AND DATABASEPROPERTYEX (@DatabaseName, ''Updateability'') <> ''READ_ONLY''
          BEGIN
            SELECT @String = ''DBCC UPDATEUSAGE ('''''' + @DatabaseName + '''''') '';
            PRINT ''*** '' + @String + ''*** '';
            EXEC (@String);
            PRINT '''';
          END
    
        SELECT @Ident_last = ISNULL(MAX(Id), 0) FROM #Tbl_DbFileStats;

        SELECT @String = ''INSERT INTO #Tbl_CombinedInfo (DatabaseName, type, LogicalName, PhysicalName, T) '' + @BaseString; 

        EXEC (''USE ['' + @DatabaseName + ''] '' + @String);
      
        INSERT INTO #Tbl_DbFileStats (FileId, FileGroup, TotalExtents, UsedExtents, Name, FileName)
          EXEC (''USE ['' + @DatabaseName + ''] DBCC SHOWFILESTATS WITH NO_INFOMSGS'');

        UPDATE #Tbl_DbFileStats SET DatabaseName = @DatabaseName WHERE Id BETWEEN @Ident_last + 1 AND @@IDENTITY;
      END
  END

--  set used size for data files, do not change total obtained from sys.database_files as it has for log files
UPDATE #Tbl_CombinedInfo 
SET U = s.UsedExtents*8*8/1024.0 
FROM #Tbl_CombinedInfo t JOIN #Tbl_DbFileStats s 
ON t.LogicalName = s.Name AND s.DatabaseName = t.DatabaseName;

--  set used size and % values for log files:
UPDATE #Tbl_CombinedInfo 
SET [U(%)] = LogSpaceUsedPercent, 
U = T * LogSpaceUsedPercent/100.0
FROM #Tbl_CombinedInfo t JOIN #Tbl_Logs l 
ON l.DatabaseName = t.DatabaseName 
WHERE t.type = ''Log'';

UPDATE #Tbl_CombinedInfo SET F = T - U, [U(%)] = U*100.0/T;

UPDATE #Tbl_CombinedInfo SET [F(%)] = F*100.0/T;

IF UPPER(ISNULL(@Level, ''DATABASE'')) = ''FILE''
  BEGIN
    IF @Unit = ''KB''
      UPDATE #Tbl_CombinedInfo
      SET T = T * 1024, U = U * 1024, F = F * 1024;
      
    IF @Unit = ''GB''
      UPDATE #Tbl_CombinedInfo
      SET T = T / 1024, U = U / 1024, F = F / 1024;
      
    SELECT DatabaseName AS ''Database'',
      type AS ''Type'',
      LogicalName,
      T AS ''Total'',
      U AS ''Used'',
      [U(%)] AS ''Used (%)'',
      F AS ''Free'',
      [F(%)] AS ''Free (%)'',
      PhysicalName
      FROM #Tbl_CombinedInfo 
      WHERE DatabaseName LIKE ISNULL(@TargetDatabase, ''%'') 
      ORDER BY DatabaseName ASC, type ASC;

    SELECT CASE WHEN @Unit = ''GB'' THEN ''GB'' WHEN @Unit = ''KB'' THEN ''KB'' ELSE ''MB'' END AS ''SUM'',
        SUM (T) AS ''TOTAL'', SUM (U) AS ''USED'', SUM (F) AS ''FREE'' FROM #Tbl_CombinedInfo;
  END

IF UPPER(ISNULL(@Level, ''DATABASE'')) = ''DATABASE''
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
           x.Data + y.Log AS ''TOTAL'', 
           x.Data_Used + y.Log_Used AS ''U'',
           (x.Data_Used + y.Log_Used)*100.0 / (x.Data + y.Log)  AS ''U(%)'',
           x.Data_Free + y.Log_Free AS ''F'',
           (x.Data_Free + y.Log_Free)*100.0 / (x.Data + y.Log)  AS ''F(%)'',
           x.Data, 
           x.Data_Used, 
           x.Data_Used*100/x.Data AS ''D_U(%)'',
           x.Data_Free, 
           x.Data_Free*100/x.Data AS ''D_F(%)'',
           y.Log, 
           y.Log_Used, 
           y.Log_Used*100/y.Log AS ''L_U(%)'',
           y.Log_Free, 
           y.Log_Free*100/y.Log AS ''L_F(%)''
      FROM 
      ( SELECT d.DatabaseName, 
               SUM(d.T) AS ''Data'', 
               SUM(d.U) AS ''Data_Used'', 
               SUM(d.F) AS ''Data_Free'' 
          FROM #Tbl_CombinedInfo d WHERE d.type = ''Data'' GROUP BY d.DatabaseName ) AS x
      JOIN 
      ( SELECT l.DatabaseName, 
               SUM(l.T) AS ''Log'', 
               SUM(l.U) AS ''Log_Used'', 
               SUM(l.F) AS ''Log_Free'' 
          FROM #Tbl_CombinedInfo l WHERE l.type = ''Log'' GROUP BY l.DatabaseName ) AS y
      ON x.DatabaseName = y.DatabaseName;
    
    IF @Unit = ''KB''
      UPDATE @Tbl_Final SET TOTAL = TOTAL * 1024,
      Used = Used * 1024,
      Free = Free * 1024,
      Data = Data * 1024,
      Data_Used = Data_Used * 1024,
      Data_Free = Data_Free * 1024,
      Log = Log * 1024,
      Log_Used = Log_Used * 1024,
      Log_Free = Log_Free * 1024;
      
    IF @Unit = ''GB''
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

    IF object_id(''tempdb.dbo.DBA_DBSpace'', ''U'') IS NOT NULL
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
GO

DECLARE @ServerName sysname, @St nvarchar(MAX) 
SELECT @ServerName = '''', @St = N''''

SELECT @ServerName = @@SERVERNAME

SELECT @St = N''SELECT '''''' + @ServerName + N'''''', [DatabaseName], [TOTAL], 
    [Used], [Used (%)], [Free], [Free (%)], [Data], [Data_Used], [Data_Used (%)], 
    [Data_Free], [Data_Free (%)], [Log], [Log_Used], [Log_Used (%)], [Log_Free], 
    [Log_Free (%)], CURRENT_TIMESTAMP FROM ['' + @ServerName + 
    N''].tempdb.dbo.DBA_DBSpace WITH (NOLOCK) ORDER BY Id ASC'' 

INSERT INTO DatabaseServices.dbo.DBA_DBSpaceReport EXEC SP_EXECUTESQL @St

GO

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect Drive Space]    Script Date: 08/08/2013 15:40:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect Drive Space', 
		@step_id=11, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
SET NOCOUNT ON
GO

IF OBJECT_ID (''DatabaseServices.dbo.DBA_DriveSpaceReport'', ''U'') IS NULL
CREATE TABLE DatabaseServices.dbo.DBA_DriveSpaceReport (
  [Id] [int] IDENTITY(1,1) NOT NULL,
  [ServerName] sysname NULL, 
  [Drive] char(1) NOT NULL, 
  [FreeSpace (GB)] dec(8,2) NULL, 
  [TotalSize (GB)] dec(8,2) NULL, 
  [Free (%)] AS CONVERT(dec(4,1), ([FreeSpace (GB)]/[TotalSize (GB)] * 100)),
  EventTime datetime NOT NULL,
  PRIMARY KEY CLUSTERED ([Id] ASC))
GO
  

IF OBJECT_ID (''tempdb..#Drive'', ''U'') IS NOT NULL
  DROP TABLE #Drive

CREATE TABLE #Drive (
  Drive char(1) PRIMARY KEY, 
  [FreeSpace (GB)] dec(8,2) NULL, 
  [TotalSize (GB)] dec(8,2) NULL, 
  [Free (%)] AS CONVERT(dec(4,1), ([FreeSpace (GB)]/[TotalSize (GB)] * 100)),
  EventTime datetime NULL DEFAULT CURRENT_TIMESTAMP
)
  
INSERT #Drive (Drive, [FreeSpace (GB)]) EXEC master.dbo.xp_fixedDrives

DECLARE @hr int, @fso int, @Drive char(1), @oDrive int, @TotalSize varchar(20)

EXEC @hr=sp_OACreate ''Scripting.FileSystemObject'',@fso OUT
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso

DECLARE dcur CURSOR LOCAL FAST_FORWARD FOR 
  SELECT Drive FROM #Drive ORDER BY Drive ASC
OPEN dcur
FETCH NEXT FROM dcur INTO @Drive

WHILE @@FETCH_STATUS=0
  BEGIN
    EXEC @hr = sp_OAMethod @fso, ''GetDrive'', @oDrive OUT, @Drive
    IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso
    
    EXEC @hr = sp_OAGetProperty @oDrive, ''TotalSize'', @TotalSize OUT
    IF @hr <> 0 EXEC sp_OAGetErrorInfo @oDrive
                    
    UPDATE #Drive
    SET [TotalSize (GB)] = @TotalSize / (1024.0 * 1024.0 * 1024.0),
        [FreeSpace (GB)] = [FreeSpace (GB)] / 1024.0
    WHERE Drive = @Drive
    
    FETCH NEXT FROM dcur INTO @Drive
  END

CLOSE dcur
DEALLOCATE dcur

EXEC @hr=sp_OADestroy @fso
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso
GO

DECLARE @ServerName sysname, @String nvarchar(MAX) 
SELECT @ServerName = @@SERVERNAME, @String = N''''

SELECT @String = N''SELECT '''''' + @ServerName + N'''''', [Drive], [FreeSpace (GB)], 
    [TotalSize (GB)], EventTime 
    FROM #Drive WITH (NOLOCK) ORDER BY Drive ASC'' 

INSERT INTO DatabaseServices.dbo.DBA_DriveSpaceReport ([ServerName],[Drive],[FreeSpace (GB)],[TotalSize (GB)],EventTime)
EXEC SP_EXECUTESQL @String
GO


', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect Table Size]    Script Date: 08/08/2013 15:40:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect Table Size', 
		@step_id=12, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
SET NOCOUNT ON
GO

IF OBJECT_ID (''DatabaseServices.dbo.DBA_TableSize'', ''U'') IS NULL
  CREATE TABLE DatabaseServices.dbo.DBA_TableSize (
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [ServerName] sysname NULL, 
    [DatabaseName] [sysname] NULL,
	[TableName] NVARCHAR (128) NULL, 
	[RowsCnt] int NULL, 
	[ReservedSpaceKB] int NULL, 
	[DataSpaceKB] int NULL, 
	[CombinedIndexSpaceKB] int NULL, 
	[UnusedSpaceKB] int NULL,
	[EventTime] datetime NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC) )
GO


USE [master]
GO

IF OBJECT_ID(''tempdb..#temp_table_size'', ''U'') IS NOT NULL
  DROP TABLE #temp_table_size;
  
IF OBJECT_ID(''tempdb..#DBA_TableSize'', ''U'') IS NOT NULL
  DROP TABLE #DBA_TableSize;
  
CREATE TABLE #temp_table_size (DatabaseName NVARCHAR (128), TableName NVARCHAR (128), RowsCnt VARCHAR (11), ReservedSpace VARCHAR(18), 
					DataSpace VARCHAR(18), CombinedIndexSpace VARCHAR(18), UnusedSpace VARCHAR(18))
CREATE TABLE #DBA_TableSize (DatabaseName NVARCHAR (128), TableName NVARCHAR (128), RowsCnt int, ReservedSpaceKB int, 
					DataSpaceKB int, CombinedIndexSpaceKB int, UnusedSpaceKB int, [EventTime] [datetime] NULL DEFAULT (CURRENT_TIMESTAMP))

declare @DBName sysname, @TBLName sysname, @sql nvarchar(4000)
set @DBName = ''''

SELECT @DBName = min(name) FROM sys.databases 
WHERE name NOT IN (''master'', ''model'', ''tempdb'', ''msdb'', ''distribution'', ''pubs'', ''northwind'')
AND DATABASEPROPERTY(name, ''IsOffline'') = 0 
AND DATABASEPROPERTY(name, ''IsSuspect'') = 0 

while @DBName is not null
begin

	set @sql = ''USE ['' + @DBName + '']
	declare @TBLName sysname
	select @TBLName = min(s.name+''''.''''+t.name) from sys.tables t, sys.schemas s 
	where t.schema_id = s.schema_id

	while @TBLName is not null
	begin
		INSERT INTO #temp_table_size (TableName, RowsCnt, ReservedSpace, DataSpace, CombinedIndexSpace, UnusedSpace) 
				EXEC sp_spaceused @TBLName	
		select @TBLName = min(s.name+''''.''''+t.name) from sys.tables t, sys.schemas s 
		where t.schema_id = s.schema_id and s.name+''''.''''+t.name > @tblname
	end''

	exec sp_executesql @sql

	insert into #DBA_TableSize
	SELECT @DBName, TableName, 
			cast(RowsCnt as int), 
			cast(substring(ReservedSpace, 1, len(ReservedSpace)-3) as int),
			cast(substring(DataSpace, 1, len(DataSpace)-3) as int), 
			cast(substring(CombinedIndexSpace, 1, len(CombinedIndexSpace)-3) as int),
			cast(substring(UnusedSpace, 1, len(UnusedSpace)-3) as int),
			CURRENT_TIMESTAMP
	FROM #temp_table_size
	delete from #temp_table_size

	SELECT @DBName = min(name) FROM sys.databases 
	WHERE name NOT IN (''master'', ''model'', ''tempdb'', ''msdb'', ''distribution'', ''pubs'', ''northwind'')
	AND DATABASEPROPERTY(name, ''IsOffline'') = 0 
	AND DATABASEPROPERTY(name, ''IsSuspect'') = 0 
	AND name > @DBName
end

GO


DECLARE @ServerName sysname, @String nvarchar(MAX) 
SELECT @ServerName = @@SERVERNAME, @String = N''''

SELECT @String = N''SELECT '''''' + @ServerName + N'''''', [DatabaseName], [TableName], 
    [RowsCnt], [ReservedSpaceKB], [DataSpaceKB], [CombinedIndexSpaceKB], [UnusedSpaceKB], 
	[EventTime] FROM #DBA_TableSize WITH (NOLOCK) '' 

INSERT INTO DatabaseServices.dbo.DBA_TableSize 
EXEC SP_EXECUTESQL @String

GO
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Purge Old Data]    Script Date: 08/08/2013 15:40:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge Old Data', 
		@step_id=13, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use DatabaseServices
go

--select max(eventtime), min(eventtime) from [dbo].[DBA_DBSpaceReport]

--select datediff(d, min(eventtime), max(eventtime))
--from [dbo].[DBA_DBSpaceReport]

delete from [dbo].[DBA_DBSpaceReport]
where eventtime < (getdate() - 180)
go

delete from [dbo].[DBA_DriveSpaceReport]
where eventtime < (getdate() - 180)
go

delete from [dbo].[DBA_DriveSpaceReport]
where eventtime < (getdate() - 180)
go

delete from [dbo].[FileIOStats]
where datecollected < (getdate() - 90)
go

delete from [dbo].[MissingColumnsFromNCIndex]
where datecollected < (getdate() - 90)
go

delete from [dbo].[MissingIndexes]
where datecollected < (getdate() - 90)
go

delete from [dbo].[MissingIndexesFromQueryPlans]
where datecollected < (getdate() - 90)
go

delete from [dbo].[PlanCachePollution]
where datecollected < (getdate() - 90)

delete from [dbo].[TopCPUConsumingQueries]
where datecollected < (getdate() - 90)
go

delete from [dbo].[TopIOStatistics]
where datecollected < (getdate() - 90)
go

delete from [dbo].[TopWaits]
where datecollected < (getdate() - 90)
go

delete from [dbo].[UnusedIndexes]
where datecollected < (getdate() - 90)
go', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily @ 6 pm', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130407, 
		@active_end_date=99991231, 
		@active_start_time=180000, 
		@active_end_time=235959, 
		@schedule_uid=N'd52a696c-ee5e-4b06-990c-7ba3475959e9'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
-----------------------------------------------------
USE [msdb]
GO

/****** Object:  Job [ASA Update Statistics - User Databases]    Script Date: 08/08/2013 15:43:45 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/08/2013 15:43:45 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ASA Update Statistics - User Databases', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Updates stats for all user databases', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'ASASA', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Statistics on User Databases]    Script Date: 08/08/2013 15:43:45 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Update Statistics on User Databases', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @SQL VARCHAR(1000)  
DECLARE @DB sysname  

DECLARE curDB CURSOR FORWARD_ONLY STATIC FOR  
   SELECT [name]  
   FROM master..sysdatabases 
   WHERE [name] NOT IN (''master'', ''model'', ''tempdb'', ''msdb'') 
   ORDER BY [name] 
     
OPEN curDB  
FETCH NEXT FROM curDB INTO @DB  
WHILE @@FETCH_STATUS = 0  
   BEGIN  
       SELECT @SQL = ''USE ['' + @DB +'']'' + CHAR(13) + ''EXEC sp_updatestats'' + CHAR(13)  
       --PRINT @SQL
       EXECUTE (@SQL)  
       FETCH NEXT FROM curDB INTO @DB  
   END  
    
CLOSE curDB  
DEALLOCATE curDB', 
		@database_name=N'master', 
		@output_file_name=N'M:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Log\sp_update_statistics_result.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily at 8:15 pm', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130406, 
		@active_end_date=99991231, 
		@active_start_time=201500, 
		@active_end_time=235959, 
		@schedule_uid=N'20b6e50f-199e-4bd3-bfbe-9397e0214413'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
-----------------------------------------------------
USE [msdb]
GO

/****** Object:  Job [Change_Data_Capture]    Script Date: 08/08/2013 15:45:24 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/08/2013 15:45:24 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Change_Data_Capture', 
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
/****** Object:  Step [Security]    Script Date: 08/08/2013 15:45:24 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Security', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
SELECT * INTO #temp_trc
FROM fn_trace_gettable(''F:\SQL\TrackSecurityChanges.trc'', default);

with LastDate_CTE (LastDate) as
(select max(starttime) from [DatabaseServices].[dbo].[SecurityChanges])

insert into [DatabaseServices].[dbo].[SecurityChanges]
(	[EventClass],[TextData],[ApplicationName],[LoginName],[SPID],[StartTime],[HostName],[RoleName],
	[OwnerName],[TargetLoginName],[ServerName],[EventSubClass],[DatabaseName],[BinaryData],[Success]
)
select 
	e.name,[TextData],[ApplicationName],[LoginName],[SPID],[StartTime],[HostName],[RoleName],
	[OwnerName],[TargetLoginName],[ServerName],cast(t.EventSubClass as nvarchar(5)) + '' - '' + v.subclass_name,[DatabaseName],[BinaryData],[Success]
from LastDate_CTE ld,
	#temp_trc t
JOIN sys.trace_events e ON e.trace_event_id = t.EventClass
JOIN sys.trace_subclass_values v ON v.trace_event_id = e.trace_event_id AND v.subclass_value = t.EventSubClass
where t.StartTime > ld.LastDate
and spid is not null;

drop table #temp_trc;
', 
		@database_name=N'DatabaseServices', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 10 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130406, 
		@active_end_date=99991231, 
		@active_start_time=328, 
		@active_end_time=235959, 
		@schedule_uid=N'bb255ce1-32a0-4c66-adcf-eb4b1c01676e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
-----------------------------------------------------
USE [msdb]
GO

/****** Object:  Job [Client - DBA Monitoring]    Script Date: 08/08/2013 15:46:25 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 08/08/2013 15:46:25 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Client - DBA Monitoring', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'ASASA', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp_SQLDBSpace]    Script Date: 08/08/2013 15:46:25 ******/
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
/****** Object:  Step [Check Disk Space]    Script Date: 08/08/2013 15:46:26 ******/
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
/****** Object:  Step [Run sp_SQLTableSize]    Script Date: 08/08/2013 15:46:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run sp_SQLTableSize', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
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
/****** Object:  Step [Run sp_SQLFragmentation]    Script Date: 08/08/2013 15:46:26 ******/
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
		@active_end_time=235959, 
		@schedule_uid=N'8eef6974-4423-4985-b1a2-31c9626281f1'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
-----------------------------------------------------

-----------------------------------------------------

-----------------------------------------------------

-----------------------------------------------------

-----------------------------------------------------