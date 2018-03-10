USE [master]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_SetTraceFlags]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_SetTraceFlags]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[sp_SetTraceFlags] 
as

dbcc traceon(3226, -1)	-- Suppress successful log backup message in error log and application log

GO

EXEC sp_procoption N'[dbo].[sp_SetTraceFlags]', 'startup', '1'
GO


