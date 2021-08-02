DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_BUS_ORG';
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
                 q'{  as SELECT 0       AS bus_org_id, 
                                'abc'   AS bus_org_type, 
                                'abc'   AS bus_org_name,
                                0       AS parent_bus_org_id,
                                0       AS enterprise_id,
                                0       AS enterprise_bus_org_id,
                                'abc'   AS enterprise_name,
                                'abc'   AS managing_organization,   
                                0       AS firm_id,
                                0       AS marketplace_id,
								0       AS buyer_udf_collection_id, 
								0       AS supplier_udf_collection_id,
								0       AS contact_info_id,
                                'abc' AS inheritance_mode					
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';
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
                 q'{  as SELECT 0       AS bus_org_id, 
                                'abc'   AS bus_org_type, 
                                'abc'   AS bus_org_name,
                                0       AS parent_bus_org_id,
                                0       AS enterprise_id,
                                0       AS enterprise_bus_org_id,
                                'abc'   AS enterprise_name,
                                'abc'   AS managing_organization,   
                                0       AS firm_id,
                                0       AS marketplace_id,
								0       AS buyer_udf_collection_id, 
								0       AS supplier_udf_collection_id,
								0       AS contact_info_id,
                                'abc' AS inheritance_mode					
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';  
  EXECUTE IMMEDIATE 'grant select on '||lv_syn_name||' to  finance WITH GRANT OPTION';
  EXECUTE IMMEDIATE 'grant select on '||lv_syn_name||' to  finance_user';  

  ELSE
    EXECUTE IMMEDIATE 'grant select on '||lv_syn_name||' to  finance WITH GRANT OPTION';
    EXECUTE IMMEDIATE 'grant select on '||lv_syn_name||' to  finance_user';
	
  END IF;
  
END;
/