--  This script creates Database Mail using T-SQL stored procedures
--  Created by Richard ding
--  Created on 6/15/2009
--  Modify the variables as necessary in Section 4.
--  Run the whole script. If everything works, you should get a test email

/*********** You only need to manually polulate the variables ***********/


/* Section 1 - Enable Database Mail on the SQL Server */
use master
exec sp_configure 'Show Advanced Options', 1
reconfigure with override
exec sp_configure 'Database Mail XPs', 1
reconfigure with override


/* Section 2 - Set up security for users who can send database mails */
use msdb
if not exists (select * from sys.server_principals where name = 'AMSA\ProdDBA')
  begin
    create login [amsa\ProdDBA] from windows;
    exec sp_addsrvrolemember 'AMSA\ProdDBA', 'sysadmin'
  end
if not exists (select * from sys.database_principals where name = 'AMSA\ProdDBA')
  create user [amsa\ProdDBA] for login [amsa\ProdDBA]
exec sp_addrolemember 'DatabaseMailUserRole', 'amsa\ProdDBA'


/* Section 3 - Set up an opertor */
USE [msdb]
GO
IF  EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'DBA')
EXEC msdb.dbo.sp_delete_operator @name=N'DBA'
GO

EXEC msdb.dbo.sp_add_operator @name=N'DBA', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'dba@amsa.com', 
		@category_name=N'[Uncategorized]'
GO

/* Section 4 - Populate variables as needed */
declare @ProfileName sysname,
        @PrincipalName sysname,
        @AcctName sysname, 
        @EmailAddr sysname, 
        @DisplayName varchar(50), 
        @ReplyToAddr sysname, 
        @Desc varchar(255), 
        @SMTPServer sysname,
        @RecipientName sysname,
        @SubjectLine varchar(255),
        @BodyText varchar(max)

select  @ProfileName = @@servername,
        @PrincipalName = 'amsa\ProdDBA',
        @AcctName = 'DBA', 
        @EmailAddr = 'DBA@amsa.com', 
        @DisplayName = 'SQL Alert (' + @@servername + ')', 
        @ReplyToAddr = 'DBA@amsa.com', 
        @Desc = 'db mail account for DBA', 
        @SMTPServer = 'mailhost.amsa.com',
        @RecipientName = 'DBA@amsa.com',
        @SubjectLine = 'database mail test from ' + @@servername + '',
        @BodyText = 'Please ignore.'
--  select  @ProfileName, @AcctName, @EmailAddr, @DisplayName, @ReplyToAddr, @Desc, @SMTPServer

/* Section 5 - Create a Database Mail account */
exec msdb.dbo.sysmail_add_account_sp   
  @account_name = @AcctName,                 
  @email_address = @EmailAddr,        
  @display_name = @DisplayName,               
  @replyto_address = @ReplyToAddr,      
  @description = @Desc,     
  @mailserver_name = @SMTPServer,            
  @mailserver_type = 'SMTP',                
  @port = 25,                               
  @use_default_credentials = 1,                          
  @enable_ssl = 0;

/* Section 6 - Create a Database Mail profile */
exec msdb.dbo.sysmail_add_profile_sp
  @profile_name = @ProfileName,
  @description = 'Profile A used for database mail.' ;

/* Section 7 - Adds a Database Mail account to a profile */
exec msdb.dbo.sysmail_add_profileaccount_sp 
  @profile_name = @ProfileName, 
  @account_name = @AcctName,
  @sequence_number = 1; 

/* Section 8 - Grants permission for an msdb user or public to use Database Mail profile */
EXEC msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = @ProfileName,
    @principal_name = @PrincipalName,
    @is_default = 1; 


/* Section 9 - Test sending Database Mail message */
declare @rtn int
exec msdb.dbo.sp_send_dbmail   
  @profile_name = @profileName,
  @recipients = @RecipientName,
  @subject = @SubjectLine, 
  @body = @BodyText,
  @mailitem_id = @rtn
select @rtn
