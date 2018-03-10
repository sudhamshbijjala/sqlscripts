

  SELECT object_name(i.object_id) AS 'Object Name',
	     i.object_id AS 'Object Id',
         i.name AS 'Idex Name',
         i.index_id AS 'Index Id',
         fg.name AS 'Filegroup Name',
         df.name AS 'Data File Logical Name',
         df.physical_name AS 'Data File Physical Name & Location',
         df.size/128 AS 'Size (MB)'
    FROM sys.indexes i
    JOIN sys.filegroups fg
      ON i.data_space_id = fg.data_space_id 
    JOIN sys.database_files df
      ON fg.data_space_id = df.data_space_id
   WHERE objectproperty(i.object_id, 'IsMSShipped') = 0
     AND fg.[type] = 'FG' 
ORDER BY [Object Name] ASC, i.index_id ASC;
         
