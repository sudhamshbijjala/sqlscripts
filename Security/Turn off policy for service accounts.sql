--  Per DBA standard, all standard SQL service accounts should not use password policy or expiration

/********************************  for BPMS  ************************************/
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'teamworks')
  ALTER LOGIN [teamworks] WITH CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;


/********************************  for B*2B  ************************************/
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'Sentinel')
  ALTER LOGIN [Sentinel] WITH CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'Interchange')
  ALTER LOGIN [Interchange] WITH CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;


/*********************************  for OSS  ************************************/
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'SvDevMonOSS')
  ALTER LOGIN [SvDevMonOSS] WITH CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'SvTstMonOSS')
  ALTER LOGIN [SvTstMonOSS] WITH CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'SvStaMonOSS')
  ALTER LOGIN [SvStaMonOSS] WITH CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'SvProdMonOSS')
  ALTER LOGIN [SvProdMonOSS] WITH CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;


/***************************  for linked server  *********************************/
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'TempLinkedServerUser')
  ALTER LOGIN [TempLinkedServerUser] WITH CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;
  

/***************************  for other monitoring  ******************************/
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'DBAMonitoring')
  ALTER LOGIN [DBAMonitoring] WITH CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;
