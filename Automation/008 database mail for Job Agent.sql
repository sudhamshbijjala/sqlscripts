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
SET @SQLInstance = N'AOPSDBSCLSTR03\ODS'
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', @SQLInstance
GO
