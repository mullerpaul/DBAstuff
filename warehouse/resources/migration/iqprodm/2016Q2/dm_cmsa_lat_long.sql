--IQN-32013 Assignment By Location 
--Joe Pullifrone, 5/16/2016
--The pupose of this script is to change structure of DM_CMSA:
--column, state_code will be renamed to primary_state_code
--column primary_city_name will be added
--columns latitude and longitude will be added and populated as well 

--Noted on 5/14/2016
--Will have to look at potentially making changes to DM_RATE_EVENT and DM_FOTIMECARD_RATE_EVENT packages
--since they both use dm_cmsa.  

--I investigated the above assumption and it turns out to be false.  Reason is that those two packages
--only reference the 2 columns on dm_cmsa while are not changing, therefore, no changes are 
--necessary.

--select *
--  from user_source 
-- where upper(text) like '%DM_CMSA%';

CREATE TABLE dm_cmsa_bkp AS
SELECT *
  FROM dm_cmsa
/
TRUNCATE TABLE dm_cmsa REUSE STORAGE
/
ALTER TABLE dm_cmsa RENAME COLUMN state_code TO primary_state_code
/
ALTER TABLE dm_cmsa ADD primary_city_name VARCHAR2(100)
/
ALTER TABLE dm_cmsa ADD latitude NUMBER(9,6)
/
ALTER TABLE dm_cmsa ADD longitude NUMBER(9,6)
/
COMMENT ON COLUMN  dm_cmsa.primary_state_code  IS 'Primary designated state for entire CMSA'
/
COMMENT ON COLUMN  dm_cmsa.primary_city_name   IS 'Primary designated city for entire CMSA'
/
COMMENT ON COLUMN  dm_cmsa.latitude            IS 'Latitude for primary designated city for entire CMSA'
/
COMMENT ON COLUMN  dm_cmsa.longitude           IS 'Longitude for primary designated city for entire CMSA'
/
