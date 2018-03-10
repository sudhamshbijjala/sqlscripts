
USE master;
GO

IF OBJECT_ID ( 'dbo.sp_version', 'P' ) IS NOT NULL 
  BEGIN
    DROP PROCEDURE dbo.sp_version;
    IF OBJECT_ID('dbo.sp_version', 'P' ) IS NOT NULL
        PRINT '*** FAILED DROPPING PROCEDURE dbo.sp_version ***';
    ELSE
        PRINT '*** DROPPED PROCEDURE dbo.sp_version ****';
  END;
GO

CREATE PROCEDURE dbo.sp_version  
  WITH ENCRYPTION                      
AS

-- ********************************************************************
-- Procedure Name:  sp_version
-- Purpose:         List key server information for SQL Server 2005, 2008
-- Returns          An -1 if it fails or 0 if it succeeds
-- Author:          Richard Ding
-- Date Created:    07/01/2008 
--********************************************************************

set nocount on;

create table #versioninfo 
( [Index] varchar(5), 
  [Name] varchar(20), 
  Internal_Value varchar(10), 
  Character_Value varchar(120));    

insert into #versioninfo exec ('master.dbo.xp_msver');

declare  
  @ProductVersion varchar(50),
  @winver varchar(10), 
  @cpuspeedcount varchar(3), 
  @Memory varchar(6);
select @ProductVersion = CONVERT(VARCHAR(50), SERVERPROPERTY('ProductVersion'));
set @cpuspeedcount = (select Internal_Value from #versioninfo where Name = 'ProcessorCount');
set @Memory = (select Internal_Value from #versioninfo where Name = 'PhysicalMemory');
set @winver = (select Character_Value from #versioninfo where Name = 'WindowsVersion');

/*  automatically read registry keys and values  */
DECLARE @cpuspeed int, @cpuidentifier varchar(100), @CPUNameString varchar(100);

/*  Find CPU speed and number  */
EXEC master..xp_regread 
  @rootkey='HKEY_LOCAL_MACHINE', 
  @key='HARDWARE\DESCRIPTION\system\Centralprocessor\0', 
  @value_name='~MHz', 
  @value = @cpuspeed OUTPUT;

/*  Find CPU identifier such as "x86 Family 15 Model 1 Stepping 1"  */
EXEC master..xp_regread 
  @rootkey='HKEY_LOCAL_MACHINE', 
  @key='HARDWARE\DESCRIPTION\system\Centralprocessor\0', 
  @value_name='Identifier', 
  @value = @cpuidentifier OUTPUT;

/*  Find CPU Name String such as "Intel(R) Xeon(TM) CPU 1.60GHz"  */
EXEC master..xp_regread
  @rootkey='HKEY_LOCAL_MACHINE',
  @key='HARDWARE\DESCRIPTION\system\Centralprocessor\0',
  @value_name='ProcessorNameString',
  @value = @CPUNameString OUTPUT,
  @no_output = 'no_output';

select 'Windows OS' as 'Category', 'Version' as 'Item',  
  case left(@winver, 4) 
    when '5.0' then 'Windows 2000' 
    when '4.0' then 'NT 4.0' 
    when '5.2' then 'Windows 2003' 
    when '5.1' then 'XP' 
    when '6.0' then 'Windows 2008' end as 'Value' UNION ALL
select 'Windows OS', 'Service pack', 
  case substring(@@version, (len(@@version) - 15), 14) 
    when 'Service Pack 1' then 'SP1'
    when 'Service Pack 2' then 'SP2'
    when 'Service Pack 3' then 'SP3'
    when 'Service Pack 4' then 'SP4'
    when 'Service Pack 5' then 'SP5'
    when 'Service Pack 6' then 'SP6'
    when 'Service Pack 7' then 'SP7'
    when 'Service Pack 8' then 'SP8' 
    else 'N/A' end UNION ALL

select 'Hardware', 'Memory', @Memory + ' MB ' UNION ALL 
select 'Hardware', 'CPU', '(x' + @cpuspeedcount + ') ' + cast(@cpuspeed as varchar(4)) + ' MHz' UNION ALL
select 'Hardware', 'CPUBrand', left(ltrim(@CPUNameString), 50) UNION ALL
select 'Hardware', 'CPUID', left(@cpuidentifier, 35) UNION ALL
SELECT 'SQL Server', 'ComputerNamePhysicalNetBIOS', CONVERT(VARCHAR(50), SERVERPROPERTY('ComputerNamePhysicalNetBIOS')) UNION ALL
SELECT 'SQL Server', 'MachineName', CONVERT(VARCHAR(50), SERVERPROPERTY('MachineName')) UNION ALL
SELECT 'SQL Server', 'ServerName', CONVERT(VARCHAR(50), SERVERPROPERTY('ServerName')) UNION ALL
SELECT 'SQL Server', 'InstanceName', CONVERT(VARCHAR(50), SERVERPROPERTY('InstanceName')) UNION ALL
SELECT 'SQL Server', 'Edition', CONVERT(VARCHAR(50), SERVERPROPERTY('Edition')) + '   (ID: ' + CONVERT(VARCHAR(50), SERVERPROPERTY('EditionID')) + ')' UNION ALL
SELECT 'SQL Server', 'ProductLevel', CONVERT(VARCHAR(50), SERVERPROPERTY('ProductLevel')) UNION ALL
--  http://msdn2.microsoft.com/en-us/library/ms186823.aspx
SELECT 'SQL Server', 'ProductVersion', 
  --  SQL Server 2008
  case 
    when @ProductVersion like '10.0.2714%' then '<' + @ProductVersion + '> SQL Server 2008 SP1 + CU2 (KB970315) (May 18, 2009)' 
    when @ProductVersion like '10.0.2710%' then '<' + @ProductVersion + '> SQL Server 2008 SP1 + CU1 (KB969099) (April 16, 2009)'  
    when @ProductVersion like '10.0.2531%' then '<' + @ProductVersion + '> SQL Server 2008 SP1 (April 7, 2009)' 
    when @ProductVersion like '10.0.2520%' then '<' + @ProductVersion + '> SQL Server 2008 SP1 CTP (Feb 23, 2009)' 
    when @ProductVersion like '10.0.1806%' then '<' + @ProductVersion + '> SQL Server 2008 CU5 (KB969531) (May 18, 2009)' 
    when @ProductVersion like '10.0.1798%' then '<' + @ProductVersion + '> SQL Server 2008 CU4 (KB963036) (March 17, 2009)'  
    when @ProductVersion like '10.0.1787%' then '<' + @ProductVersion + '> SQL Server 2008 CU3 (KB960484) (Jan 19, 2009)'  
    when @ProductVersion like '10.0.1779%' then '<' + @ProductVersion + '> SQL Server 2008 CU2 (KB958186) (Nov 19, 2008)'  
    when @ProductVersion like '10.0.1771%' then '<' + @ProductVersion + '> SQL Server 2008 CU2 (KB958611) (Oct 29, 2008)'  
    when @ProductVersion like '10.0.1763%' then '<' + @ProductVersion + '> SQL Server 2008 CU1 (KB956717) (Oct 28, 2008)' 
    when @ProductVersion like '10.0.1750%' then '<' + @ProductVersion + '> SQL Server 2008 CTP (KB956718) (Aug 25, 2008)' 
    when @ProductVersion like '10.0.1600%' then '<' + @ProductVersion + '> SQL Server 2008 RTM (Aug 7, 2008)'  
    when @ProductVersion like '10.0.1442%' then '<' + @ProductVersion + '> SQL Server 2008 RC0 (June 5, 2008)' 
    when @ProductVersion like '10.0.1300%' then '<' + @ProductVersion + '> SQL Server 2008 CTP (Feb 19, 2008)' 
    when @ProductVersion like '10.0.1075%' then '<' + @ProductVersion + '> SQL Server 2008 CTP (Nov 18, 2007)' 
    when @ProductVersion like '10.0.1049%' then '<' + @ProductVersion + '> SQL Server 2008 CTP (July 31, 2007)' 
    when @ProductVersion like '10.0.1019%' then '<' + @ProductVersion + '> SQL Server 2008 CTP (May 21, 2007)' 

    --  SQL Server 2005
    when @ProductVersion like '9.00.4220%' then '<' + @ProductVersion + '> SQL Server 2005 SP3 + CU3 (KB967909) (Apr 20, 2009)'  
    when @ProductVersion like '9.00.4216%' then '<' + @ProductVersion + '> SQL Server 2005 SP3 + CU2 (KB967101) (Apr 20, 2009)'  
    when @ProductVersion like '9.00.4211%' then '<' + @ProductVersion + '> SQL Server 2005 SP3 + CU2 (KB961930) (Feb 17, 2009)'  
    when @ProductVersion like '9.00.4207%' then '<' + @ProductVersion + '> SQL Server 2005 SP3 + CU1 (KB959195) (Dec 20, 2008)'  
    when @ProductVersion like '9.00.4035%' then '<' + @ProductVersion + '> SQL Server 2005 SP3 (Dec 15, 2008)'  
	when @ProductVersion like '9.00.4028%' then '<' + @ProductVersion + '> SQL Server 2005 SP3 CTP (Oct 27, 2008)'  
	when @ProductVersion like '9.00.3325%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 + CU13 (KB967908) (Apr 20, 2009)'  
	when @ProductVersion like '9.00.3320%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 + CU12 (KB969142) (Apr 1, 2009)'  
	when @ProductVersion like '9.00.3318%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 + CU12 (KB967199) (Apr 20, 2009)'  
	when @ProductVersion like '9.00.3315%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 + CU12 (KB962970) (Feb 17, 2009)'  
	when @ProductVersion like '9.00.3310%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 + CU11 (KB960090 MS09-004) (Feb 10, 2009)'  
    when @ProductVersion like '9.00.3301%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 + CU11 (Dec 16, 2008)'  
    when @ProductVersion like '9.00.3294%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 + CU10 (KB956854) (Oct 20, 2008)'  
    when @ProductVersion like '9.00.3282%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 + CU9 (KB953752) (June 16, 2008)'  
    when @ProductVersion like '9.00.3260%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 + CU9 (KB954950) (June 16, 2008)'  
    when @ProductVersion like '9.00.3259%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 + CU9 (KB954831) (June 16, 2008)'  
    when @ProductVersion like '9.00.3259%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 + CU9 (KB954669) (June 16, 2008)'  

    when @ProductVersion like '9.00.3257%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 CU8 (June 16, 2008)'  
    when @ProductVersion like '9.00.3239%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 CU7 (April 14, 2008)'  
    when @ProductVersion like '9.00.3233%' then '<' + @ProductVersion + '> SQL Server 2005 QFE Security Update (July 8, 2008)'  
    when @ProductVersion like '9.00.3228%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 CU6 (Feb 18, 2008)'  
    when @ProductVersion like '9.00.3215%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 CU5 (Dec 17, 2007)'  
    when @ProductVersion like '9.00.3200%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 CU4 (Oct 15, 2007)'  
    when @ProductVersion like '9.00.3186%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 CU3 (20 Aug 2007)'  
    when @ProductVersion like '9.00.3175%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 CU2 (28 June 2007)'  
    when @ProductVersion like '9.00.3077%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 + KB960089 (10 Feb 2009)'  
    when @ProductVersion like '9.00.3054%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 + KB934458 (Apr 5, 2007)'
    when @ProductVersion like '9.00.3152%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 Cumulative Update 1 (Mar 7, 2007)'  
    when @ProductVersion like '9.00.3042.01%' then '<' + @ProductVersion + '> SQL Server 2005 "SP2a" (Mar 5, 2007)'  
    when @ProductVersion like '9.00.3042%' then '<' + @ProductVersion + '> SQL Server 2005 SP2 (Feb, 2007)'  
    when @ProductVersion like '9.00.3027%' then '<' + @ProductVersion + '> SQL Server 2005 2005 SP2 CTP'  
    when @ProductVersion like '9.00.2164%' then '<' + @ProductVersion + '> SQL Server 2005 SP1 + Q919636'  
    when @ProductVersion like '9.00.2156%' then '<' + @ProductVersion + '> SQL Server 2005 SP1 + Q919611'  
    when @ProductVersion like '9.00.2153%' then '<' + @ProductVersion + '> SQL Server 2005 SP1 + builds 1531-40 (See Q919224 before applying!)'  
    when @ProductVersion like '9.00.2047%' then '<' + @ProductVersion + '> SQL Server 2005 SP1 RTM'  
    when @ProductVersion like '9.00.2040%' then '<' + @ProductVersion + '> SQL Server 2005 SP1 CTP'  
    when @ProductVersion like '9.00.1550%' then '<' + @ProductVersion + '> SQL Server 2005 RTM + Q917887'  
    when @ProductVersion like '9.00.1547%' then '<' + @ProductVersion + '> SQL Server 2005 RTM + Q918276'  
    when @ProductVersion like '9.00.1541%' then '<' + @ProductVersion + '> SQL Server 2005 RTM + Q917888/917971'  
    when @ProductVersion like '9.00.1538%' then '<' + @ProductVersion + '> SQL Server 2005 RTM + Q917824'  
    when @ProductVersion like '9.00.1536%' then '<' + @ProductVersion + '> SQL Server 2005 RTM + Q917016'  
    when @ProductVersion like '9.00.1533%' then '<' + @ProductVersion + '> SQL Server 2005 RTM + Q916086'  
    when @ProductVersion like '9.00.1531%' then '<' + @ProductVersion + '> SQL Server 2005 RTM + Q915918'  
    when @ProductVersion like '9.00.1528%' then '<' + @ProductVersion + '> SQL Server 2005 RTM + Q915112'  
    when @ProductVersion like '9.00.1518%' then '<' + @ProductVersion + '> SQL Server 2005 RTM + Q912472/913371/913941'  
    when @ProductVersion like '9.00.1514%' then '<' + @ProductVersion + '> SQL Server 2005 RTM + Q912471'  
    when @ProductVersion like '9.00.1503%' then '<' + @ProductVersion + '> SQL Server 2005 RTM + Q911662'  
    when @ProductVersion like '9.00.1502%' then '<' + @ProductVersion + '> SQL Server 2005 RTM + Q915793'  
    when @ProductVersion like '9.00.1500%' then '<' + @ProductVersion + '> SQL Server 2005 RTM + KB910416' 
    when @ProductVersion like '9.00.1406%' then '<' + @ProductVersion + '> SQL Server 2005 RTM (KB932557 Fix) (Nov 11, 2007)'  
    when @ProductVersion like '9.00.1399%' then '<' + @ProductVersion + '> SQL Server 2005 RTM (Nov 7, 2005)'  
  else 'Unknown' end UNION ALL
SELECT 'SQL Server', 'ResourceVersion', CONVERT(VARCHAR(50), SERVERPROPERTY('ResourceVersion')) UNION ALL
SELECT 'SQL Server', 'ResourceLastUpdateDateTime', CONVERT(VARCHAR(50), SERVERPROPERTY('ResourceLastUpdateDateTime')) UNION ALL

SELECT 'SQL Server', 'BuildClrVersion', CONVERT(VARCHAR(50), SERVERPROPERTY('BuildClrVersion')) UNION ALL
SELECT 'SQL Server', 'Collation', CONVERT(VARCHAR(50), SERVERPROPERTY('Collation')) + '   (ID: ' + CONVERT(VARCHAR(50), SERVERPROPERTY('CollationID')) + ')' UNION ALL
SELECT 'SQL Server', 'ComparisonStyle', 
  case CONVERT(VARCHAR(50), SERVERPROPERTY('ComparisonStyle')) 
  when 1 then 'Ignore: accent'
  when 2 then 'Ignore: case'
  when 65536 then 'Ignore: Kana'
  when 131072 then 'Ignore: width'
  when 3 then 'Ignore: accent, case'
  when 65537 then 'Ignore: accent, Kana'
  when 131073 then 'Ignore: accent, width'
  when 65539 then 'Ignore: accent, case, Kana'
  when 131075 then 'Ignore: accent, case, width'
  when 196611 then 'Ignore: accent, case, Kana, width'
  when 65538 then 'Ignore: case, Kana'
  when 131074 then 'Ignore: case, width'
  when 196608 then 'Ignore: Kana, width'
  when 196609 then 'Ignore: accent, Kana, width'
  when 196610 then 'Ignore: case, Kana, width'
  else 'Unknown' end UNION ALL
SELECT 'SQL Server', 'IsClustered', CONVERT(VARCHAR(50), SERVERPROPERTY('IsClustered')) UNION ALL
SELECT 'SQL Server', 'IsFullTextInstalled', CONVERT(VARCHAR(50), SERVERPROPERTY('IsFullTextInstalled')) UNION ALL
SELECT 'SQL Server', 'IsIntegratedSecurityOnly', CONVERT(VARCHAR(50), SERVERPROPERTY('IsIntegratedSecurityOnly')) UNION ALL
SELECT 'SQL Server', 'IsSingleUser', CONVERT(VARCHAR(50), SERVERPROPERTY('IsSingleUser')) UNION ALL
SELECT 'SQL Server', 'LCID', CONVERT(VARCHAR(50), SERVERPROPERTY('LCID')) UNION ALL
SELECT 'SQL Server', 'LicenseType', CONVERT(VARCHAR(50), SERVERPROPERTY('LicenseType')) UNION ALL
SELECT 'SQL Server', 'NumLicenses', CONVERT(VARCHAR(50), SERVERPROPERTY('NumLicenses')) UNION ALL
SELECT 'SQL Server', 'ProcessID', CONVERT(VARCHAR(50), SERVERPROPERTY('ProcessID')) UNION ALL
SELECT 'SQL Server', 'SqlCharSet', CONVERT(VARCHAR(50), SERVERPROPERTY('SqlCharSet')) UNION ALL
SELECT 'SQL Server', 'SqlCharSetName', CONVERT(VARCHAR(50), SERVERPROPERTY('SqlCharSetName')) UNION ALL
SELECT 'SQL Server', 'SqlSortOrder', CONVERT(VARCHAR(50), SERVERPROPERTY('SqlSortOrder')) UNION ALL
SELECT 'SQL Server', 'SqlSortOrderName', CONVERT(VARCHAR(50), SERVERPROPERTY('SqlSortOrderName')) 

drop table #versioninfo; 

Return 0;    

GO

GRANT EXEC ON sp_version TO public;
GO

IF OBJECT_ID('dbo.sp_version', 'P') IS NOT NULL
    PRINT '*** CREATED PROCEDURE dbo.sp_version ***'
ELSE
    PRINT '*** FAILED CREATING PROCEDURE dbo.sp_version ***'
GO

