
----------------------------------------------------
--  sp_change_users_login 'report'
sp_change_users_login 'update_one', 'servicer', 'servicer'


-----------------------------------------------------------------------------------------------------------
--  clean up old stuff


--  sTEP 1. drop schemas
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
--  Step 2. Drop users or roles

declare @UserName sysname, @cmd varchar(4000), @type varchar(25)
select @UserName = '', @cmd = '', @type = ''

while 1=1
begin
  select top 1 @UserName = name, @type = type from sys.database_principals 
  where (principal_id not between 16384 and 16393) 
  and (principal_id > 4) 
  and name > @UserName order by name asc
  if @@rowcount = 0
    break
  set @cmd = 'DROP ' + CASE @type when 'R' THEN 'ROLE' else 'USER' end + ' [' + @UserName + ']' 
  EXEC (@cmd)
end

--select * from sys.database_principals

CREATE USER [DBTKUSER] FOR LOGIN [DBTKUSER] WITH DEFAULT_SCHEMA = [dbo];
CREATE USER [EntManagers] FROM LOGIN [EntManagers] WITH DEFAULT_SCHEMA = [EntManagers];
CREATE USER [servicer] FOR LOGIN [servicer] WITH DEFAULT_SCHEMA = [servicer];
CREATE USER [teamworks] FOR LOGIN [teamworks] WITH DEFAULT_SCHEMA = [dbo];
CREATE USER [TempLinkedServerUser] FOR LOGIN [TempLinkedServerUser] WITH DEFAULT_SCHEMA = [dbo];

EXEC dbo.sp_addrolemember 'db_datareader', 'servicer';
EXEC dbo.sp_addrolemember 'db_datareader', 'EntManagers';
EXEC dbo.sp_addrolemember 'db_datareader', 'teamworks';
EXEC dbo.sp_addrolemember 'db_datareader', 'TempLinkedServerUser';
EXEC dbo.sp_addrolemember 'db_datawriter', 'servicer';
EXEC dbo.sp_addrolemember 'db_datawriter', 'EntManagers';

grant view definition to [AMSA\SQL_STA_Reader];