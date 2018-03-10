USE [master]
GO

/****** Object:  UserDefinedFunction [dbo].[DatabaseSelect]    Script Date: 07/09/2013 23:29:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE FUNCTION [dbo].[DatabaseSelect] (@DatabaseList varchar(max))

RETURNS @Database TABLE(DatabaseName varchar(max) NOT NULL)

AS

BEGIN

	DECLARE @Database01 TABLE(	DatabaseName varchar(max),
								DatabaseStatus bit)

	DECLARE @Database02 TABLE(	DatabaseName varchar(max),
								DatabaseStatus bit)
	
	DECLARE @DatabaseItem varchar(max)
	DECLARE @Position int
	
	SET @DatabaseList = LTRIM(RTRIM(@DatabaseList))
	SET @DatabaseList = REPLACE(@DatabaseList,' ','')
	SET @DatabaseList = REPLACE(@DatabaseList,'[','')
	SET @DatabaseList = REPLACE(@DatabaseList,']','')
	SET @DatabaseList = REPLACE(@DatabaseList,'''','')
	SET @DatabaseList = REPLACE(@DatabaseList,'"','')

	WHILE CHARINDEX(',,',@DatabaseList) > 0 SET @DatabaseList = REPLACE(@DatabaseList,',,',',')

	IF RIGHT(@DatabaseList,1) = ',' SET @DatabaseList = LEFT(@DatabaseList,LEN(@DatabaseList) - 1)
	IF LEFT(@DatabaseList,1) = ','	SET @DatabaseList = RIGHT(@DatabaseList,LEN(@DatabaseList) - 1)

	WHILE LEN(@DatabaseList) > 0
	BEGIN
		SET @Position = CHARINDEX(',', @DatabaseList)
		IF @Position = 0
		BEGIN
			SET @DatabaseItem = @DatabaseList
			SET @DatabaseList = ''
		END
		ELSE
		BEGIN
			SET @DatabaseItem = LEFT(@DatabaseList, @Position - 1) 
			SET @DatabaseList = RIGHT(@DatabaseList, LEN(@DatabaseList) - @Position)
		END
		INSERT INTO @Database01 (DatabaseName) VALUES(@DatabaseItem)
	END
	
	UPDATE @Database01
	SET DatabaseStatus = 1
	WHERE DatabaseName NOT LIKE '-%'

	UPDATE @Database01
	SET	DatabaseName = RIGHT(DatabaseName,LEN(DatabaseName) - 1), DatabaseStatus = 0
	WHERE DatabaseName LIKE '-%'

	INSERT INTO @Database02 (DatabaseName, DatabaseStatus)
	SELECT DISTINCT DatabaseName, DatabaseStatus
	FROM @Database01
	WHERE DatabaseName NOT IN('SYSTEM_DATABASES','USER_DATABASES')

	IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'SYSTEM_DATABASES' AND DatabaseStatus = 0)
	BEGIN
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('master', 0)
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('model', 0)
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('msdb', 0)
	END

	IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'SYSTEM_DATABASES' AND DatabaseStatus = 1)
	BEGIN
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('master', 1)
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('model', 1)
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('msdb', 1)
	END

	IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'USER_DATABASES' AND DatabaseStatus = 0)
	BEGIN
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus)
		SELECT [name], 0
		FROM sys.databases
		WHERE database_id > 4
	END

	IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'USER_DATABASES' AND DatabaseStatus = 1)
	BEGIN
		INSERT INTO @Database02 (DatabaseName, DatabaseStatus)
		SELECT [name], 1
		FROM sys.databases
		WHERE database_id > 4
	END
				
	INSERT INTO @Database (DatabaseName)
	SELECT [name]
	FROM sys.databases
	WHERE [name] <> 'tempdb'
	INTERSECT
	SELECT DatabaseName
	FROM @Database02
	WHERE DatabaseStatus = 1
	EXCEPT
	SELECT DatabaseName
	FROM @Database02
	WHERE DatabaseStatus = 0
		
	RETURN

END




GO


