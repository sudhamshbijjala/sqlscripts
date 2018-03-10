-- This will display all sessions captured by sp_who2 ordered by blocked sessions, then by spid

begin try

create table #who
(spid nvarchar(256), status nvarchar(256), loginname nvarchar(256), hostname nvarchar(256), blkby nvarchar(256), dbname nvarchar(256), command nvarchar(256),
 CPUTime bigint, DiskIO bigint, lastbatch nvarchar(256), programName nvarchar(256), spid2 nvarchar(256), requestid int)

insert into #who exec sp_who2

select * from #who 
--where dbname = 'BPM' 
--where spid in (144, 59)
--where loginname not in ('asasa', 'AMSA\SvProdSQLAgentExec', 'AMSA\sv_Idera', 'AMSA\SvProdSSRSExec', 'amsa\tflaherty', '') -- aopsdbs040
order by blkby desc, cast(spid as int) asc

drop table #who

-- use this dbcc command to look at the input buffer for a spid
-- dbcc inputbuffer(51)

end try

begin catch
drop table #who
end catch

SELECT  tl.resource_type ,
        tl.resource_database_id ,
        tl.resource_associated_entity_id ,
        tl.request_mode ,
        tl.request_session_id ,
        wt.blocking_session_id ,
        wt.wait_type ,
        wt.wait_duration_ms
FROM    sys.dm_tran_locks AS tl
        INNER JOIN sys.dm_os_waiting_tasks AS wt
           ON tl.lock_owner_address = wt.resource_address
ORDER BY wait_duration_ms DESC ;
/*

-2 = The blocking resource is owned by an orphaned distributed transaction.

-3 = The blocking resource is owned by a deferred recovery transaction.

-4 = Session ID of the blocking latch owner could not be determined due to internal latch state transitions.

Captured from adevdbs034 BPM database on 08/28/2012 10:48

resource_type	resource_database_id	resource_associated_entity_id	request_mode	request_session_id	blocking_session_id	wait_type	wait_duration_ms
KEY				7						72057594071351296				U				77					-2					LCK_M_U		1666420
KEY				7						72057594058506240				S				108					-2					LCK_M_S		1494568

Captured from adevdbs023\bts1 on 09/27/2012 15:34

KEY				7						72057594422493184				U				187					-2					LCK_M_U		35009
KEY				7						72057594422493184				U				179					187					LCK_M_U		34716
OBJECT			7						1989582126						X				98					-2					LCK_M_X		34390

*/
