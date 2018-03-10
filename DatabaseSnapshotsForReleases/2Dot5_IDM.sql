USE Master;
GO
-- create folder if it doesn't exist
DECLARE @DirTree TABLE (subdirectory nvarchar(255), depth INT)
INSERT INTO @DirTree(subdirectory, depth) EXEC master.sys.xp_dirtree N'Z:\'
IF NOT EXISTS (SELECT 1 FROM @DirTree WHERE subdirectory = N'DBSnapshots')
EXEC master.dbo.xp_create_subdir N'Z:\DBSnapshots'


-- create snapshots
create database IDM_Insight_Snapshot ON
    ( NAME = IDM_Insight, FILENAME = 'Z:\DBSnapshots\IDM_Insight.ss'),
    ( NAME = IDM_Insight_Dim_IDM, FILENAME = 'Z:\DBSnapshots\IDM_Insight_Dim_IDM.ss'),
    ( NAME = IDM_Insight_Dim_Source, FILENAME = 'Z:\DBSnapshots\IDM_Insight_Dim_Source.ss'),
    ( NAME = IDM_Insight_Fact_IDM, FILENAME = 'Z:\DBSnapshots\IDM_Insight_Fact_IDM.ss'),
    ( NAME = IDM_Insight_Fact_Source, FILENAME = 'Z:\DBSnapshots\IDM_Insight_Fact_Source.ss'),
    ( NAME = IDM_Insight_NonClIndex_IDM, FILENAME = 'Z:\DBSnapshots\IDM_Insight_NonClIndex_IDM.ss'),
    ( NAME = IDM_Insight_NonClIndex_Source, FILENAME = 'Z:\DBSnapshots\IDM_Insight_NonClIndex_Source.ss')
as snapshot of IDM_Insight
GO
create database IDM_Staging_Snapshot ON
    ( NAME = IDM_Staging, FILENAME = 'Z:\DBSnapshots\IDM_Staging.ss'),
    ( NAME = IDM_Staging_01, FILENAME = 'Z:\DBSnapshots\IDM_Staging_01.ss'),
    ( NAME = IDM_Staging_02, FILENAME = 'Z:\DBSnapshots\IDM_Staging_02.ss')
as snapshot of IDM_Staging
GO

create database IDM_ETL_Admin_Snapshot ON
    ( NAME = IDM_ETL_Admin, FILENAME = 'Z:\DBSnapshots\IDM_ETL_Admin.ss')
as snapshot of IDM_ETL_Admin
GO

/*
-- Drop snapshots
IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'IDM_Insight_Snapshot')
DROP DATABASE [IDM_Insight_Snapshot]
GO
IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'IDM_Staging_Snapshot')
DROP DATABASE [IDM_Staging_Snapshot]
GO
IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'IDM_ETL_Admin_Snapshot')
DROP DATABASE [IDM_ETL_Admin_Snapshot]
GO


-- Revert snapshots
RESTORE DATABASE IDM_Insight from DATABASE_SNAPSHOT = 'IDM_Insight_Snapshot';
GO
RESTORE DATABASE IDM_Staging from DATABASE_SNAPSHOT = 'IDM_Staging_Snapshot';
GO
RESTORE DATABASE IDM_ETL_Admin from DATABASE_SNAPSHOT = 'IDM_ETL_Admin_Snapshot';
GO

*/

