select OBJECT_NAME(object_id) as table_name
, STATS_DATE(object_id, stats_id) as table_stats_updated
, *
from sys.stats
order by 2 desc

