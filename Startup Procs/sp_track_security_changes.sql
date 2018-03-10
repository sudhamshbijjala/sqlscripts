USE [master]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_track_security_changes]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_track_security_changes]
GO

USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[sp_track_security_changes] 
as

-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
set @maxfilesize = 5 

-- Please replace the text InsertFileNameHere, with an appropriate
-- filename prefixed by a path, e.g., c:\MyFolder\MyTrace. The .trc extension
-- will be appended to the filename automatically. If you are writing from
-- remote server to local drive, please use UNC path and make sure server has
-- write access to your network share

exec @rc = sp_trace_create @TraceID output, 2, N'F:\SQL\TrackSecurityChanges', @maxfilesize, NULL, 5
if (@rc != 0) goto error

-- Client side File and Table cannot be scripted

-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 109, 8, @on
exec sp_trace_setevent @TraceID, 109, 10, @on
exec sp_trace_setevent @TraceID, 109, 26, @on
exec sp_trace_setevent @TraceID, 109, 42, @on
exec sp_trace_setevent @TraceID, 109, 11, @on
exec sp_trace_setevent @TraceID, 109, 35, @on
exec sp_trace_setevent @TraceID, 109, 12, @on
exec sp_trace_setevent @TraceID, 109, 21, @on
exec sp_trace_setevent @TraceID, 109, 37, @on
exec sp_trace_setevent @TraceID, 109, 14, @on
exec sp_trace_setevent @TraceID, 109, 38, @on
exec sp_trace_setevent @TraceID, 109, 23, @on
exec sp_trace_setevent @TraceID, 108, 8, @on
exec sp_trace_setevent @TraceID, 108, 1, @on
exec sp_trace_setevent @TraceID, 108, 10, @on
exec sp_trace_setevent @TraceID, 108, 26, @on
exec sp_trace_setevent @TraceID, 108, 42, @on
exec sp_trace_setevent @TraceID, 108, 11, @on
exec sp_trace_setevent @TraceID, 108, 12, @on
exec sp_trace_setevent @TraceID, 108, 21, @on
exec sp_trace_setevent @TraceID, 108, 37, @on
exec sp_trace_setevent @TraceID, 108, 14, @on
exec sp_trace_setevent @TraceID, 108, 38, @on
exec sp_trace_setevent @TraceID, 108, 23, @on
exec sp_trace_setevent @TraceID, 110, 8, @on
exec sp_trace_setevent @TraceID, 110, 1, @on
exec sp_trace_setevent @TraceID, 110, 10, @on
exec sp_trace_setevent @TraceID, 110, 26, @on
exec sp_trace_setevent @TraceID, 110, 42, @on
exec sp_trace_setevent @TraceID, 110, 11, @on
exec sp_trace_setevent @TraceID, 110, 35, @on
exec sp_trace_setevent @TraceID, 110, 12, @on
exec sp_trace_setevent @TraceID, 110, 21, @on
exec sp_trace_setevent @TraceID, 110, 37, @on
exec sp_trace_setevent @TraceID, 110, 14, @on
exec sp_trace_setevent @TraceID, 110, 38, @on
exec sp_trace_setevent @TraceID, 110, 23, @on
exec sp_trace_setevent @TraceID, 111, 8, @on
exec sp_trace_setevent @TraceID, 111, 10, @on
exec sp_trace_setevent @TraceID, 111, 14, @on
exec sp_trace_setevent @TraceID, 111, 26, @on
exec sp_trace_setevent @TraceID, 111, 38, @on
exec sp_trace_setevent @TraceID, 111, 11, @on
exec sp_trace_setevent @TraceID, 111, 35, @on
exec sp_trace_setevent @TraceID, 111, 12, @on
exec sp_trace_setevent @TraceID, 111, 21, @on
exec sp_trace_setevent @TraceID, 111, 23, @on
exec sp_trace_setevent @TraceID, 104, 8, @on
exec sp_trace_setevent @TraceID, 104, 10, @on
exec sp_trace_setevent @TraceID, 104, 14, @on
exec sp_trace_setevent @TraceID, 104, 26, @on
exec sp_trace_setevent @TraceID, 104, 42, @on
exec sp_trace_setevent @TraceID, 104, 11, @on
exec sp_trace_setevent @TraceID, 104, 12, @on
exec sp_trace_setevent @TraceID, 104, 21, @on
exec sp_trace_setevent @TraceID, 104, 23, @on
exec sp_trace_setevent @TraceID, 107, 8, @on
exec sp_trace_setevent @TraceID, 107, 1, @on
exec sp_trace_setevent @TraceID, 107, 10, @on
exec sp_trace_setevent @TraceID, 107, 26, @on
exec sp_trace_setevent @TraceID, 107, 42, @on
exec sp_trace_setevent @TraceID, 107, 11, @on
exec sp_trace_setevent @TraceID, 107, 35, @on
exec sp_trace_setevent @TraceID, 107, 12, @on
exec sp_trace_setevent @TraceID, 107, 21, @on
exec sp_trace_setevent @TraceID, 107, 37, @on
exec sp_trace_setevent @TraceID, 107, 14, @on
exec sp_trace_setevent @TraceID, 107, 23, @on
exec sp_trace_setevent @TraceID, 106, 8, @on
exec sp_trace_setevent @TraceID, 106, 1, @on
exec sp_trace_setevent @TraceID, 106, 10, @on
exec sp_trace_setevent @TraceID, 106, 26, @on
exec sp_trace_setevent @TraceID, 106, 42, @on
exec sp_trace_setevent @TraceID, 106, 11, @on
exec sp_trace_setevent @TraceID, 106, 35, @on
exec sp_trace_setevent @TraceID, 106, 12, @on
exec sp_trace_setevent @TraceID, 106, 21, @on
exec sp_trace_setevent @TraceID, 106, 37, @on
exec sp_trace_setevent @TraceID, 106, 14, @on
exec sp_trace_setevent @TraceID, 106, 23, @on


-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

exec sp_trace_setfilter @TraceID, 10, 0, 7, N'SQL Server Profiler - e5b07733-f3b7-4a4f-ac67-a552db618c97'
-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 

GO

EXEC sp_procoption N'[dbo].[sp_track_security_changes]', 'startup', '1'

GO


