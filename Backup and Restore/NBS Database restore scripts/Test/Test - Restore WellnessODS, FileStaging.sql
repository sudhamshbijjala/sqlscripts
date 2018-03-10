--  Restore WellnessODS from PROD (AOPSDBSCLSTR03\ODS) to Test (ATSTDBS011\ODS)

--  VM into atstdbs011, copy backup file from \\aopsdbsclstr03\z$\AOPSDBSCLSTR03\ODS to local z:\temp\
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = 'Z:\temp\WELLNESSODS_201004140530.BAK'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE WellnessODS SET OFFLINE WITH ROLLBACK IMMEDIATE;

--  To prevent error of not finding database, wait for a few seconds:
WAITFOR DELAY '00:01:00'

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



---------------------------------------------------------------------------------
--  For Filestaging
--  since filestaging is too big (> 100 GB) it needs to be restored somewhere else, shrunk, and the backed up, finally restored
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = 'Z:\temp\FILESTAGING_201004140546_WhiteSpaceTrimmed.BAK'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE Filestaging SET OFFLINE WITH ROLLBACK IMMEDIATE;

--  To prevent error of not finding database, wait for a few seconds:
WAITFOR DELAY '00:01:00'

RESTORE DATABASE Filestaging FROM DISK = @BackupFile WITH REPLACE, STATS = 1,
MOVE 'FileStaging_Data' TO 'F:\SQL\DATA\FileStaging_Data.mdf',
MOVE 'FileStaging_Data_01' TO 'G:\SQL\DATA\FileStaging_Data_01.ndf',
MOVE 'FileStaging_Data_02' TO 'H:\SQL\DATA\FileStaging_Data_02.ndf',
MOVE 'FileStaging_log' TO 'L:\SQL\LOG\FileStaging_log.ldf';

