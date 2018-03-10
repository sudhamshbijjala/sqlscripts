--//////////////////////////////////////////////////////////////////////
--  Revision: 		$Revision: 1 $
--  WorkFile Name:	$Workfile: DBUpdate_MRM_RTA_49511_927.sql $
--  ASA Proprietary Information
--//////////////////////////////////////////////////////////////////////

--This script changes the clustered index on selected tables in order to improve performance
--For each listed table:  drop fks referencing the table, drop the old pk constraint, 
--add the new pk constraint, add the identity, add the cluster on the identity, recreate the fks


DECLARE @DBUpdateHistory_cd     varchar(16)
DECLARE @DBUpdateHistory_cd1    varchar(16)

DECLARE @This_ver				varchar(8)
DECLARE @DB_Ver					int
DECLARE @Current_Release_num	int
DECLARE @Current_Build_num		int
DECLARE @Object_nm				varchar(60)
DECLARE @Object_Type_cd			varchar(16)
DECLARE @Event_Type_cd			varchar(16)
DECLARE @Error_num				int
DECLARE @End_dt					datetime
DECLARE @Remarks				varchar(255)

SELECT @This_ver				= RIGHT(dbo.cmn_f_DbVersion(),8)
SELECT @DB_Ver				    = dbo.cmn_f_DbVersion()

/* use these lines for testing in personal local database only */
--SELECT @This_ver				= '12345678' --RIGHT(dbo.cmn_f_DbVersion(),8)
--SELECT @DB_Ver				    = '1234567890' --dbo.cmn_f_DbVersion()

SELECT @Current_Release_num		= NULL	--Set to Bundle_ID if known; else leave NULL and set when merged to Bundle Stream
SELECT @Current_Build_num		= 927	--Unique Incremental Script Number
SELECT @Object_nm				= 'DBUpdate_MRM_RTA_49511_927' --Set to script name
SELECT @Object_Type_cd			= 'SCHEMA' --default is 'SCHEMA'
SELECT @Event_Type_cd			= 'UPGRADE'

--**************************************************************************************************
/* Following columns are used to construct messages and sql statements                            */
--**************************************************************************************************
DECLARE @v_drop_fk_sql nvarchar(1000);
DECLARE @v_add_fk_sql nvarchar(1000);
DECLARE @fk_constraint_name  nvarchar(100);
DECLARE @FK_TableName  nvarchar(100);
DECLARE @FK_ColName  nvarchar(100);
DECLARE @FK_RefColName  nvarchar(100);
DECLARE @InProgressMsg nvarchar(1000);
DECLARE @pk_constraint_name nvarchar(1000);
DECLARE @pk_drop_sql  nvarchar(1000);
DECLARE @pk_add_sql  nvarchar(1000);
DECLARE @identity_add_sql  nvarchar(1000);
DECLARE @identity_cluster_sql  nvarchar(1000);
DECLARE @pk_column_name nvarchar(1000);
DECLARE @clustered_id_name nvarchar(1000);
/**/

PRINT 'Beginning MRM database update script ' + @Object_nm + ' on SQL Server '+@@servername
SET NOCOUNT ON
select getdate()

PRINT ''
PRINT '**********************************************************************'
PRINT '* NOTE TO OPERATOR:  This is a database update script for MRM *'
PRINT '**********************************************************************'

IF db_name() not like 'MRM%'
BEGIN
   PRINT 'ERROR:  This script should be run in MRM database'
   return
END

--**************************************************************************************************
--*  GENERAL INSERT TO CMN_DBUpdateHistory FOR SCHEMA CHANGE                                       *
--**************************************************************************************************

EXEC cmn_GetUpdateHistoryKey @DBUpdateHistory_cd output
EXEC cmn_DBHistoryInsert @DBUpdateHistory_cd, @This_ver,@Current_Release_num,@Current_Build_num,@DB_Ver,@Current_Build_num,
		@Object_nm,@Object_Type_cd,@Event_Type_cd,@@servername,@Object_nm, -1


--**************************************************************************************************
--*  SCHEMA CHANGE PROCESSING STARTS HERE
--**************************************************************************************************

/* get the tables */

set nocount on
declare @table_name  nvarchar(100);
declare @prefix char(3);
declare @suffix char(3);
declare table_cursor cursor for
select table_name, 
		case(table_name)
			when  ('co_individual') then 'ind'
			when  ('co_individual_ext') then 'ind' 
			when ('co_individual_x_organization') then 'ixo' 
			when ('co_individual_x_organization_ext') then 'ixo' 
			when ('co_customer') then 'cst' 
			when ('co_customer_ext') then 'cst' 
			when ('co_address') then 'adr' 
			when ('co_address_ext') then 'adr' 
			when ('co_customer_x_address') then 'cxa' 
			when ('co_customer_x_address_ext') then 'cxa'
			when ('co_customer_x_phone') then 'cph'
			when ('co_phone') then 'phn'
			when ('co_phone_ext') then 'phn'
			when ('co_customer_x_phone_ext') then 'cph'
			when ('co_email') then 'eml'
			when ('co_email_ext') then 'eml'
			when ('mb_membership_proxy') then 'mpr'
			when ('mb_membership_proxy_ext') then 'mpr'
			when ('client_asa_file_import_header') then 'a21'
         end as prefix,
		 case(right(table_name, 3))
			when  'ext' then 'ext'
			else ''
		 end as suffix
from INFORMATION_SCHEMA.TABLES
where TABLE_NAME in (
						'co_individual'
                        ,'co_individual_ext'
                        ,'co_individual_x_organization'
                        ,'co_individual_x_organization_ext'
                        ,'co_customer'
                        ,'co_customer_ext'
                        ,'co_address'
                        ,'co_address_ext'
                        ,'co_customer_x_address'
                        ,'co_customer_x_address_ext'
                        ,'co_customer_x_phone'
                        ,'co_phone'
                        ,'co_phone_ext'
                        ,'co_customer_x_phone_ext'
                        ,'co_email'
                        ,'co_email_ext'
                        ,'mb_membership_proxy'
                        ,'mb_membership_proxy_ext'
                        --,'fw_change_log'
                        ,'client_asa_file_import_header'
                        --,'co_address_change_log'
                        )
and table_name 
not in 
(SELECT 
  T.[name] 
  FROM sys.[tables] AS T  
  INNER JOIN sys.[indexes] I ON T.[object_id] = I.[object_id]  
 where  1=1 
AND T.[is_ms_shipped] = 0 
AND I.type_desc = 'CLUSTERED' 
AND I.is_primary_key = 0
AND I.is_unique_constraint = 0 -- do not include UQ
AND I.is_disabled = 0
AND I.is_hypothetical = 0
and i.[name]  like 'CUIX_%')
order by table_name;

/* get the FKs into a permenant work table so that they will not be lost if this process fails. The FKs will be dropped and recreated during this process */

CREATE TABLE RTA_49511_927_FK_WorkTable
(FK_constraint_name  nvarchar(1000)
,FK_TableName nvarchar(1000)
,FK_ColName nvarchar(1000)
,FK_RefTableName nvarchar(100)
,FK_RefColName nvarchar(1000)
)

INSERT INTO RTA_49511_927_FK_WorkTable
(FK_constraint_name, FK_TableName, FK_ColName, FK_RefTableName, FK_RefColName)
SELECT 
	f.name AS ForeignKey,
	OBJECT_NAME(f.parent_object_id) AS FK_TableName,
	COL_NAME(fc.parent_object_id,
	fc.parent_column_id) AS ColumnName,
	OBJECT_NAME (f.referenced_object_id) AS ReferenceTableName,
	COL_NAME(fc.referenced_object_id,
	fc.referenced_column_id) AS ReferenceColumnName
FROM 
sys.foreign_keys AS f
INNER JOIN sys.foreign_key_columns AS fc ON f.OBJECT_ID = fc.constraint_object_id
AND OBJECT_NAME (f.referenced_object_id) in ('co_individual'
                        ,'co_individual_ext'
                        ,'co_individual_x_organization'
                        ,'co_individual_x_organization_ext'
                        ,'co_customer'
                        ,'co_customer_ext'
                        ,'co_address'
                        ,'co_address_ext'
                        ,'co_customer_x_address'
                        ,'co_customer_x_address_ext'
                        ,'co_customer_x_phone'
                        ,'co_phone'
                        ,'co_phone_ext'
                        ,'co_customer_x_phone_ext'
                        ,'co_email'
                        ,'co_email_ext'
                        ,'mb_membership_proxy'
                        ,'mb_membership_proxy_ext'
                        --,'fw_change_log'
                        ,'client_asa_file_import_header'
                        --,'co_address_change_log'
                        )

/* START PROCESSING TABLES */

open table_cursor;
fetch next from table_cursor into @table_name, @prefix, @suffix;
if @@fetch_status <> 0 PRINT 'No listed tables were found or script was already run'

while (@@FETCH_STATUS = 0)  /* start working on one table */
begin  
    
	PRINT '';
	PRINT 'Starting conversion for table ' + @table_name;

	/* Step 1:  Set up cursors and variables */

	DECLARE FK_Cursor cursor for
	SELECT FK_constraint_name, FK_TableName, FK_ColName, FK_RefColName
	FROM RTA_49511_927_FK_WorkTable
	WHERE FK_RefTableName = @Table_Name
	ORDER BY 1
	
	set @fk_constraint_name = null;
	set @FK_TableName = Null;
	set @FK_ColName = Null;
	set @FK_RefColName = Null;
	
	/* log history for removing clustered index */

	SELECT @InProgressMsg = 'Removing clustered index'
	EXEC cmn_GetUpdateHistoryKey @DBUpdateHistory_cd1 output
    EXEC cmn_DBHistoryInsert @DBUpdateHistory_cd1,@This_Ver,@Current_Release_num,@Current_Build_num,
    @Current_Release_num,@Current_Build_num,@table_name,'TABLE','Uncluster',@@servername,@InProgressMsg, NULL 
	
	/* Step 2:  drop the FKs */
	
	open FK_cursor;
	fetch next from FK_cursor into @fk_constraint_name, @FK_TableName, @FK_ColName, @FK_RefColName
	if @@fetch_status <> 0 PRINT 'No fks found for table ' + @table_name;
	
	while (@@FETCH_STATUS = 0)
	begin    
		--print 'Dropping FK on table: ' + @FK_TableName + ' column: ' + @FK_ColName + ' constraint name: ' + @fk_Constraint_name
		set @v_drop_fk_sql = 'ALTER TABLE ' + @FK_TableName + ' DROP CONSTRAINT ' + @fk_constraint_name
		--print @v_drop_fk_sql;
		execute sp_executesql @v_drop_fk_sql
		SELECT @Error_num = @@ERROR
		SELECT @End_dt = GETDATE()
		EXEC cmn_DBHistoryUpdate @DBUpdateHistory_cd1, @End_dt, @Error_num
		fetch next from FK_cursor into @fk_constraint_name, @FK_TableName, @FK_ColName, @FK_RefColName
	end;

	close fk_cursor;
	deallocate fk_cursor;

	/*  Step 3: Set up for remaining steps */

	set @pk_column_name = null;
	
	set @clustered_id_name = 
		case(@table_name)
			when ('co_customer') then 'cst_recno'
			else
				case(@suffix)
					when 'ext' then @prefix + '_identity_id' + '_ext'
					else  @prefix + '_identity_id'
				end
			end;
			
	SELECT @pk_column_name = column_name
	, @pk_constraint_name = TC.CONSTRAINT_NAME
	, @pk_drop_sql = 'alter table ' + ku.table_name  + ' drop constraint ' + tc.CONSTRAINT_NAME
	, @pk_add_sql = 'alter table ' + ku.table_name  + ' add constraint ' + tc.CONSTRAINT_NAME + ' primary key nonclustered (' + column_name + ')'
	, @identity_add_sql = 'alter table ' + ku.table_name  + ' add ' + @clustered_id_name + ' int identity(1,1) not null'
	, @identity_cluster_sql = 'create unique clustered index ' + 'CUIX_' + ku.table_name  + '_' + @clustered_id_name + ' on ' + ku.table_name  + '(' + @clustered_id_name + ')'
		FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
	  INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KU
		ON TC.CONSTRAINT_TYPE = 'PRIMARY KEY'
		AND TC.CONSTRAINT_NAME = KU.CONSTRAINT_NAME
	   and ku.table_name = @Table_Name
	
	/*  Step 4: Drop/Add PK Constraint */

	if @pk_column_name is null
		print 'pk not found '
	else begin
		--print 'dropping pk constraint ' + @pk_constraint_name + ' on column ' + @pk_column_name
		print @pk_drop_sql
		execute sp_executesql @pk_drop_sql
		SELECT @Error_num = @@ERROR
		SELECT @End_dt = GETDATE()
 		EXEC cmn_DBHistoryUpdate @DBUpdateHistory_cd1, @End_dt, @Error_num

		--print 'adding new pk constraint '
		print @pk_add_sql
		execute sp_executesql @pk_add_sql
		SELECT @Error_num = @@ERROR
		SELECT @End_dt = GETDATE()
 		EXEC cmn_DBHistoryUpdate @DBUpdateHistory_cd1, @End_dt, @Error_num
		
	
		/*	Step 3: Add Identity */
		
		/* log history for adding identity */

		SELECT @InProgressMsg = 'Adding identity'
		EXEC cmn_GetUpdateHistoryKey @DBUpdateHistory_cd1 output
		EXEC cmn_DBHistoryInsert @DBUpdateHistory_cd1,@This_Ver,@Current_Release_num,@Current_Build_num,
		@Current_Release_num,@Current_Build_num,@table_name,'TABLE','Add Identity',@@servername,@InProgressMsg, NULL 
			
		/*	Add Identity  */
		
		if @table_name <> 'co_customer'
		begin
			--print 'adding identity column '
			print @identity_add_sql
			execute sp_executesql @identity_add_sql
			SELECT @Error_num = @@ERROR
			SELECT @End_dt = GETDATE()
 			EXEC cmn_DBHistoryUpdate @DBUpdateHistory_cd1, @End_dt, @Error_num
		end
		
		/* log history for new clustered index*/

		SELECT @InProgressMsg = 'Adding cluster on identity'
		EXEC cmn_GetUpdateHistoryKey @DBUpdateHistory_cd1 output
		EXEC cmn_DBHistoryInsert @DBUpdateHistory_cd1,@This_Ver,@Current_Release_num,@Current_Build_num,
		@Current_Release_num,@Current_Build_num,@table_name,'TABLE','Add Clustering',@@servername,@InProgressMsg, NULL 
			
		--print 'adding new clustered index '
		print @identity_cluster_sql
		execute sp_executesql @identity_cluster_sql
		SELECT @Error_num = @@ERROR
		SELECT @End_dt = GETDATE()
 		EXEC cmn_DBHistoryUpdate @DBUpdateHistory_cd1, @End_dt, @Error_num
	end;
	
	/* step 3: add back FKs */

	DECLARE FK_Cursor cursor for
	SELECT FK_constraint_name, FK_TableName, FK_ColName, FK_RefColName
	FROM RTA_49511_927_FK_WorkTable
	WHERE FK_RefTableName = @Table_Name
	ORDER BY 1
	
	set @fk_constraint_name = null;
	set @FK_TableName = Null;
	set @FK_ColName = Null;
	set @FK_RefColName = Null;
	
	open FK_cursor;
	fetch next from FK_cursor into @fk_constraint_name, @FK_TableName, @FK_ColName, @FK_RefColName
	if @@fetch_status <> 0 PRINT 'No fks found for table ' + @table_name;
	
	while (@@FETCH_STATUS = 0)
	begin    
		--print 'Adding FK on table: ' + @FK_TableName + ' column: ' + @FK_ColName + ' constraint name: ' + @fk_Constraint_name;
		set @v_add_fk_sql =  'ALTER TABLE ' + @FK_TableName + ' ADD  CONSTRAINT ' + @FK_constraint_Name + ' FOREIGN KEY([' + @FK_ColName + ']) REFERENCES ' + @Table_name+ ' ([' + @FK_RefColName + '])'
		
		SELECT @InProgressMsg = 'Re-creating FK ' + @FK_Constraint_Name
		EXEC cmn_GetUpdateHistoryKey @DBUpdateHistory_cd1 output
		EXEC cmn_DBHistoryInsert @DBUpdateHistory_cd1,@This_Ver,@Current_Release_num,@Current_Build_num,
		@Current_Release_num,@Current_Build_num,@table_name,'TABLE','Add FK',@@servername,@InProgressMsg, NULL 
					
		--print @v_add_fk_sql;
		execute sp_executesql @v_add_fk_sql
		SELECT @Error_num = @@ERROR
		SELECT @End_dt = GETDATE()
 		EXEC cmn_DBHistoryUpdate @DBUpdateHistory_cd1, @End_dt, @Error_num
		fetch next from FK_cursor into @fk_constraint_name, @FK_TableName, @FK_ColName, @FK_RefColName
	end;

	close fk_cursor;
	deallocate fk_cursor;
	
	print '--Done with table ' + @table_name;
	
	fetch next from table_cursor into @table_name, @prefix, @suffix;

end;

close table_cursor;
deallocate table_cursor;
drop table RTA_49511_927_FK_WorkTable;

--**************************************************************************************************
--*  FINAL UPDATE TO CMN_DBUpdateHistory AND DBS_Parameter for Current Database Version            *
--**************************************************************************************************
SELECT @This_ver		= RIGHT(dbo.cmn_f_DbVersion(),8)
SELECT @DB_Ver			= dbo.cmn_f_DbVersion()

UPDATE	cmn_DBUpdateHistory
SET		Database_Version = @This_ver,
		Compatible_Release_num = @DB_ver
WHERE	Current_Build_num = @Current_Build_num
 AND	ISNULL(Error_num,0) = 0

PRINT ' '
PRINT 'Your database is now at version: ' + CAST(@This_ver as varchar)
PRINT ' '
PRINT 'DB update script for  Database version ' + CAST(@This_ver as varchar) + ' completed.'
SELECT getdate()
SET NOCOUNT OFF
GO


