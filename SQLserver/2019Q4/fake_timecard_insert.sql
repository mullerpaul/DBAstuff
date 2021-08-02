begin transaction;

insert into timecard
select x.client_id,
       newid() as timecard_id,
       t.timecard_date as create_timestamp,  -- all created at "midnight" is that OK?  if not, add an offset and random distribution of minutes
       x.job_id,
       CASE 
	     WHEN cast(crypt_gen_random(1) as INT) < 178 then 'approved'
		 WHEN cast(crypt_gen_random(1) as INT) < 229 then 'created' 
		 when cast(crypt_gen_random(1) as INT) < 240 then 'pending'
		 else 'rejected' 
	   end as status,  -- we can add some randomness here if needed
	   x.client_name,
	   x.work_location,
	   NULL as contractor_name
  from (select j.client_guid as client_id, 
               c.client_name,
	           j.job_guid as job_id,
	           l.location_name as work_location
          from fake_job_ids j 
		       inner join fake_job_locations l on (j.job_location_id = l.id)
		       inner join fake_client_guid c on (j.client_guid = c.client_guid)
	   ) x 
	   cross join fake_timecard_week t   -- cross or "cartesian" join
;

commit transaction;
