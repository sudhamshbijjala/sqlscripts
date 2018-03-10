--  Script:  Set up deadlock alert and job
--  Date: 9/3/2009
--  By: Richard Ding
--  Note: 1. Replace job owner account


--  Step 1. Change SQL Server Agent to accept alert
USE [msdb]
GO

EXEC dbo.sp_set_sqlagent_properties @alert_replace_runtime_tokens = 1;
GO

--  Step 2. Create a job
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/03/2009 15:24:30 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Deadlock detection', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Job for responding to DEADLOCK_GRAPH events', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'AMSA\SvDEVSQLAgentExec', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Create deadlock graph table]    Script Date: 09/03/2009 15:24:30 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Create deadlock graph table', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
USE tempdb ;

IF OBJECT_ID(''dbo.DeadlockEvents'', ''U'') IS NULL

CREATE TABLE dbo.DeadlockEvents 
  ( AlertTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, 
    DeadlockGraph XML NULL
  );', 
		@database_name=N'tempdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Insert graph into LogEvents]    Script Date: 09/03/2009 15:24:30 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Insert graph into LogEvents', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO tempdb.dbo.DeadlockEvents (DeadlockGraph)
                VALUES (N''$(ESCAPE_SQUOTE(WMI(TextData)))'')', 
		@database_name=N'tempdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
	
-- Set the job server for the job to the current instance of SQL Server.
declare @ServerName sysname
SET @ServerName = @@servername
IF not exists (SELECT * FROM msdb.dbo.sysjobservers s 
join msdb.dbo.sysjobs j 
on s.job_id = j.job_id
join master.sys.servers ss
on s.server_id = ss.server_id
where j.name = 'Blocking detection' 
and ss.name = @ServerName)

EXEC msdb.dbo.sp_add_jobserver @job_name = N'Deadlock detection', @server_name = @ServerName;
GO

--  Step 3. Create an alert:  
declare @WMIInstanceName nvarchar(255), @WMINameSpace nvarchar(510)
set @WMIInstanceName = convert(nvarchar(255), SERVERPROPERTY(N'instancename'))
set @WMIInstanceName = ISNULL(@WMIInstanceName, N'MSSQLSERVER')
select @WMINameSpace = N'\\.\root\Microsoft\SqlServer\ServerEvents\' + @WMIInstanceName

EXEC msdb.dbo.sp_add_alert @name=N'Deadlock detected', 
	@message_id=0, 
	@severity=0, 
	@enabled=1, 
	@delay_between_responses=0, 
	@include_event_description_in=0, 
	@notification_message=N'Please find XML details from the query:     SELECT TOP 1 DeadlockGraph FROM tempdb.dbo.DeadlockEvents order by AlertTime desc;', 
	@category_name=N'[Uncategorized]', 
    @wmi_namespace=@WMINameSpace, 
    @wmi_query=N'SELECT * FROM DEADLOCK_GRAPH', 
    @job_name='Deadlock detection' ;
GO

--  set up alert notification:
EXEC msdb.dbo.sp_add_notification @alert_name = N'Deadlock detected', @operator_name = N'DBA', @notification_method = 1
GO


