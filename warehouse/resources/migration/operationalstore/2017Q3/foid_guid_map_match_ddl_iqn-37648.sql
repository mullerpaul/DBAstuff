/* Joe Pullifrone 
   05/17/2017
   IQN-37648

*/

BEGIN

  EXECUTE IMMEDIATE 'DROP TABLE match_foid_guid_map PURGE';
     
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/

CREATE TABLE match_foid_guid_map (
match_id        NUMBER(38),
match_guid      RAW(16),
etl_load_date   DATE
)
/

ALTER TABLE match_foid_guid_map 
ADD CONSTRAINT match_foid_guid_map_pk PRIMARY KEY (match_id)
/
