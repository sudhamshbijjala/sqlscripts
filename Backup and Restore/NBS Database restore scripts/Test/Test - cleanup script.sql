--  cleanup script for TEST legacy restore
--  Modified by Richard Ding
--  Modified on 2/4/2010
--  Reference: \\mayflower\DATA\GROUP\QARestoreScripts\Database Restore\AQADBS009\AQADBS009_Ent_Restore_EntRestructureA.sql

--  On AQADBS009
USE enterprise;

--  UPDATEs on old values:
UPDATE msc_outputdistribution 
  SET distribution_location = '\\aqaapp003\XI\Outbound\FFHDispatcherIn'
  WHERE OutputDistribution_cd ='ORUT173';     ------ Elmnet
  
UPDATE msc_outputdistribution 
  SET distribution_location = '\\aqaapp003\XI\Outbound\FFHDispatcherIn'
  WHERE OutputDistribution_cd = 'odb000007500'; ------  This cd doesn't eXIst  10/24/02--> 'ORUT174' --- Equifax

UPDATE msc_outputdistribution 
  SET Distribution_Location ='\\aqaapp004\WebReports'
  WHERE outputdistribution_cd = 'ORUT164';	---- Web_DisbChg_Rpt
  
UPDATE dbs_parameter 
  SET Parameter_val ='\\aqaapp005\WebReports'
  WHERE parameter_cd = 'WEB_RPT_SERVER';


DELETE FROM DBS_FileHandlerCOnfirg;
DELETE FROM DBS_FileHandlerConfigFeed;
DELETE FROM DBS_FileHandlerFtpPoll;
DELETE FROM DBS_FileHandlerConfig;
DELETE FROM DBS_FileHandlerFtpConfig;
DELETE FROM dbs_FileHandlerMailbox;
DELETE FROM dbs_EncryptionKey;
DELETE FROM dbs_filehandlerserver;
DELETE FROM dbs_server;

UPDATE msc_outputrptsection
	SET outputprinter_cd='OPR000000005'
	WHERE outputprinter_cd<>'OPR000000005';

TRUNCATE TABLE msc_outputqueue;


UPDATE dbo.ORG_ContactInfo
	SET Email_Address = 'nkent@amsa.com'
	WHERE Email_Address is not null;

UPDATE dbo.PER_Demog  
	SET Email_Addr = 'email@amsa.com'
	WHERE Email_Addr is not null;


UPDATE org_productsubscribe
       SET Participation_flg = 'N'
       WHERE product_cd = 'PRD000000116';

UPDATE org_productsubscribe
       SET Termination_dt = '09/26/2007'
       WHERE product_cd = 'PRD000000116';

DELETE FROM msc_outputqueue
       WHERE OutputQueueGroup_cd = 'OOG000000151';

UPDATE dbs_filehandlerconfigdirectory
	SET Directory_Name ='\\aqaapp003\CL4\Input' 
	WHERE MediaType_cd ='OUTPUT_WEBUP';
	
UPDATE dbs_filehandlerconfigdirectory
	SET Directory_Name ='\\aqaapp003\CL4\Output' 
	WHERE MediaType_cd ='OUTPUT_WEBDOWN'

UPDATE dbs_filehandlerconfigdirectory
	SET FFH_Server_nm='aqaapp003'
	WHERE FFH_Server_nm<>'aqaapp003';
--this section has been added per Damon and Bundle 395's CAM file handling

UPDATE dbs_parameter
	SET Parameter_val = '\\aqaapp004\temp\CamExtract'
	WHERE Parameter_cd = 'Cam_Archive_Dir';


UPDATE org_productsubscribe
	SET Participation_flg = 'N'
	WHERE product_cd = 'PRD000000116';

UPDATE org_productsubscribe
	SET Termination_dt = '09/26/2007'
	WHERE product_cd = 'PRD000000116';

DELETE FROM msc_outputqueue
	WHERE OutputQueueGroup_cd = 'OOG000000151' ;


UPDATE org_institutionweblink
	SET Link_URL_nm = 'http://aqaapp004/ewp/login/conditions.asp'
	WHERE InstitutionWebLink_cd = 'IWL000000226';

UPDATE org_institutionweblink
	SET Link_URL_nm = 'http://aqaapp004/ewp/login/login.asp'
	WHERE InstitutionWebLink_cd = 'IWL000000227';

UPDATE org_institutionweblink
	SET Link_URL_nm = 'http://aqaapp004/oowcr/login/login.aspx'
	WHERE InstitutionWebLink_cd = 'IWL000000228';

