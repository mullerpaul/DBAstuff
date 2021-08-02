/* Joe Pullifrone 
   05/17/2017
   IQN-37648

*/

BEGIN

  EXECUTE IMMEDIATE 'DROP TABLE job_opp_foid_guid_map PURGE';
     
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/

CREATE TABLE job_opp_foid_guid_map (
job_opportunity_id        NUMBER(38),
job_opportunity_guid      RAW(16),
etl_load_date             DATE
)
/

ALTER TABLE job_opp_foid_guid_map 
ADD CONSTRAINT job_opp_foid_guid_map_pk PRIMARY KEY (job_opportunity_id)
/
