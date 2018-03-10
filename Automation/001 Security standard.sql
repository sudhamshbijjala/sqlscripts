--  This script handles login security
--  based on DBA's << SQL Server and Database Standard >>

--  Grant DBA group access to all SQL Servers
if not exists (select * from sys.server_principals where name = 'AMSA\prodDBA')
  create login [AMSA\prodDBA] from windows;

exec dbo.sp_addsrvrolemember 'AMSA\prodDBA', 'sysadmin';

--  Delete builtin administrator account
if exists (select * from sys.server_principals where name = 'BUILTIN\Administrators')
  drop login [BUILTIN\Administrators];

--  Rename SA account, password protect it and disable it
if exists (select * from sys.server_principals where name = 'sa')
  begin
    ALTER LOGIN sa WITH 
		NAME = ASASA, 
		PASSWORD = 'P@ssw0rd' MUST_CHANGE, 
		CHECK_EXPIRATION = ON, 
		CHECK_POLICY = ON, 
		DEFAULT_DATABASE=[master], 
		DEFAULT_LANGUAGE=[us_english];
	ALTER LOGIN ASASA DISABLE;
  end

--  Choose which access to grant
/*
if not exists (select * from sys.server_principals where name = 'AMSA\SQL_DEV_Reader')
  create login [AMSA\SQL_DEV_Reader] from windows;

if not exists (select * from sys.server_principals where name = 'AMSA\SQL_TST_Reader')
  create login [AMSA\SQL_TST_Reader] from windows;

if not exists (select * from sys.server_principals where name = 'AMSA\SQL_STG_Reader')
  create login [AMSA\SQL_STG_Reader] from windows;

if not exists (select * from sys.server_principals where name = 'AMSA\SQL_PRD_Reader')
  create login [AMSA\SQL_PRD_Reader] from windows;
*/



