USE Master;
GO
-- create folder if it doesn't exist
DECLARE @DirTree TABLE (subdirectory nvarchar(255), depth INT)
INSERT INTO @DirTree(subdirectory, depth) EXEC master.sys.xp_dirtree N'Z:\'
IF NOT EXISTS (SELECT 1 FROM @DirTree WHERE subdirectory = N'DBSnapshots')
EXEC master.dbo.xp_create_subdir N'Z:\DBSnapshots'
GO

-- create snapshots
create database MRM_Snapshot ON
    ( NAME = Sneferu_Data, FILENAME = 'Z:\DBSnapshots\Sneferu_Data.ss')
as snapshot of MRM
GO
create database WellnessODS_Snapshot ON
    ( NAME = WellnessODS, FILENAME = 'Z:\DBSnapshots\WellnessODS.ss'),
    ( NAME = FG_WellnessODS_01, FILENAME = 'Z:\DBSnapshots\FG_WellnessODS_01.ss'),
    ( NAME = FG_WellnessODS_02, FILENAME = 'Z:\DBSnapshots\FG_WellnessODS_02.ss'),
    ( NAME = FG_WellnessODS_03, FILENAME = 'Z:\DBSnapshots\FG_WellnessODS_03.ss'),
    ( NAME = FG_WellnessODS_04, FILENAME = 'Z:\DBSnapshots\FG_WellnessODS_04.ss'),
    ( NAME = FG_WellnessODS_05, FILENAME = 'Z:\DBSnapshots\FG_WellnessODS_05.ss'),
    ( NAME = FG_WellnessODS_06, FILENAME = 'Z:\DBSnapshots\FG_WellnessODS_06.ss')
as snapshot of WellnessODS
GO

/*
-- Drop snapshots
IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'MRM_Snapshot')
DROP DATABASE [MRM_Snapshot]
GO
IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'WellnessODS_Snapshot')
DROP DATABASE [WellnessODS_Snapshot]
GO

-- Revert snapshots
RESTORE DATABASE MRM from DATABASE_SNAPSHOT = 'MRM_Snapshot';
GO
RESTORE DATABASE WellnessODS from DATABASE_SNAPSHOT = 'WellnessODS_Snapshot';
GO

*/

