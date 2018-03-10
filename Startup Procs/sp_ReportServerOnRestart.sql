USE [master]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_ReportServerOnRestart]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_ReportServerOnRestart]
GO

USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_ReportServerOnRestart]
AS

  SET NOCOUNT ON;
  
  DECLARE @ServerInfo TABLE (
    ServerName sysname, 
    HostName sysname, 
    ProductVersion varchar(20), 
    SQLServicePack varchar(20)
  );

  DECLARE 
  @ServerName sysname, 
  @HostName sysname, 
  @ProductVersion sysname, 
  @ProductLevel sysname;
  
  SELECT 
  @ServerName = @@servername, 
  @ProductVersion = convert(varchar(20), SERVERPROPERTY('productVersion')), 
  @ProductLevel = convert(varchar(20), SERVERPROPERTY('productlevel'));

  IF SERVERPROPERTY('IsClustered') = 1 
    SELECT @HostName = host_name FROM sys.dm_exec_sessions WHERE [program_name] = 'Microsoft® Windows® Operating System';
  ELSE
    SELECT @HostName = CONVERT(VARCHAR(30), SERVERPROPERTY('ComputerNamePhysicalNetBIOS'));

  INSERT INTO @ServerInfo VALUES (@ServerName, @HostName, @ProductVersion, @ProductLevel);

  DECLARE @p_name varchar(100),
          @r_name varchar(100),
          @sub varchar(100),
          @bo varchar(100);
          
  SELECT @hostname = HostName from @ServerInfo;
  
  SELECT @p_name=@@servername, 
         @r_name='DBA@amsa.com', 
         @sub='SQL Server '+@@servername+' has started on ' + 
                CASE WHEN SERVERPROPERTY ('IsClustered') = 1 THEN 'cluster node ' 
                     WHEN SERVERPROPERTY ('IsClustered') = 0 THEN 'machine ' 
                END + SPACE(1) + @hostname + '...', 
         @bo='This message indicates that the MSSQL Server Service just started...';

  EXEC msdb.dbo.sp_send_dbmail
    @profile_name = @p_name,
    @recipients = @r_name,
    @body = @bo,
    @subject = @sub;


GO

EXEC sp_procoption N'[dbo].[sp_ReportServerOnRestart]', 'startup', '1'

GO


