/*
USE [master]
GO
alter database mrm set restricted_user with rollback immediate;
RESTORE DATABASE [MRM] FROM  DISK = N'Z:\ADEVDBS029\MRM_B4_FPA_43.BAK' WITH  FILE = 1,  
MOVE N'Sneferu_Data' TO N'F:\SQL\Data\MRM.mdf',  NOUNLOAD,  REPLACE,  STATS = 5
GO
*/

USE [master]
GO
alter database mrm set multi_user with rollback immediate;
go
use [mrm]
go
exec sp_dropsubscription @publication = N'MRM_1_Replicate', @subscriber = N'ATSTDBS019\IDM', @destination_db = N'MRM_Replicate', @article = N'all'
GO
exec sp_dropsubscription @publication = N'MRM_2_Replicate', @subscriber = N'ATSTDBS019\IDM', @destination_db = N'MRM_Replicate', @article = N'all'
GO
exec sp_dropsubscription @publication = N'MRM_3_Replicate', @subscriber = N'ATSTDBS019\IDM', @destination_db = N'MRM_Replicate', @article = N'all'
GO
exec sp_dropsubscription @publication = N'MRM_4_Replicate', @subscriber = N'ATSTDBS019\IDM', @destination_db = N'MRM_Replicate', @article = N'all'
GO
exec sp_droppublication @publication = N'MRM_1_Replicate'
GO
exec sp_droppublication @publication = N'MRM_2_Replicate'
GO
exec sp_droppublication @publication = N'MRM_3_Replicate'
GO
exec sp_droppublication @publication = N'MRM_4_Replicate'
GO
EXEC sp_removedbreplication @dbname = N'MRM'
go


-- run after release to set db for replication
/*
exec sp_replicationdboption @dbname = N'MRM', @optname = N'publish', @value = N'true'
GO
*/
