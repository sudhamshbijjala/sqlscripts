ALTER DATABASE master
  MODIFY FILE (name = 'master', size = 100 MB);
  
ALTER DATABASE master
  MODIFY FILE (name = 'mastlog', size = 50 MB);
  
ALTER DATABASE msdb
  MODIFY FILE (name = 'msdbdata', size = 100 MB);
  
ALTER DATABASE msdb
  MODIFY FILE (name = 'msdblog', size = 50 MB);
  