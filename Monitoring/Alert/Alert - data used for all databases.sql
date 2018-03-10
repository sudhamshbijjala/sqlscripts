--  *********************  Important !! You need to change @owner_login_name to proper account *********************


USE [msdb]
GO

/****** Object:  Job [Alert - Data Used Space Exceeds Threshold]    Script Date: 09/09/2009 15:29:03 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/09/2009 15:29:03 ******/
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
		@owner_login_name=N'AMSA\SvProdSQLAgentExec', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Data Used Space]    Script Date: 09/09/2009 15:29:04 ******/
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
    WHERE name > @dbname AND [state] = 0 AND database_id <> 3 AND is_read_only = 0 ORDER BY name ASC;
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
           @r_name=''DBA@amsa.com'', 
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
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Schedule for every 5 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20090909, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'2efc2bd2-cb0d-4034-b8c0-758841d3aaa6'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


