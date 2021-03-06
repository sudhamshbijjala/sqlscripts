USE edm_audit;
--
-- Data extracted from SQLDEVEDM on Jul 21 2015 11:10AM
--
 
CREATE USER [PIMCO\edm-read-np] FROM LOGIN [PIMCO\edm-read-np];
CREATE USER [PIMCO\edm-admin-np] FROM LOGIN [PIMCO\edm-admin-np];
CREATE USER [PIMCO\edm-write-np] FROM LOGIN [PIMCO\edm-write-np];
CREATE ROLE [EDM_AUDIT_WR_ROLE] AUTHORIZATION [dbo];
CREATE USER [svc_edmaud_dev] FOR LOGIN [svc_edmaud_dev] WITH DEFAULT_SCHEMA = [dbo];
CREATE ROLE [EDM_AUDIT_RO_ROLE] AUTHORIZATION [dbo];
CREATE USER [PIMCO\svc_refdtd] FROM LOGIN [PIMCO\svc_refdtd] WITH DEFAULT_SCHEMA = [dbo];
