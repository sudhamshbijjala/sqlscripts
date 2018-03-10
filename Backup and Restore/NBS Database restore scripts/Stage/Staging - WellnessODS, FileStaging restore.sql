--  Restore WellnessODS and FileStaging from PROD (AOPSDBSCLSTR03\ODS) to STAGING (ASTADBS011\ODS)

--  VM into astadbs013, copy backup file from \\aopsdbsclstr03\z$\AOPSDBSCLSTR03\ODS to local z:\temp\
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = 'Z:\temp\WELLNESSODS_201001270530.BAK'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

--ALTER DATABASE WellnessODS SET OFFLINE WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE WellnessODS FROM DISK = @BackupFile WITH REPLACE, STATS = 1,
MOVE 'WellnessODS' TO 'F:\SQL\DATA\WellnessODS_Data.mdf',
MOVE 'FG_WellnessODS_01' TO 'F:\SQL\DATA\WellnessODS_Data_01.ndf',
MOVE 'FG_WellnessODS_02' TO 'G:\SQL\DATA\WellnessODS_Data_02.ndf',
MOVE 'FG_WellnessODS_03' TO 'H:\SQL\DATA\WellnessODS_Data_03.ndf',
MOVE 'FG_WellnessODS_04' TO 'I:\SQL\DATA\WellnessODS_Data_04.ndf',
MOVE 'FG_WellnessODS_05' TO 'R:\SQL\DATA\WellnessODS_Data_05.ndf',
MOVE 'FG_WellnessODS_06' TO 'S:\SQL\DATA\WellnessODS_Data_06.ndf',
MOVE 'WellnessODS_log' TO 'L:\SQL\LOG\WellnessODS_Log.ldf';

--  delete backup file from temp folder


-----------------------------------------------------------------------------------------------------------
--  script to drop schemas
--  assume schemas do not own any object
declare @SchemaName sysname 
select @SchemaName = ''

while 1=1
begin
  select top 1 @SchemaName = name from sys.Schemas 
  where (schema_id not between 16384 and 16393) 
  and (schema_id not between 1 and 4) 
  and name > @SchemaName order by name asc
  if @@rowcount = 0
    break
  EXEC ('DROP SCHEMA [' + @SchemaName + ']')
end
-----------------------------------------------------
--  script to drop users
declare @UserName sysname 
select @UserName = ''

while 1=1
begin
  select top 1 @UserName = name from sys.database_principals 
  where (principal_id not between 16384 and 16393) 
  and (principal_id > 4) 
  and name > @UserName order by name asc
  if @@rowcount = 0
    break
  EXEC ('DROP USER [' + @UserName + ']')
end


---------------------------------------------------------------------------------
--  For Filestaging
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = 'z:\temp\FileStaging_201004271915_trimmed.bak'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE Filestaging SET OFFLINE WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE Filestaging FROM DISK = @BackupFile WITH REPLACE, STATS = 1,
MOVE 'FileStaging_Data' TO 'F:\SQL\DATA\FileStaging_Data.mdf',
MOVE 'FileStaging_Data_01' TO 'G:\SQL\DATA\FileStaging_Data_01.ndf',
MOVE 'FileStaging_Data_02' TO 'H:\SQL\DATA\FileStaging_Data_02.ndf',
MOVE 'FileStaging_log' TO 'L:\SQL\LOG\FileStaging_log.ldf';


