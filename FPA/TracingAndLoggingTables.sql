/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [id]
      ,[package_name]
      ,[logging_date]
      ,[debug_message]
      ,[trace_logging_id]
  FROM [FPA_Configuration].[dbo].[t_debug_logging]
--  where logging_date > getdate() -1
  order by logging_date desc

SELECT [id]
      ,[file_id]
      ,[package_name]
      ,[start_time]
      ,[end_time]
      ,[success_flag]
  FROM [FPA_Configuration].[dbo].[t_trace_logging] where start_time > getdate()-1

	select 
	t.start_time, 
	t.end_time, 
	substring(d.debug_message, 32, 30) as RecordCount, 
	convert(nvarchar(8),(coalesce(t.end_time, '2020-01-01') - t.start_time), 108) as 'ElapsedTime(HH:MM:SS)',
	case t.success_flag
	when 0 then 'Failure'
	when 1 then 'Success'
	end as CompletionStatus
	FROM [FPA_Configuration].[dbo].[t_debug_logging] d
	inner join [FPA_Configuration].[dbo].[t_trace_logging] t
		on d.logging_date between t.start_time and coalesce(t.end_time, '2020-01-01')
	where d.debug_message like 'Finished loading file records. Total record count: %'
	and t.success_flag = 1
--	order by RecordCount desc
	order by start_time

