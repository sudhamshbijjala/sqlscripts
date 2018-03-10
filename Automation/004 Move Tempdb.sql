--  Change tempdb files for small or vendor dbs
use master
go

--  Step 1. Change file path. Do not change other things as it may break it
Alter database tempdb modify file 
(	name = tempdev, 
	filename = 'P:\TEMPDB\tempdb.mdf')
go

Alter database tempdb modify file 
(	name = templog, 
	filename = 'T:\TEMPDB\templog.ldf')
go

--  Step 2. Restart MSSQL Server service

--  Step 3. Change other attributes
Alter database tempdb modify file 
(	name = tempdev, 
	size = 20GB,
	filegrowth = 0)
go

Alter database tempdb modify file 
(	name = templog, 
	size = 20GB,
	filegrowth = 0)
go