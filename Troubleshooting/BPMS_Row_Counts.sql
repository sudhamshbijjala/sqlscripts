select bc.Name as EX_STATUS, count(*) as total 
from teamworks.LSW_BPD_INSTANCE inst with (nolock), teamworks.LSW_TASK task with (nolock), teamworks.lsw_bpd_status_codes bc with (nolock)
where task.BPD_INSTANCE_ID = inst.BPD_INSTANCE_ID 
and inst.EXECUTION_STATUS = bc.STATUS_ID
group by bc.Name --inst.EXECUTION_STATUS,
with rollup

select bc.Name as EX_STATUS, count(*) as total 
from teamworks.LSW_BPD_INSTANCE inst with (nolock), teamworks.lsw_bpd_status_codes bc with (nolock)
where inst.EXECUTION_STATUS = bc.STATUS_ID
group by bc.Name --inst.EXECUTION_STATUS, bc.Name
with rollup

/*
Starting numbers for purging completed BPD's on 7/16 about 4:30pm
TWPROC DB    85,525

Tasks
Completed			940,763

Instances
Completed			782,437
				   + 64,748 from update statement that made ACTIVE into COMPLETED
					-------
					847,185
*/

