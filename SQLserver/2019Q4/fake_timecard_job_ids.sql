--- make and load a table to hold job GUIDs and locations
create table fake_job_ids
 (client_guid     uniqueidentifier,
  job_guid        uniqueidentifier,
  job_location_id int
 );

 -- run this 10 times, manually changing the hardcoded ID each time.
 -- I'd normally do this in a loop; but haven't figured out the T-SQL syntax syntax yet and since its 
 -- just 10 times, manual will be faster.
 -- BTW the SQRTs are an easy way to give a nice skewed distribution.  A few very common values and a few uncommon ones.
begin transaction;

INSERT INTO fake_job_ids
SELECT f.client_guid, 
       newid() as job_id,
--       x.id % 51 as job_location_id1,  --using sqrt instead of mod to get skew
--       round(f.id - 1  + sqrt(x.id), 0) as job_location_id2,  --skewed wrong way!
	   f.id + round(sqrt(f.job_count) - sqrt(x.id), 0) as job_location_id
  from fake_client_guid f,
       (SELECT ROW_NUMBER() OVER (ORDER BY a.object_id) as id 
	      FROM sys.all_objects a) x
 where x.id < f.job_count 
   and f.id = 1;
   
INSERT INTO fake_job_ids
SELECT f.client_guid, 
       newid() as job_id,
	   f.id + round(sqrt(f.job_count) - sqrt(x.id), 0) as job_location_id
  from fake_client_guid f,
       (SELECT ROW_NUMBER() OVER (ORDER BY a.object_id) as id 
	      FROM sys.all_objects a) x
 where x.id < f.job_count 
   and f.id = 2;

INSERT INTO fake_job_ids
SELECT f.client_guid, 
       newid() as job_id,
	   f.id + round(sqrt(f.job_count) - sqrt(x.id), 0) as job_location_id
  from fake_client_guid f,
       (SELECT ROW_NUMBER() OVER (ORDER BY a.object_id) as id 
	      FROM sys.all_objects a) x
 where x.id < f.job_count 
   and f.id = 3;

INSERT INTO fake_job_ids
SELECT f.client_guid, 
       newid() as job_id,
	   f.id + round(sqrt(f.job_count) - sqrt(x.id), 0) as job_location_id
  from fake_client_guid f,
       (SELECT ROW_NUMBER() OVER (ORDER BY a.object_id) as id 
	      FROM sys.all_objects a) x
 where x.id < f.job_count 
   and f.id = 4;

INSERT INTO fake_job_ids
SELECT f.client_guid, 
       newid() as job_id,
	   f.id + round(sqrt(f.job_count) - sqrt(x.id), 0) as job_location_id
  from fake_client_guid f,
       (SELECT ROW_NUMBER() OVER (ORDER BY a.object_id) as id 
	      FROM sys.all_objects a) x
 where x.id < f.job_count 
   and f.id = 5;

INSERT INTO fake_job_ids
SELECT f.client_guid, 
       newid() as job_id,
	   f.id + round(sqrt(f.job_count) - sqrt(x.id), 0) as job_location_id
  from fake_client_guid f,
       (SELECT ROW_NUMBER() OVER (ORDER BY a.object_id) as id 
	      FROM sys.all_objects a) x
 where x.id < f.job_count 
   and f.id = 6;

INSERT INTO fake_job_ids
SELECT f.client_guid, 
       newid() as job_id,
	   f.id + round(sqrt(f.job_count) - sqrt(x.id), 0) as job_location_id
  from fake_client_guid f,
       (SELECT ROW_NUMBER() OVER (ORDER BY a.object_id) as id 
	      FROM sys.all_objects a) x
 where x.id < f.job_count 
   and f.id = 7;

INSERT INTO fake_job_ids
SELECT f.client_guid, 
       newid() as job_id,
	   f.id + round(sqrt(f.job_count) - sqrt(x.id), 0) as job_location_id
  from fake_client_guid f,
       (SELECT ROW_NUMBER() OVER (ORDER BY a.object_id) as id 
	      FROM sys.all_objects a) x
 where x.id < f.job_count 
   and f.id = 8;

INSERT INTO fake_job_ids
SELECT f.client_guid, 
       newid() as job_id,
	   f.id + round(sqrt(f.job_count) - sqrt(x.id), 0) as job_location_id
  from fake_client_guid f,
       (SELECT ROW_NUMBER() OVER (ORDER BY a.object_id) as id 
	      FROM sys.all_objects a) x
 where x.id < f.job_count 
   and f.id = 9;

INSERT INTO fake_job_ids
SELECT f.client_guid, 
       newid() as job_id,
	   f.id + round(sqrt(f.job_count) - sqrt(x.id), 0) as job_location_id
  from fake_client_guid f,
       (SELECT ROW_NUMBER() OVER (ORDER BY a.object_id) as id 
	      FROM sys.all_objects a) x
 where x.id < f.job_count 
   and f.id = 10;

commit transaction;
