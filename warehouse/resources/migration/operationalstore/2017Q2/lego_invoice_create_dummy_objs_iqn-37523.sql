DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_INVOICE';
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
                 q'{  as SELECT 0       AS buyer_org_id, 
                                'abc'   AS is_adjustment, 
                                SYSDATE AS cutoff_time,
                                0 AS expenditure_count,
                                0 AS total_bill_amount,
                                0 AS total_buyer_adjusted_amount,
                                0 AS total_supplier_reimb_amount,
                                0 AS total_fee_amount,   
                                0 AS total_buyer_fee_amount,
                                0 AS total_supplier_fee_amount,
								SYSDATE AS bill_through_date, 
								SYSDATE AS invoice_create_date,
								0 AS created_by_person_id,
                                SYSDATE AS last_update_date,
								SYSDATE AS approved_date,
                                0 AS last_updated_by_person_id,
								0 AS version,
                                0 AS invoice_adjustment_id,
								0 AS invoice_number,                                
                                'abc' AS has_taxes_discounts_applied,
                                0 AS net_buyer_adjusted_amount,                                                                   
								0 AS total_buyer_tax_amount,
                                0 AS total_buyer_discount_amount,								
								0 AS configuration_edition_id,
								0 AS total_supplier_tax_amount,
                                0 AS total_supplier_discount_amount,
								0 AS net_supplier_reimb_amount,								
                                0 AS invoice_batch_id,       
                                SYSDATE AS invoice_date,
                                0 AS total_mgmt_fee_tax_amount,
                                0 AS total_mgmt_fee_rebate_amount,
                                0 AS total_wthldg_tax_on_fee_amount,
                                0 AS currency_id,
                                'abc' AS currency								
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
                 q'{  as SELECT 0       AS buyer_org_id, 
                                'abc'   AS is_adjustment, 
                                SYSDATE AS cutoff_time,
                                0 AS expenditure_count,
                                0 AS total_bill_amount,
                                0 AS total_buyer_adjusted_amount,
                                0 AS total_supplier_reimb_amount,
                                0 AS total_fee_amount,   
                                0 AS total_buyer_fee_amount,
                                0 AS total_supplier_fee_amount,
								SYSDATE AS bill_through_date, 
								SYSDATE AS invoice_create_date,
								0 AS created_by_person_id,
                                SYSDATE AS last_update_date,
								SYSDATE AS approved_date,
                                0 AS last_updated_by_person_id,
								0 AS version,
                                0 AS invoice_adjustment_id,
								0 AS invoice_number,                                
                                'abc' AS has_taxes_discounts_applied,
                                0 AS net_buyer_adjusted_amount,                                                                   
								0 AS total_buyer_tax_amount,
                                0 AS total_buyer_discount_amount,								
								0 AS configuration_edition_id,
								0 AS total_supplier_tax_amount,
                                0 AS total_supplier_discount_amount,
								0 AS net_supplier_reimb_amount,								
                                0 AS invoice_batch_id,       
                                SYSDATE AS invoice_date,
                                0 AS total_mgmt_fee_tax_amount,
                                0 AS total_mgmt_fee_rebate_amount,
                                0 AS total_wthldg_tax_on_fee_amount,
                                0 AS currency_id,
                                'abc' AS currency								
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