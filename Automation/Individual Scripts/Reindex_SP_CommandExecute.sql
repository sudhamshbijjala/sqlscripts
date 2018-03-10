USE [master]
GO

/****** Object:  StoredProcedure [dbo].[CommandExecute]    Script Date: 07/09/2013 23:32:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[CommandExecute]

@Command varchar(max),
@Comment varchar(max),
@Mode int

AS

SET NOCOUNT ON

SET LOCK_TIMEOUT 3600000

----------------------------------------------------------------------------------------------------
--// Declare variables                                                                          //--
----------------------------------------------------------------------------------------------------

DECLARE @StartMessage varchar(max)
DECLARE @EndMessage varchar(max)
DECLARE @ErrorMessage varchar(max)

DECLARE @Error int

SET @Error = 0

----------------------------------------------------------------------------------------------------
--// Check input parameters                                                                     //--
----------------------------------------------------------------------------------------------------

IF @Command IS NULL OR @Command = ''
BEGIN
	SET @ErrorMessage = 'The value for parameter @Command is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

IF @Comment IS NULL
BEGIN
	SET @ErrorMessage = 'The value for parameter @Comment is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

IF @Mode NOT IN(1,2) OR @Mode IS NULL
BEGIN
	SET @ErrorMessage = 'The value for parameter @Mode is not supported.' + CHAR(13) + CHAR(10)
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	SET @Error = @@ERROR
END

----------------------------------------------------------------------------------------------------
--// Check error variable                                                                       //--
----------------------------------------------------------------------------------------------------

IF @Error <> 0 GOTO ReturnCode

----------------------------------------------------------------------------------------------------
--// Log initial information                                                                    //--
----------------------------------------------------------------------------------------------------

SET @StartMessage = 'DateTime: ' + CONVERT(varchar,GETDATE(),120) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Command: ' + @Command + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Comment: ' + @Comment

RAISERROR(@StartMessage,10,1) WITH NOWAIT

----------------------------------------------------------------------------------------------------
--// Execute command                                                                            //--
----------------------------------------------------------------------------------------------------

IF @Mode = 1
BEGIN
	EXECUTE(@Command)
	SET @Error = @@ERROR
END

IF @Mode = 2
BEGIN
	BEGIN TRY
		EXECUTE(@Command)
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = 'Msg ' + CAST(ERROR_NUMBER() AS varchar) + ', ' + ISNULL(ERROR_MESSAGE(),'')
		RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	END CATCH
END

----------------------------------------------------------------------------------------------------
--// Log completing information                                                                 //--
----------------------------------------------------------------------------------------------------

SET @EndMessage = 'DateTime: ' + CONVERT(varchar,GETDATE(),120) + CHAR(13) + CHAR(10)

RAISERROR(@EndMessage,10,1) WITH NOWAIT

----------------------------------------------------------------------------------------------------
--// Return code                                                                                //--
----------------------------------------------------------------------------------------------------

ReturnCode:

RETURN @Error

----------------------------------------------------------------------------------------------------




GO


