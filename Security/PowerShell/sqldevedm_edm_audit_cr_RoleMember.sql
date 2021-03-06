USE edm_audit;
--
-- Data extracted from SQLDEVEDM on Jul 21 2015 11:10AM
--
 
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'EDM_AUDIT_WR_ROLE') CREATE ROLE [EDM_AUDIT_WR_ROLE];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'EDM_AUDIT_RO_ROLE') CREATE ROLE [EDM_AUDIT_RO_ROLE];
EXEC dbo.sp_addrolemember 'EDM_AUDIT_WR_ROLE', 'PIMCO\svc_refdtd';
EXEC dbo.sp_addrolemember 'EDM_AUDIT_RO_ROLE', 'svc_edmaud_dev';
EXEC dbo.sp_addrolemember 'db_owner', 'PIMCO\edm-read-np';
EXEC dbo.sp_addrolemember 'db_owner', 'PIMCO\edm-write-np';
EXEC dbo.sp_addrolemember 'db_datareader', 'PIMCO\edm-read-np';
EXEC dbo.sp_addrolemember 'db_datareader', 'PIMCO\edm-admin-np';
EXEC dbo.sp_addrolemember 'db_datareader', 'PIMCO\edm-write-np';
EXEC dbo.sp_addrolemember 'db_datawriter', 'PIMCO\edm-read-np';
EXEC dbo.sp_addrolemember 'db_datawriter', 'PIMCO\edm-admin-np';
EXEC dbo.sp_addrolemember 'db_datawriter', 'PIMCO\edm-write-np';
