-- drop newly-unused columns (and their constraints) on lego_refresh
ALTER TABLE lego_refresh
DROP (refresh_schedule, 
      refresh_group, 
      refresh_dependency_order, 
      refresh_on_or_after_time, 
      started_refresh
     ) 
/
