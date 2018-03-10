exec sp_configure 'show advanced options', 1;
RECONFIGURE;

exec sp_configure 'Agent XPs', 1;

exec sp_configure 'Database Mail XPs', 1;

exec sp_configure 'Ole Automation Procedures', 1;

exec sp_configure 'remote admin connections', 1;

exec sp_configure 'scan for startup procs', 1;

RECONFIGURE WITH OVERRIDE;


----------------------------------------
--  Memory configuration:
declare @MSVersion table
( [Index] varchar(5), 
  [Name] varchar(20), 
  Internal_Value varchar(10), 
  Character_Value varchar(120));    

insert into @MSVersion exec ('master.dbo.xp_msver');

declare @Memory varchar(6);
select @Memory = (select Internal_Value from @MSVersion where Name = 'PhysicalMemory');

/*
--  Based on DBA's << SQL and Database Standard >>
RAM installed	Available Memory for OS		Max Memory for SQL
< 4 GB			512 MB – 1 GB				< 3 GB – 3.5 GB
4 - 32 GB		1 GB – 2 GB					3 GB – 30 GB
32 – 128 GB		2 GB – 4 GB					30 GB – 124 GB
128 GB			4 GB						124 GB
*/

if @Memory <= 2048
  set @Memory = @Memory - 512;
if @Memory <= 8192 and @Memory > 2048
  set @Memory = @Memory - 1024;
if @Memory <= 32768 and @Memory > 8192
  set @Memory = @Memory - 2048;

exec dbo.sp_configure 'max server memory (MB)', @Memory;
RECONFIGURE WITH OVERRIDE;