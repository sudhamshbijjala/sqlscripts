
--------------------------------------------------------------------------------------------------------------
--  Restore other NBS dbs from PROD (AOPSDBSCLSTR01\BPMS) to Test (AQADBSCLSTR02\MCDB)

--  VM into aqadbsclstr02, copy backup file from \\aopsdbsclstr02\B$\AOPSDBSCLSTR02\MCDB to local W:\temp\

--  For BOWS
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = 'W:\Temp\BOWS_201004140540.BAK'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE BOWS SET OffLINE WITH ROLLBACK IMMEDIATE;

--  To prevent error of not finding database, wait for a few seconds:
WAITFOR DELAY '00:01:00'

RESTORE DATABASE BOWS FROM DISK = @BackupFile WITH REPLACE, STATS = 1,
MOVE 'BOWS_Data' TO 'R:\Microsoft SQL Server\MSSQL.1\MSSQL\Data\BOWS_Data.mdf',
MOVE 'BOWS_log' TO 'S:\Microsoft SQL Server\MSSQL.1\MSSQL\Data\BOWS_log.ldf';


--  For MCDB
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = 'W:\Temp\MCDB_201004140530.BAK'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE MCDB SET OFFLINE WITH ROLLBACK IMMEDIATE;

--  To prevent error of not finding database, wait for a few seconds:
WAITFOR DELAY '00:01:00'

RESTORE DATABASE MCDB FROM DISK = @BackupFile WITH REPLACE, STATS = 1,
MOVE 'MCDB' TO 'R:\Microsoft SQL Server\MSSQL.1\MSSQL\Data\MCDB.mdf',
MOVE 'FG_MCDB_01' TO 'R:\Microsoft SQL Server\MSSQL.1\MSSQL\Data\FG_MCDB_01.ndf',
MOVE 'FG_MCDB_02' TO 'R:\Microsoft SQL Server\MSSQL.1\MSSQL\Data\FG_MCDB_02.ndf',
MOVE 'FG_MCDB_03' TO 'R:\Microsoft SQL Server\MSSQL.1\MSSQL\Data\FG_MCDB_03.ndf',
MOVE 'FG_MCDB_04' TO 'R:\Microsoft SQL Server\MSSQL.1\MSSQL\Data\FG_MCDB_04.ndf',
MOVE 'MCDB_log' TO 'W:\Microsoft SQL Server\MSSQL.1\MSSQL\Data\MCDB_log.ldf';


--  For MCDBStaging
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = 'W:\Temp\MCDBSTAGING_201004140539.BAK'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE MCDBStaging SET OFFLINE WITH ROLLBACK IMMEDIATE;

--  To prevent error of not finding database, wait for a few seconds:
WAITFOR DELAY '00:01:00'

RESTORE DATABASE MCDBStaging FROM DISK = @BackupFile WITH REPLACE, STATS = 1,
MOVE 'MCDBStaging' TO 'r:\Microsoft SQL Server\MSSQL.1\MSSQL\Data\MCDBStaging_Data.mdf',
MOVE 'FG_MCDBStaging_01' TO 'r:\Microsoft SQL Server\MSSQL.1\MSSQL\Data\MCDB_01.ndf',
MOVE 'FG_MCDBStaging_02' TO 'r:\Microsoft SQL Server\MSSQL.1\MSSQL\Data\MCDB_02.ndf',
MOVE 'MCDBStaging_log' TO 'w:\Microsoft SQL Server\MSSQL.1\MSSQL\Data\MCDBStaging_Log.ldf';


--  For ODSStaging
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = 'W:\Temp\ODSSTAGING_201004140540.BAK'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE ODSSTAGING SET OFFLINE WITH ROLLBACK IMMEDIATE;

--  To prevent error of not finding database, wait for a few seconds:
WAITFOR DELAY '00:01:00'

RESTORE DATABASE ODSSTAGING FROM DISK = @BackupFile WITH REPLACE, STATS = 1,
MOVE 'ODSStaging_Data' TO 'P:\SQL\DATA\ODSStaging_Data.mdf',
MOVE 'ODSStaging_Data_01' TO 'P:\SQL\DATA\ODSStaging_Data_01.ndf',
MOVE 'ODSStaging_Data_02' TO 'R:\SQL\DATA\ODSStaging_Data_02.ndf',
MOVE 'ODSStaging_log' TO 'W:\SQL\LOG\ODSStaging_log.ldf';

--  delete copied backup files
