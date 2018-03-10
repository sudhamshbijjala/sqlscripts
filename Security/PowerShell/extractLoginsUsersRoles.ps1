########################################################################
# ASA Proprietary Information
# 
# This script will extract and generate scripts to re-create Logins, Users and Roles
# 
# -s name of database server to extract data
# -d name of database to extract data
#
# Usage
# PS>./extractLoginsUsersRoles.ps1 -s adevdbs700 
#
########################################################################

param(
[string]$s = $(throw write-host "Database server name is missing. Please try again." -foreGroundColor "red"), `
[string]$d = $(throw write-host "Database name is missing. Please try again." -foreGroundColor "red")
)

# ------------------------------------------------------------------
# set up local variables for the script

$dbInstance = $s
$dbName = $d

write-host '** START SCRIPT'(Get-Date)

$scriptName = "extractLoginsUsersRoles.sql"

sqlcmd -S $dbInstance  -d $dbName -E  -i $scriptName 
$ok = $?

if ($ok)
{
	#
	# Generate runnable SQL scripts
	#

	$outputScript = "{0}_{1}_cr_UserAccount.sql" -f $dbInstance, $dbName

	write-host "==> Generate script $outputScript"

	write-output "USE $dbName;" > $outputScript

	sqlcmd -S $dbInstance -d $dbName -E -i genScript.sql -v tbName="UserAccountToKeep" -h -1 -W >> $outputScript
	$ok = $?

	if ($ok)
	{
		$outputScript = "{0}_{1}_cr_RoleMember.sql" -f $dbInstance, $dbName
		write-host "==> Generate script $outputScript"

		write-output "USE $dbName;" > $outputScript

		sqlcmd -S $dbInstance -d $dbName -E -i genScript.sql -v tbName="RoleMemberMapping" -h -1 -W >> $outputScript
	}


	if ($ok)
	{
		$outputScript = "{0}_{1}_cr_UserPermission.sql" -f $dbInstance, $dbName
		write-host "==> Generate script $outputScript"

		sqlcmd -S $dbInstance -E -i genScript.sql -v tbName="UserPermission" -h -1 -W -o $outputScript
	}

}


if (!($ok))
{
	write-host "ERROR: Unexpected errors encountered. Please verify and try again." -foregroundcolor red
}

write-host '** END SCRIPT'(Get-Date)