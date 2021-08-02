DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_CAC_COLLECTION_CURRENT';
  lv_syn_name    lego_refresh.synonym_name%TYPE := REPLACE(lv_object_name, 'LEGO_') || '_IQP';
  lv_object_cnt  PLS_INTEGER;

BEGIN

  SELECT COUNT(*)
    INTO lv_object_cnt
    FROM user_tables
   WHERE table_name IN (lv_syn_name||'1',lv_syn_name||'2');

  IF lv_object_cnt = 0 THEN 
  
  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0       AS cac_id, 
                                'abc'   AS source_name, 
                                0       AS cac_collection_id,
                                'abc'   AS cac_guid,
                                0       AS bus_org_id,
                                0       AS cac_kind,
                                SYSDATE AS start_date,
                                SYSDATE AS end_date,   
                                SYSDATE AS load_date,
                                'abc' AS attribute_md5_hash				
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create or replace synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';
  EXECUTE IMMEDIATE 'grant select on '||lv_syn_name||' to  finance WITH GRANT OPTION';
  EXECUTE IMMEDIATE 'grant select on '||lv_syn_name||' to  finance_user';
  
  ELSE
    EXECUTE IMMEDIATE 'grant select on '||lv_syn_name||' to  finance WITH GRANT OPTION';
    EXECUTE IMMEDIATE 'grant select on '||lv_syn_name||' to  finance_user';
  END IF;
  
  lv_syn_name := REPLACE(lv_object_name, 'LEGO_') || '_WF';
  
  SELECT COUNT(*)
    INTO lv_object_cnt
    FROM user_tables
   WHERE table_name IN (lv_syn_name||'1',lv_syn_name||'2');  
  
  IF lv_object_cnt = 0 THEN
  
  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0       AS cac_id, 
                                'abc'   AS source_name, 
                                0       AS cac_collection_id,
                                'abc'   AS cac_guid,
                                0       AS bus_org_id,
                                0       AS cac_kind,
                                SYSDATE AS start_date,
                                SYSDATE AS end_date,   
                                SYSDATE AS load_date,
                                'abc' AS attribute_md5_hash				
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create or replace synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';  
  EXECUTE IMMEDIATE 'grant select on '||lv_syn_name||' to  finance WITH GRANT OPTION';
  EXECUTE IMMEDIATE 'grant select on '||lv_syn_name||' to  finance_user';
  
  ELSE
    EXECUTE IMMEDIATE 'grant select on '||lv_syn_name||' to  finance WITH GRANT OPTION';
    EXECUTE IMMEDIATE 'grant select on '||lv_syn_name||' to  finance_user';
  END IF;
  
END;
/