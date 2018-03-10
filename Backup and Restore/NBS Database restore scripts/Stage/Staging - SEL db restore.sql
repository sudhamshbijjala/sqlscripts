--  Restore SEL database from PROD (AOPSDBSCLSTR05\SEL) to testing - (ATSTDBS010\SEL)

--  first copy the backup file from prod to test
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = 'z:\Temp\SEL_201004270530.BAK'

RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE SEL SET OFFLINE WITH ROLLBACK IMMEDIATE;

--  To prevent error of not finding database, wait for a few seconds:
WAITFOR DELAY '00:01:00'

RESTORE DATABASE SEL FROM DISK = @BackupFile WITH REPLACE, STATS = 1,
MOVE 'SEL_Data' TO 'H:\SQL\DATA\SQL_Data.mdf',
MOVE 'SEL_Data_01' TO 'H:\sql\data\SEL_Data_01.ndf',
MOVE 'SEL_Log' TO 'H:\SQL\LOG\SQL_Log.ldf';