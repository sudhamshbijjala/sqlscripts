--  For XI
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = '\\e1srv\SQL_Backups\XI\XI_backup_201004140500.bak'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE XI SET OffLINE WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE XI FROM DISK = @BackupFile WITH REPLACE, STATS = 1, 
MOVE 'XI_log' TO 'H:\SQL\LOG\XI\XI_LOG.LDF',
MOVE 'XI_dat' TO 'G:\SQL\DATA\XI\XI.MDF'


----  For Confidential
--DECLARE @BackupFile VARCHAR(255)
--SET @BackupFile = '\\e1srv\SQL_Backups\Confidential\Confidential_backup_201004140500.bak'
--RESTORE FILELISTONLY FROM DISK = @BackupFile; 

--ALTER DATABASE Confidential SET OffLINE WITH ROLLBACK IMMEDIATE;

--RESTORE DATABASE Confidential FROM DISK = '\\e1srv\SQL_Backups\Confidential\Confidential_backup_200911040500.bak' WITH STATS = 1, REPLACE, NORECOVERY, 
--MOVE 'Confidential_Log' TO 'H:\SQL\LOG\Confidential\Confidential_log.ldf',
--MOVE 'Confidential_Data' TO 'G:\SQL\DATA\Confidential\Confidential.mdf'


--RESTORE DATABASE [Security] FROM DISK = '\\e1srv\SQL_Backups\Security\Security_backup_200911040500.bak' WITH STATS = 1, REPLACE, NORECOVERY, 
--MOVE 'Security_Log' TO 'H:\SQL\LOG\Security\Security_log.ldf',
--MOVE 'Security_Data' TO 'G:\SQL\DATA\Security\Security_data.mdf'

--  For BOPS
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = '\\e1srv\SQL_Backups\BOPS\BOPS_backup_201004140500.bak'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE BOPS SET OffLINE WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE BOPS FROM DISK = @BackupFile WITH REPLACE, STATS = 1,
MOVE 'Bops_log' TO 'H:\SQL\LOG\bops\BOPS_LOG.LDF',
MOVE 'Bops_dat' TO 'G:\SQL\DATA\bops\BOPS.MDF'


--  For enterprise
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = '\\e1srv\SQL_Backups\Enterprise\enterprise_backup_201004140500.bak'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

--ALTER DATABASE enterprise SET OffLINE WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE enterprise FROM DISK = @BackupFile WITH REPLACE, STATS = 1,
MOVE 'TransactionTable_idx01' TO 'G:\SQL\DATA\Enterprise\TransactionTable_idx01.ndf',
MOVE 'TransactionTable_dat02' TO 'G:\SQL\DATA\Enterprise\TransactionTable_dat02.ndf',
MOVE 'TransactionTable_dat01' TO 'G:\SQL\DATA\Enterprise\TransactionTable_dat01.ndf',
MOVE 'TransactionHistory_idx03' TO 'G:\SQL\DATA\Enterprise\TransactionHistory_idx03.ndf',
MOVE 'TransactionHistory_idx02' TO 'G:\SQL\DATA\Enterprise\TransactionHistory_idx02.ndf',
MOVE 'TransactionHistory_idx01' TO 'G:\SQL\DATA\Enterprise\TransactionHistory_idx01.ndf',
MOVE 'TransactionHistory_dat03' TO 'G:\SQL\DATA\Enterprise\TransactionHistory_dat03.ndf',
MOVE 'TransactionHistory_dat02' TO 'G:\SQL\DATA\Enterprise\TransactionHistory_dat02.ndf',
MOVE 'TransactionHistory_dat01' TO 'G:\SQL\DATA\Enterprise\TransactionHistory_dat01.ndf',
MOVE 'TransactionDetail_idx04' TO 'G:\SQL\DATA\Enterprise\TransactionDetail_idx04.ndf',
MOVE 'TransactionDetail_idx03' TO 'G:\SQL\DATA\Enterprise\TransactionDetail_idx03.ndf',
MOVE 'TransactionDetail_idx02' TO 'G:\SQL\DATA\Enterprise\TransactionDetail_idx02.ndf',
MOVE 'TransactionDetail_idx01' TO 'G:\SQL\DATA\Enterprise\TransactionDetail_idx01.ndf',
MOVE 'TransactionDetail_dat04' TO 'G:\SQL\DATA\Enterprise\TransactionDetail_dat04.ndf',
MOVE 'TransactionDetail_dat03' TO 'G:\SQL\DATA\Enterprise\TransactionDetail_dat03.ndf',
MOVE 'TransactionDetail_dat02' TO 'G:\SQL\DATA\Enterprise\TransactionDetail_dat02.ndf',
MOVE 'TransactionDetail_dat01' TO 'G:\SQL\DATA\Enterprise\TransactionDetail_dat01.ndf',
MOVE 'TMPMiscellaneous_idx01' TO 'G:\SQL\DATA\Enterprise\TMPMiscellaneous_idx01.ndf',
MOVE 'TMPMiscellaneous_dat01' TO 'G:\SQL\DATA\Enterprise\TMPMiscellaneous_dat01.ndf',
MOVE 'Report_Group_idx01' TO 'G:\SQL\DATA\Enterprise\Report_Group_idx01.ndf',
MOVE 'Report_Group_dat01' TO 'G:\SQL\DATA\Enterprise\Report_Group_dat01.ndf',
MOVE 'PrincipalReduce_idx02' TO 'G:\SQL\DATA\Enterprise\PrincipalReduce_idx02.ndf',
MOVE 'PrincipalReduce_idx01' TO 'G:\SQL\DATA\Enterprise\PrincipalReduce_idx01.ndf',
MOVE 'PrincipalReduce_dat02' TO 'G:\SQL\DATA\Enterprise\PrincipalReduce_dat02.ndf',
MOVE 'PrincipalReduce_dat01' TO 'G:\SQL\DATA\Enterprise\PrincipalReduce_dat01.ndf',
MOVE 'PersonMiscellaneous_idx01' TO 'G:\SQL\DATA\Enterprise\PersonMiscellaneous_idx01.ndf',
MOVE 'PersonMiscellaneous_dat01' TO 'G:\SQL\DATA\Enterprise\PersonMiscellaneous_dat01.ndf',
MOVE 'Person_idx01' TO 'G:\SQL\DATA\Enterprise\Person_idx01.ndf',
MOVE 'Person_dat01' TO 'G:\SQL\DATA\Enterprise\Person_dat01.ndf',
MOVE 'MiscMiscellaneous_idx01' TO 'G:\SQL\DATA\Enterprise\MiscMiscellaneous_idx01.ndf',
MOVE 'MiscMiscellaneous_dat01' TO 'G:\SQL\DATA\Enterprise\MiscMiscellaneous_dat01.ndf',
MOVE 'LoanMiscellaneous_idx01' TO 'G:\SQL\DATA\Enterprise\LoanMiscellaneous_idx01.ndf',
MOVE 'LoanMiscellaneous_dat01' TO 'G:\SQL\DATA\Enterprise\LoanMiscellaneous_dat01.ndf',
MOVE 'Loan_idx02' TO 'G:\SQL\DATA\Enterprise\Loan_idx02.ndf',
MOVE 'Loan_idx01' TO 'G:\SQL\DATA\Enterprise\Loan_idx01.ndf',
MOVE 'Loan_dat02' TO 'G:\SQL\DATA\Enterprise\Loan_dat02.ndf',
MOVE 'Loan_dat01' TO 'G:\SQL\DATA\Enterprise\Loan_dat01.ndf',
MOVE 'HistoryComment_idx01' TO 'G:\SQL\DATA\Enterprise\HistoryComment_idx01.ndf',
MOVE 'HistoryComment_dat01' TO 'G:\SQL\DATA\Enterprise\HistoryComment_dat01.ndf',
MOVE 'EventMiscellaneous_idx01' TO 'G:\SQL\DATA\Enterprise\EventMiscellaneous_idx01.ndf',
MOVE 'EventMiscellaneous_dat01' TO 'G:\SQL\DATA\Enterprise\EventMiscellaneous_dat01.ndf',
MOVE 'Enterprise_log08' TO 'H:\SQL\LOG\Enterprise\Enterprise_log08.ldf',
MOVE 'Enterprise_log07' TO 'H:\SQL\LOG\Enterprise\Enterprise_log07.ldf',
MOVE 'Enterprise_log06' TO 'H:\SQL\LOG\Enterprise\Enterprise_log06.ldf',
MOVE 'Enterprise_log05' TO 'H:\SQL\LOG\Enterprise\Enterprise_log05.ldf',
MOVE 'Enterprise_log04' TO 'H:\SQL\LOG\Enterprise\Enterprise_log04.ldf',
MOVE 'Enterprise_log03' TO 'H:\SQL\LOG\Enterprise\Enterprise_log03.ldf',
MOVE 'Enterprise_log02' TO 'H:\SQL\LOG\Enterprise\Enterprise_log02.ldf',
MOVE 'Enterprise_log01' TO 'H:\SQL\LOG\Enterprise\Enterprise_log01.ldf',
MOVE 'Enterprise_idx01' TO 'G:\SQL\DATA\Enterprise\Enterprise_idx01.ndf',
MOVE 'Enterprise_dat01' TO 'G:\SQL\DATA\Enterprise\Enterprise_dat01.mdf',
MOVE 'Disbursement_idx02' TO 'G:\SQL\DATA\Enterprise\Disbursement_idx02.ndf',
MOVE 'Disbursement_idx01' TO 'G:\SQL\DATA\Enterprise\Disbursement_idx01.ndf',
MOVE 'Disbursement_dat02' TO 'G:\SQL\DATA\Enterprise\Disbursement_dat02.ndf',
MOVE 'Disbursement_dat01' TO 'G:\SQL\DATA\Enterprise\Disbursement_dat01.ndf',
MOVE 'DisbMiscellaneous_idx02' TO 'G:\SQL\DATA\Enterprise\DisbMiscellaneous_idx02.ndf',
MOVE 'DisbMiscellaneous_idx01' TO 'G:\SQL\DATA\Enterprise\DisbMiscellaneous_idx01.ndf',
MOVE 'DisbMiscellaneous_dat02' TO 'G:\SQL\DATA\Enterprise\DisbMiscellaneous_dat02.ndf',
MOVE 'DisbMiscellaneous_dat01' TO 'G:\SQL\DATA\Enterprise\DisbMiscellaneous_dat01.ndf',
MOVE 'Demog_idx01' TO 'G:\SQL\DATA\Enterprise\Demog_idx01.ndf',
MOVE 'Demog_dat01' TO 'G:\SQL\DATA\Enterprise\Demog_dat01.ndf',
MOVE 'Comment_idx04' TO 'G:\SQL\DATA\Enterprise\Comment_idx04.ndf',
MOVE 'Comment_idx03' TO 'G:\SQL\DATA\Enterprise\Comment_idx03.ndf',
MOVE 'Comment_idx02' TO 'G:\SQL\DATA\Enterprise\Comment_idx02.ndf',
MOVE 'Comment_idx01' TO 'G:\SQL\DATA\Enterprise\Comment_idx01.ndf',
MOVE 'Comment_dat04' TO 'G:\SQL\DATA\Enterprise\Comment_dat04.ndf',
MOVE 'Comment_dat03' TO 'G:\SQL\DATA\Enterprise\Comment_dat03.ndf',
MOVE 'Comment_dat02' TO 'G:\SQL\DATA\Enterprise\Comment_dat02.ndf',
MOVE 'Comment_dat01' TO 'G:\SQL\DATA\Enterprise\Comment_dat01.ndf',
MOVE 'CollectionPayment_idx01' TO 'G:\SQL\DATA\Enterprise\CollectionPayment_idx01.ndf',
MOVE 'CollectionPayment_dat02' TO 'G:\SQL\DATA\Enterprise\CollectionPayment_dat02.ndf',
MOVE 'CollectionPayment_dat01' TO 'G:\SQL\DATA\Enterprise\CollectionPayment_dat01.ndf',
MOVE 'CollectionMiscellaneous_idx01' TO 'G:\SQL\DATA\Enterprise\CollectionMiscellaneous_idx01.ndf',
MOVE 'CollectionMiscellaneous_dat01' TO 'G:\SQL\DATA\Enterprise\CollectionMiscellaneous_dat01.ndf',
MOVE 'CollectionDefaultedLoan_idx01' TO 'G:\SQL\DATA\Enterprise\CollectionDefaultedLoan_idx01.ndf',
MOVE 'CollectionDefaultedLoan_dat01' TO 'G:\SQL\DATA\Enterprise\CollectionDefaultedLoan_dat01.ndf',
MOVE 'CollectionDebtor_idx01' TO 'G:\SQL\DATA\Enterprise\CollectionDebtor_idx01.ndf',
MOVE 'CollectionDebtor_dat01' TO 'G:\SQL\DATA\Enterprise\CollectionDebtor_dat01.ndf',
MOVE 'ClaimMiscellaneous_idx02' TO 'G:\SQL\DATA\Enterprise\ClaimMiscellaneous_idx02.ndf',
MOVE 'ClaimMiscellaneous_idx01' TO 'G:\SQL\DATA\Enterprise\ClaimMiscellaneous_idx01.ndf',
MOVE 'ClaimMiscellaneous_dat02' TO 'G:\SQL\DATA\Enterprise\ClaimMiscellaneous_dat02.ndf',
MOVE 'ClaimMiscellaneous_dat01' TO 'G:\SQL\DATA\Enterprise\ClaimMiscellaneous_dat01.ndf',
MOVE 'Application_idx03' TO 'G:\SQL\DATA\Enterprise\Application_idx03.ndf',
MOVE 'Application_idx02' TO 'G:\SQL\DATA\Enterprise\Application_idx02.ndf',
MOVE 'Application_idx01' TO 'G:\SQL\DATA\Enterprise\Application_idx01.ndf',
MOVE 'Application_dat03' TO 'G:\SQL\DATA\Enterprise\Application_dat03.ndf',
MOVE 'Application_dat02' TO 'G:\SQL\DATA\Enterprise\Application_dat02.ndf',
MOVE 'Application_dat01' TO 'G:\SQL\DATA\Enterprise\Application_dat01.ndf',
MOVE 'ACRMiscellaneous_idx01' TO 'G:\SQL\DATA\Enterprise\ACRMiscellaneous_idx01.ndf',
MOVE 'ACRMiscellaneous_dat01' TO 'G:\SQL\DATA\Enterprise\ACRMiscellaneous_dat01.ndf',
MOVE 'ACRLoanTransaction_idx01' TO 'G:\SQL\DATA\Enterprise\ACRLoanTransaction_idx01.ndf',
MOVE 'ACRLoanTransaction_dat01' TO 'G:\SQL\DATA\Enterprise\ACRLoanTransaction_dat01.ndf',
MOVE 'ACRFinancialTransaction_idx01' TO 'G:\SQL\DATA\Enterprise\ACRFinancialTransaction_idx01.ndf',
MOVE 'ACRFinancialTransaction_dat01' TO 'G:\SQL\DATA\Enterprise\ACRFinancialTransaction_dat01.ndf',
MOVE 'ACRFinancialSnapshot_idx01' TO 'G:\SQL\DATA\Enterprise\ACRFinancialSnapshot_idx01.ndf',
MOVE 'ACRFinancialSnapshot_dat01' TO 'G:\SQL\DATA\Enterprise\ACRFinancialSnapshot_dat01.ndf',
MOVE 'ACRFinancialMilestone_idx01' TO 'G:\SQL\DATA\Enterprise\ACRFinancialMilestone_idx01.ndf',
MOVE 'ACRFinancialMilestone_dat01' TO 'G:\SQL\DATA\Enterprise\ACRFinancialMilestone_dat01.ndf',
MOVE 'ACRElementaryLoanTransaction_idx01' TO 'G:\SQL\DATA\Enterprise\ACRElementaryLoanTransaction_idx01.ndf',
MOVE 'ACRElementaryLoanTransaction_dat01' TO 'G:\SQL\DATA\Enterprise\ACRElementaryLoanTransaction_dat01.ndf',
MOVE 'ACRElementaryFinancialSnapshot_idx01' TO 'G:\SQL\DATA\Enterprise\ACRElementaryFinancialSnapshot_idx01.ndf',
MOVE 'ACRElementaryFinancialSnapshot_dat01' TO 'G:\SQL\DATA\Enterprise\ACRElementaryFinancialSnapshot_dat01.ndf',
MOVE 'ACRElementaryFinancialDenormalized_idx01' TO 'G:\SQL\DATA\Enterprise\ACRElementaryFinancialDenormalized_idx01.ndf',
MOVE 'ACRElementaryFinancialDenormalized_dat01' TO 'G:\SQL\DATA\Enterprise\ACRElementaryFinancialDenormalized_dat01.ndf'


RESTORE DATABASE Confidential WITH RECOVERY;
RESTORE DATABASE Security WITH RECOVERY;
RESTORE DATABASE enterprise WITH RECOVERY;
RESTORE DATABASE BOPS WITH RECOVERY;
RESTORE DATABASE XI WITH RECOVERY;

--exec sp_change_users_login 'report'

--exec sp_change_users_login 'update_one', 'bdowd', 'bdowd'
--exec sp_change_users_login 'update_one', 'brdowd', 'brdowd'
--exec sp_change_users_login 'update_one', 'JFang', 'JFang'
--exec sp_change_users_login 'update_one', 'pete', 'pete'
--exec sp_change_users_login 'update_one', 'servicer', 'servicer'
--exec sp_change_users_login 'update_one', 'WZhang', 'WZhang'






