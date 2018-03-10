-----  Staging refresh for legacy databases  ------

--  For enterprise
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = '\\dcrestore\Production_Backups\ASA\04-21-10\SQL_Backups\Enterprise\enterprise_backup_201004210500.bak'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE enterprise SET OffLINE WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE enterprise FROM DISK = @BackupFile WITH STATS = 1, REPLACE, NORECOVERY, 
MOVE 'TransactionTable_idx01' TO 'D:\auadbs004\data\enterprise\TransactionTable_idx01.ndf',
MOVE 'TransactionTable_dat02' TO 'D:\auadbs004\data\enterprise\TransactionTable_dat02.ndf',
MOVE 'TransactionTable_dat01' TO 'D:\auadbs004\data\enterprise\TransactionTable_dat01.ndf',
MOVE 'TransactionHistory_idx03' TO 'D:\auadbs004\data\enterprise\TransactionHistory_idx03.ndf',
MOVE 'TransactionHistory_idx02' TO 'D:\auadbs004\data\enterprise\TransactionHistory_idx02.ndf',
MOVE 'TransactionHistory_idx01' TO 'D:\auadbs004\data\enterprise\TransactionHistory_idx01.ndf',
MOVE 'TransactionHistory_dat03' TO 'D:\auadbs004\data\enterprise\TransactionHistory_dat03.ndf',
MOVE 'TransactionHistory_dat02' TO 'D:\auadbs004\data\enterprise\TransactionHistory_dat02.ndf',
MOVE 'TransactionHistory_dat01' TO 'D:\auadbs004\data\enterprise\TransactionHistory_dat01.ndf',
MOVE 'TransactionDetail_idx04' TO 'D:\auadbs004\data\enterprise\TransactionDetail_idx04.ndf',
MOVE 'TransactionDetail_idx03' TO 'D:\auadbs004\data\enterprise\TransactionDetail_idx03.ndf',
MOVE 'TransactionDetail_idx02' TO 'D:\auadbs004\data\enterprise\TransactionDetail_idx02.ndf',
MOVE 'TransactionDetail_idx01' TO 'D:\auadbs004\data\enterprise\TransactionDetail_idx01.ndf',
MOVE 'TransactionDetail_dat04' TO 'D:\auadbs004\data\enterprise\TransactionDetail_dat04.ndf',
MOVE 'TransactionDetail_dat03' TO 'D:\auadbs004\data\enterprise\TransactionDetail_dat03.ndf',
MOVE 'TransactionDetail_dat02' TO 'D:\auadbs004\data\enterprise\TransactionDetail_dat02.ndf',
MOVE 'TransactionDetail_dat01' TO 'D:\auadbs004\data\enterprise\TransactionDetail_dat01.ndf',
MOVE 'TMPMiscellaneous_idx01' TO 'D:\auadbs004\data\enterprise\TMPMiscellaneous_idx01.ndf',
MOVE 'TMPMiscellaneous_dat01' TO 'D:\auadbs004\data\enterprise\TMPMiscellaneous_dat01.ndf',
MOVE 'Report_Group_idx01' TO 'D:\auadbs004\data\enterprise\Report_Group_idx01.ndf',
MOVE 'Report_Group_dat01' TO 'D:\auadbs004\data\enterprise\Report_Group_dat01.ndf',
MOVE 'PrincipalReduce_idx02' TO 'D:\auadbs004\data\enterprise\PrincipalReduce_idx02.ndf',
MOVE 'PrincipalReduce_idx01' TO 'D:\auadbs004\data\enterprise\PrincipalReduce_idx01.ndf',
MOVE 'PrincipalReduce_dat02' TO 'D:\auadbs004\data\enterprise\PrincipalReduce_dat02.ndf',
MOVE 'PrincipalReduce_dat01' TO 'D:\auadbs004\data\enterprise\PrincipalReduce_dat01.ndf',
MOVE 'PersonMiscellaneous_idx01' TO 'D:\auadbs004\data\enterprise\PersonMiscellaneous_idx01.ndf',
MOVE 'PersonMiscellaneous_dat01' TO 'D:\auadbs004\data\enterprise\PersonMiscellaneous_dat01.ndf',
MOVE 'Person_idx01' TO 'D:\auadbs004\data\enterprise\Person_idx01.ndf',
MOVE 'Person_dat01' TO 'D:\auadbs004\data\enterprise\Person_dat01.ndf',
MOVE 'MiscMiscellaneous_idx01' TO 'D:\auadbs004\data\enterprise\MiscMiscellaneous_idx01.ndf',
MOVE 'MiscMiscellaneous_dat01' TO 'D:\auadbs004\data\enterprise\MiscMiscellaneous_dat01.ndf',
MOVE 'LoanMiscellaneous_idx01' TO 'D:\auadbs004\data\enterprise\LoanMiscellaneous_idx01.ndf',
MOVE 'LoanMiscellaneous_dat01' TO 'D:\auadbs004\data\enterprise\LoanMiscellaneous_dat01.ndf',
MOVE 'Loan_idx02' TO 'D:\auadbs004\data\enterprise\Loan_idx02.ndf',
MOVE 'Loan_idx01' TO 'D:\auadbs004\data\enterprise\Loan_idx01.ndf',
MOVE 'Loan_dat02' TO 'D:\auadbs004\data\enterprise\Loan_dat02.ndf',
MOVE 'Loan_dat01' TO 'D:\auadbs004\data\enterprise\Loan_dat01.ndf',
MOVE 'HistoryComment_idx01' TO 'D:\auadbs004\data\enterprise\HistoryComment_idx01.ndf',
MOVE 'HistoryComment_dat01' TO 'D:\auadbs004\data\enterprise\HistoryComment_dat01.ndf',
MOVE 'EventMiscellaneous_idx01' TO 'D:\auadbs004\data\enterprise\EventMiscellaneous_idx01.ndf',
MOVE 'EventMiscellaneous_dat01' TO 'D:\auadbs004\data\enterprise\EventMiscellaneous_dat01.ndf',
MOVE 'Enterprise_log08' TO 'D:\auadbs004\log\enterprise_log\Enterprise_log08.ldf',
MOVE 'Enterprise_log07' TO 'D:\auadbs004\log\enterprise_log\Enterprise_log07.ldf',
MOVE 'Enterprise_log06' TO 'D:\auadbs004\log\enterprise_log\Enterprise_log06.ldf',
MOVE 'Enterprise_log05' TO 'D:\auadbs004\log\enterprise_log\Enterprise_log05.ldf',
MOVE 'Enterprise_log04' TO 'D:\auadbs004\log\enterprise_log\Enterprise_log04.ldf',
MOVE 'Enterprise_log03' TO 'D:\auadbs004\log\enterprise_log\Enterprise_log03.ldf',
MOVE 'Enterprise_log02' TO 'D:\auadbs004\log\enterprise_log\Enterprise_log02.ldf',
MOVE 'Enterprise_log01' TO 'D:\auadbs004\log\enterprise_log\Enterprise_log01.ldf',
MOVE 'Enterprise_idx01' TO 'D:\auadbs004\data\enterprise\Enterprise_idx01.ndf',
MOVE 'Enterprise_dat01' TO 'D:\auadbs004\data\enterprise\Enterprise_dat01.mdf',
MOVE 'Disbursement_idx02' TO 'D:\auadbs004\data\enterprise\Disbursement_idx02.ndf',
MOVE 'Disbursement_idx01' TO 'D:\auadbs004\data\enterprise\Disbursement_idx01.ndf',
MOVE 'Disbursement_dat02' TO 'D:\auadbs004\data\enterprise\Disbursement_dat02.ndf',
MOVE 'Disbursement_dat01' TO 'D:\auadbs004\data\enterprise\Disbursement_dat01.ndf',
MOVE 'DisbMiscellaneous_idx02' TO 'D:\auadbs004\data\enterprise\DisbMiscellaneous_idx02.ndf',
MOVE 'DisbMiscellaneous_idx01' TO 'D:\auadbs004\data\enterprise\DisbMiscellaneous_idx01.ndf',
MOVE 'DisbMiscellaneous_dat02' TO 'D:\auadbs004\data\enterprise\DisbMiscellaneous_dat02.ndf',
MOVE 'DisbMiscellaneous_dat01' TO 'D:\auadbs004\data\enterprise\DisbMiscellaneous_dat01.ndf',
MOVE 'Demog_idx01' TO 'D:\auadbs004\data\enterprise\Demog_idx01.ndf',
MOVE 'Demog_dat01' TO 'D:\auadbs004\data\enterprise\Demog_dat01.ndf',
MOVE 'Comment_idx04' TO 'D:\auadbs004\data\enterprise\Comment_idx04.ndf',
MOVE 'Comment_idx03' TO 'D:\auadbs004\data\enterprise\Comment_idx03.ndf',
MOVE 'Comment_idx02' TO 'D:\auadbs004\data\enterprise\Comment_idx02.ndf',
MOVE 'Comment_idx01' TO 'D:\auadbs004\data\enterprise\Comment_idx01.ndf',
MOVE 'Comment_dat04' TO 'D:\auadbs004\data\enterprise\Comment_dat04.ndf',
MOVE 'Comment_dat03' TO 'D:\auadbs004\data\enterprise\Comment_dat03.ndf',
MOVE 'Comment_dat02' TO 'D:\auadbs004\data\enterprise\Comment_dat02.ndf',
MOVE 'Comment_dat01' TO 'D:\auadbs004\data\enterprise\Comment_dat01.ndf',
MOVE 'CollectionPayment_idx01' TO 'D:\auadbs004\data\enterprise\CollectionPayment_idx01.ndf',
MOVE 'CollectionPayment_dat02' TO 'D:\auadbs004\data\enterprise\CollectionPayment_dat02.ndf',
MOVE 'CollectionPayment_dat01' TO 'D:\auadbs004\data\enterprise\CollectionPayment_dat01.ndf',
MOVE 'CollectionMiscellaneous_idx01' TO 'D:\auadbs004\data\enterprise\CollectionMiscellaneous_idx01.ndf',
MOVE 'CollectionMiscellaneous_dat01' TO 'D:\auadbs004\data\enterprise\CollectionMiscellaneous_dat01.ndf',
MOVE 'CollectionDefaultedLoan_idx01' TO 'D:\auadbs004\data\enterprise\CollectionDefaultedLoan_idx01.ndf',
MOVE 'CollectionDefaultedLoan_dat01' TO 'D:\auadbs004\data\enterprise\CollectionDefaultedLoan_dat01.ndf',
MOVE 'CollectionDebtor_idx01' TO 'D:\auadbs004\data\enterprise\CollectionDebtor_idx01.ndf',
MOVE 'CollectionDebtor_dat01' TO 'D:\auadbs004\data\enterprise\CollectionDebtor_dat01.ndf',
MOVE 'ClaimMiscellaneous_idx02' TO 'D:\auadbs004\data\enterprise\ClaimMiscellaneous_idx02.ndf',
MOVE 'ClaimMiscellaneous_idx01' TO 'D:\auadbs004\data\enterprise\ClaimMiscellaneous_idx01.ndf',
MOVE 'ClaimMiscellaneous_dat02' TO 'D:\auadbs004\data\enterprise\ClaimMiscellaneous_dat02.ndf',
MOVE 'ClaimMiscellaneous_dat01' TO 'D:\auadbs004\data\enterprise\ClaimMiscellaneous_dat01.ndf',
MOVE 'Application_idx03' TO 'D:\auadbs004\data\enterprise\Application_idx03.ndf',
MOVE 'Application_idx02' TO 'D:\auadbs004\data\enterprise\Application_idx02.ndf',
MOVE 'Application_idx01' TO 'D:\auadbs004\data\enterprise\Application_idx01.ndf',
MOVE 'Application_dat03' TO 'D:\auadbs004\data\enterprise\Application_dat03.ndf',
MOVE 'Application_dat02' TO 'D:\auadbs004\data\enterprise\Application_dat02.ndf',
MOVE 'Application_dat01' TO 'D:\auadbs004\data\enterprise\Application_dat01.ndf',
MOVE 'ACRMiscellaneous_idx01' TO 'D:\auadbs004\data\enterprise\ACRMiscellaneous_idx01.ndf',
MOVE 'ACRMiscellaneous_dat01' TO 'D:\auadbs004\data\enterprise\ACRMiscellaneous_dat01.ndf',
MOVE 'ACRLoanTransaction_idx01' TO 'D:\auadbs004\data\enterprise\ACRLoanTransaction_idx01.ndf',
MOVE 'ACRLoanTransaction_dat01' TO 'D:\auadbs004\data\enterprise\ACRLoanTransaction_dat01.ndf',
MOVE 'ACRFinancialTransaction_idx01' TO 'D:\auadbs004\data\enterprise\ACRFinancialTransaction_idx01.ndf',
MOVE 'ACRFinancialTransaction_dat01' TO 'D:\auadbs004\data\enterprise\ACRFinancialTransaction_dat01.ndf',
MOVE 'ACRFinancialSnapshot_idx01' TO 'D:\auadbs004\data\enterprise\ACRFinancialSnapshot_idx01.ndf',
MOVE 'ACRFinancialSnapshot_dat01' TO 'D:\auadbs004\data\enterprise\ACRFinancialSnapshot_dat01.ndf',
MOVE 'ACRFinancialMilestone_idx01' TO 'D:\auadbs004\data\enterprise\ACRFinancialMilestone_idx01.ndf',
MOVE 'ACRFinancialMilestone_dat01' TO 'D:\auadbs004\data\enterprise\ACRFinancialMilestone_dat01.ndf',
MOVE 'ACRElementaryLoanTransaction_idx01' TO 'D:\auadbs004\data\enterprise\ACRElementaryLoanTransaction_idx01.ndf',
MOVE 'ACRElementaryLoanTransaction_dat01' TO 'D:\auadbs004\data\enterprise\ACRElementaryLoanTransaction_dat01.ndf',
MOVE 'ACRElementaryFinancialSnapshot_idx01' TO 'D:\auadbs004\data\enterprise\ACRElementaryFinancialSnapshot_idx01.ndf',
MOVE 'ACRElementaryFinancialSnapshot_dat01' TO 'D:\auadbs004\data\enterprise\ACRElementaryFinancialSnapshot_dat01.ndf',
MOVE 'ACRElementaryFinancialDenormalized_idx01' TO 'D:\auadbs004\data\enterprise\ACRElementaryFinancialDenormalized_idx01.ndf',
MOVE 'ACRElementaryFinancialDenormalized_dat01' TO 'D:\auadbs004\data\enterprise\ACRElementaryFinancialDenormalized_dat01.ndf'

-----------------------------------------------------------------------------------------------------------------------------------------------------
--  For BOPS
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = '\\dcrestore\Production_Backups\ASA\04-21-10\SQL_Backups\BOPS\BOPS_backup_201004210500.bak'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE BOPS SET OffLINE WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE BOPS FROM DISK = @BackupFile WITH STATS = 1, REPLACE, NORECOVERY, 
MOVE 'Bops_log' TO 'D:\auadbs004\LOG\BOPS_LOG.LDF',
MOVE 'Bops_dat' TO 'D:\auadbs004\DATA\BOPS.MDF'

-----------------------------------------------------------------------------------------------------------------------------------------------------
--  For XI
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = '\\dcrestore\Production_Backups\ASA\04-21-10\SQL_Backups\XI\XI_backup_201004210500.bak'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE XI SET OffLINE WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE XI FROM DISK = @BackupFile WITH STATS = 1, REPLACE, NORECOVERY,  
MOVE 'XI_log' TO 'D:\auadbs004\LOG\XI_LOG.LDF',
MOVE 'XI_dat' TO 'D:\auadbs004\DATA\XI.MDF'

-----------------------------------------------------------------------------------------------------------------------------------------------------
--  For Report_Central
DECLARE @BackupFile VARCHAR(255)
SET @BackupFile = '\\dcrestore\Production_Backups\ASA\04-21-10\SQL_Backups\Third_party_sql_backups\Report_Central\Report_Central\Report_Central_backup_201004210500.bak'
RESTORE FILELISTONLY FROM DISK = @BackupFile; 

ALTER DATABASE Report_Central SET OffLINE WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE Report_Central FROM DISK = @BackupFile WITH STATS = 1, REPLACE, NORECOVERY,  
MOVE 'Report_Central_log' TO 'D:\auadbs004\LOG\Report_Central_LOG.LDF',
MOVE 'Report_Central_Data' TO 'D:\auadbs004\DATA\Report_Central.MDF'


--------------------------------------------------------------------------------------------------------------------------------------------------
--  Finilize:
RESTORE DATABASE Report_Central WITH RECOVERY;
RESTORE DATABASE enterprise WITH RECOVERY;
RESTORE DATABASE BOPS WITH RECOVERY;
RESTORE DATABASE XI WITH RECOVERY;

ALTER DATABASE Report_Central SET RECOVERY SIMPLE;
ALTER DATABASE enterprise SET RECOVERY SIMPLE;
ALTER DATABASE BOPS SET RECOVERY SIMPLE;
ALTER DATABASE XI SET RECOVERY SIMPLE;
