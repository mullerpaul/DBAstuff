DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_CAC_CURRENT';
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
                 q'{  as SELECT 'abc'   AS cac_guid, 
                                'abc'   AS source_name, 
								'abc'   AS cac_oid,
								'abc'   AS cac_value,
								'abc'   AS cac_desc,
								0       AS cac_segment_1_id,
								'abc'   AS cac_segment_1_value,
								'abc'   AS cac_segment_1_desc,
								0       AS cac_segment_2_id,
								'abc'   AS cac_segment_2_value,
								'abc'   AS cac_segment_2_desc,
								0       AS cac_segment_3_id,
								'abc'   AS cac_segment_3_value,
								'abc'   AS cac_segment_3_desc,
								0       AS cac_segment_4_id,
								'abc'   AS cac_segment_4_value,
								'abc'   AS cac_segment_4_desc,
								0       AS cac_segment_5_id,
								'abc'   AS cac_segment_5_value,
								'abc'   AS cac_segment_5_desc,																															
                                SYSDATE AS load_date,
                                'abc'   AS attribute_md5_hash			
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
                 q'{  as SELECT 'abc'   AS cac_guid, 
                                'abc'   AS source_name, 
								'abc'   AS cac_oid,
								'abc'   AS cac_value,
								'abc'   AS cac_desc,
								0       AS cac_segment_1_id,
								'abc'   AS cac_segment_1_value,
								'abc'   AS cac_segment_1_desc,
								0       AS cac_segment_2_id,
								'abc'   AS cac_segment_2_value,
								'abc'   AS cac_segment_2_desc,
								0       AS cac_segment_3_id,
								'abc'   AS cac_segment_3_value,
								'abc'   AS cac_segment_3_desc,
								0       AS cac_segment_4_id,
								'abc'   AS cac_segment_4_value,
								'abc'   AS cac_segment_4_desc,
								0       AS cac_segment_5_id,
								'abc'   AS cac_segment_5_value,
								'abc'   AS cac_segment_5_desc,																															
                                SYSDATE AS load_date,
                                'abc'   AS attribute_md5_hash			
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