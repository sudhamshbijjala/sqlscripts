:on error exit

set nocount on;

print '--'
select '-- Data extracted from '+ @@SERVERNAME + ' on ' + cast(getDate() as varchar(50))
print '--'
print ' '

select script from tempdb.dbo.$(tbname) where script is not null;

set nocount off;
