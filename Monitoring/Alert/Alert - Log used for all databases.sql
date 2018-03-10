--  Script:   Monitor log usage for all databases
--  Author:   Richard Ding
--  Created:  9/9/2009  
--  Note:     Must use percentage for each database, not _total. 
--            threshold = 80%, interval = 60 min, email to DBA. 

USE [msdb];
GO

DECLARE @AlertName nvarchar(100), 
        @PerfConditionString nvarchar(400),
        @dbname nvarchar(255);
SET @dbname = N'';

WHILE 1=1
  BEGIN
    SELECT TOP 1 @dbname = name FROM sys.databases 
        WHERE name > @dbname AND name NOT IN (N'model') ORDER BY name ASC;
    IF @@ROWCOUNT = 0
      BREAK;

    SELECT @AlertName = N'Log Used (' + @dbname + N') > 80 %', 
           @PerfConditionString = CASE 
             WHEN SERVERPROPERTY(N'instancename') is null THEN N'SQLServer'
             ELSE N'MSSQL$' + convert(nvarchar(25), SERVERPROPERTY(N'instancename')) END + 
             N':Databases|Percent Log Used|' + @dbname + N'|>|80.00';

    EXEC msdb.dbo.sp_add_alert 
      @name = @AlertName, 
	  @message_id=0, 
	  @severity=0, 
	  @enabled=1, 
	  @delay_between_responses=3600,					-- alerts at an interval of 60 minutes
	  @include_event_description_in=1, 
	  @category_name=N'[Uncategorized]', 
	  @performance_condition = @PerfConditionString, 
	  @job_id=N'00000000-0000-0000-0000-000000000000';  -- no job needed

    EXEC msdb.dbo.sp_add_notification 
      @alert_name = @AlertName, 
      @operator_name = N'DBA', 
      @notification_method = 1;
  END
GO



