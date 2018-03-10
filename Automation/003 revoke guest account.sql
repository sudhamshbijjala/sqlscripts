
declare @name sysname, @sql nvarchar(1000)
select @name = min(name) from sys.sysdatabases where name not in ('master','tempdb')
while @name is not null
begin
	set @sql = 'use [' + @name + ']; revoke connect from guest;'
	exec sp_executesql @sql
	select @name = min(name) from sys.sysdatabases where name not in ('master','tempdb') and name > @name
end

