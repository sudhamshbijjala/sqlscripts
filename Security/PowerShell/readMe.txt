extractLoginsUsersRoles.ps1 will help extract logins, users and permissions based on 
original sql script done by Richard D.

If you want to run it, open PowerShell to run following commands


set-location <to where you keep the script extractLoginsUsersRoles.ps1>

./extractLoginsUsersRoles.ps1 -s AOPSDBS708 -d DMCDR

(the above will extract from database DMCDR in instance AOPSDBS708)

You will get three SQL scripts generated from the above call and 
you can cut-paste to run them in SSMS or just run 

./runSQL.ps1 -s AOPSDBS708 -d DMCDR -i aopsdbs708_dmcdr_cr_UserAccount.sql
./runSQL.ps1 -s AOPSDBS708 -d DMCDR -i aopsdbs708_dmcdr_cr_RoleMember.sql
./runSQL.ps1 -s AOPSDBS708 -d DMCDR -i aopsdbs708_dmcdr_cr_UserPermission.sql
