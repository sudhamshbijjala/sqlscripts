USE [master]
GO

if OBJECT_ID ('sp_ScriptDBSecurity', 'P') is not null
	DROP PROCEDURE [dbo].[sp_ScriptDBSecurity]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




create procedure [dbo].[sp_ScriptDBSecurity] (@DBName sysname)

as
/*
	exec sp_ScriptDBSecurity 'WellnessODS'
*/

set nocount on

declare @string varchar(max)--, @dbname sysname
select @string = ''--, @dbname = db_name()


if OBJECT_ID ('tempdb.dbo.UserAccountToKeep', 'U') is not null
  drop table tempdb.dbo.UserAccountToKeep;

create table tempdb.dbo.UserAccountToKeep
( Id int identity primary key clustered,
  Name sysname NULL,
  Type varchar(10) NULL,
  DefaultSchema sysname NULL,
  OwnerName sysname null, 
  Script varchar(1000) NULL,
  ScriptTime datetime not null default current_timestamp);
  
if OBJECT_ID ('tempdb.dbo.RoleMemberMapping', 'U') is not null
  drop table tempdb.dbo.RoleMemberMapping;
  
create table tempdb.dbo.RoleMemberMapping
( MappingId int identity,
  RoleType sysname NULL,
  RoleName sysname NULL,
  RoleMember sysname NULL,
  Script varchar(1000) null default '');

if OBJECT_ID ('tempdb.dbo.UserPermission', 'U') is not null
  drop table tempdb.dbo.UserPermission;
  
create table tempdb.dbo.UserPermission
( UserPermissionId int identity,
  Grantor sysname NULL,
  Status varchar(25) NULL,
  Permission varchar(255) NULL,
  [ON] varchar(3) NULL,
  [Schema] sysname NULL,
  [Object] varchar(255) NULL,
  [TO] varchar(3) NULL,
  Grantee sysname NULL,
  Scope varchar(20) NULL,
  Script varchar(1000));

/************  Save user account information from @DBName ***********/

set @string = '
	use ['+ @DBName + '];
	insert into tempdb.dbo.UserAccountToKeep (Name, Type, DefaultSchema, OwnerName)
	select d.name, d.type, d.default_schema_name, p.name from sys.database_principals d
	left outer join sys.database_principals p on p.principal_id = d.owning_principal_id
	where d.principal_id between 5 and 16383
	and d.type in (''G'', ''U'', ''S'')
	'
--print @string
exec (@string)

update tempdb.dbo.UserAccountToKeep 
set Script = 'USE [' + @dbname + ']; CREATE ' + 
case when [Type] = 'R' then 'ROLE ' when [Type] IN ('G', 'U', 'S') then 'USER ' end 
+ '[' + Name + ']'
+ case when [Type] = 'G' then ' FROM LOGIN [' + name + '];' 
       when [Type] = 'R' then ' AUTHORIZATION [' + OwnerName + '];' 
       when [Type] = 'U' then ' FROM LOGIN [' + name + '] WITH DEFAULT_SCHEMA = [' + DefaultSchema + '];'
       when [Type] = 'S' then ' FOR LOGIN [' + name + '] WITH DEFAULT_SCHEMA = [' + DefaultSchema + '];' 
end 

--select Script from tempdb.dbo.UserAccountToKeep order by name asc;


/************  Save roles and role membership from @DBName  ***********/

--  User created database roles
set @string = '
	use ['+ @DBName + '];
	insert into tempdb.dbo.RoleMemberMapping
	select ''DB Role'', name, null,  
	''IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''''''+ name + '''''') CREATE ROLE ['' + name + ''];''
	from sys.database_principals where type = ''R'' and is_fixed_role <> 1
	and principal_id > 4
	'
--print @string
exec (@string)

--  Role membership
set @string = '
	use ['+ @DBName + '];
	insert into tempdb.dbo.RoleMemberMapping
	select ''DB Role'' as ''RoleType'', c.name as ''RoleName'', c2.name as ''RoleMember'', null 
	from sys.database_role_members r  
	join sys.database_principals c
	on r.role_principal_id = c.principal_id
	join sys.database_principals c2
	on r.member_principal_id = c2.principal_id
	where c2.name not in (''dbo'')
	'
--print @string
exec (@string)

  update tempdb.dbo.RoleMemberMapping set Script = 
    case when RoleType = 'DB Role' then 'EXEC [' + @dbname + '].dbo.sp_addrolemember ''' + RoleName + ''', ''' + RoleMember + ''';'
    else Script end
  where Script is null

update tempdb.dbo.RoleMemberMapping set Script = '--' where Script is null 

--select script from tempdb.dbo.RoleMemberMapping order by MappingId asc, RoleName asc, RoleMember asc


/************  Save permissions from @DBName  ***********/

set @string = '
	use ['+ @DBName + '];
	insert into tempdb.dbo.UserPermission
	select c2.name as ''Grantor'', m.state_desc as ''Status'', m.permission_name as ''Explicit permission'',
	  '''', '''', '''', ''TO'', c.name as ''Grantee'', ''-- '' + m.class_desc as ''Scope'', null 
	from  sys.server_permissions m  
	join sys.server_principals c
	on m.Grantee_principal_id = c.principal_id
	join sys.server_principals c2
	on m.Grantor_principal_id = c2.principal_id
	where c.type not in (''C'', ''K'')  
	UNION
	select USER_NAME(grantor_principal_id) as ''Grantor'', state_desc as ''Status'', permission_name as ''Explicit permissio'', 
	case when class in (1, 3) then ''ON '' else '''' end, 
	case when m.major_id < 0 THEN ''sys'' when class = 3 then schema_name(m.major_id) else schema_name(o.schema_id) end as ''Schema'', --o.schema_id,
	case when m.major_id <> 1 then object_name(m.major_id) else '''' end as ''Object'', ''TO'', 
	user_name(m.grantee_principal_id) as ''Grantee'', ''-- '' + m.class_desc as ''Scope'', null 
	from sys.database_permissions m 
	left outer JOIN SYS.OBJECTS o
	on o.object_id = m.major_id
	'

--print @string
exec (@string)

update tempdb.dbo.UserPermission 
	set Script =
	case 
	when Scope like '%SCHEMA' then 'USE [' + @dbname + ']; ' + [Status] + ' ' + Permission + ' ON SCHEMA::' + [Schema] + ' TO ' + quotename(Grantee, '[') + ';'
	when Scope like '%OBJECT_OR_COLUMN%' then 'USE [' + @dbname + ']; ' + [Status] + ' ' + Permission + ' ON ' + [Schema] + '.' + [Object] + ' TO ' + quotename(Grantee, '[') + ';'
	when Scope like '%SERVER' OR Scope like '%ENDPOINT' then 'USE master; ' + [Status] + ' ' + Permission + ' TO ' + quotename(Grantee, '[')+ ';'
	--NULLIF(quotename(Grantee, '['), '[public]') + ';'
	when (Scope like '%DATABASE' AND Grantee <> 'dbo') OR Scope like '%SERVER' OR Scope like '%ENDPOINT' then 'USE [' + @dbname + ']; ' + [Status] + ' ' + Permission + ' TO ' + quotename(Grantee, '[') + ';' END

update tempdb.dbo.UserPermission 
	set Script = '--' where Script is null 
	or Script like 'USE master;%'
	  --or Script = 'USE master; GRANT CONNECT SQL TO [sa];'
	  --or Script = 'USE master; GRANT CONNECT SQL TO [ASASA];'
	  --or Script = 'USE master; GRANT CONNECT TO [public];'

delete from tempdb.dbo.UserAccountToKeep where script = '--';
delete from tempdb.dbo.RoleMemberMapping where script = '--';
delete from tempdb.dbo.UserPermission where script = '--';

-- Remove previous permissions for @DBName
delete from [DatabaseServices].[dbo].[ReApplySecurity] where DBName = @DBName

-- Insert current permissions for @DBName
insert into [DatabaseServices].[dbo].[ReApplySecurity] 
(DBName, SQLStatement)
select @DBName, Script from tempdb.dbo.UserAccountToKeep order by name asc;

insert into [DatabaseServices].[dbo].[ReApplySecurity] 
(DBName, SQLStatement)
select @DBName, script from tempdb.dbo.RoleMemberMapping order by MappingId asc, RoleName asc, RoleMember asc

insert into [DatabaseServices].[dbo].[ReApplySecurity] 
(DBName, SQLStatement)
select @DBName, script from tempdb.dbo.UserPermission 
where grantee != 'public'
--where permission = 'administer bulk operations' 
ORDER BY UserPermissionId asc

declare @id int, @SQL nvarchar(max)
select @id = min(PKId) from [DatabaseServices].[dbo].[ReApplySecurity]  where DBName = @DBName
while @id is not null
begin
	select @SQL = SQLStatement from [DatabaseServices].[dbo].[ReApplySecurity] where PKId = @id
	print @SQL
	--exec @SQL
	select @id = min(PKId) from [DatabaseServices].[dbo].[ReApplySecurity]  where DBName = @DBName and PKId > @id
end

--select * from [DatabaseServices].[dbo].[ReApplySecurity] 
--where DBName = 'BOPS'
--order by PKId

-- Cleanup
if OBJECT_ID ('tempdb.dbo.UserAccountToKeep', 'U') is not null
  drop table tempdb.dbo.UserAccountToKeep;
if OBJECT_ID ('tempdb.dbo.RoleMemberMapping', 'U') is not null
  drop table tempdb.dbo.RoleMemberMapping;
if OBJECT_ID ('tempdb.dbo.UserPermission', 'U') is not null
  drop table tempdb.dbo.UserPermission;




GO


