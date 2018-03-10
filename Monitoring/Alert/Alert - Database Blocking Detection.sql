

USE [msdb]
GO

/****** Object:  Job [Blocking detection]    Script Date: 08/24/2009 09:14:38 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/24/2009 09:14:38 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Blocking detection', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [block detection]    Script Date: 08/24/2009 09:14:39 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'block detection', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/********************************************************************************************
				--  Name:   Blockng detection script
				--  Use:    Improve existing blocking detecting alert. It fires whenever blocking occurs but
				--          most of the time it resolves by itself. We only need to report on blocking that 
				--          lasts for more than 5  Min (adjustable).
				********************************************************************************************/

DECLARE @CmdString nvarchar(max),
		@servername nvarchar(100) = @@servername, 
		@time datetime = getdate()

--  Build the base blocking checking query  
SELECT @CmdString = N''
  SET NOCOUNT ON;
  WITH block (session_id, 
     blocking_session_id, 
     start_time, 
     status, 
     command, 
     db_name, 
     user_name, 
     wait_type, 
     wait_time)
  AS (
    SELECT a.session_id, 
         blocking_session_id, 
         start_time, 
         convert(varchar(15), b.status),          
         convert(varchar(15), command), 
         convert(varchar(15), db_name(a.database_id)), 
		convert(varchar(100),b.login_name) as [user_name], 
         convert(varchar(10), wait_type), 
         wait_time 
    FROM sys.dm_exec_requests a
	left join sys.dm_exec_sessions b
	on  a.session_id = b.session_id
    WHERE blocking_session_id > 0
  )
  SELECT cast(blocking_session_id AS varchar(5)) + '''' (HEAD)'''' AS ''''Session'''', 
       start_time, 
       status, 
       command, 
       db_name, 
       user_name, 
       wait_type, 
       wait_time
  INTO ##initalBlockingSnapshot
  FROM block
  WHERE (blocking_session_id IS NULL) 
  OR (blocking_session_id NOT IN 
       (SELECT session_id FROM block))
  UNION ALL
  SELECT cast(session_id AS varchar(5)) + '''' (blocked)'''', 
       start_time, 
       status, 
       command, 
       db_name, 
       user_name, 
       wait_type, 
       wait_time 
  FROM block; 
'';

--  Creating initial snapshot table
EXEC sp_executesql @CmdString;

--  this is adjustalbe time depending on business scenario
WAITFOR DELAY ''00:00:005'';

--  Creating final snapshot table
SELECT @CmdString = REPLACE(@CmdString, ''inital'', ''final'');
EXEC sp_executesql @CmdString;

--  If there''s at one record to email, we will get its commnad detail
IF EXISTS (SELECT 0 FROM ##initalBlockingSnapshot i 
           JOIN ##finalBlockingSnapshot f ON i.Session = f.Session)
  BEGIN
    SELECT f.*, convert(varchar(max), '''') AS ''InputBuffer''
    INTO ##BlobkingForEmail
    FROM ##initalBlockingSnapshot i JOIN ##finalBlockingSnapshot f
    ON i.Session = f.Session;

    DECLARE @SessionIdString varchar(15), @SessionId varchar(5), @cmd varchar (1000);
    SELECT @SessionIdString = '''', @SessionId = '''', @cmd = '''';

    DECLARE @DBCCInputBuffer TABLE (EventType varchar(50), Parameters int, EventInfo varchar(max)); 

    WHILE 1 = 1
      BEGIN               
        SELECT TOP 1 @SessionIdString = Session FROM ##BlobkingForEmail 
          WHERE Session > @SessionIdString ORDER BY Session ASC;
        IF @@ROWCOUNT = 0
          BREAK;
        SELECT @SessionId = substring(@SessionIdString, 1, CHARINDEX('' '', @SessionIdString)-1);
        SELECT @cmd = ''DBCC INPUTBUFFER ('' + @SessionId + '') WITH NO_INFOMSGS'';
        DELETE FROM @DBCCInputBuffer;
        INSERT INTO @DBCCInputBuffer EXEC (@cmd);
             
        UPDATE ##BlobkingForEmail SET InputBuffer = (SELECT EventInfo FROM @DBCCInputBuffer) 
          WHERE Session = @SessionIdString;            
      END
                          
    DECLARE @p_name varchar(30),
            @r_name varchar(50),
            @sub varchar(100),
            @q varchar(max);
  
         SELECT @p_name=''Notifications'', 
           @r_name=''nagasai.repalle@pimco.com'',
          @sub=''[Warning]:''+''Blocking detected on ''+ @servername +'' at ''+cast(@time as nvarchar),
           @q = ''SELECT * FROM ##BlockingForEmail ORDER BY Session ASC'';
       
    EXEC msdb.dbo.sp_send_dbmail
      @profile_name = @p_name,
      @recipients = @r_name,
      @query = @q,
      @subject = @sub;
    
    DROP TABLE ##BlobkingForEmail
  END              
                         
DROP TABLE ##initalBlockingSnapshot
DROP TABLE ##finalBlockingSnapshot
', 
		@database_name=N'master', 
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

-------------------------------------------------------------------------------------------
USE [msdb]
GO

/****** Object:  Alert [Blocking detected]    Script Date: 08/24/2009 08:58:04 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Blocking detected', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=0, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'SQLServer:General Statistics|Processes blocked||>|0', 
		@job_name=N'Blocking detection'
GO

-------------------------------------------------------------------------------------------
--  Alerts on fatal errors 019 - 025
USE [msdb]
GO

/****** Object:  Alert [019 - Fatal error]    Script Date: 08/18/2009 14:54:45 ******/
EXEC msdb.dbo.sp_add_alert @name=N'019 - Fatal error', 
		@message_id=0, 
		@severity=19, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

EXEC msdb.dbo.sp_add_alert @name=N'020 - Fatal error', 
		@message_id=0, 
		@severity=20, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_alert @name=N'021 - Fatal error', 
		@message_id=0, 
		@severity=21, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_alert @name=N'022 - Fatal error', 
		@message_id=0, 
		@severity=22, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_alert @name=N'023 - Fatal error', 
		@message_id=0, 
		@severity=23, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_alert @name=N'024 - Fatal error', 
		@message_id=0, 
		@severity=24, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_alert @name=N'025 - Fatal error', 
		@message_id=0, 
		@severity=25, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

------------------------------------------------------------------------------
USE [msdb]
GO

/****** Object:  Alert [Log_used % Exceeds 75%]    Script Date: 08/18/2009 14:57:27 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Log_used % Exceeds 75%', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'SQLServer:Databases|Percent Log Used|_Total|>|75', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

USE [msdb]
GO

/****** Object:  Alert [Tempdb free space < 1 GB]    Script Date: 08/18/2009 14:58:29 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Tempdb free space < 1 GB', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'SQLServer:Transactions|Free Space in tempdb (KB)||<|1048576', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO


----------------------------------------------------------------------------------
--  Loop to set up all alerts to respond to emailing DBA

USE msdb ;
GO

declare @AlertID int, @AlertName sysname
select @AlertID = 1, @AlertName = ''

While 0=0 
begin
  select top 1 @AlertID = id, @AlertName = name from msdb.dbo.sysalerts with (nolock) 
    where id > @AlertID and name not in ('Blocking detected') order by id asc
    if @@rowcount = 0
      break;
  if not exists (select * from msdb.dbo.sysnotifications where alert_id = @AlertID and notification_method = 1)    
  EXEC dbo.sp_add_notification
    @alert_name = @AlertName, @operator_name = N'DBA', @notification_method = 1  --  1 = email, 2 = pager, 4=net wend

end

GO

