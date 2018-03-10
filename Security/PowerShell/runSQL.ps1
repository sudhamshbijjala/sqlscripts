########################################################################
# ASA Proprietary Information
# 
# This script will execute a specific SQL script
# 
# -s name of database server 
# -d name of database 
# -i name of script
#
# Usage
# PS>./runSQL.ps1 -s adevdbs700 -d dmcdr -i scriptName.sql
#
########################################################################

param(
[string]$s = $(throw write-host "Database server name is missing. Please try again." -foreGroundColor "red"), `
[string]$d = $(throw write-host "Database name is missing. Please try again." -foreGroundColor "red"), `
[string]$i = $(throw write-host "Script name is missing. Please try again." -foreGroundColor "red")
)

# ------------------------------------------------------------------
# set up local variables for the script

$dbInstance = $s
$dbName = $d
$scriptName = $i

write-host '** START SCRIPT'(Get-Date)

if (!(test-path $scriptName))
{
	write-host "ERROR: SQL Script $scriptName is missing. Please verify and try again." -foregroundcolor red
	exit 1
}

sqlcmd -S $dbInstance -d $dbName -E  -i $scriptName 

$ok = $?

if (!($ok))
{
	write-host "ERROR: Unexpected errors encountered. Please verify and try again." -foregroundcolor red
}

write-host '** END SCRIPT'(Get-Date)