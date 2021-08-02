DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_ADDRESS';
  lv_syn_name    lego_refresh.synonym_name%TYPE :=  lv_object_name || '_IQP';

BEGIN

  /* Dummy table and synonym so that view can be created valid. */
  BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE ' || lv_syn_name || '1' || 
                   q'{  as SELECT CAST(NULL AS RAW(16)) AS address_guid, 
                                  123 AS country_id,
                                  'abc' AS country,
                                  'abc' AS country_code,
                                  'abc' AS state,
                                  'abc' AS city,  
                                  'abc' AS postal_code,
                                  123   AS place_id,
                                  'abc' AS standard_place_desc,                                                                    
                                  'abc' AS line1,
                                  'abc' AS line2,
                                  'abc' AS line3,
                                  'abc' AS line4,
                                  'abc' AS county                                                                 
                             FROM dual WHERE 1=0}';    
                           
  
  
  
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
  
  BEGIN 
    EXECUTE IMMEDIATE 'CREATE SYNONYM ' || lv_syn_name || ' FOR ' || lv_syn_name || '1';
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
  
  BEGIN 
    EXECUTE IMMEDIATE 'GRANT SELECT ON '|| lv_syn_name || '1' ||' TO ops, readonly';
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;  
  
  
  lv_syn_name := lv_object_name || '_WF';
  

  /* Dummy table and synonym so that view can be created valid. */
  BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE ' || lv_syn_name || '1' || 
                   q'{  as SELECT CAST(NULL AS RAW(16)) AS address_guid, 
                                  123 AS country_id,
                                  'abc' AS country,
                                  'abc' AS country_code,
                                  'abc' AS state,
                                  'abc' AS city,  
                                  'abc' AS postal_code,
                                  123   AS place_id,
                                  'abc' AS standard_place_desc,                                                                    
                                  'abc' AS line1,
                                  'abc' AS line2,
                                  'abc' AS line3,
                                  'abc' AS line4,
                                  'abc' AS county                                                                 
                             FROM dual WHERE 1=0}';
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
  
  BEGIN 
    EXECUTE IMMEDIATE 'CREATE SYNONYM ' || lv_syn_name || ' FOR ' || lv_syn_name || '1';
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;   

  BEGIN 
    EXECUTE IMMEDIATE 'GRANT SELECT ON '|| lv_syn_name || '1' ||' TO ops, readonly';
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;  
  

END;
/